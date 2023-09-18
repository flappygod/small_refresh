import 'package:synchronized/synchronized.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'small_refresh_resize.dart';
import 'small_refresh_space.dart';
import 'small_stick_page.dart';

typedef SmallCallback = Future<void> Function();

//refresh action listener
typedef SmallRefreshListener = Function(SmallRefreshEvents events);

//refresh load change listener
typedef SmallLoadListener = Function(SmallLoadEvents events);

//refresh status change listener
typedef SmallHeaderStatusChangeListener = Function(
    SmallRefreshHeaderChangeEvents events);

//refresh footer status change listener
typedef SmallFooterStatusChangeListener = Function(
    SmallRefreshFooterChangeEvents events);

//duration time
const int durationTime = 320;

//load status
enum LoadStatus {
  //LOAD_END
  loadStatusEnd,
  //LOADING
  loadStatusLoading,
}

///refresh status
enum RefreshStatus {
  //lock status to avoid gesture when refresh signal reached
  refreshStatusPullLock,
  //user is pulling
  refreshStatusPullAction,
  //user pulled a long distance and if touch up ,we will start refresh.
  refreshStatusPullOver,
  //is refreshing
  refreshStatusRefreshing,
  //refresh end and is animating to top if need.
  refreshStatusEndAnimation,
  //refresh end
  refreshStatusEnded,
}

///refresh status change
enum SmallRefreshHeaderChangeEvents {
  //refresh state change notify (when state changed)
  refreshStateStart,
  refreshStateProgress,
  refreshStateProgressOver,
  refreshStatePullOver,
  refreshStateRefreshing,
  refreshStateEndAnim,
  refreshStateEnded,
}

///refresh state change notify
enum SmallRefreshEvents {
  refreshActionStart,
  refreshActionStop,
}

///load state change notify
enum SmallLoadEvents {
  loadStateStart,
  loadStateEnd,
}

///load state change notify
enum SmallRefreshFooterChangeEvents {
  notifyShowFooter,
  notifyHideFooter,
  notifyFooterEnd,
  notifyFooterReset,
}

class SmallRefresh extends StatefulWidget {
  //sliver
  final List<Widget> slivers;

  //refresh first time
  final bool firstRefresh;

  //refresh controller
  final SmallRefreshController controller;

  //top padding
  final double topPadding;

  //bottom padding
  final double bottomPadding;

  //on refresh
  final SmallCallback? onRefresh;

  //on load
  final SmallCallback? onLoad;

  //refresh head
  final SmallRefreshHeaderWidget? header;

  //load footer
  final SmallRefreshFooterWidget? footer;

  //scroll physics
  final ScrollPhysics? physics;

  //cacheExtend
  final double? cacheExtent;

  //keyboard
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;

  //clip
  final Clip clipBehavior;

  const SmallRefresh({
    Key? key,
    this.firstRefresh = false,
    required this.controller,
    this.header,
    this.onRefresh,
    this.footer,
    this.onLoad,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.slivers = const [],
    this.physics,
    this.cacheExtent,
    this.keyboardDismissBehavior,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SmallRefreshState();
  }
}

class SmallRefreshState extends State<SmallRefresh> {
  //head key
  final GlobalKey _globalKeyHeader = GlobalKey();

  //lock
  final Lock _stateChangeLock = Lock();

  //notification lock
  final Lock _nestedLock = Lock();

  //height can show
  final double _heightCanShow = 0.0001;

  //listener
  late SmallRefreshListener _listener;

  //refresh end
  RefreshStatus _status = RefreshStatus.refreshStatusEnded;

  //load end
  LoadStatus _loadStatus = LoadStatus.loadStatusEnd;

  ///set status and also update controllers refresh status
  set status(RefreshStatus refreshStatus) {
    _status = refreshStatus;
    widget.controller.refreshStatus = refreshStatus;
  }

  ///init controller
  void _initController() {
    //create small size widget
    widget.controller._scaleWidgetController = SmallSizeWidgetController(
      baseHeight: _heightCanShow,
      innerHeight: widget.header != null ? widget.header!.getHeight() : 0,
    );

    ///listener
    _listener = (value) {
      ///do nothing if has no clients
      if (widget.controller._scrollController.hasClients != true) {
        return;
      }

      ///start refresh action
      if (value == SmallRefreshEvents.refreshActionStart) {
        ///refresh header is null ,do nothing
        if (widget.header == null || widget.onRefresh == null) {
          return;
        }

        ///if refresh is end or is pull, animate to
        if (_status == RefreshStatus.refreshStatusEnded ||
            _status == RefreshStatus.refreshStatusPullAction) {
          status = RefreshStatus.refreshStatusPullLock;

          ///nested must not fling when refresh start
          _forceNestedNotFling();
          _forceNestedNotScroll();

          ///set show animation and auto animation flag
          widget.controller._isShowAnimating = true;
          widget.controller._isAutoAnimating = true;
          Future future =
              widget.controller._getCurrentScrollPosition().animateTo(
                    -widget.header!.getHeight(),
                    duration: const Duration(milliseconds: durationTime),
                    curve: Curves.easeInOut,
                  );
          future.then((value) {
            widget.controller._isShowAnimating = false;
          });
        }
      }

      ///stop refresh action
      else if (value == SmallRefreshEvents.refreshActionStop) {
        if (widget.header == null || widget.onRefresh == null) {
          return;
        }
        changeToEndAnim();
      }
    };
    widget.controller._addActionListener(_listener);
  }

  ///if first refresh animation is set and header is not null,start refresh
  void _initFreshIfNeedFirstTime() {
    WidgetsBinding.instance.addPostFrameCallback((callback) async {
      if (widget.firstRefresh && widget.header != null) {
        widget.controller.startRefresh();
      }
    });
  }

  @override
  void initState() {
    _initController();
    _initFreshIfNeedFirstTime();
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller._removeActionListener(_listener);
      widget.controller._addActionListener(_listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller._removeActionListener(_listener);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> slivers = [];

    //add top padding if nested need
    Widget? nestedTop = _buildNestedTop();
    if (nestedTop != null) {
      slivers.add(nestedTop);
    }

    //add top padding
    Widget? topPadding = _buildTopPadding();
    if (topPadding != null) {
      slivers.add(topPadding);
    }

    //add top header
    Widget? topHeader = _buildTopHeader();
    if (topHeader != null) {
      slivers.add(topHeader);
    }

    //add slivers
    if (widget.slivers.isNotEmpty) {
      slivers.addAll(_buildChildSlivers());
    }

    //add footer
    Widget? bottomFooter = _buildBottomFooter();
    if (bottomFooter != null) {
      slivers.add(bottomFooter);
    }

    //add bottom padding
    Widget? bottomPadding = _buildBottomPadding();
    if (bottomPadding != null) {
      slivers.add(bottomPadding);
    }

    //for nested
    Widget? nestedBottom = _buildNestedBottom();
    if (nestedBottom != null) {
      slivers.add(nestedBottom);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: CustomScrollView(
        controller: widget.controller.scrollController,
        physics: _buildScrollPhysics(),
        cacheExtent: widget.cacheExtent,
        keyboardDismissBehavior: widget.keyboardDismissBehavior ??
            ScrollViewKeyboardDismissBehavior.manual,
        clipBehavior: widget.clipBehavior,
        slivers: slivers,
      ),
    );
  }

  //scroll physics
  ScrollPhysics _buildScrollPhysics() {
    return widget.physics ??
        const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        );
  }

  //nested padding
  Widget? _buildNestedTop() {
    if (widget.controller.stickController == null) {
      return null;
    }
    return SliverToBoxAdapter(
      child: SmallResizeWidget(
        key: widget.controller._stickTopKey,
        controller: widget.controller._stickFlingTopResizeController,
      ),
    );
  }

  //build top padding
  Widget? _buildTopPadding() {
    if (widget.topPadding == 0) {
      return null;
    }
    Widget top = SliverToBoxAdapter(
      child: SizedBox(
        height: widget.topPadding,
      ),
    );
    return top;
  }

  //build top header
  Widget? _buildTopHeader() {
    if (widget.header != null &&
        widget.controller._scaleWidgetController != null) {
      return SliverToBoxAdapter(
        child: SmallSizeWidget(
          key: _globalKeyHeader,
          controller: widget.controller._scaleWidgetController!,
          child: widget.header!,
        ),
      );
    } else {
      return null;
    }
  }

  //build children
  List<Widget> _buildChildSlivers() {
    return widget.slivers;
  }

  //build footer
  Widget? _buildBottomFooter() {
    if (widget.footer != null) {
      Widget memFooter = SliverToBoxAdapter(
        child: widget.footer,
      );
      return memFooter;
    } else {
      return null;
    }
  }

  //build bottom padding
  Widget? _buildBottomPadding() {
    if (widget.bottomPadding == 0) {
      return null;
    }
    Widget top = SliverToBoxAdapter(
      child: SizedBox(
        height: widget.bottomPadding,
      ),
    );
    return top;
  }

  //bottom
  Widget? _buildNestedBottom() {
    if (widget.controller.stickController == null) {
      return null;
    }
    return SliverToBoxAdapter(
      child: SmallResizeWidget(
        key: widget.controller._stickBtmKey,
        controller: widget.controller._stickFlingBtmResizeController,
      ),
    );
  }

  //handle notification
  bool _handleNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.horizontal) {
      return false;
    }
    if (!widget.controller._scrollController.hasClients) {
      return false;
    }
    //nested
    _handleNotificationNested(notification);
    //header
    _handleNotificationHeader(notification);
    //footer
    _handleNotificationFooter(notification);
    return false;
  }

  //scroll max
  double _getNestedScrollMax() {
    return widget.controller.getNestedScrollMax();
  }

  //get scroll start
  double _getNestedScrollStart() {
    return widget.controller.getNestedScrollStart();
  }

  //handle nested
  void _handleNotificationNested(ScrollNotification notification) {
    //null return
    if (widget.controller.stickController == null) {
      return;
    }
    //synchronized
    _nestedLock.synchronized(() {
      ///set current
      if ((notification is ScrollStartNotification &&
              notification.dragDetails != null) ||
          (notification is ScrollUpdateNotification &&
              notification.dragDetails != null)) {
        widget.controller.stickController!
            .setCurrentChildController(widget.controller);
      }

      ///when nested locked by other scroll views
      if (widget.controller !=
          widget.controller.stickController?.getCurrentChildController()) {
        return;
      }

      ///when small refresh is  refresh animating ,do nothing
      if (widget.controller.isAnimating) {
        return;
      }

      ///start notification
      if (notification is ScrollStartNotification) {
        if (widget.controller._stickTopKey.currentContext?.findRenderObject() !=
                null &&
            widget.controller._stickBtmKey.currentContext?.findRenderObject() !=
                null) {
          RenderBox boxTop = widget.controller._stickTopKey.currentContext
              ?.findRenderObject() as RenderBox;
          RenderBox boxBtm = widget.controller._stickBtmKey.currentContext
              ?.findRenderObject() as RenderBox;

          Offset topOffset = boxTop.localToGlobal(Offset.zero);
          Offset btmOffset = boxBtm.localToGlobal(Offset.zero);

          ///content height
          double contentHeight =
              btmOffset.dy - topOffset.dy - boxTop.size.height;
          double totalHeight = widget.controller.scrollController.position
                  .context.storageContext.size?.height ??
              0;
          double needHeight = totalHeight - contentHeight;

          ///need height ,if over height less than 10
          if (needHeight < -10) {
            widget.controller._stickFlingBtmResizeController.setHeight(0);
          } else {
            widget.controller._stickFlingBtmResizeController
                .setHeight(needHeight + 10);
          }
        }
      }

      ///if is scroll update
      if (notification is ScrollUpdateNotification) {
        //get scroll delta
        double deltaA = notification.dragDetails?.delta.dy ??
            -(notification.scrollDelta ?? 0);
        //check is user gesture
        bool isGesture = (notification.dragDetails != null);
        //top resilience
        bool isResilienceTop = !isGesture &&
            widget.controller._nestedFatherOut &&
            widget.controller._getCurrentScrollPosition().pixels < 0;
        //no scroll space
        bool isNoScrollSpace =
            (widget.controller._getCurrentScrollPosition().maxScrollExtent ==
                0);

        ///pull down when this list has no scroll space
        if (isGesture &&
            deltaA > 0 &&
            isNoScrollSpace &&
            widget.controller.stickController!.scrollController.offset != 0) {
          widget.controller._getCurrentScrollPosition().correctBy(
              _getNestedScrollStart() -
                  widget.controller._getCurrentScrollPosition().pixels);
          double jumpTo = widget.controller.stickController!.scrollController
                  .position.pixels -
              deltaA;
          jumpTo = jumpTo < 0 ? 0 : jumpTo;
          widget.controller.stickController!.scrollController.position
              .jumpTo(jumpTo);
          return;
        }

        ///pull up when this list has no scroll space
        if (isGesture &&
            deltaA < 0 &&
            isNoScrollSpace &&
            (widget.controller.scrollController.offset * 10).toInt() >
                (_getNestedScrollStart() * 10).toInt() &&
            (widget.controller.stickController!.scrollController.offset * 10)
                    .toInt() !=
                (_getNestedScrollMax() * 10).toInt()) {
          widget.controller._getCurrentScrollPosition().correctBy(
              _getNestedScrollStart() -
                  widget.controller._getCurrentScrollPosition().pixels);
          double jumpTo = widget.controller.stickController!.scrollController
                  .position.pixels -
              deltaA;
          jumpTo =
              jumpTo > _getNestedScrollMax() ? _getNestedScrollMax() : jumpTo;
          widget.controller.stickController!.scrollController.position
              .jumpTo(jumpTo);
          return;
        }

        ///pull down normal
        if (deltaA > 0 &&
            widget.controller.stickController!.scrollController.offset > 0 &&
            (widget.controller.stickController!.scrollController.offset * 10)
                    .toInt() <=
                (_getNestedScrollMax() * 10).toInt() &&
            (widget.controller._getCurrentScrollPosition().pixels * 10)
                    .toInt() <
                (_getNestedScrollStart() * 10).toInt()) {
          double jumpTo = widget.controller.stickController!.scrollController
                  .position.pixels -
              deltaA;
          if ((widget.controller._getCurrentScrollPosition().pixels -
                      _getNestedScrollStart())
                  .abs() <
              deltaA) {
            double jumpCross =
                (widget.controller._getCurrentScrollPosition().pixels -
                        _getNestedScrollStart())
                    .abs();
            jumpTo = widget.controller.stickController!.scrollController
                    .position.pixels -
                jumpCross;
            widget.controller._getCurrentScrollPosition().correctBy(
                _getNestedScrollStart() -
                    widget.controller._getCurrentScrollPosition().pixels);
          } else {
            widget.controller._getCurrentScrollPosition().correctBy(deltaA);
          }
          jumpTo = jumpTo < 0 ? 0 : jumpTo;
          widget.controller.stickController!.scrollController.position
              .jumpTo(jumpTo);
        }

        ///pull up normal
        if (deltaA < 0 &&
            !isResilienceTop &&
            (widget.controller.scrollController.offset * 10).toInt() >
                (_getNestedScrollStart() * 10).toInt() &&
            (widget.controller.stickController!.scrollController.offset * 10)
                    .toInt() <
                (_getNestedScrollMax() * 10).toInt()) {
          double jumpTo = widget.controller.stickController!.scrollController
                  .position.pixels -
              deltaA;
          if (widget.controller.scrollController.offset -
                  _getNestedScrollStart() <
              deltaA.abs()) {
            double jumpCross =
                (widget.controller._getCurrentScrollPosition().pixels -
                        _getNestedScrollStart())
                    .abs();
            jumpTo = widget.controller.stickController!.scrollController
                    .position.pixels +
                jumpCross;
            widget.controller._getCurrentScrollPosition().correctBy(
                _getNestedScrollStart() -
                    widget.controller._getCurrentScrollPosition().pixels);
          } else {
            widget.controller._getCurrentScrollPosition().correctBy(deltaA);
          }
          jumpTo =
              jumpTo > _getNestedScrollMax() ? _getNestedScrollMax() : jumpTo;
          widget.controller.stickController!.scrollController.position
              .jumpTo(jumpTo);
        }
      }
      //set not fling
      if (notification is ScrollUpdateNotification ||
          notification is ScrollStartNotification) {
        if (widget.controller.stickController!.scrollController.offset <= 0) {
          _forceNestedNotFling();
        } else {
          _forceNestedCanFling();
        }
      }
    });
  }

  //force nested out
  bool _forceNestedNotFling() {
    if (widget.controller.stickController == null) {
      return false;
    }
    //nested
    if (widget.controller._nestedFatherOut == false) {
      widget.controller._nestedFatherOut = true;
      return true;
    }
    return false;
  }

  //force not scroll
  bool _forceNestedNotScroll() {
    if (widget.controller.stickController == null) {
      return false;
    }
    if (widget.controller.stickController?.getCurrentChildController() ==
        widget.controller) {
      widget.controller
          ._getCurrentScrollPosition()
          .jumpTo(widget.controller._getCurrentScrollPosition().pixels);
    }
    return true;
  }

  //force nested doing
  bool _forceNestedCanFling() {
    if (widget.controller.stickController == null) {
      return false;
    }
    //nested
    if (widget.controller._nestedFatherOut == true) {
      widget.controller._nestedFatherOut = false;
      return true;
    }
    return false;
  }

  //head refresh
  void _handleNotificationHeader(ScrollNotification notification) {
    if (widget.header == null || widget.onRefresh == null) {
      return;
    }
    //get scroll height
    double scrollHeight = (-widget.controller.scrollController.offset);

    //refresh header
    widget.controller._scaleWidgetController?.setScrollOffset(-scrollHeight);

    ///start pull
    if (scrollHeight > 0) {
      changeToPull();
    }

    ///refresh pull progress
    if (_status == RefreshStatus.refreshStatusPullAction) {
      if (scrollHeight > 0 && scrollHeight <= widget.header!.getHeight()) {
        widget.controller
            ._refreshDragProgress(scrollHeight / widget.header!.getHeight());
      } else if (scrollHeight >= widget.header!.getHeight()) {
        widget.controller._refreshDragProgressOver(
            scrollHeight / widget.header!.getHeight());
      }
    }

    ///if pull out,and touch gone,change to pull out
    if (scrollHeight >= widget.header!.getHeight() &&
        notification is ScrollUpdateNotification &&
        notification.dragDetails == null) {
      changeToPullOut(scrollHeight);
    }

    ///drag interrupt
    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      changeToInterrupt(scrollHeight);
    }

    ///if pulled out ,change to refreshing
    if (notification is ScrollEndNotification) {
      changeToRefreshing();
    }

    ///is refreshing and end
    if (notification is ScrollEndNotification &&
        widget.controller.refreshStatus ==
            RefreshStatus.refreshStatusEndAnimation &&
        widget.controller._getCurrentScrollPosition().pixels == 0) {
      changeToEnd();
    }
  }

  //change to pull
  Future<void> changeToPull() async {
    if (_status == RefreshStatus.refreshStatusEnded ||
        _status == RefreshStatus.refreshStatusPullLock) {
      await _stateChangeLock.synchronized(() {
        if (_status == RefreshStatus.refreshStatusEnded ||
            _status == RefreshStatus.refreshStatusPullLock) {
          status = RefreshStatus.refreshStatusPullAction;
        }
      });
    }
  }

  //change to pull out
  Future<void> changeToPullOut(double scrollHeight) async {
    if (_status == RefreshStatus.refreshStatusPullAction) {
      await _stateChangeLock.synchronized(() {
        if (_status == RefreshStatus.refreshStatusPullAction) {
          status = RefreshStatus.refreshStatusPullOver;
          widget.controller._scaleWidgetController?.setSmallHeadShow(true);
          widget.controller
              ._getCurrentScrollPosition()
              .jumpTo(widget.header!.getHeight() - scrollHeight);
        }
      });
    }
  }

  //change to pull out
  Future<void> changeToInterrupt(double scrollHeight) async {
    //all animation set gone
    widget.controller._isHideAnimating = false;
    widget.controller._isAutoAnimating = false;
    widget.controller._isShowAnimating = false;
    //change to end,if _status == RefreshStatus.Refresh_ANIMATION
    changeToEnd();
  }

  //pull end
  Future<void> changeToRefreshing() async {
    //if pulled out
    if (_status == RefreshStatus.refreshStatusPullOver) {
      await _stateChangeLock.synchronized(() {
        if (_status == RefreshStatus.refreshStatusPullOver) {
          status = RefreshStatus.refreshStatusRefreshing;
          Future future = widget.onRefresh!();
          future.then((value) async {
            if (mounted) {
              changeToEndAnim();
            }
          }).catchError((error) async {
            if (mounted) {
              changeToEndAnim();
            }
          });
        }
      });
    }
    //if not pulled out
    if (_status == RefreshStatus.refreshStatusPullAction) {
      await _stateChangeLock.synchronized(() {
        if (_status == RefreshStatus.refreshStatusPullAction) {
          //just set state ,and the scroll controller resilience
          status = RefreshStatus.refreshStatusEnded;
          widget.controller._isAutoAnimating = false;
        }
      });
    }
  }

  //start end animation
  //just use scroll controller resilience
  Future<void> changeToEndAnim() async {
    if (widget.controller._scrollController.hasClients != true) {
      return;
    }
    //if is Refresh_REFRESHING
    if (_status == RefreshStatus.refreshStatusRefreshing) {
      //lock
      await _stateChangeLock.synchronized(() {
        //check twice
        if (_status == RefreshStatus.refreshStatusRefreshing) {
          //end anim must not fling
          _forceNestedNotFling();
          //end anim must not scroll
          _forceNestedNotScroll();
          //check current position,if header is no longer show,just set status
          if (widget.controller.scrollController.offset.toInt() >=
              widget.header!.getHeight().toInt()) {
            //set refresh animation
            //refresh end and jump for resilience
            widget.controller._scaleWidgetController?.setSmallHeadShow(false);
            //jump to position
            widget.controller._getCurrentScrollPosition().jumpTo(
                widget.controller._getCurrentScrollPosition().pixels -
                    widget.header!.getHeight());
            //change to end directly
            status = RefreshStatus.refreshStatusEnded;
            widget.controller._isAutoAnimating = false;
            widget.controller._isHideAnimating = false;
          } else {
            //set refresh animation
            status = RefreshStatus.refreshStatusEndAnimation;
            //set hide animation
            widget.controller._isHideAnimating = true;
            //refresh end and jump for resilience
            widget.controller._scaleWidgetController?.setSmallHeadShow(false);
            //jump to position
            widget.controller._getCurrentScrollPosition().jumpTo(
                widget.controller._getCurrentScrollPosition().pixels -
                    widget.header!.getHeight());
          }
        }
      });
    }
  }

  //change to end anim
  Future<void> changeToEnd() async {
    if (_status == RefreshStatus.refreshStatusEndAnimation) {
      await _stateChangeLock.synchronized(() {
        if (_status == RefreshStatus.refreshStatusEndAnimation) {
          status = RefreshStatus.refreshStatusEnded;
          widget.controller._isAutoAnimating = false;
          widget.controller._isHideAnimating = false;
        }
      });
    }
  }

  //loading
  void _handleNotificationFooter(ScrollNotification notification) {
    if (widget.footer == null || widget.onLoad == null) {
      return;
    }
    if (notification is ScrollEndNotification &&
        notification.metrics.extentAfter <= widget.footer!.getHeight() &&
        _status == RefreshStatus.refreshStatusEnded) {
      changeToLoading();
    }
  }

  //change to loading
  Future<void> changeToLoading() async {
    if (_loadStatus == LoadStatus.loadStatusEnd) {
      await _stateChangeLock.synchronized(() async {
        if (_loadStatus == LoadStatus.loadStatusEnd) {
          _loadStatus = LoadStatus.loadStatusLoading;
          widget.controller._loadStart();
          try {
            await widget.onLoad!();
            await Future.delayed(
              const Duration(milliseconds: 10),
            );
            if (mounted) {
              changeToLoadEnd();
            }
          } catch (error) {
            if (mounted) {
              changeToLoadEnd();
            }
          }
        }
      });
    }
  }

  //change to load end
  Future<void> changeToLoadEnd() async {
    if (_loadStatus == LoadStatus.loadStatusLoading) {
      await _stateChangeLock.synchronized(() {
        if (_loadStatus == LoadStatus.loadStatusLoading) {
          _loadStatus = LoadStatus.loadStatusEnd;
          widget.controller._loadEnd();
        }
      });
    }
  }
}

/// header base
abstract class SmallRefreshHeaderWidget extends StatefulWidget {
  const SmallRefreshHeaderWidget({Key? key}) : super(key: key);

  double getHeight();

  SmallRefreshController getController();
}

/// footer base
abstract class SmallRefreshFooterWidget extends StatefulWidget {
  const SmallRefreshFooterWidget({Key? key}) : super(key: key);

  double getHeight();

  SmallRefreshController getController();
}

///small refresh controller
class SmallRefreshController {
  //scroll controller
  late ScrollController _scrollController;

  //scroll controller
  bool _scrollControllerCreateSelfTag = false;

  //scroll controller
  ScrollController get scrollController {
    return _scrollController;
  }

  //nested status
  SmallStickPageViewController? _stickController;

  //get stick controller
  SmallStickPageViewController? get stickController {
    return _stickController;
  }

  //top scale size widget
  SmallSizeWidgetController? _scaleWidgetController;

  //resize controller
  final SmallResizeWidgetController _stickFlingTopResizeController =
      SmallResizeWidgetController(0);

  //resize controller
  final SmallResizeWidgetController _stickFlingBtmResizeController =
      SmallResizeWidgetController(0);

  final GlobalKey _stickTopKey = GlobalKey();
  final GlobalKey _stickBtmKey = GlobalKey();

  //out
  bool _nestedFlingSpaceDisappear = true;

  //set nested flag
  set _nestedFatherOut(bool flag) {
    if (_nestedFlingSpaceDisappear != flag) {
      _nestedFlingSpaceDisappear = flag;
    }
    if (_nestedFlingSpaceDisappear == true) {
      _stickFlingTopResizeController.setHeight(0);
      _getCurrentScrollPosition()
          .correctBy(-(stickController?.headHeight ?? 0));
    } else {
      _stickFlingTopResizeController
          .setHeight((stickController?.headHeight ?? 0));
      _getCurrentScrollPosition().correctBy((stickController?.headHeight ?? 0));
    }
  }

  //get nested flag
  bool get _nestedFatherOut {
    return _nestedFlingSpaceDisappear;
  }

  //pull progress
  double progress = 0;

  //is animating
  bool _isShowAnimating = false;

  //is animating
  bool _isHideAnimating = false;

  //is animating
  bool _isAutoAnimating = false;

  //check is animate
  bool get isAnimating {
    return _isShowAnimating || _isHideAnimating || _isAutoAnimating;
  }

  //lock
  Lock lock = Lock();

  //init status
  RefreshStatus _refreshStatus = RefreshStatus.refreshStatusEnded;

  ///action listeners
  List<SmallRefreshListener> actionListeners = [];

  ///load listeners
  List<SmallLoadListener> loadListeners = [];

  ///status change listeners
  List<SmallHeaderStatusChangeListener> headerStatusListeners = [];

  ///footer status listener
  List<SmallFooterStatusChangeListener> footerStatusListeners = [];

  //start
  SmallRefreshController({
    ScrollController? scrollController,
    SmallStickPageViewController? stickController,
  }) {
    //scroll controller create self
    _scrollControllerCreateSelfTag = scrollController == null;
    //set scroll controller
    _scrollController = scrollController ?? ScrollController();
    //set stick controller
    _stickController = stickController;
    //register if need
    _stickController?.registerChildController(this);
  }

  ///set status
  set refreshStatus(RefreshStatus status) {
    if (_refreshStatus != status) {
      _refreshStatus = status;
      if (_refreshStatus == RefreshStatus.refreshStatusPullAction) {
        _refreshStart();
      }
      if (_refreshStatus == RefreshStatus.refreshStatusPullOver) {
        _refreshCanTrigger();
      }
      if (_refreshStatus == RefreshStatus.refreshStatusRefreshing) {
        _refreshRefreshing();
      }
      if (_refreshStatus == RefreshStatus.refreshStatusEndAnimation) {
        _refreshEndAnimation();
      }
      if (_refreshStatus == RefreshStatus.refreshStatusEnded) {
        _refreshEnd();
      }
    }
  }

  //refresh status
  RefreshStatus get refreshStatus {
    return _refreshStatus;
  }

  //can refresh
  bool get canRefresh {
    return _refreshStatus == RefreshStatus.refreshStatusEnded;
  }

  ///action listeners
  Future<void> startRefresh() {
    return _notifyActionListener(SmallRefreshEvents.refreshActionStart);
  }

  Future<void> endRefresh() {
    return _notifyActionListener(SmallRefreshEvents.refreshActionStop);
  }

  ///notify refresh state changed
  Future<void> _refreshStart() {
    return _notifyHeaderStatusChangeListener(
        SmallRefreshHeaderChangeEvents.refreshStateStart);
  }

  Future<void> _refreshDragProgress(double progress) {
    this.progress = progress;
    return _notifyHeaderStatusChangeListener(
        SmallRefreshHeaderChangeEvents.refreshStateProgress);
  }

  Future<void> _refreshDragProgressOver(double progress) {
    this.progress = progress;
    return _notifyHeaderStatusChangeListener(
        SmallRefreshHeaderChangeEvents.refreshStateProgressOver);
  }

  Future<void> _refreshCanTrigger() {
    return _notifyHeaderStatusChangeListener(
        SmallRefreshHeaderChangeEvents.refreshStatePullOver);
  }

  Future<void> _refreshRefreshing() {
    return _notifyHeaderStatusChangeListener(
        SmallRefreshHeaderChangeEvents.refreshStateRefreshing);
  }

  Future<void> _refreshEndAnimation() {
    return _notifyHeaderStatusChangeListener(
        SmallRefreshHeaderChangeEvents.refreshStateEndAnim);
  }

  Future<void> _refreshEnd() {
    return _notifyHeaderStatusChangeListener(
        SmallRefreshHeaderChangeEvents.refreshStateEnded);
  }

  ///notify load state change listeners
  Future<void> _loadEnd() {
    return _notifyLoadChangeListener(SmallLoadEvents.loadStateEnd);
  }

  Future<void> _loadStart() {
    return _notifyLoadChangeListener(SmallLoadEvents.loadStateStart);
  }

  ///notify footer status change listener
  Future<void> footerShow() {
    return _notifyFooterStatusChangeListener(
        SmallRefreshFooterChangeEvents.notifyShowFooter);
  }

  Future<void> footerHide() {
    return _notifyFooterStatusChangeListener(
        SmallRefreshFooterChangeEvents.notifyHideFooter);
  }

  Future<void> footerEnd() {
    return _notifyFooterStatusChangeListener(
        SmallRefreshFooterChangeEvents.notifyFooterEnd);
  }

  Future<void> footerReset() {
    return _notifyFooterStatusChangeListener(
        SmallRefreshFooterChangeEvents.notifyFooterReset);
  }

  ///action listeners
  void _addActionListener(SmallRefreshListener listener) {
    lock.synchronized(() {
      actionListeners.add(listener);
    });
  }

  void _removeActionListener(SmallRefreshListener listener) {
    lock.synchronized(() {
      actionListeners.add(listener);
    });
  }

  Future _notifyActionListener(SmallRefreshEvents value) {
    return lock.synchronized(() {
      for (int s = 0; s < actionListeners.length; s++) {
        SmallRefreshListener listener = actionListeners[s];
        listener(value);
      }
    });
  }

  ///status listeners
  void addHeaderStatusChangeListener(SmallHeaderStatusChangeListener listener) {
    lock.synchronized(() {
      headerStatusListeners.add(listener);
    });
  }

  void removeHeaderStatusChangeListener(
      SmallHeaderStatusChangeListener listener) {
    lock.synchronized(() {
      headerStatusListeners.add(listener);
    });
  }

  Future _notifyHeaderStatusChangeListener(
      SmallRefreshHeaderChangeEvents value) {
    return lock.synchronized(() {
      for (int s = 0; s < headerStatusListeners.length; s++) {
        SmallHeaderStatusChangeListener listener = headerStatusListeners[s];
        listener(value);
      }
    });
  }

  ///footer status listeners
  void addFooterStatusChangeListener(SmallFooterStatusChangeListener listener) {
    lock.synchronized(() {
      footerStatusListeners.add(listener);
    });
  }

  void removeFooterStatusChangeListener(
      SmallFooterStatusChangeListener listener) {
    lock.synchronized(() {
      footerStatusListeners.add(listener);
    });
  }

  Future _notifyFooterStatusChangeListener(
      SmallRefreshFooterChangeEvents value) {
    return lock.synchronized(() {
      for (int s = 0; s < footerStatusListeners.length; s++) {
        SmallFooterStatusChangeListener listener = footerStatusListeners[s];
        listener(value);
      }
    });
  }

  ///loadListeners
  void addLoadChangeListener(SmallLoadListener listener) {
    lock.synchronized(() {
      loadListeners.add(listener);
    });
  }

  void removeLoadChangeListener(SmallLoadListener listener) {
    lock.synchronized(() {
      loadListeners.add(listener);
    });
  }

  Future _notifyLoadChangeListener(SmallLoadEvents value) {
    return lock.synchronized(() {
      for (int s = 0; s < loadListeners.length; s++) {
        SmallLoadListener listener = loadListeners[s];
        listener(value);
      }
    });
  }

  //get scroll max
  double getNestedScrollMax() {
    return stickController!.headHeight;
  }

  //get start
  double getNestedScrollStart() {
    if (_nestedFatherOut) {
      return 0;
    } else {
      return stickController!.headHeight;
    }
  }

  //get position
  double getFixedScrollPosition() {
    if (_scaleWidgetController == null) {
      return 0;
    }
    if (stickController != null) {
      return _getCurrentScrollPosition().pixels - getNestedScrollStart();
    }
    double headHeight = _getCurrentScrollPosition().pixels;
    return headHeight;
  }

  ScrollPosition _getCurrentScrollPosition() {
    return scrollController.position;
  }

  //dispose
  void dispose() {
    //unregister if need
    _stickController?.unregisterChildController(this);
    //dispose inner controllers
    _scaleWidgetController?.dispose();
    //dispose scroll controllers
    if (_scrollControllerCreateSelfTag) {
      _scrollController.dispose();
    }
    //dispose stick controller
    _stickFlingTopResizeController.dispose();
  }
}
