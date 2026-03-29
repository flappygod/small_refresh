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

  ///fling ballistic
  void flingBallistic(double velocity) {
    //Clamp current pixels to the new extents immediately (especially when extents shrink).
    setPixels(pixels);
    //Do not interrupt an active drag; the new extents will be respected on release.
    if (activity is DragScrollActivity) {
      return;
    }
    //Re-run ballistic with the current activity velocity so the new extents take effect now.
    goBallistic(velocity);
  }

  ///get activity
  ScrollActivity? getActivity() {
    return activity;
  }
}
