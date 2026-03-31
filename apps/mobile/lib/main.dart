import 'package:flutter/material.dart';

/// Entry point for the While You're Out app.
void main() {
  runApp(const App());
}

/// Root application widget.
class App extends StatelessWidget {
  /// Creates the root [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "While You're Out",
      home: Scaffold(
        body: Center(
          child: Text("While You're Out"),
        ),
      ),
    );
  }
}
