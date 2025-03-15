import 'package:flutter/material.dart';
import 'package:magicai/services/utils.dart';

class AdaptiveBottomSheet extends StatelessWidget {
  final Widget child;
  final double minWidthRatio;

  const AdaptiveBottomSheet({
    super.key,
    required this.child,
    this.minWidthRatio = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final themeData = Theme.of(context);
    final isWide = EnvironmentUtils.isDesktop;

    if (!isWide) {
      return _buildMobileContainer(themeData, child);
    }

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: media.size.width,
          minWidth: media.size.width * minWidthRatio,
        ),
        decoration: _getContainerDecoration(themeData),
        child: Column(
          children: [
            // 顶部拖动指示条
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getContainerDecoration(ThemeData themeData) {
    return BoxDecoration(
      color: themeData.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      boxShadow: [
        BoxShadow(
          color: themeData.shadowColor,
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );
  }

  Widget _buildMobileContainer(ThemeData themeData, Widget child) {
    return Container(
      decoration: _getContainerDecoration(themeData),
      child: child,
    );
  }
}

// 保持原来的_ModelConfigContentState内容不变
// 只需修改弹窗调用方式：
void showConfigBottomSheet(BuildContext context, AdaptiveBottomSheet sheet) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isDismissible: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.95, // 最大高度95%
      minHeight: 200, // 最小高度
      // maxWidth: MediaQuery.of(context).size.width * 0.7,
    ),
    builder: (context) => sheet,
  );
}
