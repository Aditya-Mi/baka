import 'dart:io';

import 'package:flutter/material.dart';
import 'package:baka/widgets/app_icon.dart';
import 'package:path_provider/path_provider.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/anchor.dart';
import 'package:baka/utils/song_preview.dart';
import 'package:baka/widgets/weather_icon.dart';
import 'location_sheet.dart';
import 'photo_sheet.dart';
import 'weather_sheet.dart';

/// The editor's bottom toolbar. Unset anchors are quiet icon buttons; once
/// set they become chips that show their value. [leading] (the tag button)
/// sits first, [trailing] (the word count) stays pinned to the right.
class AnchorBar extends StatelessWidget {
  final Anchor anchor;
  final ValueChanged<Anchor> onChanged;
  final Widget? leading;
  final Widget? trailing;

  const AnchorBar({
    super.key,
    required this.anchor,
    required this.onChanged,
    this.leading,
    this.trailing,
  });

  Future<void> _pickLocation(BuildContext context) async {
    final result = await showLocationSheet(context, initial: anchor.location);
    if (result == null) return;
    onChanged(anchor.copyWith(location: result.isEmpty ? null : result));
  }

  Future<void> _pickWeather(BuildContext context) async {
    final result = await showWeatherSheet(
      context,
      initialCondition: anchor.weatherCondition,
      initialTemp: anchor.weatherTemp,
    );
    if (result == null) return;
    if (result.isRemove) {
      onChanged(anchor.copyWith(weather: null, weatherTemp: null));
    } else {
      onChanged(anchor.copyWith(
        weather: result.condition,
        weatherTemp: result.temp,
      ));
    }
  }

  Future<void> _pickSong(BuildContext context) async {
    final nameCtrl   = TextEditingController(text: anchor.songName ?? '');
    final artistCtrl = TextEditingController(text: anchor.songArtist ?? '');
    final urlCtrl    = TextEditingController(text: anchor.songUrl ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Song'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Song name *',
                labelStyle: AppText.label(context),
                hintStyle: AppText.label(context),
              ),
              style: AppText.rowTitle(context),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: artistCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Artist',
                labelStyle: AppText.label(context),
              ),
              style: AppText.rowTitle(context),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'Spotify / YouTube / Apple Music URL',
                labelStyle: AppText.label(context),
                hintText: 'https://',
                hintStyle: AppText.label(context),
              ),
              style: AppText.rowTitle(context),
            ),
          ],
        ),
        actions: [
          if (anchor.hasSong)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == null) return;
    if (!saved) {
      onChanged(anchor.copyWith(songName: null, songArtist: null, songUrl: null));
      return;
    }
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final url = urlCtrl.text.trim();
    onChanged(anchor.copyWith(
      songName:   name,
      songArtist: artistCtrl.text.trim().isEmpty ? null : artistCtrl.text.trim(),
      songUrl:    url.isEmpty ? null : normalizeSongUrl(url),
    ));
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final result = await showPhotoSheet(context, existingPath: anchor.photoPath);
    if (result == null) return;
    onChanged(anchor.copyWith(photoPath: result.isEmpty ? null : result));
  }

  Widget _valueChip(BuildContext context, BakaTokens t,
      {required Widget icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _Chip(
        active: true,
        t: t,
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          icon,
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.meta(context).copyWith(color: t.onPrimaryContainer)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (leading != null) leading!,

                  if (anchor.hasLocation)
                    _valueChip(context, t,
                        icon: AppIcon(AppIconData.mapPin, size: 16, color: t.primary),
                        label: anchor.location!,
                        onTap: () => _pickLocation(context))
                  else
                    ToolButton(
                        icon: AppIconData.mapPin,
                        tooltip: 'Location',
                        onTap: () => _pickLocation(context)),

                  if (anchor.hasWeather)
                    _valueChip(context, t,
                        icon: WeatherIcon(anchor.weatherCondition!,
                            size: 16, color: t.primary),
                        label: anchor.weatherTemp != null
                            ? '${anchor.weatherCondition!.label} · ${anchor.weatherTemp}°C'
                            : anchor.weatherCondition!.label,
                        onTap: () => _pickWeather(context))
                  else
                    ToolButton(
                        icon: AppIconData.cloud,
                        tooltip: 'Weather',
                        onTap: () => _pickWeather(context)),

                  if (anchor.hasSong)
                    _valueChip(context, t,
                        icon: AppIcon(AppIconData.music, size: 16, color: t.primary),
                        label: anchor.songArtist != null
                            ? '${anchor.songName!} · ${anchor.songArtist!}'
                            : anchor.songName!,
                        onTap: () => _pickSong(context))
                  else
                    ToolButton(
                        icon: AppIconData.music,
                        tooltip: 'Song',
                        onTap: () => _pickSong(context)),

                  if (anchor.hasPhoto)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _PhotoChip(
                          anchor: anchor, t: t, onTap: () => _pickPhoto(context)),
                    )
                  else
                    ToolButton(
                        icon: AppIconData.image,
                        tooltip: 'Photo',
                        onTap: () => _pickPhoto(context)),
                ],
              ),
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 20),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

/// 44×44 icon-only toolbar button with a tooltip (also its TalkBack label).
class ToolButton extends StatelessWidget {
  final AppIconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  const ToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 22,
          child: SizedBox(
            width: 44, height: 44,
            child: Center(
              child: AppIcon(icon,
                  size: 20, color: color ?? context.tokens.onSurfaceMuted),
            ),
          ),
        ),
      );
}

// ── Generic chip ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final Widget child;
  final bool active;
  final BakaTokens t;
  final VoidCallback onTap;
  const _Chip({required this.child, required this.active,
      required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: active,
    child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active
                  ? t.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active ? t.primary.withValues(alpha: 0.35) : t.outline,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
  );
}

// ── Photo chip — shows thumbnail when set ─────────────────────────────────────

class _PhotoChip extends StatelessWidget {
  final Anchor anchor;
  final BakaTokens t;
  final VoidCallback onTap;
  const _PhotoChip({required this.anchor, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!anchor.hasPhoto) {
      return _Chip(
        onTap: onTap,
        active: false,
        t: t,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AppIcon(AppIconData.image, size: 16, color: t.onSurfaceMuted),
          const SizedBox(width: 5),
          Text('Photo', style: AppText.meta(context).copyWith(
              color: t.onSurface,
            )),
        ]),
      );
    }

    return FutureBuilder<String>(
      future: _resolve(anchor.photoPath!),
      builder: (_, snap) {
        final hasFile = snap.hasData && File(snap.data!).existsSync();
        return Semantics(
          button: true,
          label: 'Photo',
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 36,
              padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
              decoration: BoxDecoration(
                color: t.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: t.primary.withValues(alpha: 0.35), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (hasFile)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(File(snap.data!),
                        width: 24, height: 24, fit: BoxFit.cover,
                        cacheWidth: (24 * MediaQuery.devicePixelRatioOf(context)).round()),
                  )
                else
                  AppIcon(AppIconData.image, size: 16, color: t.primary),
                const SizedBox(width: 5),
                Text('Photo', style: AppText.meta(context).copyWith(
                    color: t.onPrimaryContainer,
                  )),
              ]),
            ),
          ),
        );
      },
    );
  }

  Future<String> _resolve(String rel) async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$rel';
  }
}
