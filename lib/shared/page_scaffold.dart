import 'package:flutter/material.dart';
import 'package:snapfood/shared/on_device_badge.dart';

/// Standard page wrapper: AppBar with OnDeviceMiniConsumer, SafeArea,
/// SingleChildScrollView.
class PageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? extraActions;

  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?extraActions,
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnDeviceMiniConsumer(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: child,
        ),
      ),
    );
  }
}
