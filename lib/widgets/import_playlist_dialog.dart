import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../content/labels.dart';
import '../content/words.dart';
import '../models/playlist.dart';
import '../models/playlist_import.dart';
import '../models/youtube_result.dart';
import '../services/server_api.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';

/// What she chose to import: the name for the new playlist and its songs.
class PlaylistImportChoice {
  const PlaylistImportChoice({required this.name, required this.songs});

  final String name;
  final List<YoutubeResult> songs;
}

/// Asks for a YouTube playlist link, has the server read it, and shows the
/// playlist's name (she can change it) and how many songs will come. Answers
/// the choice, or null when she cancels. Nothing is made here: the caller
/// makes the playlist.
Future<PlaylistImportChoice?> showImportPlaylistDialog(BuildContext context) {
  return showDialog<PlaylistImportChoice>(
    context: context,
    builder: (_) => const _ImportDialog(),
  );
}

enum _Step { link, reading, confirm }

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _link = TextEditingController();
  final _name = TextEditingController();

  _Step _step = _Step.link;
  String? _message;
  ImportedPlaylist? _found;

  @override
  void dispose() {
    _link.dispose();
    _name.dispose();
    super.dispose();
  }

  String get _cleanName => Playlist.cleanName(_name.text);

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    setState(() {
      _link.text = text;
      _link.selection = TextSelection.collapsed(offset: text.length);
      _message = null;
    });
  }

  Future<void> _read() async {
    final link = _link.text.trim();
    if (link.isEmpty || _step == _Step.reading) return;
    final api = context.read<ServerApi>();
    setState(() {
      _step = _Step.reading;
      _message = null;
    });

    final result = await api.importPlaylist(link);
    if (!mounted) return; // she cancelled while it was reading

    switch (result) {
      case ServerOk(:final value):
        final playlist = value.playlist;
        if (playlist == null) {
          _backToLink(_problemText(value.problem));
          return;
        }
        setState(() {
          _found = playlist;
          _name.text = Playlist.cleanName(
            playlist.title.isEmpty ? Labels.importDefaultName : playlist.title,
          );
          _step = _Step.confirm;
        });
      case ServerUnauthorized():
        _backToLink(Words.importUnauthorized);
      case ServerUnavailable():
        _backToLink(Words.importUnreachable);
      case ServerUnexpected():
        _backToLink(Words.importFailed);
    }
  }

  void _backToLink(String message) {
    setState(() {
      _step = _Step.link;
      _message = message;
    });
  }

  String _problemText(PlaylistImportProblem? problem) {
    return switch (problem) {
      PlaylistImportProblem.badLink => Words.importBadLink,
      PlaylistImportProblem.mix => Words.importMix,
      PlaylistImportProblem.privateList => Words.importPrivate,
      PlaylistImportProblem.unavailable || null => Words.importUnavailable,
    };
  }

  void _confirm() {
    final found = _found;
    final name = _cleanName;
    if (found == null || name.isEmpty) return;
    Navigator.of(context).pop(
      PlaylistImportChoice(name: name, songs: found.songs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
        side: const BorderSide(color: AppColors.hairline),
      ),
      title: Text(Labels.importFromYoutube, style: AppType.trackTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
        child: switch (_step) {
          _Step.link => _linkContent(),
          _Step.reading => _readingContent(),
          _Step.confirm => _confirmContent(),
        },
      ),
      actions: _actions(),
    );
  }

  Widget _linkContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _link,
          autofocus: true,
          keyboardType: TextInputType.url,
          style: AppType.body,
          cursorColor: AppColors.accent,
          onChanged: (_) => setState(() => _message = null),
          onSubmitted: (_) => _read(),
          decoration: InputDecoration(
            hintText: Labels.importLinkHint,
            hintStyle: AppType.bodyMuted,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.hairline),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _paste,
            child: Text(
              Labels.importPaste,
              style: AppType.body.copyWith(color: AppColors.accent),
            ),
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _message!,
              style: AppType.bodyMuted.copyWith(color: AppColors.danger),
            ),
          ),
      ],
    );
  }

  Widget _readingContent() {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(Words.importReading, style: AppType.bodyMuted)),
      ],
    );
  }

  Widget _confirmContent() {
    final found = _found!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _name,
          maxLength: Playlist.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          style: AppType.body,
          cursorColor: AppColors.accent,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _confirm(),
          decoration: InputDecoration(
            hintText: Labels.playlistNameHint,
            hintStyle: AppType.bodyMuted,
            counterText: '',
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.hairline),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(Words.importCount(found.songs.length), style: AppType.body),
        if (found.skipped > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              Words.importSkipped(found.skipped),
              style: AppType.bodyMuted,
            ),
          ),
        if (found.truncated)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(Words.importTruncated, style: AppType.bodyMuted),
          ),
      ],
    );
  }

  List<Widget> _actions() {
    final cancel = TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        Labels.cancel,
        style: AppType.body.copyWith(color: AppColors.textSecondary),
      ),
    );
    switch (_step) {
      case _Step.reading:
        return [cancel];
      case _Step.link:
        final ready = _link.text.trim().isNotEmpty;
        return [
          cancel,
          TextButton(
            onPressed: ready ? _read : null,
            child: Text(
              Labels.importRead,
              style: AppType.body.copyWith(
                color: ready ? AppColors.accent : AppColors.textFaint,
              ),
            ),
          ),
        ];
      case _Step.confirm:
        final ready = _cleanName.isNotEmpty;
        return [
          cancel,
          TextButton(
            onPressed: ready ? _confirm : null,
            child: Text(
              Words.importSongs(_found!.songs.length),
              style: AppType.body.copyWith(
                color: ready ? AppColors.accent : AppColors.textFaint,
              ),
            ),
          ),
        ];
    }
  }
}
