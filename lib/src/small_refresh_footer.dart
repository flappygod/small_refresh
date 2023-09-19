import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'small_refresh_base.dart';
import 'small_refresh.dart';

///small refresh footer
class DefaultSmallRefreshFooter extends SmallRefreshFooterWidget {
  //height
  final double height;

  //the init state show or not;
  final bool initHide;

  //controller
  final SmallRefreshController controller;

  const DefaultSmallRefreshFooter({
    Key? key,
    required this.controller,
    this.initHide = false,
    this.height = 60,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DefaultSmallRefreshFooterState();
  }

  @override
  double getHeight() {
    return height;
  }

  @override
  SmallRefreshController getController() {
    return controller;
  }
}

///footer state
class DefaultSmallRefreshFooterState
    extends SmallRefreshFooterState<DefaultSmallRefreshFooter> {
  ///get hide view
  @override
  Widget getHideView() {
    return const SizedBox();
  }

  @override
  Widget getLoadingView() {
    return const SpinKitSpinningLines(
      itemCount: 1,
      lineWidth: 2,
      duration: Duration(milliseconds: 500),
      color: Colors.grey,
      size: 30.0,
    );
  }

  @override
  Widget getNoMoreView() {
    return Text(
      "No more data",
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget getNorMalView() {
    return Text(
      "Pull to load",
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    );
  }

  @override
  void onRefreshNotify(bool isHide, bool isLoading, bool isNoMore) {
    ///do nothing
  }
}
