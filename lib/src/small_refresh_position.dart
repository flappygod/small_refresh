import 'package:flutter/cupertino.dart';

///negatived scroll position
class SmallRefreshScrollPosition extends ScrollPositionWithSingleContext {
  ///min scroll extend
  double _minScrollExtend = 0;


  SmallRefreshScrollPosition({
    required super.physics,
    required super.context,
    double super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  ///set min scroll extend
  set headerHeight(double data) {
    _minScrollExtend = -data;
    applyContentDimensions(minScrollExtent, maxScrollExtent);
    applyBoundaryConditions(0);
  }

  @override
  double get minScrollExtent => _minScrollExtend;
}
