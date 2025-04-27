import 'package:flutter/cupertino.dart';

///negatived scroll position
class SmallRefreshScrollPosition extends ScrollPositionWithSingleContext {
  ///min scroll extend
  double _minScrollExtend = 0;

  ///callback
  /*late VoidCallback _callback;*/

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
    notifyListeners();
    /*_callback = () {
      if (pixels < _minScrollExtend) {
        jumpTo(_minScrollExtend);
      }
    };
    removeListener(_callback);
    addListener(_callback);*/
  }

  @override
  double get minScrollExtent => _minScrollExtend;
}
