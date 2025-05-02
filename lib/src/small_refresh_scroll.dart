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

  ///set header can fling
  void setHeaderCanFling() {
    if (position is SmallRefreshScrollPosition) {
      (position as SmallRefreshScrollPosition).setHeaderCanFling();
    }
  }

  ///set header not fling
  void setHeaderNotFling() {
    if (position is SmallRefreshScrollPosition) {
      (position as SmallRefreshScrollPosition).setHeaderNotFling();
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
