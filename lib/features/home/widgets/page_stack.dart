import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/utils/note_marks.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/draft.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/paper.dart';
import 'package:baka/providers/draft_provider.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/widgets/motion.dart';
import 'package:baka/widgets/paper_background.dart';

/// A loose sheet of paper on Home: its own paper pattern, a terracotta
/// margin and a slight tilt from [seed].
class PageSheet extends StatelessWidget {
  final Widget child;
  final Paper paper;
  final int seed;
  final bool draft;
  final VoidCallback? onTap;
  const PageSheet({
    super.key,
    required this.child,
    this.paper = Paper.ruled,
    required this.seed,
    this.draft = false,
    this.onTap,
  });

  /// Up to ±0.7°: enough to read as paper, never as crooked.
  static double tilt(int seed) => ((seed % 17) - 8) / 8 * 0.012;

  @override
  Widget build(BuildContext context) {
    final t     = context.tokens;
    final tint  = paperTint(context, paper);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: BorderSide(
          color: draft ? t.primary.withValues(alpha: 0.45) : t.outlineSoft),
    );
    return Transform.rotate(
            angle: tilt(seed),
            child: Material(
              color: tint ?? (draft ? t.background : t.surfaceElev),
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: CustomPaint(
                  painter: PaperPainter(
                    paper: paper,
                    rule: (tint == null
                            ? t.rule
                            : Color.lerp(tint, t.onBackground, 0.16)!)
                        // Only a hint of the paper: the face must read first.
                        .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.55),
                    margin: t.primary.withValues(alpha: 0.4),
                    spacing: 16,
                    topOffset: 4,
                    inset: 0,
                  ),
                  foregroundPainter: _MarginPainter(t.primary.withValues(alpha: 0.3)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(30, 12, 16, 12),
                    child: child,
                  ),
                ),
              ),
            ),
          );
  }
}

class _MarginPainter extends CustomPainter {
  final Color color;
  const _MarginPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
      const Offset(18, 0), Offset(18, size.height), Paint()..color = color..strokeWidth = 1);

  @override
  bool shouldRepaint(_MarginPainter o) => o.color != color;
}

/// The sheet's two lines: what day it is and how it felt, then the page's
/// title, or its first line faded when it has none.
class SheetFace extends StatelessWidget {
  final String date;
  final JournalEntry? entry;
  final String? lead;
  final int pages;
  final Widget? trailing;
  final Color? dateColor;
  const SheetFace({
    super.key,
    required this.date,
    this.entry,
    this.lead,
    this.pages = 1,
    this.trailing,
    this.dateColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final e = entry;
    final title = e?.title;
    final firstLine = lead ?? _firstLine(e?.body ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(date,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption(context)
                      .copyWith(color: dateColor ?? t.onSurfaceMuted, height: 1.2)),
            ),
            if (pages > 1) ...[
              Text('$pages pages',
                  style: AppText.caption(context).copyWith(color: t.primaryText, height: 1.2)),
              const SizedBox(width: 10),
            ],
            if (e?.mood != null) ...[
              MoodGlyph(mood: e!.mood!, size: 16, color: t.primary),
              const SizedBox(width: 4),
              Text(e.mood!.label,
                  style: AppText.caption(context)
                      .copyWith(color: t.onPrimaryContainer, height: 1.2)),
            ],
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 26,
          child: Align(
            alignment: Alignment.centerLeft,
            child: title != null
          ? Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.heading(context)
                  .copyWith(color: t.onBackground, fontSize: 18, height: 1.3))
          : Text(firstLine.isEmpty ? 'An empty page' : firstLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.reading(context).copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                  height: 1.4,
                  color: t.onSurfaceMuted)),
          ),
        ),
      ],
    );
  }

  static String _firstLine(String body) => leadLine(body);
}

/// One day's pages as a stack. A single page opens on tap; several deal
/// out from under the top sheet into a column first, so the right one can be
/// picked.
class DayStack extends HookConsumerWidget {
  final List<JournalEntry> entries; // newest first, all on one day
  const DayStack({super.key, required this.entries});

  static const _gap = 10.0;
  static const _foldH = 36.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = useAnimationController(duration: const Duration(milliseconds: 460));
    final f = useAnimation(CurvedAnimation(parent: c, curve: Motion.curve));
    final topKey = useMemoized(GlobalKey.new);
    final sheetH = useState(76.0);
    useEffect(() {
      // Every face has the same height, so one measure places them all.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final h = topKey.currentContext?.size?.height;
        if (h != null && h != sheetH.value) sheetH.value = h;
      });
      return null;
    }, [MediaQuery.textScalerOf(context)]);

    final top  = entries.first;
    final date = DateFormat('EEE, MMM d').format(top.createdAt);
    final fanned = c.status == AnimationStatus.forward || c.isCompleted;

    Widget sheet(JournalEntry e, {Key? key, int pages = 1, VoidCallback? onTap}) =>
        _Landing(
          id: e.id,
          child: PageSheet(
            key: key,
            seed: e.id.hashCode,
            paper: e.paper,
            onTap: onTap ?? () => context.push('/entry/${e.id}'),
            child: SheetFace(
              date: pages > 1 || entries.length == 1
                  ? date
                  : DateFormat('EEE, MMM d · h:mm a').format(e.createdAt),
              entry: e,
              pages: pages,
            ),
          ),
        );

    if (entries.length == 1) return sheet(top, key: topKey);

    final n = entries.length;
    final h = sheetH.value;
    // Where each sheet rests while stacked: two peek out, the rest hide.
    const peek = [Offset.zero, Offset(5, 7), Offset(-4, 14)];
    const peekTurn = [0.0, 0.04, -0.035];
    final stackedH = h + 7.0 * math.min(n - 1, 2);
    final fannedH  = n * h + (n - 1) * _gap + _foldH;

    return SizedBox(
      height: stackedH + (fannedH - stackedH) * f,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = n - 1; i >= 0; i--)
            Positioned(
              left: 0,
              right: 0,
              top: peek[math.min(i, 2)].dy * (1 - f) + i * (h + _gap) * f,
              child: Transform.translate(
                offset: Offset(peek[math.min(i, 2)].dx * (1 - f), 0),
                child: Transform.rotate(
                  angle: peekTurn[math.min(i, 2)] * (1 - f),
                  child: i == 0 && !fanned
                      ? sheet(top, key: topKey, pages: n, onTap: () {
                          HapticFeedback.selectionClick();
                          if (Motion.reduced(context)) {
                            c.value = 1;
                          } else {
                            c.forward();
                          }
                        })
                      : sheet(entries[i], key: i == 0 ? topKey : null),
                ),
              ),
            ),
          // Gathers the pages back under the top sheet.
          if (f > 0)
            Positioned(
              right: 0,
              bottom: 0,
              height: _foldH,
              child: Opacity(
                opacity: Curves.easeIn.transform(f),
                child: Semantics(
                  button: true,
                  label: 'Fold pages',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: c.isCompleted
                        ? () {
                            HapticFeedback.selectionClick();
                            Motion.reduced(context) ? c.value = 0 : c.reverse();
                          }
                        : null,
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Fold',
                                style: AppText.caption(context)
                                    .copyWith(color: context.tokens.primaryText)),
                            const SizedBox(width: 4),
                            AppIcon(AppIconData.chevronUp,
                                size: 16, color: context.tokens.primaryText),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// An unsaved page: lighter, terracotta-edged, with a way to throw it out.
class DraftSheet extends ConsumerWidget {
  final Draft draft;
  const DraftSheet({super.key, required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final label = draft.isEdit ? 'Unsaved edits' : 'Draft';
    final title = draft.title.trim();
    return PageSheet(
      seed: draft.id.hashCode,
      paper: draft.paper,
      draft: true,
      onTap: () => context.push(
          draft.isEdit ? '/edit/${draft.entryId}' : '/new?draftId=${draft.id}'),
      child: SheetFace(
        date: '$label · ${_relTime(draft.savedAt)}',
        dateColor: t.primaryText,
        lead: title.isNotEmpty ? title : SheetFace._firstLine(draft.body),
        trailing: SizedBox(
          width: 28, height: 20,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 16,
            tooltip: 'Discard draft',
            onPressed: () => ref.read(draftsProvider.notifier).clear(draft.id),
            icon: AppIcon(AppIconData.close, size: 16, color: t.onSurfaceMuted),
          ),
        ),
      ),
    );
  }

  static String _relTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(d);
  }
}

/// Plays once for the page just saved: it drops onto its pile with a small
/// turn, and a terracotta wash fades off it like ink drying.
class _Landing extends HookConsumerWidget {
  final String id;
  final Widget child;
  const _Landing({required this.id, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landing = ref.watch(justSavedProvider) == id;
    final c = useAnimationController(duration: const Duration(milliseconds: 1100));
    useEffect(() {
      if (!landing) return null;
      if (Motion.reduced(context)) {
        ref.read(justSavedProvider.notifier).state = null;
        return null;
      }
      // Wait out the editor's pop so the drop is seen.
      Future.delayed(const Duration(milliseconds: 250), () {
        if (context.mounted) {
          c.forward(from: 0).whenComplete(() {
            if (context.mounted) ref.read(justSavedProvider.notifier).state = null;
          });
        }
      });
      return null;
    }, [landing]);
    if (!landing && !c.isAnimating) return child;

    final t = context.tokens;
    final drop = CurvedAnimation(parent: c, curve: const Interval(0, 0.4, curve: Curves.easeOutCubic));
    final dry  = CurvedAnimation(parent: c, curve: const Interval(0.3, 1, curve: Curves.easeOut));
    return AnimatedBuilder(
      animation: c,
      child: child,
      builder: (context, child) {
        final started = c.value > 0;
        return Opacity(
          opacity: started ? 1 : 0,
          child: Transform.translate(
            offset: Offset(0, -22 * (1 - drop.value)),
            child: Transform.rotate(
              angle: 0.035 * (1 - drop.value),
              child: Stack(
                children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.primary.withValues(alpha: 0.22 * (1 - dry.value)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
