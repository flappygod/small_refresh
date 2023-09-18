import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'small_refresh_base.dart';
import 'small_refresh.dart';

///small refresh header
class DefaultSmallRefreshHeader extends SmallRefreshHeaderBase {
  //height
  final double height;

  //controller
  final SmallRefreshController controller;

  const DefaultSmallRefreshHeader({
    Key? key,
    required this.controller,
    this.height = 75,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DefaultHeaderRefreshFooterState();
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

///small refresh header state
class DefaultHeaderRefreshFooterState extends SmallRefreshHeaderState<DefaultSmallRefreshHeader> {
  @override
  Widget getNormalView() {
    return const SizedBox();
  }

  @override
  Widget getProgressView(double progress) {
    return Text(
      "${(progress * 100).toInt()}%",
      style: TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  @override
  Widget getRefreshingView() {
    return const SpinKitSpinningLines(
      itemCount: 1,
      lineWidth: 2,
      duration: Duration(milliseconds: 500),
      color: Colors.grey,
      size: 30.0,
    );
  }

  @override
  void onRefreshNotify() {
    ///just do nothing
  }
}
