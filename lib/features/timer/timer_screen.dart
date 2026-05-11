import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────
  int _totalSeconds = 120;
  int _remainingSeconds = 120;
  bool _running = false;
  Timer? _countdownTimer;
  StreamSubscription? _accelerometerSub;

  // ── Animations ────────────────────────────────────────
  late AnimationController _sandController;
  late AnimationController _shakeController;
  late AnimationController _grainController;
  late Animation<double> _shakeAnim;

  // Rotation detection
  double _lastZ = 0;
  DateTime _lastRotation = DateTime.now();

  // Preset options
  static const presets = [
    (label: '30s', seconds: 30),
    (label: '1m', seconds: 60),
    (label: '2m', seconds: 120),
    (label: '5m', seconds: 300),
    (label: '10m', seconds: 600),
    (label: '15m', seconds: 900),
  ];

  @override
  void initState() {
    super.initState();

    // Keep screen on
    // WakelockPlus.enable(); // uncomment when wakelock_plus added

    // Sand animation controller
    _sandController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );

    // Shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    // Grain falling animation
    _grainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _startAccelerometer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _accelerometerSub?.cancel();
    _sandController.dispose();
    _shakeController.dispose();
    _grainController.dispose();
    // WakelockPlus.disable();
    super.dispose();
  }

  // ── Accelerometer — detect rotation ──────────────────

  void _startAccelerometer() {
    _accelerometerSub = accelerometerEventStream().listen((event) {
      final z = event.z;
      final now = DateTime.now();

      // Detect significant rotation (phone flipped)
      if (now.difference(_lastRotation).inMilliseconds > 800) {
        final delta = (z - _lastZ).abs();
        if (delta > 12) {
          _lastRotation = now;
          _onRotation();
        }
      }
      _lastZ = z;
    });
  }

  void _onRotation() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    _resetTimer();
  }

  // ── Timer controls ────────────────────────────────────

  void _startTimer() {
    if (_remainingSeconds == 0) return;
    setState(() => _running = true);

    _sandController.duration = Duration(seconds: _totalSeconds);
    final progress = 1.0 - (_remainingSeconds / _totalSeconds);
    _sandController.forward(from: progress);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _running = false;
          _countdownTimer?.cancel();
          _sandController.stop();
          _onTimerEnd();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() => _running = false);
    _countdownTimer?.cancel();
    _sandController.stop();
  }

  void _resetTimer() {
    _countdownTimer?.cancel();
    _sandController.stop();
    setState(() {
      _running = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _setPreset(int seconds) {
    if (_running) return;
    _countdownTimer?.cancel();
    _sandController.stop();
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
    });
  }

  void _onTimerEnd() {
    HapticFeedback.vibrate();
    // Play alarm sound here when audioplayers is set up
    _showDoneOverlay();
  }

  void _showDoneOverlay() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFFD600), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏰', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text(
                'Time\'s up!',
                style: TextStyle(
                  color: Color(0xFFFFD600),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _setPreset(_totalSeconds);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD600),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Again',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) {
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return '0:${s.toString().padLeft(2, '0')}';
  }

  double get _sandProgress => 1.0 - (_remainingSeconds / _totalSeconds);

  bool get _isUrgent => _remainingSeconds <= 10 && _running;

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [Color(0xFF1A1A2E), Color(0xFF0F0E17)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ───────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white54,
                        ),
                        onPressed: () => context.go('/'),
                      ),
                      const Expanded(
                        child: Text(
                          'PARTY TIMER',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFFD600),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Time display ──────────────────
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: _isUrgent ? const Color(0xFFEF5350) : Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.w200,
                    fontFamily: 'monospace',
                    letterSpacing: 4,
                  ),
                  child: Text(_formatTime(_remainingSeconds)),
                ),

                const SizedBox(height: 8),

                // Status text
                Text(
                  _remainingSeconds == 0
                      ? 'Time\'s up!'
                      : _running
                      ? 'Running...'
                      : _remainingSeconds < _totalSeconds
                      ? 'Paused'
                      : 'Ready',
                  style: TextStyle(
                    color: _remainingSeconds == 0
                        ? const Color(0xFFEF5350)
                        : Colors.white38,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(),

                // ── Hourglass ─────────────────────
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    final shake =
                        sin(_shakeAnim.value * pi * 6) *
                        8 *
                        (1 - _shakeAnim.value);
                    return Transform.translate(
                      offset: Offset(shake, 0),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 160,
                    height: 280,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_grainController]),
                      builder: (context, _) {
                        return CustomPaint(
                          painter: HourglassPainter(
                            progress: _sandProgress,
                            isRunning: _running,
                            grainOffset: _grainController.value,
                            isUrgent: _isUrgent,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const Spacer(),

                // ── Presets ───────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: presets.map((p) {
                      final isActive = p.seconds == _totalSeconds && !_running;
                      return GestureDetector(
                        onTap: () => _setPreset(p.seconds),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFFFD600).withOpacity(0.2)
                                : Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFFFFD600)
                                  : Colors.white24,
                              width: isActive ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            p.label,
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFFFFD600)
                                  : Colors.white60,
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Controls ──────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play/Pause
                    GestureDetector(
                      onTap: _remainingSeconds == 0
                          ? null
                          : _running
                          ? _pauseTimer
                          : _startTimer,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _remainingSeconds == 0
                              ? Colors.white12
                              : const Color(0xFFFFD600),
                          shape: BoxShape.circle,
                          boxShadow: _running
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFD600,
                                    ).withOpacity(0.4),
                                    blurRadius: 20,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          _running
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: _remainingSeconds == 0
                              ? Colors.white30
                              : Colors.black,
                          size: 36,
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Reset
                    GestureDetector(
                      onTap: _resetTimer,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white60,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Rotate hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.screen_rotation,
                      color: Colors.white24,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Rotate phone to reset',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hourglass Painter ──────────────────────────────────
class HourglassPainter extends CustomPainter {
  final double progress; // 0.0 = full, 1.0 = empty
  final bool isRunning;
  final double grainOffset;
  final bool isUrgent;

  HourglassPainter({
    required this.progress,
    required this.isRunning,
    required this.grainOffset,
    required this.isUrgent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Dimensions
    const topY = 8.0;
    const botY_end = 272.0;
    const neckTop = 130.0;
    const neckBot = 150.0;
    const sideX = 12.0;

    final sandColor = isUrgent
        ? const Color(0xFFEF5350)
        : const Color(0xFFFFD600);

    final glassPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final sandPaint = Paint()
      ..color = sandColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = sandColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // ── Draw glass outline ────────────────────────────
    // Top triangle
    final topPath = Path()
      ..moveTo(sideX, topY)
      ..lineTo(w - sideX, topY)
      ..lineTo(cx + 10, neckTop)
      ..lineTo(cx - 10, neckTop)
      ..close();
    canvas.drawPath(topPath, glassPaint);

    // Bottom triangle
    final botPath = Path()
      ..moveTo(cx - 10, neckBot)
      ..lineTo(cx + 10, neckBot)
      ..lineTo(w - sideX, botY_end)
      ..lineTo(sideX, botY_end)
      ..close();
    canvas.drawPath(botPath, glassPaint);

    // Neck
    canvas.drawRect(
      Rect.fromLTRB(cx - 10, neckTop, cx + 10, neckBot),
      glassPaint,
    );

    // ── Draw top sand (shrinking) ─────────────────────
    final topH = neckTop - topY; // 122
    final sandSurfaceY = topY + topH * progress;
    final lx = sideX + (cx - 10 - sideX) * (sandSurfaceY - topY) / topH;
    final rx = (w - sideX) - (cx - 10 - sideX) * (sandSurfaceY - topY) / topH;

    if (progress < 1.0) {
      final topSand = Path()
        ..moveTo(lx, sandSurfaceY)
        ..lineTo(rx, sandSurfaceY)
        ..lineTo(cx + 10, neckTop)
        ..lineTo(cx - 10, neckTop)
        ..close();
      canvas.drawPath(topSand, sandPaint);
    }

    // ── Draw bottom sand (growing) ────────────────────
    final botH = botY_end - neckBot; // 122
    final filledH = botH * progress;
    final botSurfaceY = botY_end - filledH;
    final blx = sideX + (cx - 10 - sideX) * (botY_end - botSurfaceY) / botH;
    final brx =
        (w - sideX) - (cx - 10 - sideX) * (botY_end - botSurfaceY) / botH;

    if (progress > 0) {
      final botSand = Path()
        ..moveTo(blx, botSurfaceY)
        ..lineTo(brx, botSurfaceY)
        ..lineTo(w - sideX, botY_end)
        ..lineTo(sideX, botY_end)
        ..close();
      canvas.drawPath(botSand, sandPaint);

      // Glow under bottom sand surface
      final glowPath = Path()
        ..moveTo(blx, botSurfaceY)
        ..lineTo(brx, botSurfaceY)
        ..lineTo(brx + 4, botSurfaceY + 8)
        ..lineTo(blx - 4, botSurfaceY + 8)
        ..close();
      canvas.drawPath(glowPath, glowPaint);
    }

    // ── Falling grain ─────────────────────────────────
    if (isRunning && progress < 1.0) {
      final grainY = neckTop + 5 + (neckBot - neckTop - 10) * grainOffset;
      final grainPaint = Paint()
        ..color = sandColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, grainY), 2.5, grainPaint);

      // Thin stream line
      final streamPaint = Paint()
        ..color = sandColor.withOpacity(0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx, neckTop + 2), Offset(cx, grainY), streamPaint);
    }

    // ── Glass shimmer ─────────────────────────────────
    final shimmerPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(sideX + 12, topY + 8),
      Offset(cx - 6, neckTop - 10),
      shimmerPaint,
    );
    canvas.drawLine(
      Offset(cx + 6, neckBot + 10),
      Offset(w - sideX - 12, botY_end - 8),
      shimmerPaint,
    );
  }

  @override
  bool shouldRepaint(HourglassPainter old) =>
      old.progress != progress ||
      old.isRunning != isRunning ||
      old.grainOffset != grainOffset ||
      old.isUrgent != isUrgent;
}
