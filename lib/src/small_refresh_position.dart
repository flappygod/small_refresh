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
  void setHeaderCanFling() {
    _minScrollExtend = -15;
  }

  ///set min scroll extend
  void setHeaderNotFling() {
    _minScrollExtend = 0;
  }

  @override
  double get minScrollExtent => _minScrollExtend;
}
