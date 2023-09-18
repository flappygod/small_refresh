import 'package:flutter/cupertino.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((mag) {
      ///size is null
      if (_observeKey.currentContext?.size == null) {
        return;
      }

      ///just not the same
      if (_observeKey.currentContext?.size?.width != _observeSize?.width ||
          _observeKey.currentContext?.size?.height != _observeSize?.height) {
        _observeSize = _observeKey.currentContext?.size;
        widget.listener(_observeKey.currentContext!.size!);
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
