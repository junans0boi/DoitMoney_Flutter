// lib/widgets/news_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/news_provider.dart';
import '../../constants/colors.dart';

/// A reusable banner that shows today’s finance news.
///
/// [height], [borderRadius], and [fontSize] allow you to tweak it on each page.
class NewsBanner extends ConsumerWidget {
  final double height;
  final BorderRadius borderRadius;
  final double fontSize;

  const NewsBanner({
    super.key,
    this.height = 152,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return newsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return SizedBox(
            height: height,
            child: const Center(child: Text('금융 뉴스를 불러올 수 없습니다.')),
          );
        }
        return SizedBox(
          height: height,
          child: PageView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, idx) {
              final item = list[idx];
              return ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.thumbnail.isNotEmpty)
                      Image.network(item.thumbnail, fit: BoxFit.cover)
                    else
                      Container(color: Colors.grey.shade200),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.only(
                            bottomLeft: borderRadius.bottomLeft,
                            bottomRight: borderRadius.bottomRight,
                          ),
                        ),
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading:
          () => SizedBox(
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => SizedBox(
            height: height,
            child: Center(child: Text('뉴스 로드 실패: $e')),
          ),
    );
  }
}
