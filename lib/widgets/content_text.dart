import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/content_service.dart';

/// Words he can replace from the admin site: his words for [textKey] when he
/// has written some, otherwise [fallback]. It updates the moment he
/// publishes, with the app open.
class ContentText extends StatelessWidget {
  final String textKey;
  final String fallback;
  final TextStyle? style;
  final TextAlign? textAlign;

  const ContentText({
    super.key,
    required this.textKey,
    required this.fallback,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final words = context.select<ContentService, String>(
      (content) => content.textFor(textKey, fallback),
    );
    return Text(words, style: style, textAlign: textAlign);
  }
}
