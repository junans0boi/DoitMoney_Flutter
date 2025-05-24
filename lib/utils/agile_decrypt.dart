import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart';

// ── pointycastle
import 'package:pointycastle/api.dart'
    show Digest, KeyParameter, ParametersWithIV; // ← Digest 추가
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/digests/sha1.dart';
import 'package:pointycastle/digests/sha512.dart';

class AgileDecryptResult {
  final bool ok;
  final Uint8List? bytes;
  final String? error;
  const AgileDecryptResult.success(this.bytes) : ok = true, error = null;
  const AgileDecryptResult.fail(this.error) : ok = false, bytes = null;
}

class AgileDecryptor {
  /// AES-128/256 “Agile Encryption”(.xlsx) 복호화
  static AgileDecryptResult decryptXlsx(Uint8List fileBytes, String password) {
    try {
      // 0️⃣  ZIP 내부 스트림 추출 --------------------------------------------------
      final zip = ZipDecoder().decodeBytes(fileBytes);
      final infoEntry =
          zip.findFile('EncryptionInfo') ?? zip.findFile('encryptionInfo');
      final pkgEntry =
          zip.findFile('EncryptedPackage') ?? zip.findFile('encryptedPackage');
      if (infoEntry == null || pkgEntry == null) {
        return const AgileDecryptResult.fail('EncryptionInfo stream 없음');
      }

      final reader = _InfoReader(infoEntry.content as Uint8List);

      // 1️⃣  헤더 파라미터 --------------------------------------------------------
      final algo = reader.hashAlgo; // SHA1 / SHA512
      final salt = reader.salt;
      final spin = reader.spinCount;
      final keyBits = reader.keyBits; // 128 / 256
      final blockSize = reader.blockSize; // 16
      final verifierIn = reader.verifierHashInput;
      final verifierEn = reader.verifierHashValue;
      final encryptedKey = reader.encryptedKey;

      // 2️⃣  비밀번호 → FinalKey  (SHA-1/512 * spinCount, UTF-16LE) --------------
      Uint8List _utf16Le(String s) {
        final bytes = Uint8List(s.length * 2);
        final bd = bytes.buffer.asByteData();
        for (var i = 0; i < s.length; i++) {
          bd.setUint16(i * 2, s.codeUnitAt(i), Endian.little);
        }
        return bytes;
      }

      Uint8List _hash(Uint8List data, Digest d) {
        d
          ..reset()
          ..update(data, 0, data.length);
        final out = Uint8List(d.digestSize);
        d.doFinal(out, 0);
        return out;
      }

      final Digest digest = (algo == 'SHA1') ? SHA1Digest() : SHA512Digest();

      // step-1 : H(salt ‖ pwdUtf16)
      Uint8List hash = _hash(
        Uint8List.fromList(salt + _utf16Le(password)),
        digest,
      );

      // step-2 : spinCount 반복
      for (var i = 0; i < spin; i++) {
        final ctr = ByteData(4)..setUint32(0, i, Endian.little);
        hash = _hash(
          Uint8List.fromList(hash + ctr.buffer.asUint8List()),
          digest,
        );
      }

      // step-3 : 앞 keyBits/8 바이트 = FinalKey
      final finalKey = hash.sublist(0, keyBits ~/ 8);

      // 3️⃣  AES-CBC 유틸 --------------------------------------------------------
      Uint8List _aesCbc(Uint8List key, Uint8List iv, Uint8List data) {
        final cipher = CBCBlockCipher(AESFastEngine())
          ..init(false, ParametersWithIV(KeyParameter(key), iv));
        final out = Uint8List(data.length);
        for (var off = 0; off < data.length; off += cipher.blockSize) {
          cipher.processBlock(data, off, out, off);
        }
        return out;
      }

      final ivZero = Uint8List(blockSize);

      // 4️⃣  masterKey & verifier 복호화 -----------------------------------------
      final masterKey = _aesCbc(
        finalKey,
        ivZero,
        encryptedKey,
      ).sublist(0, keyBits ~/ 8);
      final verifier = _aesCbc(masterKey, ivZero, verifierIn);
      final verifierHash = _aesCbc(
        masterKey,
        ivZero,
        verifierEn,
      ).sublist(0, algo == 'SHA1' ? 20 : 64);

      // 5️⃣  비밀번호 검증 -------------------------------------------------------
      final calc = _hash(verifier, digest).sublist(0, verifierHash.length);
      if (!const ListEquality().equals(calc, verifierHash)) {
        return const AgileDecryptResult.fail('비밀번호 불일치');
      }

      // 6️⃣  EncryptedPackage 해제 ----------------------------------------------
      final decrypted = _aesCbc(
        masterKey,
        ivZero,
        pkgEntry.content as Uint8List,
      );
      return AgileDecryptResult.success(decrypted);
    } catch (e) {
      return AgileDecryptResult.fail(e.toString());
    }
  }
}

/* ───── EncryptionInfo 바이너리 파서 ───── */
class _InfoReader {
  final ByteData _bd;
  _InfoReader(Uint8List bytes) : _bd = ByteData.sublistView(bytes);

  int get keyBits => _bd.getUint32(0x18, Endian.little);
  int get blockSize => _bd.getUint32(0x1C, Endian.little);
  int get spinCount => _bd.getUint32(0x28, Endian.little);
  String get hashAlgo =>
      (_bd.getUint32(0x20, Endian.little) == 0x8004) ? 'SHA1' : 'SHA512';

  Uint8List _slice(int off, int len) => Uint8List.view(_bd.buffer, off, len);

  Uint8List get salt {
    final len = _bd.getUint32(0x2C, Endian.little);
    return _slice(0x30, len);
  }

  Uint8List get verifierHashInput {
    final sLen = _bd.getUint32(0x2C, Endian.little);
    final off = 0x34 + sLen;
    final len = _bd.getUint32(off, Endian.little);
    return _slice(off + 4, len);
  }

  Uint8List get verifierHashValue {
    final sLen = _bd.getUint32(0x2C, Endian.little);
    var off = 0x34 + sLen;
    off += 4 + _bd.getUint32(off, Endian.little); // verifierIn
    final len = _bd.getUint32(off, Endian.little);
    return _slice(off + 4, len);
  }

  Uint8List get encryptedKey {
    final sLen = _bd.getUint32(0x2C, Endian.little);
    var off = 0x34 + sLen;
    off += 4 + _bd.getUint32(off, Endian.little); // verifierIn
    off += 4 + _bd.getUint32(off, Endian.little); // verifierHash
    final len = _bd.getUint32(off, Endian.little);
    return _slice(off + 4, len);
  }
}
