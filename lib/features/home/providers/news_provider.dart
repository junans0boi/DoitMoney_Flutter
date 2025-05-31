// lib/providers/news_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/news_service.dart';

/// 오늘자 뉴스 목록 – ref.keepAlive() + Timer 로 24시간 후 만료
final newsProvider = FutureProvider<List<NewsArticle>>((ref) {
  // 1) keepAlive 링크를 얻고
  final link = ref.keepAlive();

  // 2) 24시간 후에 close() 호출해서 캐시 만료시키기
  final timer = Timer(const Duration(hours: 24), () {
    link.close();
  });

  // 3) 이 provider 가 dispose 될 때 timer 도 해제
  ref.onDispose(() {
    timer.cancel();
  });

  // 실제 데이터 fetch
  return NewsService.fetchTodayNews();
});
