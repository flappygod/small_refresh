import 'package:small_refresh/src/small_stick_controller.dart';
import 'package:small_refresh/src/small_refresh_scroll.dart';
import 'package:small_refresh/src/small_refresh_base.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'small_refresh_resize.dart';
import 'dart:math';

//call back
typedef SmallCallback = Future<void> Function();

//refresh action listener
typedef SmallRefreshActionListener = Function(SmallRefreshActionEvents events);

//refresh load change listener
typedef SmallLoadActionListener = Function(SmallLoadActionEvents events);

//refresh status change listener
typedef SmallHeaderStatusChangeListener = Function(
    SmallRefreshHeaderChangeEvents events);

//refresh footer status change listener
typedef SmallFooterStatusChangeListener = Function(
    SmallRefreshFooterChangeEvents events);

//refresh footer hide change listener
typedef SmallFooterHideStatusChangeListener = Function(
    SmallRefreshFooterHideEvents events);

///duration time
const int durationTime = 320;

///small refresh action events
enum SmallRefreshActionEvents {
  refreshActionStart,
  refreshActionStop,
}

///small load action events
enum SmallLoadActionEvents {
  loadActionStart,
  loadActionEnd,
  loadActionStop,
}

///load status
enum LoadStatus {
  //load end
  loadStatusEnd,
  //loading
  loadStatusLoading,
  //loading stopped
  loadStatusStopped,
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

///footer status
enum FooterHideStatus {
  footerHide,
  footerShow,
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

///load state change notify
enum SmallRefreshFooterChangeEvents {
  loadEventsStart,
  loadEventsEnd,
  loadEventsStopped,
}

///load state change notify
enum SmallRefreshFooterHideEvents {
  footerEventHide,
  footerEventShow,
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

  //load next offset
  final double loadNextOffset;

  //load next scrolling
  final bool loadNextOnScrolling;

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
    this.loadNextOffset = 10,
    this.loadNextOnScrolling = false,
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
  final Lock _refreshLock = Lock();

  //lock
  final Lock _loadLock = Lock();

  //notification lock
  final Lock _nestedLock = Lock();

  //height can show
  final double _heightCanShow = 0.0001;

  //refresh action listener
  late SmallRefreshActionListener _refreshActionListener;

  //load action listener
  late SmallLoadActionListener _loadActionListener;

  //refresh end
  RefreshStatus _refreshStatus = RefreshStatus.refreshStatusEnded;

  //load end
  LoadStatus _loadStatus = LoadStatus.loadStatusEnd;

  ///nested parent drag start details
  DragStartDetails? _nestedParentDragStartDetails;

  ///nested parent drag session
  Drag? _nestedParentDrag;

  ///whether nested is proxying drag to parent
  bool _nestedParentDragging = false;

  ///set status and also update controllers refresh status
  set refreshStatus(RefreshStatus refreshStatus) {
    _refreshStatus = refreshStatus;
    widget.controller.refreshStatus = refreshStatus;
  }

  ///set load status
  set loadStatus(LoadStatus loadStatus) {
    _loadStatus = loadStatus;
    widget.controller.loadStatus = loadStatus;
  }

  ///init controller
  void _initController() {
    ///create small size widget
    widget.controller._scaleWidgetController = SmallSizeWidgetController(
      baseHeight: _heightCanShow,
      innerHeight: widget.header != null ? widget.header!.height : 0,
    );

    ///listener
    _refreshActionListener = (value) {
      ///do nothing if has no clients
      if (widget.controller.hasClients != true) {
        return;
      }

      ///actions
      switch (value) {
        case SmallRefreshActionEvents.refreshActionStart:

          ///refresh header is null ,do nothing
          if (widget.header == null || widget.onRefresh == null) {
            return;
          }

          ///if refresh is end or is pull, animate to
          if (_refreshStatus == RefreshStatus.refreshStatusEnded ||
              _refreshStatus == RefreshStatus.refreshStatusPullAction) {
            refreshStatus = RefreshStatus.refreshStatusPullLock;

            ///nested must not fling when refresh start
            widget.controller.nestedHeadCanFlingFlag = false;
            _forceNestedNotScroll();

            ///set show animation and auto animation flag
            widget.controller._isShowAnimating = true;
            widget.controller
                ._getCurrentScrollPosition()
                .animateTo(
                  -widget.header!.height,
                  duration: const Duration(milliseconds: durationTime),
                  curve: Curves.easeInOut,
                )
                .whenComplete(() {
              widget.controller._isShowAnimating = false;
            });
          }
          break;
        case SmallRefreshActionEvents.refreshActionStop:
          if (widget.header == null || widget.onRefresh == null) {
            return;
          }
          _changeToEndAnim();
          break;
      }
    };
    widget.controller._addActionRefreshListener(_refreshActionListener);

    ///load action listener
    _loadActionListener = (value) {
      switch (value) {
        case SmallLoadActionEvents.loadActionStart:

          ///action start set stopped
          _changeToLoading(true);
          break;

        ///load action end
        case SmallLoadActionEvents.loadActionEnd:
          _changeToLoadEnd(true);
          break;

        ///load action stopped
        case SmallLoadActionEvents.loadActionStop:
          _changeToLoadStopped();
          break;
      }
    };
    widget.controller._addActionLoadListener(_loadActionListener);
  }

  ///if first refresh animation is set and header is not null,start refresh
  void _initFirstTime() {
    WidgetsBinding.instance.addPostFrameCallback((callback) async {
      if (widget.firstRefresh && widget.header != null) {
        widget.controller.startRefresh();
      }
    });
  }

  @override
  void initState() {
    _initController();
    _initFirstTime();
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller._removeActionLoadListener(_loadActionListener);
      oldWidget.controller._removeActionRefreshListener(_refreshActionListener);
      widget.controller._addActionLoadListener(_loadActionListener);
      widget.controller._addActionRefreshListener(_refreshActionListener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller._removeActionLoadListener(_loadActionListener);
    widget.controller._removeActionRefreshListener(_refreshActionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //assert
    assert(
      !(widget.controller.stickController?.isStickRefresh ?? false) ||
          (widget.header == null && widget.onRefresh == null),
      'Invalid configuration: when stickController.isStickRefresh is true, '
      '`header` and `onRefresh` must both be null (refresh is handled by the stick controller).',
    );

    List<Widget> slivers = [];

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

    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: CustomScrollView(
        controller: widget.controller,
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
        BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
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
        child: HideShowWidget(
          controller: widget.controller._footerController,
          child: widget.footer!,
        ),
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

  //handle notification
  bool _handleNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.horizontal) {
      return false;
    }
    if (!widget.controller.hasClients) {
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

  ///父级可滚动对象的 ScrollPosition。
  ///
  ///这里的父级是 stickController 持有的外层 ScrollController。
  ///当子列表滚动到边界后，会把真实拖拽事件转发给这个 position。
  ScrollPosition? get _parentScrollPosition {
    return widget.controller.stickController?.sc.position;
  }

  ///父级滚动控制器当前是否可用。
  ///
  ///只有父级 controller 存在且已经 attach 到可滚动组件后，
  ///才允许创建 drag session。
  bool get _hasParentScrollPosition {
    final sc = widget.controller.stickController?.sc;
    return sc != null && sc.hasClients;
  }

  ///父级 drag 被系统释放时的回调。
  ///
  ///这个回调会在 `position.drag(...)` 创建的 Drag 生命周期结束后触发，
  ///用来清理当前缓存的 drag 状态。
  void _disposeNestedParentDrag() {
    _nestedParentDrag = null;
    _nestedParentDragging = false;
  }

  ///开始一次“子滚动 -> 父滚动”的拖拽代理。
  ///
  ///当子列表滚动到边界，且后续拖拽应该交给父列表处理时，
  ///通过父级 ScrollPosition 的 `drag(...)` 创建一个新的 drag session。
  ///
  ///[details] 优先使用子列表真实手势产生的 DragStartDetails，
  ///这样父级滚动能尽量保持与用户手势一致的行为。
  void _startNestedParentDrag(DragStartDetails? details) {
    if (!_hasParentScrollPosition) return;
    if (_nestedParentDrag != null) return;

    final ScrollPosition position = _parentScrollPosition!;
    _nestedParentDragStartDetails = details ?? DragStartDetails();
    _nestedParentDrag = position.drag(
      _nestedParentDragStartDetails!,
      _disposeNestedParentDrag,
    );
    _nestedParentDragging = _nestedParentDrag != null;
  }

  ///将子列表当前这一次真实拖拽更新转发给父级 drag。
  ///
  ///只有在 `_startNestedParentDrag` 成功创建 drag session 后，
  ///这个 update 才会真正生效。
  void _updateNestedParentDrag(DragUpdateDetails details) {
    _nestedParentDrag?.update(details);
  }

  ///正常结束一次父级 drag 代理。
  ///
  ///一般在收到 ScrollEndNotification 时调用，
  ///让父级滚动完成一次完整的 drag -> end 生命周期。
  void _endNestedParentDrag([DragEndDetails? details]) {
    if (_nestedParentDrag == null) {
      _nestedParentDragStartDetails = null;
      _nestedParentDragging = false;
      return;
    }
    _nestedParentDrag?.end(
      details ?? DragEndDetails(primaryVelocity: 0),
    );
    _nestedParentDrag = null;
    _nestedParentDragStartDetails = null;
    _nestedParentDragging = false;
  }

  ///取消当前父级 drag 代理。
  ///
  ///一般用于以下场景：
  ///- 当前子列表不再是激活的 child controller
  ///- 外层主动禁止父子联动
  ///- 当前处于刷新动画中，不允许继续联动
  void _cancelNestedParentDrag() {
    _nestedParentDrag?.cancel();
    _nestedParentDrag = null;
    _nestedParentDragStartDetails = null;
    _nestedParentDragging = false;
  }

  ///处理子滚动与父滚动之间的联动逻辑。
  ///
  ///主要职责：
  ///1. 在子列表滚动到边界时，把真实拖拽事件转发给父列表；
  ///2. 在非手势滚动阶段，保留 jumpTo 作为兜底；
  ///3. 维护 nestedHeadCanFlingFlag / nestedFootCanFlingFlag；
  ///4. 在滚动结束或联动失效时，正确结束/取消父级 drag。
  void _handleNotificationNested(ScrollNotification notification) {
    ///没有父级 stickController 时，不需要处理联动。
    if (widget.controller.stickController == null) {
      _cancelNestedParentDrag();
      return;
    }

    _nestedLock.synchronized(() {
      ///记录当前正在交互的 child controller。
      ///
      ///只有真实手势触发的 start / update 才更新 current child，
      ///避免非手势滚动干扰当前联动目标。
      if (notification is ScrollStartNotification &&
          notification.dragDetails != null) {
        widget.controller.stickController!
            .setCurrentChildController(widget.controller);
        _nestedParentDragStartDetails = notification.dragDetails;
      }

      ///记录当前正在交互的 child controller。
      if (notification is ScrollUpdateNotification &&
          notification.dragDetails != null) {
        widget.controller.stickController!
            .setCurrentChildController(widget.controller);
      }

      ///如果当前 child 已经不是激活的 child，取消父级 drag。
      if (widget.controller !=
          widget.controller.stickController?.getCurrentChildController()) {
        _cancelNestedParentDrag();
        return;
      }

      ///如果当前显式禁止父子联动，取消父级 drag。
      if (widget.controller._preventRollingWithParent) {
        _cancelNestedParentDrag();
        return;
      }

      ///刷新显示/隐藏动画期间，不参与联动。
      if (widget.controller.isAnimating) {
        _cancelNestedParentDrag();
        return;
      }

      ///处理滚动更新阶段的父子联动。
      if (notification is ScrollUpdateNotification) {
        final double deltaA = notification.dragDetails?.delta.dy ??
            -(notification.scrollDelta ?? 0);

        final bool isGesture = notification.dragDetails != null;

        ///顶部回弹阶段的非手势更新。
        ///
        ///这种情况下通常不希望继续把“顶部回弹”当成正常上拉联动处理。
        final bool isResilienceTop = !isGesture &&
            !widget.controller.nestedHeadCanFlingFlag &&
            widget.controller._getCurrentScrollPosition().pixels < 0;

        ///子列表继续下拉，但父列表顶部还有可回退空间时，
        ///需要把拖拽交给父列表。
        final bool canPullDownLinkage = deltaA > 0 &&
            (widget.controller.stickController!.sc.offset > 0 ||
                widget.controller._stickController!.isStickRefresh) &&
            widget.controller.stickController!.sc.offset.round() <=
                _getNestedScrollMax().round() &&
            widget.controller.offset.round() < 0;

        ///子列表继续上推，但父列表还没滚到最大联动位置时，
        ///需要把拖拽交给父列表。
        final bool canPullUpLinkage = deltaA < 0 &&
            !isResilienceTop &&
            widget.controller.offset.round() > 0 &&
            widget.controller.stickController!.sc.offset.round() <
                _getNestedScrollMax().round();

        ///下拉联动
        if (canPullDownLinkage) {
          ///先把子列表当前位置归零，避免子列表继续消费位移。
          widget.controller.position.correctBy(-widget.controller.offset);

          if (notification.dragDetails != null) {
            ///真实手势：通过 drag 代理给父列表。
            _startNestedParentDrag(_nestedParentDragStartDetails);
            _updateNestedParentDrag(notification.dragDetails!);
          } else {
            ///非手势阶段：保留 jumpTo 作为兜底。
            double jumpTo =
                widget.controller.stickController!.sc.offset - deltaA.abs();
            if (!widget.controller._stickController!.isStickRefresh) {
              jumpTo = jumpTo < 0 ? 0 : jumpTo;
            }
            widget.controller.stickController!.sc.position.jumpTo(jumpTo);
          }
        }

        ///上拉联动
        if (canPullUpLinkage) {
          ///先把子列表当前位置归零，避免子列表继续消费位移。
          widget.controller.position.correctBy(-widget.controller.offset);

          if (notification.dragDetails != null) {
            ///真实手势：通过 drag 代理给父列表。
            _startNestedParentDrag(_nestedParentDragStartDetails);
            _updateNestedParentDrag(notification.dragDetails!);
          } else {
            ///非手势阶段：保留 jumpTo 作为兜底。
            double jumpTo =
                widget.controller.stickController!.sc.position.pixels - deltaA;
            if (jumpTo > _getNestedScrollMax()) {
              jumpTo = _getNestedScrollMax();
            }
            widget.controller.stickController!.sc.position.jumpTo(jumpTo);
          }
        }

        ///当前 update 已经不再满足联动条件时，结束父级 drag。
        if (!canPullDownLinkage && !canPullUpLinkage) {
          if (_nestedParentDragging) {
            _endNestedParentDrag();
          }
        }
      }

      ///根据滚动距离设置是否需要Fling
      if (widget.controller.stickController!.sc.offset > 0) {
        widget.controller.nestedHeadCanFlingFlag = true;
      } else {
        widget.controller.nestedHeadCanFlingFlag = false;
      }
      if (widget.controller.stickController!.sc.offset <
          widget.controller.stickController!.headHeight) {
        widget.controller.nestedFootCanFlingFlag = true;
      } else {
        widget.controller.nestedFootCanFlingFlag = false;
      }

      ///手势结束时，结束父级 drag 生命周期。
      if (notification is ScrollEndNotification) {
        _endNestedParentDrag();
      }
    });
  }

  //force not scroll
  void _forceNestedNotScroll() {
    if (widget.controller.stickController == null) {
      return;
    }
    if (widget.controller.stickController?.getCurrentChildController() ==
        widget.controller) {
      widget.controller
          ._getCurrentScrollPosition()
          .jumpTo(widget.controller._getCurrentScrollPosition().pixels);
    }
    return;
  }

  //head refresh
  void _handleNotificationHeader(ScrollNotification notification) {
    if (widget.header == null || widget.onRefresh == null) {
      return;
    }
    //get scroll height
    double scrollHeight = (-widget.controller.offset);

    //refresh header
    widget.controller._scaleWidgetController?.setScrollOffset(-scrollHeight);

    ///start pull
    if (scrollHeight > 0) {
      _changeToPull();
    }

    ///refresh pull progress
    if (_refreshStatus == RefreshStatus.refreshStatusPullAction) {
      if (scrollHeight > 0 && scrollHeight <= widget.header!.height) {
        widget.controller
            ._refreshDragProgress(scrollHeight / widget.header!.height);
      } else if (scrollHeight >= widget.header!.height) {
        widget.controller
            ._refreshDragProgressOver(scrollHeight / widget.header!.height);
      }
    }

    ///if pull out,and touch gone,change to pull out
    if (scrollHeight >= widget.header!.height &&
        notification is ScrollUpdateNotification &&
        notification.dragDetails == null) {
      _changeToPullOut(scrollHeight);
    }

    ///drag interrupt
    if ((notification is ScrollUpdateNotification &&
            notification.dragDetails != null) ||
        (notification is ScrollStartNotification &&
            notification.dragDetails != null)) {
      _changeToInterrupt(scrollHeight);
    }

    ///if pulled out ,change to refreshing
    if (notification is ScrollEndNotification) {
      _changeToRefreshing();
    }

    ///is refreshing and end
    if (notification is ScrollEndNotification &&
        widget.controller.refreshStatus ==
            RefreshStatus.refreshStatusEndAnimation &&
        widget.controller._getCurrentScrollPosition().pixels == 0) {
      _changeToEnd();
    }
  }

  //change to pull
  Future<void> _changeToPull() async {
    if (_refreshStatus == RefreshStatus.refreshStatusEnded ||
        _refreshStatus == RefreshStatus.refreshStatusPullLock) {
      await _refreshLock.synchronized(() {
        if (_refreshStatus == RefreshStatus.refreshStatusEnded ||
            _refreshStatus == RefreshStatus.refreshStatusPullLock) {
          refreshStatus = RefreshStatus.refreshStatusPullAction;
        }
      });
    }
  }

  //change to pull out
  Future<void> _changeToPullOut(double scrollHeight) async {
    if (_refreshStatus == RefreshStatus.refreshStatusPullAction) {
      await _refreshLock.synchronized(() {
        if (_refreshStatus == RefreshStatus.refreshStatusPullAction) {
          refreshStatus = RefreshStatus.refreshStatusPullOver;
          widget.controller._scaleWidgetController?.setSmallHeadShow(true);
          widget.controller
              ._getCurrentScrollPosition()
              .jumpTo(widget.header!.height - scrollHeight);
        }
      });
    }
  }

  //change to pull out
  Future<void> _changeToInterrupt(double scrollHeight) async {
    //change to end,if _status == RefreshStatus.Refresh_ANIMATION
    _changeToEnd();
  }

  //pull end
  Future<void> _changeToRefreshing() {
    //if pulled out
    if (_refreshStatus == RefreshStatus.refreshStatusPullOver) {
      return _refreshLock.synchronized(() async {
        if (_refreshStatus == RefreshStatus.refreshStatusPullOver) {
          refreshStatus = RefreshStatus.refreshStatusRefreshing;
          await _changeToLoadEnd(true);
          Future future = widget.onRefresh!();
          future.then((value) async {
            if (mounted) {
              _changeToEndAnim();
            }
          }).catchError((error) async {
            if (mounted) {
              _changeToEndAnim();
            }
          });
        }
      });
    }
    //if not pulled out
    if (_refreshStatus == RefreshStatus.refreshStatusPullAction) {
      return _refreshLock.synchronized(() {
        if (_refreshStatus == RefreshStatus.refreshStatusPullAction) {
          //just set state ,and the scroll controller resilience
          refreshStatus = RefreshStatus.refreshStatusEnded;
        }
      });
    }
    return Future.value();
  }

  //start end animation
  //just use scroll controller resilience
  Future<void> _changeToEndAnim() async {
    if (widget.controller.hasClients != true) {
      return;
    }
    //if is Refresh_REFRESHING
    if (_refreshStatus == RefreshStatus.refreshStatusRefreshing) {
      //lock
      await _refreshLock.synchronized(() {
        //check twice
        if (_refreshStatus == RefreshStatus.refreshStatusRefreshing) {
          //end anim must not fling
          widget.controller.nestedHeadCanFlingFlag = false;
          //end anim must not scroll
          _forceNestedNotScroll();
          //check current position,if header is no longer show,just set status
          if (widget.controller.offset.toInt() >=
              widget.header!.height.toInt()) {
            //set refresh animation
            //refresh end and jump for resilience
            widget.controller._scaleWidgetController?.setSmallHeadShow(false);
            //jump to position
            widget.controller._getCurrentScrollPosition().jumpTo(
                widget.controller._getCurrentScrollPosition().pixels -
                    widget.header!.height);
            //change to end directly
            refreshStatus = RefreshStatus.refreshStatusEnded;
            widget.controller._isHideAnimating = false;
          } else {
            //set refresh animation
            refreshStatus = RefreshStatus.refreshStatusEndAnimation;
            //set can fling to false
            widget.controller.nestedHeadCanFlingFlag = false;
            //set hide animation
            widget.controller._isHideAnimating = true;
            //refresh end and jump for resilience
            widget.controller._scaleWidgetController?.setSmallHeadShow(false);
            //jump to position
            widget.controller._getCurrentScrollPosition().jumpTo(
                widget.controller._getCurrentScrollPosition().pixels -
                    widget.header!.height);
          }
        }
      });
    }
  }

  //change to end anim
  Future<void> _changeToEnd() {
    if (_refreshStatus == RefreshStatus.refreshStatusEndAnimation) {
      return _refreshLock.synchronized(() {
        if (_refreshStatus == RefreshStatus.refreshStatusEndAnimation) {
          refreshStatus = RefreshStatus.refreshStatusEnded;
          widget.controller._isHideAnimating = false;
        }
      });
    }
    return Future.value();
  }

  //loading
  void _handleNotificationFooter(ScrollNotification notification) {
    if (widget.footer == null || widget.onLoad == null) {
      return;
    }
    if ((notification is ScrollEndNotification ||
            ((notification is ScrollUpdateNotification) &&
                widget.loadNextOnScrolling)) &&
        notification.metrics.extentAfter <=
            max(widget.footer!.height + widget.loadNextOffset, 0) &&
        _refreshStatus == RefreshStatus.refreshStatusEnded) {
      _changeToLoading(false);
    }
  }

  ///change to loading
  Future<void> _changeToLoading(bool force) async {
    if (force) {
      ///force to loading
      if (_loadStatus != LoadStatus.loadStatusLoading) {
        await _loadLock.synchronized(() async {
          try {
            if (_loadStatus != LoadStatus.loadStatusLoading) {
              loadStatus = LoadStatus.loadStatusLoading;
              await widget.onLoad!();
              loadStatus = LoadStatus.loadStatusEnd;
            }
          } catch (error) {
            loadStatus = LoadStatus.loadStatusEnd;
          }
        });
      }
    } else {
      ///change to loading
      if (_loadStatus == LoadStatus.loadStatusEnd) {
        await _loadLock.synchronized(() async {
          try {
            if (_loadStatus == LoadStatus.loadStatusEnd) {
              loadStatus = LoadStatus.loadStatusLoading;
              await widget.onLoad!();
              loadStatus = LoadStatus.loadStatusEnd;
            }
          } catch (error) {
            loadStatus = LoadStatus.loadStatusEnd;
          }
        });
      }
    }
  }

  ///change to load end
  Future<void> _changeToLoadEnd(bool force) async {
    if (force) {
      if (_loadStatus != LoadStatus.loadStatusEnd) {
        await _loadLock.synchronized(() {
          if (_loadStatus != LoadStatus.loadStatusEnd) {
            loadStatus = LoadStatus.loadStatusEnd;
          }
        });
      }
    } else {
      if (_loadStatus == LoadStatus.loadStatusLoading) {
        await _loadLock.synchronized(() {
          if (_loadStatus == LoadStatus.loadStatusLoading) {
            loadStatus = LoadStatus.loadStatusEnd;
          }
        });
      }
    }
  }

  ///change to stopped
  Future<void> _changeToLoadStopped() async {
    if (_loadStatus != LoadStatus.loadStatusStopped) {
      await _loadLock.synchronized(() {
        if (_loadStatus != LoadStatus.loadStatusStopped) {
          loadStatus = LoadStatus.loadStatusStopped;
        }
      });
    }
  }
}

///header base
abstract class SmallRefreshHeaderWidget extends StatefulWidget {
  ///controller
  final SmallRefreshController controller;

  ///height
  final double height;

  const SmallRefreshHeaderWidget({
    Key? key,
    required this.controller,
    required this.height,
  }) : super(key: key);
}

///footer base
abstract class SmallRefreshFooterWidget extends StatefulWidget {
  ///controller
  final SmallRefreshController controller;

  ///height
  final double height;

  const SmallRefreshFooterWidget({
    Key? key,
    required this.controller,
    required this.height,
  }) : super(key: key);
}

///small refresh controller
class SmallRefreshController extends SmallRefreshScrollController {
  //prevent rolling with child
  bool _preventRollingWithParent = false;

  //animate to top
  Future<void> animateToTop({
    bool fatherTogether = true,
    required Duration duration,
    required Curve curve,
  }) async {
    //set prevent true
    _preventRollingWithParent = true;

    //father out remove top fling
    nestedHeadCanFlingFlag = false;

    //future one
    Future futureOne = animateTo(
      0,
      duration: duration,
      curve: curve,
    );

    //future two
    Future futureTwo = fatherTogether
        ? (_stickController?.sc.animateTo(
              0,
              duration: duration,
              curve: curve,
            ) ??
            Future.delayed(duration))
        : Future.delayed(duration);
    await Future.wait([futureOne, futureTwo]);

    //set prevent false
    _preventRollingWithParent = false;
  }

  //nested status
  SmallStickController? _stickController;

  //get stick controller
  SmallStickController? get stickController {
    return _stickController;
  }

  //top scale size widget
  SmallSizeWidgetController? _scaleWidgetController;

  //footer controller
  late HideShowController _footerController;

  //out
  bool _nestedHeadCanFlingFlag = false;

  //set nested flag
  set nestedHeadCanFlingFlag(bool flag) {
    if (_stickController == null) {
      return;
    }
    if (_nestedHeadCanFlingFlag == flag) {
      return;
    }
    _nestedHeadCanFlingFlag = flag;
    if (_nestedHeadCanFlingFlag == true) {
      setHeadCanFling();
    } else {
      setHeadNotFling();
    }
  }

  //get nested flag
  bool get nestedHeadCanFlingFlag {
    return _nestedHeadCanFlingFlag;
  }

  //out
  bool _nestedFootCanFlingFlag = false;

  //set nested flag
  set nestedFootCanFlingFlag(bool flag) {
    if (_stickController == null) {
      return;
    }
    if (_nestedFootCanFlingFlag == flag) {
      return;
    }
    _nestedFootCanFlingFlag = flag;
    if (_nestedFootCanFlingFlag == true) {
      setFootCanFling();
    } else {
      setFootNotFling();
    }
  }

  //get nested flag
  bool get nestedFootCanFlingFlag {
    return _nestedFootCanFlingFlag;
  }

  //pull progress
  double progress = 0;

  //is animating
  bool _isShowAnimating = false;

  //is animating
  bool _isHideAnimating = false;

  //check is animate
  bool get isAnimating {
    return _isShowAnimating || _isHideAnimating;
  }

  //lock
  Lock lock = Lock();

  ///refresh status
  RefreshStatus _refreshStatus = RefreshStatus.refreshStatusEnded;

  ///load status
  LoadStatus _loadStatus = LoadStatus.loadStatusEnd;

  ///action listeners
  List<SmallRefreshActionListener> actionRefreshListeners = [];

  ///load listeners
  List<SmallLoadActionListener> actionLoadListeners = [];

  ///status change listeners
  List<SmallHeaderStatusChangeListener> headerStatusListeners = [];

  ///footer status listener
  List<SmallFooterStatusChangeListener> footerStatusListeners = [];

  //start
  SmallRefreshController({
    SmallStickController? stickController,
    HideShowStatus footerHideStatus = HideShowStatus.hide,
    super.debugLabel,
    super.initialScrollOffset,
    super.keepScrollOffset,
  }) {
    //set stick controller
    _stickController = stickController;
    //register if need
    _stickController?.registerChildController(this);
    //create footer controller
    _footerController = HideShowController(footerHideStatus);
  }

  ///set status
  set refreshStatus(RefreshStatus status) {
    if (_refreshStatus != status) {
      _refreshStatus = status;
      if (_refreshStatus == RefreshStatus.refreshStatusPullAction) {
        _notifyHeaderStatusChangeListener(
          SmallRefreshHeaderChangeEvents.refreshStateStart,
        );
      }
      if (_refreshStatus == RefreshStatus.refreshStatusPullOver) {
        _notifyHeaderStatusChangeListener(
          SmallRefreshHeaderChangeEvents.refreshStatePullOver,
        );
      }
      if (_refreshStatus == RefreshStatus.refreshStatusRefreshing) {
        _notifyHeaderStatusChangeListener(
          SmallRefreshHeaderChangeEvents.refreshStateRefreshing,
        );
      }
      if (_refreshStatus == RefreshStatus.refreshStatusEndAnimation) {
        _notifyHeaderStatusChangeListener(
          SmallRefreshHeaderChangeEvents.refreshStateEndAnim,
        );
      }
      if (_refreshStatus == RefreshStatus.refreshStatusEnded) {
        _notifyHeaderStatusChangeListener(
          SmallRefreshHeaderChangeEvents.refreshStateEnded,
        );
      }
    }
  }

  RefreshStatus get refreshStatus {
    return _refreshStatus;
  }

  ///set load status
  set loadStatus(LoadStatus status) {
    if (_loadStatus != status) {
      _loadStatus = status;
      if (_loadStatus == LoadStatus.loadStatusLoading) {
        _notifyFooterStatusChangeListener(
            SmallRefreshFooterChangeEvents.loadEventsStart);
      }
      if (_loadStatus == LoadStatus.loadStatusEnd) {
        _notifyFooterStatusChangeListener(
            SmallRefreshFooterChangeEvents.loadEventsEnd);
      }
      if (_loadStatus == LoadStatus.loadStatusStopped) {
        _notifyFooterStatusChangeListener(
            SmallRefreshFooterChangeEvents.loadEventsStopped);
      }
    }
  }

  LoadStatus get loadStatus {
    return _loadStatus;
  }

  void showFooter() {
    _footerController.show();
  }

  void hideFooter() {
    _footerController.hide();
  }

  //can refresh
  bool get canRefresh {
    return _refreshStatus == RefreshStatus.refreshStatusEnded;
  }

  ///action listeners
  Future<void> startRefresh() {
    return _notifyActionRefreshListener(
        SmallRefreshActionEvents.refreshActionStart);
  }

  Future<void> endRefresh() {
    return _notifyActionRefreshListener(
        SmallRefreshActionEvents.refreshActionStop);
  }

  Future<void> startLoad() {
    return _notifyActionLoadListener(SmallLoadActionEvents.loadActionStart);
  }

  Future<void> endLoad() {
    return _notifyActionLoadListener(SmallLoadActionEvents.loadActionEnd);
  }

  Future<void> stopLoad() {
    return _notifyActionLoadListener(SmallLoadActionEvents.loadActionStop);
  }

  ///drag progress listeners
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

  ///action listeners refresh
  void _addActionRefreshListener(SmallRefreshActionListener listener) {
    lock.synchronized(() {
      actionRefreshListeners.add(listener);
    });
  }

  void _removeActionRefreshListener(SmallRefreshActionListener listener) {
    lock.synchronized(() {
      actionRefreshListeners.remove(listener);
    });
  }

  Future _notifyActionRefreshListener(SmallRefreshActionEvents value) {
    return lock.synchronized(() {
      for (int s = 0; s < actionRefreshListeners.length; s++) {
        SmallRefreshActionListener listener = actionRefreshListeners[s];
        listener(value);
      }
    });
  }

  ///action listeners load
  void _addActionLoadListener(SmallLoadActionListener listener) {
    lock.synchronized(() {
      actionLoadListeners.add(listener);
    });
  }

  void _removeActionLoadListener(SmallLoadActionListener listener) {
    lock.synchronized(() {
      actionLoadListeners.remove(listener);
    });
  }

  Future _notifyActionLoadListener(SmallLoadActionEvents value) {
    return lock.synchronized(() {
      for (int s = 0; s < actionLoadListeners.length; s++) {
        SmallLoadActionListener listener = actionLoadListeners[s];
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
      headerStatusListeners.remove(listener);
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
      footerStatusListeners.remove(listener);
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

  //get scroll max
  double getNestedScrollMax() {
    return stickController!.headHeight;
  }

  //get current controller scroll position
  ScrollPosition _getCurrentScrollPosition() {
    return position;
  }

  //dispose
  @override
  void dispose() {
    super.dispose();
    //unregister if need
    _stickController?.unregisterChildController(this);
    //dispose inner controllers
    _scaleWidgetController?.dispose();
  }
}
