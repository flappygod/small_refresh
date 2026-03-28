import 'package:flutter/material.dart';
import 'dart:async';

/// 刷新回调
typedef CustomRefreshCallback = Future<void> Function();

/// 自定义刷新指示器的状态
enum SmallStickRefreshIndicatorStatus {
  /// 空闲状态，当前没有显示刷新头
  idle,

  /// 正在拖拽中，但还没达到触发刷新阈值
  drag,

  /// 已达到触发阈值，松手后会触发刷新
  armed,

  /// 正在执行刷新回调
  refresh,

  /// 刷新完成，正在执行收起动画
  done,

  /// 没达到触发阈值，正在执行取消动画
  canceled,
}

/// 一个基于“滚动距离 / overscroll 距离”驱动的自定义刷新指示器。
///
/// 和官方 [RefreshIndicator] 的主要区别：
///
/// 1. 不强依赖 `dragDetails != null`；
/// 2. 更关注顶部 overscroll / 下拉距离本身；
/// 3. 更适合复杂嵌套滚动、drag 转发等场景。
///
/// 典型用法：
///
/// ```dart
/// CustomOverscrollRefreshIndicator(
///   onRefresh: _onRefresh,
///   child: CustomScrollView(
///     physics: const AlwaysScrollableScrollPhysics(
///       parent: BouncingScrollPhysics(),
///     ),
///     slivers: [
///       ...
///     ],
///   ),
/// )
/// ```
class SmallStickRefreshIndicator extends StatefulWidget {
  /// 被包裹的滚动子组件，通常是 ListView / CustomScrollView
  final Widget child;

  /// 触发刷新后的异步回调
  final CustomRefreshCallback onRefresh;

  /// 指示器最终停留显示的位置
  ///
  /// 注意：这不是触发刷新的距离，而是视觉上指示器停留的位置。
  final double displacement;

  /// 指示器距离顶部开始出现的偏移量
  ///
  /// 如果顶部有 AppBar、吸顶区域等，可以通过这个值把刷新头往下挪一点。
  final double edgeOffset;

  /// 触发刷新的距离阈值
  ///
  /// 当顶部下拉 / overscroll 的累计距离达到这个值时，
  /// 状态会从 [SmallStickRefreshIndicatorStatus.drag] 进入
  /// [SmallStickRefreshIndicatorStatus.armed]。
  final double triggerOffset;

  /// 圆形进度条前景色
  final Color? color;

  /// 圆形进度条背景色
  final Color? backgroundColor;

  /// 圆形进度条线宽
  final double strokeWidth;

  /// 用于过滤 ScrollNotification
  ///
  /// 默认使用 [defaultScrollNotificationPredicate]，
  /// 即只处理 depth == 0 的滚动通知。
  final ScrollNotificationPredicate notificationPredicate;

  /// 刷新状态变化回调
  final ValueChanged<SmallStickRefreshIndicatorStatus>? onStatusChange;

  const SmallStickRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.triggerOffset = 80.0,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 2.0,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.onStatusChange,
  });

  @override
  State<SmallStickRefreshIndicator> createState() =>
      _SmallStickRefreshIndicatorState();
}

class _SmallStickRefreshIndicatorState extends State<SmallStickRefreshIndicator>
    with TickerProviderStateMixin {
  /// 控制刷新头整体“展开高度”的动画控制器
  late AnimationController _positionController;

  /// 控制刷新头收起时缩放动画的控制器
  late AnimationController _scaleController;

  /// 刷新头整体展开比例
  late Animation<double> _positionFactor;

  /// 刷新头缩放比例
  late Animation<double> _scaleFactor;

  /// 圆形进度条的进度值（0 ~ 0.75）
  late Animation<double> _progressValue;

  /// 当前刷新状态
  SmallStickRefreshIndicatorStatus _status =
      SmallStickRefreshIndicatorStatus.idle;

  /// 当前累计的拖拽 / overscroll 距离
  ///
  /// 这个值是整个组件的核心驱动数据：
  /// - 小于 triggerOffset：drag
  /// - 大于等于 triggerOffset：armed
  double _dragOffset = 0.0;

  /// 当前指示器是否显示在顶部
  ///
  /// 当前实现主要面向顶部刷新，所以默认 true。
  bool _isIndicatorAtTop = true;

  /// 当前正在进行的刷新 Future
  Future<void>? _pendingRefreshFuture;

  /// 刷新头最大可拉伸倍数
  static const double _kDragSizeFactorLimit = 1.5;

  /// 进入刷新状态前，刷新头吸附到固定位置的动画时长
  static const Duration _kIndicatorSnapDuration = Duration(milliseconds: 150);

  /// 刷新完成 / 取消时，刷新头收起动画时长
  static const Duration _kIndicatorScaleDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();

    /// 控制刷新头展开程度
    _positionController = AnimationController(vsync: this);

    /// 控制刷新头收起缩放
    _scaleController = AnimationController(vsync: this);

    /// 刷新头整体展开比例，最大允许拉到 1.5 倍
    _positionFactor = Tween<double>(
      begin: 0.0,
      end: _kDragSizeFactorLimit,
    ).animate(_positionController);

    /// 收起时从 1 缩放到 0
    _scaleFactor = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_scaleController);

    /// 圆形进度条的 determinate 进度，最大显示到 0.75
    _progressValue = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(_positionController);
  }

  @override
  void dispose() {
    _positionController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// 更新状态，并通知外部监听
  void _setStatus(SmallStickRefreshIndicatorStatus status) {
    if (_status == status) return;
    setState(() {
      _status = status;
    });
    widget.onStatusChange?.call(status);
  }

  /// 是否是垂直滚动
  bool _isVertical(ScrollMetrics metrics) {
    return metrics.axisDirection == AxisDirection.down ||
        metrics.axisDirection == AxisDirection.up;
  }

  /// 当前滚动位置是否在顶部
  ///
  /// 这里通过 `extentBefore == 0.0` 判断，
  /// 表示当前内容前面已经没有可滚动内容了。
  bool _isAtTop(ScrollMetrics metrics) {
    return metrics.extentBefore == 0.0;
  }

  /// 当前通知是否应该由本组件处理
  bool _shouldHandleNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) return false;
    if (!_isVertical(notification.metrics)) return false;
    return true;
  }

  /// 开始一次新的下拉刷新交互
  ///
  /// 会重置拖拽距离、动画值，并进入 drag 状态。
  void _start(ScrollMetrics metrics) {
    _dragOffset = 0.0;
    _isIndicatorAtTop = metrics.axisDirection == AxisDirection.down ||
        metrics.axisDirection == AxisDirection.up;
    _scaleController.value = 0.0;
    _positionController.value = 0.0;
    _setStatus(SmallStickRefreshIndicatorStatus.drag);
  }

  /// 根据当前累计拖拽距离更新刷新头进度
  ///
  /// 当 `_dragOffset >= widget.triggerOffset` 时，
  /// 状态从 drag 进入 armed。
  void _updateDragOffset(double viewportDimension) {
    final double newValue =
        (_dragOffset / widget.triggerOffset).clamp(0.0, 1.0);
    _positionController.value = newValue;

    if (_status == SmallStickRefreshIndicatorStatus.drag &&
        _dragOffset >= widget.triggerOffset) {
      _setStatus(SmallStickRefreshIndicatorStatus.armed);
    }
  }

  /// 显示刷新头并执行刷新回调
  ///
  /// 流程：
  /// 1. 进入 refresh 状态
  /// 2. 刷新头吸附到固定位置
  /// 3. 执行 onRefresh
  /// 4. 刷新完成后执行收起动画
  Future<void> _show() async {
    if (_status == SmallStickRefreshIndicatorStatus.refresh) return;

    _setStatus(SmallStickRefreshIndicatorStatus.refresh);

    await _positionController.animateTo(
      1.0 / _kDragSizeFactorLimit,
      duration: _kIndicatorSnapDuration,
    );

    final completer = Completer<void>();
    _pendingRefreshFuture = completer.future;

    widget.onRefresh().whenComplete(() async {
      completer.complete();
      await _dismiss(SmallStickRefreshIndicatorStatus.done);
    });

    return _pendingRefreshFuture;
  }

  /// 收起刷新头
  ///
  /// [endStatus] 可能是：
  /// - done：刷新完成
  /// - canceled：未达到阈值，取消刷新
  Future<void> _dismiss(SmallStickRefreshIndicatorStatus endStatus) async {
    _setStatus(endStatus);

    /// 刷新完成时，先执行一个缩放收起动画
    if (endStatus == SmallStickRefreshIndicatorStatus.done) {
      await _scaleController.animateTo(
        1.0,
        duration: _kIndicatorScaleDuration,
      );
    }

    /// 再把整体展开高度收回去
    await _positionController.animateTo(
      0.0,
      duration: _kIndicatorScaleDuration,
    );

    if (!mounted) return;

    /// 重置内部状态
    _dragOffset = 0.0;
    _isIndicatorAtTop = true;
    _setStatus(SmallStickRefreshIndicatorStatus.idle);
    _scaleController.value = 0.0;
  }

  /// 处理滚动通知
  ///
  /// 这是整个组件的核心逻辑：
  /// - ScrollStartNotification：开始一次新的拖拽交互
  /// - ScrollUpdateNotification：根据 scrollDelta 累计拖拽距离
  /// - OverscrollNotification：根据 overscroll 累计拖拽距离
  /// - ScrollEndNotification：根据当前状态决定是否触发刷新
  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_shouldHandleNotification(notification)) {
      return false;
    }

    final ScrollMetrics metrics = notification.metrics;

    /// 滚动开始时，如果当前在顶部，则进入 drag 状态
    if (notification is ScrollStartNotification) {
      if (_status == SmallStickRefreshIndicatorStatus.idle &&
          _isAtTop(metrics)) {
        _start(metrics);
      }
      return false;
    }

    /// 普通滚动更新
    if (notification is ScrollUpdateNotification) {
      /// 如果当前还是 idle，但已经在顶部，也允许开始进入 drag
      if (_status == SmallStickRefreshIndicatorStatus.idle &&
          _isAtTop(metrics)) {
        _start(metrics);
      }

      if (_status == SmallStickRefreshIndicatorStatus.drag ||
          _status == SmallStickRefreshIndicatorStatus.armed) {
        final double scrollDelta = notification.scrollDelta ?? 0.0;

        /// 顶部下拉时，scrollDelta 通常为负值，
        /// 这里转成正向累计到 _dragOffset。
        ///
        /// 同时允许在已经进入负 offset（overscroll）时继续累计。
        if (_isAtTop(metrics) || metrics.pixels < metrics.minScrollExtent) {
          _dragOffset -= scrollDelta;
          if (_dragOffset < 0) _dragOffset = 0;
          _updateDragOffset(metrics.viewportDimension);
        }
      }

      return false;
    }

    /// 过量滚动通知
    if (notification is OverscrollNotification) {
      /// 如果当前还是 idle，但已经在顶部，也允许开始进入 drag
      if (_status == SmallStickRefreshIndicatorStatus.idle &&
          _isAtTop(metrics)) {
        _start(metrics);
      }

      if (_status == SmallStickRefreshIndicatorStatus.drag ||
          _status == SmallStickRefreshIndicatorStatus.armed) {
        /// overscroll 在顶部下拉时通常为负值，
        /// 这里同样转成正向累计。
        _dragOffset -= notification.overscroll;
        if (_dragOffset < 0) _dragOffset = 0;
        _updateDragOffset(metrics.viewportDimension);
      }

      return false;
    }

    /// 滚动结束时：
    /// - 如果已经 armed，则触发刷新
    /// - 如果只是 drag，则取消并收起
    if (notification is ScrollEndNotification) {
      if (_status == SmallStickRefreshIndicatorStatus.armed) {
        _show();
      } else if (_status == SmallStickRefreshIndicatorStatus.drag) {
        _dismiss(SmallStickRefreshIndicatorStatus.canceled);
      }
      return false;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    /// 指示器前景色，默认使用主题主色
    final Color indicatorColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    /// refresh / done 阶段显示不确定进度
    final bool showIndeterminate =
        _status == SmallStickRefreshIndicatorStatus.refresh ||
            _status == SmallStickRefreshIndicatorStatus.done;

    return Stack(
      children: [
        /// 监听子滚动组件的滚动通知
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),

        /// 只有非 idle 状态才显示刷新头
        if (_status != SmallStickRefreshIndicatorStatus.idle)
          Positioned(
            top: _isIndicatorAtTop ? widget.edgeOffset : null,
            bottom: !_isIndicatorAtTop ? widget.edgeOffset : null,
            left: 0,
            right: 0,
            child: SizeTransition(
              /// 顶部刷新时从上往下展开
              axisAlignment: _isIndicatorAtTop ? 1.0 : -1.0,
              sizeFactor: _positionFactor,
              child: Padding(
                padding: _isIndicatorAtTop
                    ? EdgeInsets.only(top: widget.displacement)
                    : EdgeInsets.only(bottom: widget.displacement),
                child: Align(
                  alignment: _isIndicatorAtTop
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: ScaleTransition(
                    scale: _scaleFactor,
                    child: Material(
                      color: Colors.transparent,
                      child: RefreshProgressIndicator(
                        /// refresh / done 阶段显示无限转圈
                        /// drag / armed 阶段显示确定进度
                        value: showIndeterminate ? null : _progressValue.value,
                        valueColor: AlwaysStoppedAnimation(indicatorColor),
                        backgroundColor: widget.backgroundColor,
                        strokeWidth: widget.strokeWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
