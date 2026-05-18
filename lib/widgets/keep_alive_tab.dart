import 'package:flutter/material.dart';

/// Keeps off-screen bottom-nav pages alive to avoid reloads on tab switch.
class KeepAliveTab extends StatefulWidget {
  const KeepAliveTab({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
