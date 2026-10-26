import 'memory.dart';

/// The parts of the right-hand section of Home.
enum PanelBlock { countdown, onThisDay, letters, photoNotes }

/// A note he pinned above everything else in the right-hand section.
class PinnedNote {
  final String text;

  /// The small gold heading, or empty for the default.
  final String label;

  /// The name of an uploaded photo, or null.
  final String? photo;

  const PinnedNote({required this.text, this.label = '', this.photo});
}

/// What he chose for the right-hand section of Home: the pinned note, which
/// parts show, and in what order. Everything is optional, and anything he got
/// wrong is simply left out, so a typo never hides the section.
class PanelSettings {
  final String pinned;
  final String pinnedLabel;
  final String? pinnedPhoto;

  /// The last day the note shows, or null for always.
  final DateTime? pinnedUntil;

  /// His own titles over two of the parts. Empty means the usual words.
  final String lettersTitle;
  final String photoNotesTitle;

  final Set<PanelBlock> hidden;

  /// The parts he put in order. Any he left out come last, in the usual order.
  final List<PanelBlock> order;

  const PanelSettings({
    this.pinned = '',
    this.pinnedLabel = '',
    this.pinnedPhoto,
    this.pinnedUntil,
    this.lettersTitle = '',
    this.photoNotesTitle = '',
    this.hidden = const {},
    this.order = const [],
  });

  static const none = PanelSettings();

  static const _hideKeys = {
    PanelBlock.countdown: 'hideCountdown',
    PanelBlock.onThisDay: 'hideOnThisDay',
    PanelBlock.letters: 'hideLetters',
    PanelBlock.photoNotes: 'hidePhotoNotes',
  };

  factory PanelSettings.parse(Object? json) {
    if (json is! Map) return none;
    final Map<dynamic, dynamic> map = json;

    String text(String key) {
      final value = map[key];
      return value is String ? value.trim() : '';
    }

    final photo = text('pinnedPhoto');
    final until = text('pinnedUntil');
    final names = PanelBlock.values.asNameMap();
    final order = <PanelBlock>[];
    final rawOrder = map['order'];
    if (rawOrder is List) {
      for (final name in rawOrder) {
        final block = name is String ? names[name] : null;
        if (block != null && !order.contains(block)) order.add(block);
      }
    }

    return PanelSettings(
      pinned: text('pinned'),
      pinnedLabel: text('pinnedLabel'),
      pinnedPhoto: Memory.isServerPhoto(photo) ? photo : null,
      pinnedUntil: until.isEmpty ? null : Memory.parseDate(until),
      lettersTitle: text('lettersTitle'),
      photoNotesTitle: text('photoNotesTitle'),
      hidden: {
        for (final entry in _hideKeys.entries)
          if (map[entry.value] == true) entry.key,
      },
      order: List.unmodifiable(order),
    );
  }

  /// The parts to show, top to bottom: his order, then any he did not
  /// mention in the usual order, without the ones he hid.
  List<PanelBlock> get shown {
    final all = [
      ...order,
      for (final block in PanelBlock.values)
        if (!order.contains(block)) block,
    ];
    return [
      for (final block in all)
        if (!hidden.contains(block)) block,
    ];
  }

  /// The pinned note as it should show on [today], or null when there is none
  /// or its last day has passed.
  PinnedNote? pinnedOn(DateTime today) {
    if (pinned.isEmpty) return null;
    final until = pinnedUntil;
    if (until != null &&
        DateTime(today.year, today.month, today.day).isAfter(until)) {
      return null;
    }
    return PinnedNote(text: pinned, label: pinnedLabel, photo: pinnedPhoto);
  }
}
