import 'package:small_refresh/src/small_refresh_base.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///this is a widget that clip header view to a suitable height to show
class SmallSizeWidgetController extends SmallRefreshBaseNotifier {
  //base height
  double baseHeight;

  //height inner
  double innerHeight;

  //all show flag
  bool _showFlag = false;

  SmallSizeWidgetController({
    required this.baseHeight,
    required this.innerHeight,
  }) : assert(baseHeight >= 0);

  //scroll height
  double _scrollOffset = 0;

  //set total show flag
  setSmallHeadShow(bool flag) {
    if (_showFlag != flag) {
      _showFlag = flag;
      notifyListeners();
    }
  }

  //set scroll height
  setScrollOffset(double offset) {
    _scrollOffset = offset;
    notifyListeners();
  }

  //get scroll height
  double getScrollOffset() {
    return _scrollOffset;
  }
}

///this is a widget that clip header view to a suitable height to show
class SmallSizeWidget extends StatefulWidget {
  //child
  final Widget child;

  //controller
  final SmallSizeWidgetController controller;

  const SmallSizeWidget({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SmallSizeWidgetState();
  }
}

class _SmallSizeWidgetState extends State<SmallSizeWidget> {
  //listener
  VoidCallback? _listener;

  //outer height
  late double _outerHeight;

  //inner height
  late double _innerHeight;

  //clip height
  late double _clipHeight;

  //outer height
  double _outerHeightF = 0;

  //inner height
  double _innerHeightF = 0;

  //clip height
  double _clipHeightF = 0;

  //state
  _SmallSizeWidgetState();

  @override
  void initState() {
    _listener = () {
      if (mounted && refreshHeight()) {
        setState(() {});
      }
    };
    refreshHeight();
    widget.controller.addListener(_listener!);
    super.initState();
  }

  @override
  void didUpdateWidget(SmallSizeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_listener!);
      widget.controller.addListener(_listener!);
      refreshHeight();
    }
  }

  //refresh height
  bool refreshHeight() {
    //set inner height
    _innerHeight = widget.controller.innerHeight;
    //set outer height
    if (widget.controller._showFlag) {
      _outerHeight = widget.controller.innerHeight;
      _clipHeight = 0;
    } else {
      _outerHeight = widget.controller.baseHeight;
      _clipHeight = widget.controller.innerHeight + widget.controller._scrollOffset;
    }
    if (_clipHeight > widget.controller.innerHeight) {
      _clipHeight = widget.controller.innerHeight;
    }
    if (_clipHeight < widget.controller.baseHeight) {
      _clipHeight = widget.controller.baseHeight;
    }
    if (_outerHeightF != _outerHeight || _innerHeightF != _innerHeight || _clipHeightF != _clipHeight) {
      _outerHeightF = _outerHeight;
      _innerHeightF = _innerHeight;
      _clipHeightF = _clipHeight;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _outerHeight,
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        maxHeight: _innerHeight,
        minHeight: _innerHeight,
        child: ClipPath(
          clipBehavior: Clip.hardEdge,
          clipper: ResizeClipper(
            height: _clipHeight,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

///clip current
class ResizeClipper extends CustomClipper<Path> {
  //height
  double height = 0;

  //height
  ResizeClipper({required this.height});

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, height);
    path.lineTo(size.width, height);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    return path;
  }

  @override
  bool shouldReclip(ResizeClipper oldClipper) {
    return height != oldClipper.height;
  }
}
