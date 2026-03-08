import 'package:small_refresh/small_refresh.dart';
import 'package:flutter/cupertino.dart';

///抽象
abstract class SmallStickController {
  void registerChildController(SmallRefreshController refreshController);

  void unregisterChildController(SmallRefreshController scrollController);

  SmallRefreshController? getCurrentChildController();

  void setCurrentChildController(SmallRefreshController scrollController);

  double get headHeight;

  double get stickHeight;

  double get contentHeight;

  double get totalHeight;

  //is child header allow or not
  bool get isStickRefresh;

  ScrollController get sc;
}
