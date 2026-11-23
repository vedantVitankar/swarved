import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/media_cache.dart';

/// Whether every one of [names] (null ones are ignored) is on this phone
/// already. A screen that uses this shows its photo or letter only once
/// the content has arrived AND its files have been downloaded, and it
/// redraws by itself when the last file lands.
///
/// Where there is no [MediaCache] above (a test, say) nothing is held back.
bool mediaReady(BuildContext context, Iterable<String?> names) {
  final MediaCache cache;
  try {
    cache = Provider.of<MediaCache>(context);
  } on ProviderNotFoundException {
    return true;
  }
  return names.whereType<String>().every(cache.isReady);
}
