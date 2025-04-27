import 'package:flutter/widgets.dart';

/// 自定义 BouncingScrollPhysics，支持动态调整回弹边界
class SmallRefreshBouncingScrollPhysics extends BouncingScrollPhysics {
  /// 构造函数，支持动态切换模式
  const SmallRefreshBouncingScrollPhysics({
    super.parent,
    super.decelerationRate,
  });

  @override
  SmallRefreshBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmallRefreshBouncingScrollPhysics(
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    //动态设置最小边界
    final double minBoundary = 0;
    //如果滚动超出最小边界
    if (value < minBoundary) {
      return value - minBoundary;
    }
    //如果滚动超出最大边界（保持默认行为）
    if (value > position.maxScrollExtent) {
      return value - position.maxScrollExtent;
    }
    //在合法范围内，不需要调整
    return 0.0;
  }
}
