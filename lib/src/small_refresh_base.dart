import 'package:flutter/material.dart';
import 'small_refresh.dart';

///Base change notifier
class SmallRefreshBaseNotifier extends Listenable {
  //listeners
  final List<VoidCallback> _listeners = [];

  //notify all listeners
  void notifyListeners() {
    for (int s = 0; s < _listeners.length; s++) {
      _listeners[s]();
    }
  }

  //check listeners is not empty
  bool get hasListeners {
    return _listeners.isNotEmpty;
  }

  //add
  @override
  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  //remove
  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  //remove all
  void clearListeners() {
    _listeners.clear();
  }

  //dispose
  void dispose() {
    clearListeners();
  }
}

//refresh head state
abstract class SmallRefreshHeaderState<T extends SmallRefreshHeaderWidget> extends State<T> {
  //listener
  late SmallHeaderStatusChangeListener _listener;

  @override
  void initState() {
    _listener = (value) {
      onStateNotify(value);
      if (mounted) {
        setState(() {});
      }
    };
    widget.controller.addHeaderStatusChangeListener(_listener);
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeHeaderStatusChangeListener(_listener);
      widget.controller.addHeaderStatusChangeListener(_listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      child: buildStateView(widget.controller.refreshStatus),
    );
  }

  @override
  void dispose() {
    widget.controller.removeHeaderStatusChangeListener(_listener);
    super.dispose();
  }

  ///build state view
  Widget buildStateView(RefreshStatus status);

  ///on refresh notify
  void onStateNotify(
    SmallRefreshHeaderChangeEvents events,
  );
}

///small refresh footer state
abstract class SmallRefreshFooterState<T extends SmallRefreshFooterWidget> extends State<T> {
  ///status change listener
  late SmallFooterStatusChangeListener _footerStatusChangeListener;

  @override
  void initState() {
    ///footer status change listener
    _footerStatusChangeListener = (events) {
      onStateNotify(events);
      if (mounted) {
        setState(() {});
      }
    };

    widget.controller.addFooterStatusChangeListener(_footerStatusChangeListener);
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeFooterStatusChangeListener(_footerStatusChangeListener);
      widget.controller.addFooterStatusChangeListener(_footerStatusChangeListener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeFooterStatusChangeListener(_footerStatusChangeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      child: buildStateView(
        widget.controller.loadStatus,
      ),
    );
  }

  ///build state view
  Widget buildStateView(LoadStatus status);

  ///on state notify
  void onStateNotify(
    SmallRefreshFooterChangeEvents events,
  );
}
