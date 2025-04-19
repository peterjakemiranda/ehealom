import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsAndConditionsDialog extends StatelessWidget {
  final String termsAndConditions;

  const TermsAndConditionsDialog({
    Key? key,
    required this.termsAndConditions,
  }) : super(key: key);

  String _wrapWithHtmlStyling(String content) {
    return '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
              font-size: 14px;
              line-height: 1.6;
              padding: 16px;
              color: #333;
              margin: 0;
            }
            h1, h2, h3, h4, h5, h6 {
              margin-top: 24px;
              margin-bottom: 16px;
              font-weight: 600;
            }
            p {
              margin-bottom: 16px;
            }
            ul, ol {
              margin-bottom: 16px;
              padding-left: 24px;
            }
            li {
              margin-bottom: 10px;
            }
          </style>
        </head>
        <body>
          $content
        </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Stack(
          children: [
            WebView(
              initialUrl: Uri.dataFromString(
                _wrapWithHtmlStyling(termsAndConditions),
                mimeType: 'text/html',
                encoding: Encoding.getByName('utf-8'),
              ).toString(),
              javascriptMode: JavascriptMode.unrestricted,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 