import 'package:small_refresh/src/small_refresh_base.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter/material.dart';
import 'small_refresh.dart';

//notifier
class SmallStickPageViewController extends ScrollController {
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
  SmallStickPageViewController() {
    ///limit scroll controller
    addListener(() {
      if (offset > headHeight) {
        position.jumpTo(headHeight);
      }
      if (offset < 0) {
        position.jumpTo(0);
      }
    });
  }

  ///register controllers add small refresh controller to stick controllers children
  void registerChildController(SmallRefreshController refreshController) {
    _controllerLock.synchronized(() {
      _currentScrollController = refreshController;
      if (!_childScrollControllers.contains(refreshController)) {
        _childScrollControllers.add(refreshController);
      }
    });
  }

  ///unregister controllers,remove from stick controller
  void unregisterChildController(SmallRefreshController scrollController) {
    _controllerLock.synchronized(() {
      _childScrollControllers.remove(scrollController);
    });
  }

  ///get current effect child controller , only one controller can effect any time
  SmallRefreshController? getCurrentChildController() {
    return _currentScrollController;
  }

  ///set current effect child controller
  void setCurrentChildController(SmallRefreshController scrollController) {
    _controllerLock.synchronized(() {
      _currentScrollController = scrollController;
    });
  }

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

  //清空
  void _clearHeight() {
    _stickHeight = null;
    _headHeight = null;
    _contentHeight = null;
  }

  //top is ready
  bool _isTopReady() {
    return _stickHeight != null &&
        _headHeight != null &&
        _contentHeight != null;
  }

  //get head height
  double get headHeight {
    return _headHeight ?? 0;
  }

  //get stick height
  double get stickHeight {
    return _stickHeight ?? 0;
  }

  //content height
  double get contentHeight {
    return _contentHeight ?? 0;
  }

  //get total height
  double get totalHeight {
    return headHeight + stickHeight;
  }
}

//stick page view
class SmallStickPageView extends StatefulWidget {
  //head view
  final Widget headView;

  //stick view
  final Widget stickView;

  //body
  final Widget body;

  //controller
  final SmallStickPageViewController controller;

  //cross Alignment
  final CrossAxisAlignment crossAxisAlignment;

  //clip Behavior
  final Clip clipBehavior;

  //stick page view
  const SmallStickPageView({
    Key? key,
    required this.stickView,
    required this.body,
    required this.headView,
    required this.controller,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SmallStickPageViewState();
  }
}

//state
class _SmallStickPageViewState extends State<SmallStickPageView> {
  //head key
  final GlobalKey _headKey = GlobalKey();

  //stick key
  final GlobalKey _stickKey = GlobalKey();

  //content key
  final GlobalKey _contentKey = GlobalKey();

  @override
  void didUpdateWidget(SmallStickPageView oldWidget) {
    widget.controller._clearHeight();
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
          child: SingleChildScrollView(
            controller: widget.controller,
            physics: const ClampingScrollPhysics(),
            key: widget.controller.stickKey,
            clipBehavior: widget.clipBehavior,
            child: Column(
              crossAxisAlignment: widget.crossAxisAlignment,
              children: [
                ObserveWidget(
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
                ObserveWidget(
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
                SizedBox(
                  key: _contentKey,
                  height: widget.controller.contentHeight -
                      widget.controller.stickHeight,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: widget.body,
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
