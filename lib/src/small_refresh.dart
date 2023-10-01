import 'package:synchronized/synchronized.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'small_refresh_resize.dart';
import 'small_refresh_space.dart';
import 'small_stick_page.dart';

//call back
typedef SmallCallback = Future<void> Function();

//refresh action listener
typedef SmallRefreshActionListener = Function(SmallRefreshActionEvents events);

//refresh load change listener
typedef SmallLoadActionListener = Function(SmallLoadActionEvents events);

//refresh status change listener
typedef SmallHeaderStatusChangeListener = Function(SmallRefreshHeaderChangeEvents events);

//refresh footer status change listener
typedef SmallFooterStatusChangeListener = Function(SmallRefreshFooterChangeEvents events);

//refresh footer hide change listener
typedef SmallFooterHideStatusChangeListener = Function(SmallRefreshFooterHideEvents events);

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

  //footer status change listener
  late SmallFooterHideStatusChangeListener _footerHideStatusChangeListener;

  //refresh end
  RefreshStatus _refreshStatus = RefreshStatus.refreshStatusEnded;

  //load end
  LoadStatus _loadStatus = LoadStatus.loadStatusEnd;

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
      if (widget.controller._scrollController.hasClients != true) {
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
          if (_refreshStatus == RefreshStatus.refreshStatusEnded || _refreshStatus == RefreshStatus.refreshStatusPullAction) {
            refreshStatus = RefreshStatus.refreshStatusPullLock;

            ///nested must not fling when refresh start
            _forceNestedNotFling();
            _forceNestedNotScroll();

            ///set show animation and auto animation flag
            widget.controller._isShowAnimating = true;
            widget.controller._isAutoAnimating = true;
            Future future = widget.controller._getCurrentScrollPosition().animateTo(
                  -widget.header!.height,
                  duration: const Duration(milliseconds: durationTime),
                  curve: Curves.easeInOut,
                );
            future.then((value) {
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

    ///footer status change listener
    _footerHideStatusChangeListener = (value) {
      if (mounted) {
        setState(() {});
      }
    };
    widget.controller._addFooterHideStatusChangeListener(_footerHideStatusChangeListener);
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
      oldWidget.controller._removeFooterHideStatusChangeListener(_footerHideStatusChangeListener);
      widget.controller._addActionLoadListener(_loadActionListener);
      widget.controller._addActionRefreshListener(_refreshActionListener);
      widget.controller._addFooterHideStatusChangeListener(_footerHideStatusChangeListener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller._removeActionLoadListener(_loadActionListener);
    widget.controller._removeActionRefreshListener(_refreshActionListener);
    widget.controller._removeFooterHideStatusChangeListener(_footerHideStatusChangeListener);
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
        keyboardDismissBehavior: widget.keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
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
    if (widget.header != null && widget.controller._scaleWidgetController != null) {
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
    if (widget.footer != null && widget.controller.footerHideStatus == FooterHideStatus.footerShow) {
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
      if ((notification is ScrollStartNotification && notification.dragDetails != null) ||
          (notification is ScrollUpdateNotification && notification.dragDetails != null)) {
        widget.controller.stickController!.setCurrentChildController(widget.controller);
      }

      ///when nested locked by other scroll views
      if (widget.controller != widget.controller.stickController?.getCurrentChildController()) {
        return;
      }

      ///when small refresh is  refresh animating ,do nothing
      if (widget.controller.isAnimating) {
        return;
      }

      ///start notification
      if (notification is ScrollStartNotification) {
        if (widget.controller._stickTopKey.currentContext?.findRenderObject() != null &&
            widget.controller._stickBtmKey.currentContext?.findRenderObject() != null) {
          RenderBox boxTop = widget.controller._stickTopKey.currentContext?.findRenderObject() as RenderBox;
          RenderBox boxBtm = widget.controller._stickBtmKey.currentContext?.findRenderObject() as RenderBox;

          Offset topOffset = boxTop.localToGlobal(Offset.zero);
          Offset btmOffset = boxBtm.localToGlobal(Offset.zero);

          ///content height
          double contentHeight = btmOffset.dy - topOffset.dy - boxTop.size.height;
          double totalHeight = widget.controller.scrollController.position.context.storageContext.size?.height ?? 0;
          double needHeight = totalHeight - contentHeight;

          ///need height ,if over height less than 10
          if (needHeight < -10) {
            widget.controller._stickFlingBtmResizeController.setHeight(0);
          } else {
            widget.controller._stickFlingBtmResizeController.setHeight(needHeight + 10);
          }
        }
      }

      ///if is scroll update
      if (notification is ScrollUpdateNotification) {
        //get scroll delta
        double deltaA = notification.dragDetails?.delta.dy ?? -(notification.scrollDelta ?? 0);
        //check is user gesture
        bool isGesture = (notification.dragDetails != null);
        //top resilience
        bool isResilienceTop = !isGesture && widget.controller._nestedFatherOut && widget.controller._getCurrentScrollPosition().pixels < 0;
        //no scroll space
        bool isNoScrollSpace = (widget.controller._getCurrentScrollPosition().maxScrollExtent == 0);

        ///pull down when this list has no scroll space
        if (isGesture && deltaA > 0 && isNoScrollSpace && widget.controller.stickController!.scrollController.offset != 0) {
          widget.controller
              ._getCurrentScrollPosition()
              .correctBy(_getNestedScrollStart() - widget.controller._getCurrentScrollPosition().pixels);
          double jumpTo = widget.controller.stickController!.scrollController.position.pixels - deltaA;
          jumpTo = jumpTo < 0 ? 0 : jumpTo;
          widget.controller.stickController!.scrollController.position.jumpTo(jumpTo);
          return;
        }

        ///pull up when this list has no scroll space
        if (isGesture &&
            deltaA < 0 &&
            isNoScrollSpace &&
            (widget.controller.scrollController.offset * 10).toInt() > (_getNestedScrollStart() * 10).toInt() &&
            (widget.controller.stickController!.scrollController.offset * 10).toInt() != (_getNestedScrollMax() * 10).toInt()) {
          widget.controller
              ._getCurrentScrollPosition()
              .correctBy(_getNestedScrollStart() - widget.controller._getCurrentScrollPosition().pixels);
          double jumpTo = widget.controller.stickController!.scrollController.position.pixels - deltaA;
          jumpTo = jumpTo > _getNestedScrollMax() ? _getNestedScrollMax() : jumpTo;
          widget.controller.stickController!.scrollController.position.jumpTo(jumpTo);
          return;
        }

        ///pull down normal
        if (deltaA > 0 &&
            widget.controller.stickController!.scrollController.offset > 0 &&
            (widget.controller.stickController!.scrollController.offset * 10).toInt() <= (_getNestedScrollMax() * 10).toInt() &&
            (widget.controller._getCurrentScrollPosition().pixels * 10).toInt() < (_getNestedScrollStart() * 10).toInt()) {
          double jumpTo = widget.controller.stickController!.scrollController.position.pixels - deltaA;
          if ((widget.controller._getCurrentScrollPosition().pixels - _getNestedScrollStart()).abs() < deltaA) {
            double jumpCross = (widget.controller._getCurrentScrollPosition().pixels - _getNestedScrollStart()).abs();
            jumpTo = widget.controller.stickController!.scrollController.position.pixels - jumpCross;
            widget.controller
                ._getCurrentScrollPosition()
                .correctBy(_getNestedScrollStart() - widget.controller._getCurrentScrollPosition().pixels);
          } else {
            widget.controller._getCurrentScrollPosition().correctBy(deltaA);
          }
          jumpTo = jumpTo < 0 ? 0 : jumpTo;
          widget.controller.stickController!.scrollController.position.jumpTo(jumpTo);
        }

        ///pull up normal
        if (deltaA < 0 &&
            !isResilienceTop &&
            (widget.controller.scrollController.offset * 10).toInt() > (_getNestedScrollStart() * 10).toInt() &&
            (widget.controller.stickController!.scrollController.offset * 10).toInt() < (_getNestedScrollMax() * 10).toInt()) {
          double jumpTo = widget.controller.stickController!.scrollController.position.pixels - deltaA;
          if (widget.controller.scrollController.offset - _getNestedScrollStart() < deltaA.abs()) {
            double jumpCross = (widget.controller._getCurrentScrollPosition().pixels - _getNestedScrollStart()).abs();
            jumpTo = widget.controller.stickController!.scrollController.position.pixels + jumpCross;
            widget.controller
                ._getCurrentScrollPosition()
                .correctBy(_getNestedScrollStart() - widget.controller._getCurrentScrollPosition().pixels);
          } else {
            widget.controller._getCurrentScrollPosition().correctBy(deltaA);
          }
          jumpTo = jumpTo > _getNestedScrollMax() ? _getNestedScrollMax() : jumpTo;
          widget.controller.stickController!.scrollController.position.jumpTo(jumpTo);
        }
      }
      //set not fling
      if (notification is ScrollUpdateNotification || notification is ScrollStartNotification) {
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
    if (widget.controller.stickController?.getCurrentChildController() == widget.controller) {
      widget.controller._getCurrentScrollPosition().jumpTo(widget.controller._getCurrentScrollPosition().pixels);
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
      _changeToPull();
    }

    ///refresh pull progress
    if (_refreshStatus == RefreshStatus.refreshStatusPullAction) {
      if (scrollHeight > 0 && scrollHeight <= widget.header!.height) {
        widget.controller._refreshDragProgress(scrollHeight / widget.header!.height);
      } else if (scrollHeight >= widget.header!.height) {
        widget.controller._refreshDragProgressOver(scrollHeight / widget.header!.height);
      }
    }

    ///if pull out,and touch gone,change to pull out
    if (scrollHeight >= widget.header!.height && notification is ScrollUpdateNotification && notification.dragDetails == null) {
      _changeToPullOut(scrollHeight);
    }

    ///drag interrupt
    if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
      _changeToInterrupt(scrollHeight);
    }

    ///if pulled out ,change to refreshing
    if (notification is ScrollEndNotification) {
      _changeToRefreshing();
    }

    ///is refreshing and end
    if (notification is ScrollEndNotification &&
        widget.controller.refreshStatus == RefreshStatus.refreshStatusEndAnimation &&
        widget.controller._getCurrentScrollPosition().pixels == 0) {
      _changeToEnd();
    }
  }

  //change to pull
  Future<void> _changeToPull() async {
    if (_refreshStatus == RefreshStatus.refreshStatusEnded || _refreshStatus == RefreshStatus.refreshStatusPullLock) {
      await _refreshLock.synchronized(() {
        if (_refreshStatus == RefreshStatus.refreshStatusEnded || _refreshStatus == RefreshStatus.refreshStatusPullLock) {
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
          widget.controller._getCurrentScrollPosition().jumpTo(widget.header!.height - scrollHeight);
        }
      });
    }
  }

  //change to pull out
  Future<void> _changeToInterrupt(double scrollHeight) async {
    //all animation set gone
    widget.controller._isHideAnimating = false;
    widget.controller._isAutoAnimating = false;
    widget.controller._isShowAnimating = false;
    //change to end,if _status == RefreshStatus.Refresh_ANIMATION
    _changeToEnd();
  }

  //pull end
  Future<void> _changeToRefreshing() async {
    //if pulled out
    if (_refreshStatus == RefreshStatus.refreshStatusPullOver) {
      await _refreshLock.synchronized(() async {
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
      await _refreshLock.synchronized(() {
        if (_refreshStatus == RefreshStatus.refreshStatusPullAction) {
          //just set state ,and the scroll controller resilience
          refreshStatus = RefreshStatus.refreshStatusEnded;
          widget.controller._isAutoAnimating = false;
        }
      });
    }
  }

  //start end animation
  //just use scroll controller resilience
  Future<void> _changeToEndAnim() async {
    if (widget.controller._scrollController.hasClients != true) {
      return;
    }
    //if is Refresh_REFRESHING
    if (_refreshStatus == RefreshStatus.refreshStatusRefreshing) {
      //lock
      await _refreshLock.synchronized(() {
        //check twice
        if (_refreshStatus == RefreshStatus.refreshStatusRefreshing) {
          //end anim must not fling
          _forceNestedNotFling();
          //end anim must not scroll
          _forceNestedNotScroll();
          //check current position,if header is no longer show,just set status
          if (widget.controller.scrollController.offset.toInt() >= widget.header!.height.toInt()) {
            //set refresh animation
            //refresh end and jump for resilience
            widget.controller._scaleWidgetController?.setSmallHeadShow(false);
            //jump to position
            widget.controller
                ._getCurrentScrollPosition()
                .jumpTo(widget.controller._getCurrentScrollPosition().pixels - widget.header!.height);
            //change to end directly
            refreshStatus = RefreshStatus.refreshStatusEnded;
            widget.controller._isAutoAnimating = false;
            widget.controller._isHideAnimating = false;
          } else {
            //set refresh animation
            refreshStatus = RefreshStatus.refreshStatusEndAnimation;
            //set hide animation
            widget.controller._isHideAnimating = true;
            //refresh end and jump for resilience
            widget.controller._scaleWidgetController?.setSmallHeadShow(false);
            //jump to position
            widget.controller
                ._getCurrentScrollPosition()
                .jumpTo(widget.controller._getCurrentScrollPosition().pixels - widget.header!.height);
          }
        }
      });
    }
  }

  //change to end anim
  Future<void> _changeToEnd() async {
    if (_refreshStatus == RefreshStatus.refreshStatusEndAnimation) {
      await _refreshLock.synchronized(() {
        if (_refreshStatus == RefreshStatus.refreshStatusEndAnimation) {
          refreshStatus = RefreshStatus.refreshStatusEnded;
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
        notification.metrics.extentAfter <= widget.footer!.height &&
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

/// header base
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

/// footer base
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
  final SmallResizeWidgetController _stickFlingTopResizeController = SmallResizeWidgetController(0);

  //resize controller
  final SmallResizeWidgetController _stickFlingBtmResizeController = SmallResizeWidgetController(0);

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
      _getCurrentScrollPosition().correctBy(-(stickController?.headHeight ?? 0));
    } else {
      _stickFlingTopResizeController.setHeight((stickController?.headHeight ?? 0));
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

  ///refresh status
  RefreshStatus _refreshStatus = RefreshStatus.refreshStatusEnded;

  ///load status
  LoadStatus _loadStatus = LoadStatus.loadStatusEnd;

  ///hide status
  FooterHideStatus _footerHideStatus = FooterHideStatus.footerShow;

  ///action listeners
  List<SmallRefreshActionListener> actionRefreshListeners = [];

  ///load listeners
  List<SmallLoadActionListener> actionLoadListeners = [];

  ///status change listeners
  List<SmallHeaderStatusChangeListener> headerStatusListeners = [];

  ///footer status listener
  List<SmallFooterStatusChangeListener> footerStatusListeners = [];

  ///footer hide status listener
  List<SmallFooterHideStatusChangeListener> footerHideStatusListener = [];

  //start
  SmallRefreshController({
    ScrollController? scrollController,
    SmallStickPageViewController? stickController,
    FooterHideStatus? footerHideStatus,
  }) {
    //scroll controller create self
    _scrollControllerCreateSelfTag = scrollController == null;
    //set scroll controller
    _scrollController = scrollController ?? ScrollController();
    //set stick controller
    _stickController = stickController;
    //register if need
    _stickController?.registerChildController(this);
    _footerHideStatus = footerHideStatus ?? FooterHideStatus.footerShow;
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
        _notifyFooterStatusChangeListener(SmallRefreshFooterChangeEvents.loadEventsStart);
      }
      if (_loadStatus == LoadStatus.loadStatusEnd) {
        _notifyFooterStatusChangeListener(SmallRefreshFooterChangeEvents.loadEventsEnd);
      }
      if (_loadStatus == LoadStatus.loadStatusStopped) {
        _notifyFooterStatusChangeListener(SmallRefreshFooterChangeEvents.loadEventsStopped);
      }
    }
  }

  LoadStatus get loadStatus {
    return _loadStatus;
  }

  ///set footer hide status
  set footerHideStatus(FooterHideStatus status) {
    if (_footerHideStatus != status) {
      _footerHideStatus = status;
      if (_footerHideStatus == FooterHideStatus.footerHide) {
        _notifyFooterHideStatusChangeListener(
          SmallRefreshFooterHideEvents.footerEventHide,
        );
      }
      if (_footerHideStatus == FooterHideStatus.footerShow) {
        _notifyFooterHideStatusChangeListener(
          SmallRefreshFooterHideEvents.footerEventShow,
        );
      }
    }
  }

  FooterHideStatus get footerHideStatus {
    return _footerHideStatus;
  }

  void showFooter() {
    footerHideStatus = FooterHideStatus.footerShow;
  }

  void hideFooter() {
    footerHideStatus = FooterHideStatus.footerHide;
  }

  //can refresh
  bool get canRefresh {
    return _refreshStatus == RefreshStatus.refreshStatusEnded;
  }

  ///action listeners
  Future<void> startRefresh() {
    return _notifyActionRefreshListener(SmallRefreshActionEvents.refreshActionStart);
  }

  Future<void> endRefresh() {
    return _notifyActionRefreshListener(SmallRefreshActionEvents.refreshActionStop);
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
    return _notifyHeaderStatusChangeListener(SmallRefreshHeaderChangeEvents.refreshStateProgress);
  }

  Future<void> _refreshDragProgressOver(double progress) {
    this.progress = progress;
    return _notifyHeaderStatusChangeListener(SmallRefreshHeaderChangeEvents.refreshStateProgressOver);
  }

  ///action listeners refresh
  void _addActionRefreshListener(SmallRefreshActionListener listener) {
    lock.synchronized(() {
      actionRefreshListeners.add(listener);
    });
  }

  void _removeActionRefreshListener(SmallRefreshActionListener listener) {
    lock.synchronized(() {
      actionRefreshListeners.add(listener);
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
      actionLoadListeners.add(listener);
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

  void removeHeaderStatusChangeListener(SmallHeaderStatusChangeListener listener) {
    lock.synchronized(() {
      headerStatusListeners.add(listener);
    });
  }

  Future _notifyHeaderStatusChangeListener(SmallRefreshHeaderChangeEvents value) {
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

  void removeFooterStatusChangeListener(SmallFooterStatusChangeListener listener) {
    lock.synchronized(() {
      footerStatusListeners.add(listener);
    });
  }

  Future _notifyFooterStatusChangeListener(SmallRefreshFooterChangeEvents value) {
    return lock.synchronized(() {
      for (int s = 0; s < footerStatusListeners.length; s++) {
        SmallFooterStatusChangeListener listener = footerStatusListeners[s];
        listener(value);
      }
    });
  }

  ///footer hide status listeners
  void _addFooterHideStatusChangeListener(SmallFooterHideStatusChangeListener listener) {
    lock.synchronized(() {
      footerHideStatusListener.add(listener);
    });
  }

  void _removeFooterHideStatusChangeListener(SmallFooterHideStatusChangeListener listener) {
    lock.synchronized(() {
      footerHideStatusListener.add(listener);
    });
  }

  Future _notifyFooterHideStatusChangeListener(SmallRefreshFooterHideEvents value) {
    return lock.synchronized(() {
      for (int s = 0; s < footerHideStatusListener.length; s++) {
        SmallFooterHideStatusChangeListener listener = footerHideStatusListener[s];
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
