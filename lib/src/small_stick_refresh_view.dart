import 'package:small_refresh/src/small_stick_controller.dart';
import 'package:small_refresh/src/small_refresh_base.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter/material.dart';
import 'small_refresh.dart';

//notifier
class SmallStickRefreshViewController extends ScrollController
    implements SmallStickController {
  //head height
  double? _headHeight;

  //stick height
  double? _stickHeight;

  //content height
  double? _contentHeight;

  //cached child scroll controllers
  final List<SmallRefreshController> _childScrollControllers = [];

  //current
  SmallRefreshController? _currentScrollController;

  //stick key
  final GlobalKey stickKey = GlobalKey();

  //lock
  final Lock _controllerLock = Lock();

  //create
  SmallStickRefreshViewController() {
    ///limit scroll controller
    addListener(() {
      if (offset > headHeight) {
        position.jumpTo(headHeight);
      }
    });
  }

  ///register controllers add small refresh controller to stick controllers children
  @override
  void registerChildController(SmallRefreshController refreshController) {
    _controllerLock.synchronized(() {
      _currentScrollController = refreshController;
      if (!_childScrollControllers.contains(refreshController)) {
        _childScrollControllers.add(refreshController);
      }
    });
  }

  ///unregister controllers,remove from stick controller
  @override
  void unregisterChildController(SmallRefreshController scrollController) {
    _controllerLock.synchronized(() {
      _childScrollControllers.remove(scrollController);
    });
  }

  ///get current effect child controller , only one controller can effect any time
  @override
  SmallRefreshController? getCurrentChildController() {
    return _currentScrollController;
  }

  ///set current effect child controller
  @override
  void setCurrentChildController(SmallRefreshController scrollController) {
    _controllerLock.synchronized(() {
      _currentScrollController = scrollController;
    });
  }

  //get head height
  @override
  double get headHeight {
    return _headHeight ?? 0;
  }

  //get stick height
  @override
  double get stickHeight {
    return _stickHeight ?? 0;
  }

  //content height
  @override
  double get contentHeight {
    return _contentHeight ?? 0;
  }

  //get total height
  @override
  double get totalHeight {
    return headHeight + stickHeight;
  }

  @override
  bool get isStickRefresh => true;

  @override
  ScrollController get sc => this;

  //stop flag
  bool _stopFlag = false;

  //reset
  void _resetCurrentScroll() {
    _stopFlag = false;
  }

  //stop current scroll
  void _stopCurrentScroll() {
    if ((_currentScrollController?.positions.isNotEmpty ?? false) &&
        _stopFlag == false) {
      _stopFlag = true;
      _currentScrollController?.jumpTo(_currentScrollController?.offset ?? 0);
    }
  }

  //set head height
  bool _setHeadHeight(double height) {
    if (_headHeight != height) {
      _headHeight = height;
      return _isTopReady();
    }
    return false;
  }

  //set stick height
  bool _setStickHeight(double height) {
    if (_stickHeight != height) {
      _stickHeight = height;
      return _isTopReady();
    }
    return false;
  }

  //set content height
  void _setContentHeight(double height) {
    if (_contentHeight != height) {
      _contentHeight = height;
    }
  }

  //top is ready
  bool _isTopReady() {
    return _stickHeight != null &&
        _headHeight != null &&
        _contentHeight != null;
  }
}

//stick page view
class SmallStickRefreshView extends StatefulWidget {
  //on refresh
  final SmallCallback onRefresh;

  //head view
  final Widget headView;

  //stick view
  final Widget stickView;

  //body
  final Widget body;

  //controller
  final SmallStickRefreshViewController controller;

  //cross Alignment
  final CrossAxisAlignment crossAxisAlignment;

  //clip Behavior
  final Clip clipBehavior;

  //stick page view
  const SmallStickRefreshView({
    Key? key,
    required this.controller,
    required this.headView,
    required this.stickView,
    required this.body,
    required this.onRefresh,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SmallStickRefreshViewState();
  }
}

//state
class _SmallStickRefreshViewState extends State<SmallStickRefreshView> {
  //head key
  final GlobalKey _headKey = GlobalKey();

  //stick key
  final GlobalKey _stickKey = GlobalKey();

  //content key
  final GlobalKey _contentKey = GlobalKey();

  @override
  void didUpdateWidget(SmallStickRefreshView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        widget.controller._setContentHeight(constraints.maxHeight);
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handleTapDown,
          onPointerUp: _handleTapUp,
          onPointerCancel: _handleTapUCancel,
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: CustomScrollView(
              key: widget.controller.stickKey,
              controller: widget.controller,
              clipBehavior: widget.clipBehavior,
              slivers: [
                SliverToBoxAdapter(
                  child: ObserveWidget(
                    listener: (size) {
                      if (widget.controller._setHeadHeight(size.height)) {
                        setState(() {});
                      }
                    },
                    child: SizedBox(
                      key: _headKey,
                      child: widget.headView,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ObserveWidget(
                    listener: (size) {
                      if (widget.controller._setStickHeight(size.height)) {
                        setState(() {});
                      }
                    },
                    child: SizedBox(
                      key: _stickKey,
                      child: widget.stickView,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    key: _contentKey,
                    height: widget.controller.contentHeight -
                        widget.controller.stickHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: widget.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //handle notification
  void _handleTapDown(PointerDownEvent details) {
    widget.controller._stopCurrentScroll();
  }

  //handle tap u
  void _handleTapUp(PointerUpEvent details) {
    widget.controller._resetCurrentScroll();
  }

  //handle tap u
  void _handleTapUCancel(PointerCancelEvent details) {
    widget.controller._resetCurrentScroll();
  }
}
