// lib/shared/widgets/news_banner.dart (리팩터 후, 약간 주석 정리만)
// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/providers/news_provider.dart';

/// 오늘자 금융 뉴스를 PageView로 보여주는 위젯
class NewsBanner extends ConsumerWidget {
  final double height;
  final BorderRadius borderRadius;
  final double fontSize;

  const NewsBanner({
    Key? key,
    this.height = 152,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fontSize = 14,
  }) : super(key: key);

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
