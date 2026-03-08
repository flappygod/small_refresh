import 'package:small_refresh/src/small_refresh_position.dart';
import 'package:flutter/cupertino.dart';

///small refresh scroll controller
class SmallRefreshScrollController extends ScrollController {
  SmallRefreshScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
  }) : super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  ///set head can fling
  void setHeadCanFling() {
    if (position is SmallRefreshScrollPosition) {
      (position as SmallRefreshScrollPosition).setHeadCanFling();
    }
  }

  ///set head not fling
  void setHeadNotFling() {
    if (position is SmallRefreshScrollPosition) {
      (position as SmallRefreshScrollPosition).setHeadNotFling();
    }
  }

  ///set foot can fling
  void setFootCanFling() {
    if (position is SmallRefreshScrollPosition) {
      (position as SmallRefreshScrollPosition).setFootCanFling();
    }
  }

  ///set foot not fling
  void setFootNotFling() {
    if (position is SmallRefreshScrollPosition) {
      (position as SmallRefreshScrollPosition).setFootNotFling();
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
