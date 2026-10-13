import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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
  Timer? _retry;
  int _attempt = 0;

  /// Asks for the photo, and asks again later if it could not be had (no
  /// connection yet, the token not saved yet), so it appears on its own.
  Future<File?> _fetch() {
    final future = context.read<MediaCache>().fileFor(widget.name);
    unawaited(future.then((file) {
      if (!mounted) return;
      if (file != null) {
        _attempt = 0;
        return;
      }
      _retry?.cancel();
      _retry = Timer(PhotoRetryTiming.delay(_attempt++), () {
        if (mounted) setState(() => _file = _fetch());
      });
    }));
    return future;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _file ??= _fetch();
  }

  @override
  void didUpdateWidget(ServerPhoto old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name) {
      _retry?.cancel();
      _attempt = 0;
      _file = _fetch();
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
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

/// How long a photo waits before asking again after its [attempt]th failure:
/// 3, 6, 12 and 24 seconds, then every 30. Kept apart so it can be tested.
class PhotoRetryTiming {
  PhotoRetryTiming._();

  static Duration delay(int attempt) =>
      Duration(seconds: math.min(30, 3 * (1 << math.min(attempt, 4))));
}
