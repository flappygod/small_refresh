import 'package:small_refresh/src/small_refresh_base.dart';
import 'package:flutter/cupertino.dart';

///controller
class SmallResizeWidgetController extends SmallRefreshBaseNotifier {
  double _height = 0;

  setHeight(double hei) {
    if (_height != hei) {
      _height = hei;
      notifyListeners();
    }
  }

  double get height {
    return _height;
  }

  SmallResizeWidgetController(this._height);
}

///This is just a space view which can control height by the controller
class SmallResizeWidget extends StatefulWidget {
  //controller set height
  final SmallResizeWidgetController controller;

  const SmallResizeWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SmallResizeWidget();
  }
}

class _SmallResizeWidget extends State<SmallResizeWidget> {
  ///refresh listener to setState
  late VoidCallback _listener;

  @override
  void initState() {
    _listener = () {
      if (mounted) {
        setState(() {});
      }
    };
    widget.controller.addListener(_listener);
    super.initState();
  }

  @override
  void didUpdateWidget(SmallResizeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_listener);
      widget.controller.addListener(_listener);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.controller._height,
    );
  }
}
