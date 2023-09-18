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
abstract class SmallRefreshHeaderState<T extends SmallRefreshHeaderBase> extends State<T> {
  //listener
  late SmallHeaderStatusChangeListener listener;

  //refresh state
  bool _pullingState = false;

  //refresh state
  bool _refreshingState = false;

  //progress
  double _progress = 0.0;

  @override
  void initState() {
    listener = (value) {
      switch (value) {
        case SmallRefreshHeaderChangeEvents.refreshStateStart:
          _pullingState = true;
          break;
        case SmallRefreshHeaderChangeEvents.refreshStateEnded:
          _refreshingState = false;
          _pullingState = false;
          break;
        case SmallRefreshHeaderChangeEvents.refreshStatePullOver:
          break;
        case SmallRefreshHeaderChangeEvents.refreshStateRefreshing:
          _refreshingState = true;
          break;
        case SmallRefreshHeaderChangeEvents.refreshStateEndAnim:
          break;
        case SmallRefreshHeaderChangeEvents.refreshStateProgress:
          _progress = widget.getController().progress;
          break;
        case SmallRefreshHeaderChangeEvents.refreshStateProgressOver:
          _progress = widget.getController().progress;
          break;
      }
      _refresh();
    };
    widget.getController().addHeaderStatusChangeListener(listener);
    super.initState();
  }

  ///refresh view
  void _refresh() {
    onRefreshNotify();
    setState(() {});
  }

  ///get normal view
  Widget getNormalView();

  ///get progress view
  Widget getProgressView(double progress);

  ///get pull over view
  Widget getRefreshingView();

  ///refresh notify
  void onRefreshNotify();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.getHeight(),
      alignment: Alignment.center,
      child: _buildContent(),
    );
  }

  ///build content
  Widget _buildContent() {
    ///refreshing view
    if (_refreshingState == true) {
      return getRefreshingView();
    }

    ///progress view
    if (_pullingState && _progress != 0) {
      return getProgressView(_progress);
    }

    ///normal view
    return getNormalView();
  }
}

///small refresh footer state
abstract class SmallRefreshFooterState<T extends SmallRefreshFooterBase> extends State<T> {
  //status change listener
  late SmallFooterStatusChangeListener _footerStatusChangeListener;

  //load listener
  late SmallLoadListener _footerLoadListener;

  //is loading
  bool _isLoading = true;

  //is no more
  bool _isNoMore = false;

  //is show
  bool _isHide = false;

  @override
  void initState() {
    ///footer status change listener
    _footerStatusChangeListener = (events) {
      switch (events) {
        case SmallRefreshFooterChangeEvents.notifyShowFooter:
          _isHide = false;
          break;
        case SmallRefreshFooterChangeEvents.notifyHideFooter:
          _isHide = true;
          break;

        ///footer no more data
        case SmallRefreshFooterChangeEvents.notifyFooterEnd:
          _isNoMore = true;
          break;

        ///footer has data
        case SmallRefreshFooterChangeEvents.notifyFooterReset:
          _isNoMore = false;
          break;
      }
      _refresh();
    };
    widget.getController().addFooterStatusChangeListener(_footerStatusChangeListener);

    ///footer load listener
    _footerLoadListener = (events) {
      switch (events) {
        case SmallLoadEvents.loadStateStart:
          _isLoading = true;
          break;
        case SmallLoadEvents.loadStateEnd:
          _isLoading = false;
          break;
      }
      _refresh();
    };
    widget.getController().addLoadChangeListener(_footerLoadListener);
    super.initState();
  }

  //check to refresh
  void _refresh() {
    onRefreshNotify();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (oldWidget.getController() != widget.getController()) {
      oldWidget.getController().removeFooterStatusChangeListener(_footerStatusChangeListener);
      oldWidget.getController().removeLoadChangeListener(_footerLoadListener);
      widget.getController().addFooterStatusChangeListener(_footerStatusChangeListener);
      widget.getController().addLoadChangeListener(_footerLoadListener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.getController().removeFooterStatusChangeListener(_footerStatusChangeListener);
    widget.getController().removeLoadChangeListener(_footerLoadListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ///show nothing
    if (_isHide) {
      return getHideView();
    }

    return Container(
      height: widget.getHeight(),
      width: double.infinity,
      alignment: Alignment.center,
      child: _getShowWidget(),
    );
  }

  ///get show widget
  Widget _getShowWidget() {
    ///no more data
    if (_isNoMore) {
      return getNoMoreView();
    }

    ///is loading
    if (_isLoading) {
      return getLoadingView();
    }

    ///pull to load
    return getNorMalView();
  }

  //normal and loading
  Widget getNorMalView();

  Widget getLoadingView();

  //hide and no more data
  Widget getHideView();

  Widget getNoMoreView();

  void onRefreshNotify();
}
