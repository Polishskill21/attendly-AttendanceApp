import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:flutter/material.dart';

/// Given a list [items] that is already sorted by [nameOf] (ascending or
/// descending — whatever order it's actually rendered in), returns a map
/// from each first-letter bucket ('A'-'Z', or '#' for anything else) to the
/// index of that bucket's first item in [items].
///
/// Because this just scans the list you already have, it stays correct no
/// matter which direction the list is sorted in — no separate logic needed
/// for ascending vs. descending.
Map<String, int> buildLetterIndexMap<T>(
  List<T> items,
  String Function(T item) nameOf,
) { 
  final map = <String, int>{};
  for (var i = 0; i < items.length; i++) {
    final letter = firstLetterBucket(nameOf(items[i]));
    map.putIfAbsent(letter, () => i);
  }
  return map;
}

// Common Latin diacritics folded onto their base letter for bucketing
// purposes, e.g. so "Ünal" sits under "U" instead of getting its own bucket.
// Extend this if your data has other scripts/diacritics you want folded.
const Map<String, String> _diacriticFolds = {
  'Ä': 'A', 'Ö': 'O', 'Ü': 'U', 'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A',
  'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ì': 'I', 'Í': 'I', 'Î': 'I',
  'Ï': 'I', 'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ù': 'U', 'Ú': 'U',
  'Û': 'U', 'Ç': 'C', 'Ñ': 'N', 'Ý': 'Y', 'Ø': 'O', 'Å': 'A', 'ß': 'S',
};

/// Maps a name to the sidebar bucket it should jump to: 'A'-'Z', or '#' for
/// an empty name or one that starts with a digit/symbol.
String firstLetterBucket(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '#';
  var ch = trimmed[0].toUpperCase();
  ch = _diacriticFolds[ch] ?? ch;
  return RegExp(r'^[A-Z]$').hasMatch(ch) ? ch : '#';
}

/// A vertical A-Z strip (like the one in iOS/Android Contacts) that lets the
/// user tap, or drag a finger up and down, to jump straight to a letter.
///
/// Letters with no entries in the current list are shown dimmed. Tapping or
/// dragging over a dimmed letter still jumps — to the nearest letter that
/// *does* have entries — rather than doing nothing.
class AlphabetIndexBar extends StatefulWidget {
  final Set<String> availableLetters;
  final void Function(String letter, {required bool isDragging}) onLetterSelected;
  final List<String> letters;
  final bool isTablet;

  const AlphabetIndexBar({
    super.key,
    required this.availableLetters,
    required this.onLetterSelected,
    this.isTablet = false,
    this.letters = const [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#',
    ],
  });

  @override
  State<AlphabetIndexBar> createState() => _AlphabetIndexBarState();
}

class _AlphabetIndexBarState extends State<AlphabetIndexBar> {
  String? _activeLetter;
  String? _lastNotifiedLetter;
  DateTime _lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Minimum gap between list jumps while dragging. The bubble/label still
  // updates on every letter the finger crosses (cheap - local state only).
  // Only the itemScrollController jump itself is throttled, since firing
  // that on every single letter during a fast swipe is what was flooding
  // the frame pipeline (screen flash) and starving the bubble of a frame
  // to actually paint in.
  static const _dragJumpThrottle = Duration(milliseconds: 70);

  void _handleTouchAt(Offset localPosition, double itemHeight, {required bool isDragging}) {
    if (itemHeight <= 0) return;
    final rawIndex = (localPosition.dy / itemHeight).floor();
    final index = rawIndex.clamp(0, widget.letters.length - 1);
    final letter = widget.letters[index];
    if (letter == _activeLetter) return;
    setState(() => _activeLetter = letter);
    _notify(letter, isDragging: isDragging);
  }

  void _notify(String letter, {required bool isDragging}) {
    final resolved = _nearestAvailable(letter);
    if (resolved == _lastNotifiedLetter) return;
    final now = DateTime.now();
    if (isDragging && now.difference(_lastNotifyTime) < _dragJumpThrottle) {
      return;
    }
    _lastNotifiedLetter = resolved;
    _lastNotifyTime = now;
    widget.onLetterSelected(resolved, isDragging: isDragging);
  }

  void _endTouch() {
    // Always land exactly where the finger left off, even if the last
    // in-drag notification above was throttled away.
    if (_activeLetter != null) {
      _notify(_activeLetter!, isDragging: false);
    }
    setState(() => _activeLetter = null);
    _lastNotifiedLetter = null;
  }

  String _nearestAvailable(String letter) {
    if (widget.availableLetters.isEmpty) return letter;
    if (widget.availableLetters.contains(letter)) return letter;
    final start = widget.letters.indexOf(letter);
    for (var offset = 1; offset < widget.letters.length; offset++) {
      final after = start + offset;
      if (after < widget.letters.length &&
          widget.availableLetters.contains(widget.letters[after])) {
        return widget.letters[after];
      }
      final before = start - offset;
      if (before >= 0 &&
          widget.availableLetters.contains(widget.letters[before])) {
        return widget.letters[before];
      }
    }
    return letter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isTablet = ResponsiveUtils.isTablet(context);

    // Responsive dimensions driven by ResponsiveUtils
    final barWidth = isTablet ? 38.0 : 24.0;
    final normalFontSize = isTablet ? 16.0 : 11.0;
    final activeFontSize = isTablet ? 20.0 : 14.0;
    final bubbleSize = isTablet ? 76.0 : 56.0;
    final bubbleFontSize = isTablet ? 34.0 : 24.0;
    final bubbleRightOffset = isTablet ? 46.0 : 30.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemHeight = constraints.maxHeight / widget.letters.length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragDown: (d) =>
                  _handleTouchAt(d.localPosition, itemHeight, isDragging: true),
              onVerticalDragUpdate: (d) =>
                  _handleTouchAt(d.localPosition, itemHeight, isDragging: true),
              onVerticalDragEnd: (_) => _endTouch(),
              onVerticalDragCancel: () => _endTouch(),
              onTapDown: (d) =>
                  _handleTouchAt(d.localPosition, itemHeight, isDragging: false),
              onTapUp: (_) => _endTouch(),
              child: Container(
                width: barWidth,
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: widget.letters.map((letter) {
                    final isAvailable = widget.availableLetters.contains(letter);
                    final isActive = letter == _activeLetter;
                    return SizedBox(
                      height: itemHeight,
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: isActive ? activeFontSize : normalFontSize,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                            color: isActive
                                ? theme.colorScheme.primary
                                : isAvailable
                                    ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_activeLetter != null)
              Positioned(
                right: bubbleRightOffset,
                top: (widget.letters.indexOf(_activeLetter!) * itemHeight) - (bubbleSize / 2),
                child: IgnorePointer(
                  child: Container(
                    width: bubbleSize,
                    height: bubbleSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _activeLetter!,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: bubbleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}