import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String content;
  final Object error;
  final StackTrace stackTrace;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.content,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(content),
            const SizedBox(height: 10),
            const Text("Error:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(error.toString()),
            const SizedBox(height: 10),
            const Text("Stack Trace:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(stackTrace.toString()),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
