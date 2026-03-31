import 'package:flutter/material.dart';

/// A scaffold wrapper that provides consistent [AppBar] styling across screens.
class AppScaffold extends StatelessWidget {
  /// Creates an [AppScaffold].
  const AppScaffold({
    required this.title,
    required this.body,
    super.key,
    this.actions,
    this.floatingActionButton,
  });

  /// The title displayed in the [AppBar].
  final String title;

  /// The primary content of the scaffold.
  final Widget body;

  /// Optional action widgets placed in the [AppBar].
  final List<Widget>? actions;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
