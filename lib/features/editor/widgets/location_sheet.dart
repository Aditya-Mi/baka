import 'package:flutter/material.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/fonts/font_theme.dart';

/// Bottom sheet for setting a location label.
/// Returns the label string, or null if user dismisses.
Future<String?> showLocationSheet(BuildContext context, {String? initial}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LocationSheet(initial: initial),
  );
}

class _LocationSheet extends StatefulWidget {
  final String? initial;
  const _LocationSheet({this.initial});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: t.surfaceElev,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: t.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Where are you?',
                style: TextStyle(fontFamily: context.fonts.display,
                  fontSize: 20, fontWeight: FontWeight.w600,
                  color: t.onBackground)),
            const SizedBox(height: 4),
            Text('Type a place name or address.',
                style: TextStyle(fontFamily: context.fonts.accent,
                  fontSize: 15, color: t.onSurfaceMuted)),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              cursorColor: t.primary,
              style: TextStyle(fontFamily: context.fonts.body,
                fontSize: 16, color: t.onBackground),
              decoration: InputDecoration(
                hintText: 'e.g. Café Blue, Mumbai',
                hintStyle: TextStyle(fontFamily: context.fonts.body,
                  fontSize: 16, fontStyle: FontStyle.italic,
                  color: t.onSurfaceMuted),
                prefixIcon: Icon(Icons.location_on_outlined,
                    size: 20, color: t.primary),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (widget.initial != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(''),
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error),
                    child: Text('Remove',
                        style: TextStyle(fontFamily: context.fonts.accent, fontSize: 16)),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: TextButton.styleFrom(
                      foregroundColor: t.onSurfaceMuted),
                  child: Text('Cancel',
                      style: TextStyle(fontFamily: context.fonts.accent, fontSize: 16)),
                ),
                const SizedBox(width: 8),
                _SaveBtn(onTap: _submit, t: t),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final v = _ctrl.text.trim();
    Navigator.of(context).pop(v.isEmpty ? null : v);
  }
}

class _SaveBtn extends StatelessWidget {
  final VoidCallback onTap;
  final BakaTokens t;
  const _SaveBtn({required this.onTap, required this.t});

  @override
  Widget build(BuildContext context) => Material(
        color: t.primary,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text('Set',
                style: TextStyle(fontFamily: context.fonts.accent,
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
          ),
        ),
      );
}
