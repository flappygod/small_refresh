import 'package:flutter/cupertino.dart';

///negatived scroll position
class SmallRefreshScrollPosition extends ScrollPositionWithSingleContext {
  ///min scroll extend
  double _minScrollExtend = 0;
  double _maxScrollExtend = 0;
  final double _flingOffset = 25;

  SmallRefreshScrollPosition({
    required super.physics,
    required super.context,
    double super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  void setHeadCanFling() {
    if (_minScrollExtend != -_flingOffset) {
      _minScrollExtend = -_flingOffset;
      _reconfigureAfterExtentChanged();
    }
  }

  void setHeadNotFling() {
    if (_minScrollExtend != 0) {
      _minScrollExtend = 0;
      _reconfigureAfterExtentChanged();
    }
  }

  void setFootCanFling() {
    if (_maxScrollExtend != _flingOffset) {
      _maxScrollExtend = _flingOffset;
      _reconfigureAfterExtentChanged();
    }
  }

  void setFootNotFling() {
    if (_maxScrollExtend != 0) {
      _maxScrollExtend = 0;
      _reconfigureAfterExtentChanged();
    }
  }

  void _reconfigureAfterExtentChanged() {
    //Clamp current pixels to the new extents immediately (especially when extents shrink).
    correctPixels(pixels);

    //Do not interrupt an active drag; the new extents will be respected on release.
    if (activity is DragScrollActivity) {
      notifyListeners();
      return;
    }

    //Re-run ballistic with the current activity velocity so the new extents take effect now.
    final v = activity?.velocity ?? 0.0;
    goBallistic(v);

    //Notify dependents (e.g., Scrollbar/Controller listeners).
    notifyListeners();
  }

  @override
  double get minScrollExtent => _minScrollExtend;

  @override
  double get maxScrollExtent => super.maxScrollExtent + _maxScrollExtend;
}
