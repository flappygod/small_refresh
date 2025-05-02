import 'package:flutter/cupertino.dart';

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
    _minScrollExtend = -10;
  }

  void setHeadNotFling() {
    _minScrollExtend = 0;
  }

  void setFootCanFling() {
    _maxScrollExtend = 10;
  }

  void setFootNotFling() {
    _maxScrollExtend = 0;
  }

  @override
  double get minScrollExtent => _minScrollExtend;

  @override
  double get maxScrollExtent => super.maxScrollExtent + _maxScrollExtend;
}
