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
  late SmallHeaderStatusChangeListener _headerStatusListener;

  @override
  void initState() {
    _headerStatusListener = (value) {
      onStateNotify(value);
      if (mounted) {
        setState(() {});
      }
    };
    widget.controller.addHeaderStatusChangeListener(_headerStatusListener);
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeHeaderStatusChangeListener(_headerStatusListener);
      widget.controller.addHeaderStatusChangeListener(_headerStatusListener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeHeaderStatusChangeListener(_headerStatusListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      child: buildStateView(widget.controller.refreshStatus),
    );
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

typedef ObserveHeightListener = Function(Size height);

///Observe child widget size, callback will trigger only the size has changed
class ObserveWidget extends StatefulWidget {
  //child
  final Widget child;

  //listener
  final ObserveHeightListener listener;

  const ObserveWidget({
    Key? key,
    required this.listener,
    required this.child,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ObserveWidgetState();
  }
}

///Observe child widget size, callback will trigger only the size has changed
class _ObserveWidgetState extends State<ObserveWidget> {
  //globalKey
  final GlobalKey _observeKey = GlobalKey();

  //size
  Size? _observeSize;

  ///trigger only once since build
  void _setListener() {
    ///check Size
    WidgetsBinding.instance.addPostFrameCallback((mag) {
      Size? size = _observeKey.currentContext?.size;
      if (size == null) {
        return;
      }
      if (size.width != _observeSize?.width || size.height != _observeSize?.height) {
        _observeSize = size;
        widget.listener(size);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _setListener();
    return SizedBox(
      key: _observeKey,
      child: widget.child,
    );
  }
}

///hid show listener
class HideShowController {
  HideShowController(this._hideShowStatus);

  ///hide show listeners
  final List<VoidCallback> _hideShowListeners = [];

  ///hide show status
  HideShowStatus _hideShowStatus = HideShowStatus.show;

  ///add hide show change listener
  void _addHideShowChangeListener(VoidCallback listener) {
    _hideShowListeners.add(listener);
  }

  ///remove hide show change listener
  void _removeHideShowChangeListener(VoidCallback listener) {
    _hideShowListeners.add(listener);
  }

  ///notify
  void _notify() {
    for (int s = 0; s < _hideShowListeners.length; s++) {
      VoidCallback listener = _hideShowListeners[s];
      listener();
    }
  }

  ///show
  void show() {
    _hideShowStatus = HideShowStatus.show;
    _notify();
  }

  ///hide
  void hide() {
    _hideShowStatus = HideShowStatus.hide;
    _notify();
  }
}

///footer status
enum HideShowStatus {
  hide,
  show,
}

///hide show widget
class HideShowWidget extends StatefulWidget {
  ///child
  final Widget child;

  ///controller
  final HideShowController controller;

  HideShowWidget({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HideShowWidgetState();
  }
}

///show widget state
class _HideShowWidgetState extends State<HideShowWidget> {
  late VoidCallback _listener;

  @override
  void initState() {
    _listener = () {
      setState(() {});
    };
    widget.controller._addHideShowChangeListener(_listener);
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller._removeHideShowChangeListener(_listener);
      widget.controller._addHideShowChangeListener(_listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller._removeHideShowChangeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.controller._hideShowStatus == HideShowStatus.show,
      child: widget.child,
    );
  }
}
