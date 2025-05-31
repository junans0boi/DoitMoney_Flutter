//lib/services/news_service.dart
import '../api/dio_client.dart';

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
  /// 오늘자 금융 뉴스 불러오기
  static Future<List<NewsArticle>> fetchTodayNews() async {
    final res = await dio.get('/news/today');
    if (res.statusCode != 200) {
      throw Exception('뉴스 로드 실패 (${res.statusCode})');
    }
    final data = res.data as List;
    return data
        .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
