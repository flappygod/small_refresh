import 'package:flutter/cupertino.dart';

///negatived scroll position
class SmallRefreshScrollPosition extends ScrollPositionWithSingleContext {
  SmallRefreshScrollPosition({
    required super.physics,
    required super.context,
    double super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });
}
