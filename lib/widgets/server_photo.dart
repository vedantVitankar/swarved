import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/media_cache.dart';

/// A photo he uploaded to the server. It shows [placeholder] until the photo
/// is on this phone (and for good if it cannot be had), then the photo.
class ServerPhoto extends StatefulWidget {
  final String name;
  final Widget placeholder;

  /// Photos are big; decode them near the size they show.
  final int? cacheWidth;

  const ServerPhoto({
    super.key,
    required this.name,
    required this.placeholder,
    this.cacheWidth,
  });

  @override
  State<ServerPhoto> createState() => _ServerPhotoState();
}

class _ServerPhotoState extends State<ServerPhoto> {
  Future<File?>? _file;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _file ??= context.read<MediaCache>().fileFor(widget.name);
  }

  @override
  void didUpdateWidget(ServerPhoto old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name) {
      _file = context.read<MediaCache>().fileFor(widget.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) return widget.placeholder;
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: widget.cacheWidth,
          errorBuilder: (_, __, ___) => widget.placeholder,
        );
      },
    );
  }
}
