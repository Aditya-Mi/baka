import 'dart:async';

import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/utils/song_lookup.dart';

/// What the Song dialog hands back. [remove] means clear the song.
typedef SongDialogResult = ({bool remove, String name, String artist, String url});

/// Link first: pasting a song link fills the name and artist, which stay
/// editable. Only empty fields (or ones the last link filled) are written,
/// so nothing typed by hand is ever replaced.
Future<SongDialogResult?> showSongDialog(
  BuildContext context, {
  String? name,
  String? artist,
  String? url,
  required bool canRemove,
}) =>
    showDialog<SongDialogResult>(
      context: context,
      builder: (_) => _SongDialog(
          name: name ?? '', artist: artist ?? '', url: url ?? '', canRemove: canRemove),
    );

enum _Lookup { idle, finding, found, missed }

class _SongDialog extends StatefulWidget {
  final String name, artist, url;
  final bool canRemove;
  const _SongDialog(
      {required this.name, required this.artist, required this.url, required this.canRemove});

  @override
  State<_SongDialog> createState() => _SongDialogState();
}

class _SongDialogState extends State<_SongDialog> {
  late final _url    = TextEditingController(text: widget.url);
  late final _name   = TextEditingController(text: widget.name);
  late final _artist = TextEditingController(text: widget.artist);

  Timer? _debounce;
  var _status = _Lookup.idle;
  // The link last looked up, and what it wrote, so a new link can replace
  // its own fill but never the user's typing.
  late String _lookedUp = widget.url.trim();
  String? _filledName, _filledArtist;

  @override
  void initState() {
    super.initState();
    _url.addListener(_onUrl);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _url.dispose();
    _name.dispose();
    _artist.dispose();
    super.dispose();
  }

  void _onUrl() {
    _debounce?.cancel();
    final link = _url.text.trim();
    if (link == _lookedUp) return;
    if (!SongLookup.looksLikeLink(link)) {
      if (_status != _Lookup.idle) setState(() => _status = _Lookup.idle);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _lookup(link));
  }

  Future<void> _lookup(String link) async {
    _lookedUp = link;
    setState(() => _status = _Lookup.finding);
    final info = await SongLookup.find(link);
    // The link changed while we were away: that lookup owns the result now.
    if (!mounted || _url.text.trim() != link) return;
    if (info == null) {
      setState(() => _status = _Lookup.missed);
      return;
    }
    bool free(TextEditingController c, String? filled) =>
        c.text.trim().isEmpty || c.text == filled;
    if (free(_name, _filledName)) _name.text = _filledName = info.title;
    if (info.artist != null && free(_artist, _filledArtist)) {
      _artist.text = _filledArtist = info.artist!;
    }
    setState(() => _status = _Lookup.found);
  }

  void _save() => Navigator.pop<SongDialogResult>(context, (
        remove: false,
        name: _name.text.trim(),
        artist: _artist.text.trim(),
        url: _url.text.trim(),
      ));

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final note = switch (_status) {
      _Lookup.idle    => null,
      _Lookup.finding => 'Finding the song…',
      _Lookup.found   => 'Filled in from the link',
      _Lookup.missed  => "Couldn't read that link. Type it in below.",
    };

    InputDecoration field(String label, {String? hint}) => InputDecoration(
          labelText: label,
          labelStyle: AppText.label(context),
          hintText: hint,
          hintStyle: AppText.label(context),
        );

    return AlertDialog(
      title: const Text('Song'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _url,
            autofocus: widget.name.isEmpty,
            keyboardType: TextInputType.url,
            decoration: field('Link (Spotify, YouTube, Apple Music…)', hint: 'Paste a link'),
            style: AppText.rowTitle(context),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: note == null
                ? const SizedBox(width: double.infinity, height: 10)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 0, 4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(note,
                          key: ValueKey(note),
                          style: AppText.handSm(context,
                              _status == _Lookup.found ? t.primaryText : t.onSurfaceMuted)),
                    ),
                  ),
          ),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: field('Song name *'),
            style: AppText.rowTitle(context),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _artist,
            textCapitalization: TextCapitalization.words,
            decoration: field('Artist'),
            style: AppText.rowTitle(context),
          ),
        ],
      ),
      actions: [
        if (widget.canRemove)
          TextButton(
            onPressed: () => Navigator.pop<SongDialogResult>(
                context, (remove: true, name: '', artist: '', url: '')),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remove'),
          ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
