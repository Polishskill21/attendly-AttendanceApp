import 'package:flutter/material.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

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
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTablet ? 22 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
      ),
      contentPadding: EdgeInsets.all(isTablet ? 24 : 16),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                content,
                style: TextStyle(fontSize: isTablet ? 18 : 16),
              ),
              SizedBox(height: isTablet ? 16 : 10),
              Text(
                "Error:", 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
              Text(
                error.toString(),
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              SizedBox(height: isTablet ? 16 : 10),
              Text(
                "Stack Trace:", 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
              SelectableText(
                stackTrace.toString(),
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'Close',
            style: TextStyle(fontSize: isTablet ? 18 : 14),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
