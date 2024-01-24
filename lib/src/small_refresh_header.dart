import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'small_refresh_base.dart';
import 'small_refresh.dart';

///small refresh header
class DefaultSmallRefreshHeader extends SmallRefreshHeaderWidget {
  ///header
  const DefaultSmallRefreshHeader({
    Key? key,
    required SmallRefreshController controller,
    double height = 75,
  }) : super(key: key, controller: controller, height: height);

  @override
  State<StatefulWidget> createState() {
    return DefaultHeaderRefreshFooterState();
  }
}

///small refresh header state
class DefaultHeaderRefreshFooterState
    extends SmallRefreshHeaderState<DefaultSmallRefreshHeader> {
  @override
  Widget buildStateView(RefreshStatus status) {
    switch (status) {
      case RefreshStatus.refreshStatusPullAction:
      case RefreshStatus.refreshStatusPullOver:
      case RefreshStatus.refreshStatusPullLock:
        return Text(
          "${(widget.controller.progress * 100).toInt()}%",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        );
      case RefreshStatus.refreshStatusEndAnimation:
      case RefreshStatus.refreshStatusRefreshing:
        return const SpinKitSpinningLines(
          itemCount: 1,
          lineWidth: 2,
          duration: Duration(milliseconds: 500),
          color: Colors.grey,
          size: 30.0,
        );
      case RefreshStatus.refreshStatusEnded:
        return Text(
          "Pull to load",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        );
    }
  }

  @override
  void onStateNotify(SmallRefreshHeaderChangeEvents events) {}
}
