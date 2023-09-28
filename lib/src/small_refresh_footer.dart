import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'small_refresh_base.dart';
import 'small_refresh.dart';

///small refresh footer
class DefaultSmallRefreshFooter extends SmallRefreshFooterWidget {
  const DefaultSmallRefreshFooter({
    Key? key,
    required SmallRefreshController controller,
    double height = 60,
  }) : super(key: key, controller: controller, height: height);

  @override
  State<StatefulWidget> createState() {
    return DefaultSmallRefreshFooterState();
  }
}

///footer state
class DefaultSmallRefreshFooterState extends SmallRefreshFooterState<DefaultSmallRefreshFooter> {
  ///build state view
  @override
  Widget buildStateView(LoadStatus status) {
    ///status
    switch (status) {
      case LoadStatus.loadStatusLoading:
        return const SpinKitSpinningLines(
          itemCount: 1,
          lineWidth: 2,
          duration: Duration(milliseconds: 500),
          color: Colors.grey,
          size: 30.0,
        );
      case LoadStatus.loadStatusEnd:
        return Text(
          "Pull to load",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        );
      case LoadStatus.loadStatusStopped:
        return Text(
          "No more data",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        );
    }
  }

  @override
  void onStateNotify(SmallRefreshFooterChangeEvents events) {}
}
