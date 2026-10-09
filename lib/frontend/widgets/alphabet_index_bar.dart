import 'dart:async';
import 'dart:math' as math;

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

  // The finger currently driving the bar. Extra fingers are ignored.
  int? _activePointer;

  // Delivers the last letter of a drag once the throttle window is over,
  // so the list still follows when the finger stops on a throttled letter.
  Timer? _trailingJump;

  // Minimum gap between list jumps while dragging. The bubble/label still
  // updates on every letter the finger crosses (cheap - local state only).
  // Only the list jump itself is throttled, since firing that on every
  // single letter during a fast swipe floods the frame pipeline.
  static const _dragJumpThrottle = Duration(milliseconds: 70);

  // How long the letter bubble stays visible after the finger lifts, so
  // a quick tap is still readable.
  static const _bubbleLinger = Duration(milliseconds: 200);
  Timer? _hideBubble;

  @override
  void dispose() {
    _trailingJump?.cancel();
    _hideBubble?.cancel();
    super.dispose();
  }

  void _handleTouchAt(Offset localPosition, double itemHeight) {
    if (itemHeight <= 0) return;
    final rawIndex = (localPosition.dy / itemHeight).floor();
    final index = rawIndex.clamp(0, widget.letters.length - 1);
    final letter = widget.letters[index];
    if (letter == _activeLetter) return;
    setState(() => _activeLetter = letter);
    _notify(letter, isDragging: true);
  }

  void _notify(String letter, {required bool isDragging}) {
    final resolved = _nearestAvailable(letter);
    if (resolved == _lastNotifiedLetter) return;
    final now = DateTime.now();
    final sinceLast = now.difference(_lastNotifyTime);
    if (isDragging && sinceLast < _dragJumpThrottle) {
      _trailingJump?.cancel();
      _trailingJump = Timer(_dragJumpThrottle - sinceLast, () {
        if (mounted && _activeLetter != null) {
          _notify(_activeLetter!, isDragging: false);
        }
      });
      return;
    }
    _trailingJump?.cancel();
    _lastNotifiedLetter = resolved;
    _lastNotifyTime = now;
    widget.onLetterSelected(resolved, isDragging: isDragging);
  }

  void _endTouch() {
    _activePointer = null;
    _trailingJump?.cancel();
    // Always land exactly where the finger left off, even if the last
    // in-drag notification above was throttled away.
    if (_activeLetter != null) {
      _notify(_activeLetter!, isDragging: false);
    }
    _lastNotifiedLetter = null;
    _hideBubble?.cancel();
    _hideBubble = Timer(_bubbleLinger, () {
      if (mounted) setState(() => _activeLetter = null);
    });
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
            // Raw pointer events instead of a GestureDetector: a tap and a
            // drag recognizer on the same widget both fired for a quick tap
            // (drag down -> drag cancel -> tap down -> tap up), which hid the
            // bubble again in the same frame and jumped the list twice.
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (_activePointer != null) return;
                _activePointer = e.pointer;
                // A new touch replaces a bubble that is still lingering,
                // even when it lands on the same letter again.
                _hideBubble?.cancel();
                _activeLetter = null;
                _handleTouchAt(e.localPosition, itemHeight);
              },
              onPointerMove: (e) {
                if (e.pointer == _activePointer) {
                  _handleTouchAt(e.localPosition, itemHeight);
                }
              },
              onPointerUp: (e) {
                if (e.pointer == _activePointer) _endTouch();
              },
              onPointerCancel: (e) {
                if (e.pointer == _activePointer) _endTouch();
              },
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
                // Centred on the letter, but kept inside the bar so the
                // bubble for 'A' or '#' is not clipped by the page.
                top: ((widget.letters.indexOf(_activeLetter!) + 0.5) * itemHeight - bubbleSize / 2)
                    .clamp(0.0, math.max(0.0, constraints.maxHeight - bubbleSize)),
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