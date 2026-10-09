import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shows the design's top toast: a navy pill with an orange icon tile.
/// A new toast replaces the current one.
void showAppToast(
  BuildContext context,
  String message, {
  IconData icon = Symbols.check_rounded,
  Duration duration = const Duration(milliseconds: 2200),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _removeCurrent();
  final entry = OverlayEntry(
    builder: (context) =>
        _Toast(message: message, icon: icon, duration: duration),
  );
  _current = entry;
  overlay.insert(entry);
}

OverlayEntry? _current;

void _removeCurrent([OverlayEntry? only]) {
  final entry = _current;
  if (entry == null || (only != null && entry != only)) return;
  if (entry.mounted) entry.remove();
  _current = null;
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.icon,
    required this.duration,
  });

  final String message;
  final IconData icon;
  final Duration duration;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  Timer? _timer;
  // Captured on first build: by the time the timer fires, `_current` may
  // already be a newer toast that must not be removed.
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _entry = _current;
    _controller.forward();
    _timer = Timer(widget.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) _removeCurrent(_entry);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.2, 0.9, 0.2, 1),
    );
    return Positioned(
      left: 20,
      right: 20,
      top: MediaQuery.paddingOf(context).top + 8,
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.4),
            end: Offset.zero,
          ).animate(curve),
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(18),
              elevation: 12,
              shadowColor: const Color(0xCC0D1B2A),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(widget.icon, size: 17, color: AppColors.ink),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: AppTypography.body(
                          14,
                          color: AppColors.onInk,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
