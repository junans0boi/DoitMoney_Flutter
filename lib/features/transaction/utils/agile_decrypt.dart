// lib/utils/agile_decrypt.dart
// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:pointycastle/api.dart'
    show Digest, KeyParameter, ParametersWithIV;
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
  static AgileDecryptResult decryptXlsx(Uint8List fileBytes, String password) {
    try {
      final archive = ZipDecoder().decodeBytes(fileBytes);
      final infoFile = archive.files.firstWhere(
        (f) => f.name.toLowerCase() == 'encryptioninfo',
        orElse: () => throw 'EncryptionInfo stream 없음',
      );
      final pkgFile = archive.files.firstWhere(
        (f) => f.name.toLowerCase() == 'encryptedpackage',
        orElse: () => throw 'EncryptedPackage stream 없음',
      );

      final head = _InfoReader(infoFile.content as Uint8List);

      // 1) 암호→키 생성
      Uint8List utf16le(String s) {
        final out = Uint8List(s.length * 2);
        final bd = out.buffer.asByteData();
        for (var i = 0; i < s.length; i++) {
          bd.setUint16(i * 2, s.codeUnitAt(i), Endian.little);
        }
        return out;
      }

      Digest digest = head.hashAlgo == 'SHA1' ? SHA1Digest() : SHA512Digest();
      Uint8List hash(Uint8List d) {
        digest.reset();
        digest.update(d, 0, d.length);
        final out = Uint8List(digest.digestSize);
        digest.doFinal(out, 0);
        return out;
      }

      // salt || UTF16LE(pwd)
      Uint8List h = hash(Uint8List.fromList(head.salt + utf16le(password)));
      for (var i = 0; i < head.spinCount; i++) {
        final ctr = ByteData(4)..setUint32(0, i, Endian.little);
        h = hash(Uint8List.fromList(h + ctr.buffer.asUint8List()));
      }
      final finalKey = h.sublist(0, head.keyBits ~/ 8);

      // AES-CBC 복호화 함수
      Uint8List aes(Uint8List key, Uint8List iv, Uint8List inp) {
        final cipher = CBCBlockCipher(AESFastEngine())
          ..init(false, ParametersWithIV(KeyParameter(key), iv));
        final out = Uint8List(inp.length);
        for (var offset = 0; offset < inp.length; offset += cipher.blockSize) {
          cipher.processBlock(inp, offset, out, offset);
        }
        return out;
      }

      final iv0 = Uint8List(head.blockSize);
      final masterKey = aes(
        finalKey,
        iv0,
        head.encryptedKey,
      ).sublist(0, head.keyBits ~/ 8);
      final verIn = aes(masterKey, iv0, head.verifierHashInput);
      final verHash = aes(masterKey, iv0, head.verifierHashValue);
      final calcHash = hash(verIn).sublist(0, verHash.length);
      if (!const ListEquality().equals(calcHash, verHash)) {
        return const AgileDecryptResult.fail('비밀번호 불일치');
      }

      // 실제 패키지 평문
      final plainPkg = aes(masterKey, iv0, pkgFile.content as Uint8List);

      // 2) archive 내부에 교체
      final idx = archive.files.indexOf(pkgFile);
      // 메타 복사
      final newFile =
          ArchiveFile(pkgFile.name, plainPkg.length, plainPkg)
            ..mode = pkgFile.mode
            ..lastModTime = pkgFile.lastModTime;
      archive.files[idx] = newFile;

      // 3) 전체 ZIP 재생성
      final newBytes = ZipEncoder().encode(archive);
      if (newBytes == null) throw 'ZIP 재인코딩 실패';

      return AgileDecryptResult.success(Uint8List.fromList(newBytes));
    } catch (e) {
      return AgileDecryptResult.fail(e.toString());
    }
  }
}

class _InfoReader {
  final ByteData _bd;
  _InfoReader(Uint8List src) : _bd = ByteData.sublistView(src);

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
    off += 4 + _bd.getUint32(off, Endian.little);
    final len = _bd.getUint32(off, Endian.little);
    return _slice(off + 4, len);
  }

  Uint8List get encryptedKey {
    final sLen = _bd.getUint32(0x2C, Endian.little);
    var off = 0x34 + sLen;
    off += 4 + _bd.getUint32(off, Endian.little);
    off += 4 + _bd.getUint32(off, Endian.little);
    final len = _bd.getUint32(off, Endian.little);
    return _slice(off + 4, len);
  }
}
