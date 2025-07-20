//lib/services/news_service.dart
import 'package:flutter/material.dart';

import '../../../core/api/dio_client.dart';

class NewsArticle {
  final String title;
  final String link;
  final String thumbnail;

  NewsArticle({
    required this.title,
    required this.link,
    required this.thumbnail,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
    title: json['title'] as String,
    link: json['link'] as String,
    thumbnail: json['thumbnail'] as String? ?? '',
  );
}

class NewsService {
  static Future<List<NewsArticle>> fetchTodayNews() async {
    try {
      final res = await dio.get('/news/today');
      if (res.statusCode != 200 || res.data is! List) {
        throw Exception();
      }
      return (res.data as List).map((e) {
        final map = e as Map<String, dynamic>;
        return NewsArticle(
          title: map['title'] as String,
          link: map['link'] as String,
          thumbnail: map['thumbnail'] as String? ?? 'assets/images/default.png',
        );
      }).toList();
    } catch (e) {
      debugPrint('[뉴스 로드 실패] $e');
      return [];
    }
  }
}
