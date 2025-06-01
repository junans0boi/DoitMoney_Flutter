// lib/features/more/providers/more_providers.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 예시: 서버에서 가져오는 현재 포인트 (여기선 간단히 0으로 초기화)
final pointProvider = StateProvider<int>((_) => 0);

/// 다크 모드 여부 관리
final darkModeProvider = StateProvider<bool>((_) => false);
