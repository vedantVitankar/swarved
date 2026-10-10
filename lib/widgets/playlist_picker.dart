import 'package:flutter/material.dart';
import '../content/labels.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../services/playlist_service.dart';
import '../theme/colors.dart';
import '../theme/responsive.dart';
import '../theme/shape.dart';
import '../theme/swar_glyphs.dart';
import '../theme/typography.dart';
import '../utils/membership_draft.dart';
import '../content/words.dart';
import 'swar_icon.dart';
import 'compact_icon_button.dart';
import 'swar_outlined_button.dart';
import 'track_artwork.dart';

/// Opens the playlist popup for [track]: a bottom sheet on phones and
/// tablets, a dialog on wide windows. Nothing is saved until she presses
/// Done. Closing it any other way leaves her playlists as they were.
Future<void> showPlaylistPicker(
  BuildContext context,
  Track track,
  PlaylistService service,
) {
  final wide =
      Responsive.of(MediaQuery.sizeOf(context).width) == ScreenClass.expanded;
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppShape.card)),
    side: BorderSide(color: AppColors.hairline),
  );

  if (wide) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.card),
          side: const BorderSide(color: AppColors.hairline),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
          child: PlaylistPicker(track: track, service: service),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: shape,
    constraints: const BoxConstraints(maxWidth: Responsive.contentMaxWidth),
    builder: (_) => PlaylistPicker(track: track, service: service),
  );
}

/// The inside of the popup: the song, a New playlist row, Liked songs, then
/// her playlists, each with a tick. A tap only changes the draft.
class PlaylistPicker extends StatefulWidget {
  final Track track;
  final PlaylistService service;

  const PlaylistPicker({super.key, required this.track, required this.service});

  @override
  State<PlaylistPicker> createState() => _PlaylistPickerState();
}

class _PlaylistPickerState extends State<PlaylistPicker> {
  late final MembershipDraft _draft =
      MembershipDraft(widget.service.playlistIdsWith(widget.track));
  final TextEditingController _name = TextEditingController();
  bool _naming = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submitName(String raw) {
    if (!_draft.addNew(raw)) return;
    _name.clear();
    setState(() => _naming = false);
  }

  void _cancelNaming() {
    _name.clear();
    setState(() => _naming = false);
  }

  void _done() {
    final changed = _draft.hasChanges;
    final messenger = ScaffoldMessenger.of(context);
    if (changed) {
      widget.service.applyMembership(
        widget.track,
        playlistIds: _draft.playlistIds,
        newNames: _draft.newNames,
      );
    }
    Navigator.of(context).pop();
    if (changed) {
      messenger.showSnackBar(
        const SnackBar(content: Text(Words.playlistsSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editable = [
      for (final playlist in widget.service.playlists)
        if (playlist.isEditable) playlist,
    ];
    final liked = editable.where((p) => p.isLiked).toList();
    final others = editable.where((p) => !p.isLiked).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(Labels.addToPlaylist, style: AppType.trackTitle),
          ),
          _SongHeader(track: widget.track),
          const Divider(height: 1, color: AppColors.hairline),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _naming ? _nameField() : _newPlaylistRow(),
                for (final playlist in liked) _existingRow(playlist),
                for (final staged in _draft.staged)
                  _PickerRow(
                    leading: const _CoverBox(glyph: SwarGlyph.disc),
                    title: staged.name,
                    subtitle: Labels.newBadge,
                    selected: staged.chosen,
                    onTap: () => setState(() => _draft.toggleStaged(staged)),
                  ),
                for (final playlist in others) _existingRow(playlist),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.hairline),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(Labels.cancel, style: AppType.bodyMuted),
                ),
                const SizedBox(width: 8),
                SwarOutlinedButton(label: Labels.done, onPressed: _done),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _existingRow(Playlist playlist) {
    return _PickerRow(
      leading: _CoverBox(
        glyph: playlist.isLiked ? SwarGlyph.heartFilled : SwarGlyph.disc,
        accent: playlist.isLiked,
      ),
      title: playlist.name,
      subtitle: Labels.songCount(playlist.items.length),
      selected: _draft.isChosen(playlist.id),
      onTap: () => setState(() => _draft.toggle(playlist.id)),
    );
  }

  Widget _newPlaylistRow() {
    return InkWell(
      onTap: () => setState(() => _naming = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            const _CoverBox(glyph: SwarGlyph.add, outlined: true),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                Labels.newPlaylist,
                style: AppType.body.copyWith(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _name,
              autofocus: true,
              style: AppType.body,
              cursorColor: AppColors.accent,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _submitName,
              decoration: InputDecoration(
                hintText: Labels.playlistNameHint,
                hintStyle: AppType.bodyMuted,
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ),
          CompactIconButton(
            icon: SwarGlyph.check,
            tooltip: Labels.createPlaylist,
            color: AppColors.accent,
            onPressed: () => _submitName(_name.text),
          ),
          CompactIconButton(
            icon: SwarGlyph.close,
            tooltip: Labels.cancel,
            color: AppColors.textSecondary,
            onPressed: _cancelNaming,
          ),
        ],
      ),
    );
  }
}

/// The song being added, so she can see which one the popup is about.
class _SongHeader extends StatelessWidget {
  final Track track;

  const _SongHeader({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          TrackArtwork(
            bytes: track.artworkBytes,
            url: track.artworkUrl,
            size: 44,
            radius: AppShape.thumbnail,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.title,
                    style: AppType.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(track.artist,
                    style: AppType.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small square standing in for a playlist's cover until playlists get
/// real covers.
class _CoverBox extends StatelessWidget {
  final SwarGlyph glyph;
  final bool accent;
  final bool outlined;

  const _CoverBox({
    required this.glyph,
    this.accent = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: outlined
            ? Colors.transparent
            : (accent ? AppColors.maroon : AppColors.surfaceRaised),
        border: outlined ? Border.all(color: AppColors.accent) : null,
        borderRadius: BorderRadius.circular(AppShape.thumbnail),
      ),
      child: Center(
        child: SwarIcon(
          glyph: glyph,
          size: 22,
          color: accent || outlined ? AppColors.accent : AppColors.textFaint,
        ),
      ),
    );
  }
}

/// One playlist in the popup: cover, name, count, and a tick that is filled
/// when the song is in it and empty when it is not.
class _PickerRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PickerRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppType.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: AppType.caption),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Tick(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  final bool selected;

  const _Tick({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.accent : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.textFaint,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Center(
              child: SwarIcon(
                glyph: SwarGlyph.check,
                size: 16,
                color: AppColors.onAccent,
              ),
            )
          : null,
    );
  }
}
