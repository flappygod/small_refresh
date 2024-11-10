import 'package:small_refresh/src/small_refresh_position.dart';
import 'package:flutter/cupertino.dart';

///small refresh scroll controller
class SmallRefreshScrollController extends ScrollController {
  ///set header height
  void setHeaderHeight(double height) {
    if (position is SmallRefreshScrollPosition) {
      (position as SmallRefreshScrollPosition).headerHeight = height;
    }
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return SmallRefreshScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}
