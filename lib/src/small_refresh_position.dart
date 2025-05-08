import 'package:flutter/cupertino.dart';
import 'package:small_refresh/small_refresh.dart';

///negatived scroll position
class SmallRefreshScrollPosition extends ScrollPositionWithSingleContext {
  ///min scroll extend
  double _minScrollExtend = 0;
  double _maxScrollExtend = 0;

  SmallRefreshScrollPosition({
    required super.physics,
    required super.context,
    double super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  void setHeadCanFling() {
    _minScrollExtend = -flingOffset;
  }

  void setHeadNotFling() {
    _minScrollExtend = 0;
  }

  void setFootCanFling() {
    _maxScrollExtend = flingOffset;
  }

  void setFootNotFling() {
    _maxScrollExtend = 0;
  }

  @override
  double get minScrollExtent => _minScrollExtend;

  @override
  double get maxScrollExtent => super.maxScrollExtent + _maxScrollExtend;
}
