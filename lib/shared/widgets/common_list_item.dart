// lib/shared/widgets/common_list_item.dart

// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

/// 화면에서 "레이블 + 값"을 한 행으로 보여주고, 필요하면 텍스트 컬러나 기타 옵션을 지정할 수 있습니다.
/// - label: 왼쪽에 보여줄 텍스트
/// - value: 오른쪽에 보여줄 텍스트
/// - valueColor: 값 텍스트의 색상, 기본은 검은색
/// - onTap: 해당 행을 클릭했을 때
/// - showArrow: 오른쪽에 chevron 아이콘을 표시할지 여부
class CommonListItem extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool showArrow;

  const CommonListItem({
    Key? key,
    required this.label,
    this.value,
    this.valueColor,
    this.onTap,
    this.showArrow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textValue = value ?? '-';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            textValue,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showArrow) const SizedBox(width: 4),
          if (showArrow) const Icon(Icons.chevron_right, color: Colors.black38),
        ],
      ),
      onTap: onTap,
    );
  }
}
