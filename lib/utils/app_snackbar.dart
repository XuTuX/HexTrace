import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

OverlayEntry? _currentOverlay;

void showAppSnackBar({
  required String message,
  String? title,
  Color backgroundColor = const Color(0xFFFFFBEB),
  Color textColor = const Color(0xFF1A1A1A),
  Color borderColor = const Color(0xFF1A1A1A),
  IconData icon = Icons.info_outline_rounded,
  Duration duration = const Duration(seconds: 3),
}) {
  // Dismiss any existing overlay first
  _currentOverlay?.remove();
  _currentOverlay = null;

  final navigatorState = _findNavigatorOverlay();
  if (navigatorState == null) {
    debugPrint('SnackBar skipped because Overlay is not available.');
    return;
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopSnackBarWidget(
      message: message,
      title: title,
      backgroundColor: backgroundColor,
      textColor: textColor,
      borderColor: borderColor,
      icon: icon,
      duration: duration,
      onDismiss: () {
        entry.remove();
        if (_currentOverlay == entry) {
          _currentOverlay = null;
        }
      },
    ),
  );

  _currentOverlay = entry;
  navigatorState.insert(entry);
}

OverlayState? _findNavigatorOverlay() {
  try {
    final context = appScaffoldMessengerKey.currentContext;
    if (context != null) {
      final overlay = Overlay.of(context, rootOverlay: true);
      return overlay;
    }
  } catch (_) {}

  // Fallback: try finding via NavigatorState
  try {
    final navKey = WidgetsBinding.instance.rootElement;
    if (navKey != null) {
      NavigatorState? navigator;
      navKey.visitChildElements((element) {
        element.visitChildElements((child) {
          if (child is StatefulElement && child.state is NavigatorState) {
            navigator = child.state as NavigatorState;
          }
        });
      });
      return navigator?.overlay;
    }
  } catch (_) {}

  return null;
}

void clearAppSnackBars() {
  _currentOverlay?.remove();
  _currentOverlay = null;
  appScaffoldMessengerKey.currentState?.clearSnackBars();
}

class _TopSnackBarWidget extends StatefulWidget {
  const _TopSnackBarWidget({
    required this.message,
    this.title,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final String? title;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_TopSnackBarWidget> createState() => _TopSnackBarWidgetState();
}

class _TopSnackBarWidgetState extends State<_TopSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _animController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -100) {
                _dismiss();
              }
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.borderColor,
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(widget.icon,
                        size: 20,
                        color: widget.textColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null &&
                              widget.title!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                widget.title!,
                                style: GoogleFonts.blackHanSans(
                                  fontSize: 14,
                                  color: widget.textColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.textColor.withValues(alpha: 0.75),
                              height: 1.3,
                            ),
                          ),
                        ],
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
