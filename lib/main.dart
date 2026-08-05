import 'dart:convert';
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const GlimpseAppLoader());
}

class GlimpseAppLoader extends StatefulWidget {
  const GlimpseAppLoader({super.key});

  @override
  State<GlimpseAppLoader> createState() => _GlimpseAppLoaderState();
}

class _GlimpseAppLoaderState extends State<GlimpseAppLoader> {
  @override
  void initState() {
    super.initState();
    themeController.load();
  }

  @override
  Widget build(BuildContext context) => GlimpseApp();
}

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE (light / dark)
// ─────────────────────────────────────────────────────────────────────────────
class Palette {
  final Color bg;
  final Color card;
  final Color gold;
  final Color cream;
  final Color muted;
  final Color dim;
  final Color border;
  final Color calDefault;
  final Color calWeekend;
  final Color calOutside;
  final Brightness brightness;

  const Palette({
    required this.bg,
    required this.card,
    required this.gold,
    required this.cream,
    required this.muted,
    required this.dim,
    required this.border,
    required this.calDefault,
    required this.calWeekend,
    required this.calOutside,
    required this.brightness,
  });

  static const dark = Palette(
    bg: Color(0xFF0C0A08),
    card: Color(0xFF111009),
    gold: Color(0xFFE3AC4F),
    cream: Color(0xFFF0EAE0),
    muted: Color(0xFF5A5049),
    dim: Color(0xFF6B6155),
    border: Color(0xFF201C18),
    calDefault: Color(0xFF8A7E70),
    calWeekend: Color(0xFF6A5E50),
    calOutside: Color(0xFF3A342E),
    brightness: Brightness.dark,
  );

  static const light = Palette(
    bg: Color(0xFFFBF8F2),
    card: Color(0xFFFFFFFF),
    gold: Color(0xFFB07A1E),
    cream: Color(0xFF1E1A16),
    muted: Color(0xFF7A6F62),
    dim: Color(0xFF9A9186),
    border: Color(0xFFE6DFD2),
    calDefault: Color(0xFF4A4238),
    calWeekend: Color(0xFF8A7A5E),
    calOutside: Color(0xFFCFC7B8),
    brightness: Brightness.light,
  );
}

class ThemeController extends ValueNotifier<bool> {
  ThemeController() : super(true); // true = dark

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getBool('glimpse_dark_mode') ?? true;
  }

  Future<void> toggle() async {
    value = !value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glimpse_dark_mode', value);
  }
}

final themeController = ThemeController();

class PaletteScope extends InheritedWidget {
  final Palette palette;
  const PaletteScope({required this.palette, required super.child, super.key});

  static Palette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaletteScope>()!.palette;

  @override
  bool updateShouldNotify(PaletteScope oldWidget) => oldWidget.palette.brightness != palette.brightness;
}

const List<String> kPrompts = [
  "What was one moment worth keeping today?",
  "Describe today in a single breath.",
  "What did you notice that you almost missed?",
  "One sentence. Make it true.",
  "What would you tell tomorrow-you about today?",
  "Distill today down to its essence.",
  "What flickered across your day?",
  "If today were a photo, what would it capture?",
  "What small thing made today itself?",
  "What do you want to remember from today?",
];

// ─────────────────────────────────────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────────────────────────────────────
class GlimpseApp extends StatelessWidget {
  GlimpseApp({super.key});

  ThemeData _themeFor(Palette p) {
    final base = p.brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      textTheme: base.textTheme.apply(fontFamily: 'Georgia'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeController,
      builder: (context, isDark, __) {
        final palette = isDark ? Palette.dark : Palette.light;
        return PaletteScope(
          palette: palette,
          child: MaterialApp(
            title: 'glimpse.',
            debugShowCheckedModeBanner: false,
            theme: _themeFor(palette),
            home: AppEntry(),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY
// ─────────────────────────────────────────────────────────────────────────────
class AppEntry extends StatefulWidget {
  AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _showIntro;

  @override
  void initState() {
    super.initState();
    // Start the minimum-display timer once the first frame is actually on
    // screen, same as the pen animation itself — otherwise engine warm-up
    // time eats into the wait and the two fall out of sync.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      Future.delayed(const Duration(milliseconds: 3400)),
    ]);
    final prefs = results[0] as SharedPreferences;
    final seen = prefs.getBool('glimpse_seen_intro') ?? false;
    if (mounted) setState(() => _showIntro = !seen);
  }

  void _onIntroComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glimpse_seen_intro', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => GlimpseHome(),
        transitionDuration: Duration(milliseconds: 700),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    if (_showIntro == null) return Scaffold(backgroundColor: p.bg, body: const _PenLoader());
    if (_showIntro!) return IntroScreen(onComplete: _onIntroComplete);
    return GlimpseHome();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PEN LOADER
// ─────────────────────────────────────────────────────────────────────────────
class _PenLoader extends StatefulWidget {
  const _PenLoader();

  @override
  State<_PenLoader> createState() => _PenLoaderState();
}

class _PenLoaderState extends State<_PenLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<PathMetric> _metrics;

  // One continuous stroke: the underline squiggle, then a lift up to a small
  // circle standing in for the period, right next to the word's baseline.
  // Same pen draws both, in order.
  static final Path _stroke = Path()
    ..moveTo(0, -8)
    ..cubicTo(26, -34, 52, 16, 78, -10)
    ..cubicTo(104, -36, 130, 13, 156, -13)
    ..cubicTo(182, -36, 208, 10, 234, -10)
    ..addOval(Rect.fromCircle(center: const Offset(210, -34), radius: 5));

  @override
  void initState() {
    super.initState();
    _metrics = _stroke.computeMetrics().toList();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
    // Wait for the first real frame to be on screen before starting the
    // timer — otherwise engine/first-frame warm-up time eats into the
    // animation before the user ever sees the blank starting state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "glimpse",
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: p.cream,
              letterSpacing: -2,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              // The line and the dot each get their own fixed time slice,
              // rather than splitting time by raw path length — otherwise
              // the much-shorter dot whips by nearly instantly. A gap
              // between the two slices leaves the pen paused at the end of
              // the line for a beat before it starts the dot.
              final t = _ctrl.value;
              final lineT = Curves.easeInOut.transform((t / 0.45).clamp(0.0, 1.0));
              final dotT = Curves.easeInOut.transform(((t - 0.5) / 0.2).clamp(0.0, 1.0));
              // The remaining 30% of the timeline (after the dot lands at
              // t=0.7) is spent flicking the pen off across the screen,
              // rather than extending the total duration — keeps it in
              // sync with the minimum-display timer in _AppEntryState.
              final floatT = Curves.easeIn.transform(((t - 0.7) / 0.3).clamp(0.0, 1.0));
              return CustomPaint(
                size: const Size(234, 56),
                painter: _PenPainter(
                  metrics: _metrics,
                  segmentProgress: [lineT, dotT],
                  strokeColor: p.gold,
                  floatT: floatT,
                  floatDistance: screenWidth,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PenPainter extends CustomPainter {
  final List<PathMetric> metrics;
  final List<double> segmentProgress; // one entry per metric, each 0..1
  final Color strokeColor;
  final double floatT; // 0..1, drives the pen flying off after the dot lands
  final double floatDistance; // screen width, sets how far it travels

  _PenPainter({
    required this.metrics,
    required this.segmentProgress,
    required this.strokeColor,
    this.floatT = 0,
    this.floatDistance = 0,
  });

  // Calligraphy pen silhouette in local space: broad flat nib pointed at the
  // origin facing +x (the direction of travel), tapered holder trailing
  // behind along -x.
  static final Path _nib = Path()
    ..moveTo(0, 0)
    ..lineTo(-7, -6)
    ..lineTo(-17, -4)
    ..lineTo(-17, 4)
    ..lineTo(-7, 6)
    ..close();

  static final Path _nibSlit = Path()
    ..moveTo(0, 0)
    ..lineTo(-15, 0);

  // A slender tapered barrel that bulges slightly at the grip and rounds
  // off at the back, rather than a flat wedge.
  static final Path _holder = Path()
    ..moveTo(-16, -3.5)
    ..quadraticBezierTo(-26, -6.5, -37, -5)
    ..quadraticBezierTo(-45, -4, -47, 0)
    ..quadraticBezierTo(-45, 4, -37, 5)
    ..quadraticBezierTo(-26, 6.5, -16, 3.5)
    ..close();

  static final Path _ferrule = Path()
    ..moveTo(-16, -3.7)
    ..lineTo(-19, -3.9)
    ..lineTo(-19, 3.9)
    ..lineTo(-16, 3.7)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Tangent? tangent;
    for (var i = 0; i < metrics.length; i++) {
      final t = i < segmentProgress.length ? segmentProgress[i].clamp(0.0, 1.0) : 0.0;
      if (t <= 0) continue;
      final m = metrics[i];
      final len = m.length * t;
      canvas.drawPath(m.extractPath(0, len), strokePaint);
      tangent = m.getTangentForOffset(len);
    }

    if (tangent != null && floatT < 1.0) {
      // Flick the pen up and off to the right across the screen once the
      // dot is done, fading and tumbling as it goes; the drawn stroke
      // itself is untouched and stays put.
      final flyOffset = Offset(floatT * floatDistance, -floatT * floatDistance * 0.4);
      final penOpacity = 1.0 - floatT;
      canvas.save();
      canvas.translate(tangent.position.dx + flyOffset.dx, tangent.position.dy + flyOffset.dy);
      canvas.rotate(-0.4 - floatT * 1.3); // base writing tilt plus tumble as it flies off
      canvas.drawPath(_holder, Paint()..color = Colors.black.withOpacity(penOpacity));
      canvas.drawPath(_ferrule, Paint()..color = strokeColor.withOpacity(0.7 * penOpacity));
      canvas.drawPath(_nib, Paint()..color = strokeColor.withOpacity(penOpacity));
      canvas.drawPath(
        _nibSlit,
        Paint()
          ..color = Colors.black.withOpacity(0.35 * penOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PenPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// INTRO SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class IntroScreen extends StatefulWidget {
  final VoidCallback onComplete;
  IntroScreen({required this.onComplete, super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  late AnimationController _titleCtrl;
  late AnimationController _lineCtrl;
  late AnimationController _subCtrl;
  late AnimationController _featCtrl;
  late AnimationController _btnCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _lineCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _subCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _featCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _btnCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(Duration(milliseconds: 200));
    _titleCtrl.forward();
    await Future.delayed(Duration(milliseconds: 500));
    _lineCtrl.forward();
    await Future.delayed(Duration(milliseconds: 300));
    _subCtrl.forward();
    await Future.delayed(Duration(milliseconds: 350));
    _featCtrl.forward();
    await Future.delayed(Duration(milliseconds: 350));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _lineCtrl.dispose();
    _subCtrl.dispose();
    _featCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(AnimationController c) =>
      CurvedAnimation(parent: c, curve: Curves.easeOut);

  Animation<Offset> _slide(AnimationController c) =>
      Tween<Offset>(begin: Offset(0, 0.12), end: Offset.zero)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOut));

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: ThemeToggleButton(color: p.muted),
              ),
            ),
            Padding(
          padding: EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Spacer(flex: 3),

              // Title
              FadeTransition(
                opacity: _fade(_titleCtrl),
                child: SlideTransition(
                  position: _slide(_titleCtrl),
                  child: Text(
                    "glimpse.",
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: p.cream,
                      letterSpacing: -4,
                      height: 1.0,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ),

              SizedBox(height: 18),

              // Gold line
              AnimatedBuilder(
                animation: _lineCtrl,
                builder: (_, __) => Container(
                  height: 1,
                  width: _lineCtrl.value * (w - 72),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [p.gold, Colors.transparent],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 22),

              // Tagline
              FadeTransition(
                opacity: _fade(_subCtrl),
                child: Text(
                  "one sentence.\nevery day.\nforever.",
                  style: TextStyle(
                    fontSize: 20,
                    color: p.muted,
                    fontStyle: FontStyle.italic,
                    height: 1.75,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),

              Spacer(flex: 2),

              // Features
              FadeTransition(
                opacity: _fade(_featCtrl),
                child: Column(
                  children: [
                    _IntroFeature(icon: "✦", text: "Write one sentence about your day"),
                    SizedBox(height: 16),
                    _IntroFeature(icon: "◈", text: "Build a constellation of moments"),
                    SizedBox(height: 16),
                    _IntroFeature(icon: "◌", text: "Revisit your days on a calendar"),
                  ],
                ),
              ),

              Spacer(flex: 2),

              // CTA
              FadeTransition(
                opacity: _fade(_btnCtrl),
                child: _PressableButton(
                  onTap: widget.onComplete,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: p.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        "begin →",
                        style: TextStyle(
                          color: p.bg,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Georgia',
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 52),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}

class _IntroFeature extends StatelessWidget {
  final String icon;
  final String text;
  _IntroFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    return Row(
      children: [
        Text(icon, style: TextStyle(color: p.gold, fontSize: 13)),
        SizedBox(width: 14),
        Text(text, style: TextStyle(color: p.dim, fontSize: 14, fontFamily: 'Georgia')),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class JournalEntry {
  final String dateKey; // "YYYY-MM-DD"
  final String text;
  final DateTime createdAt;

  JournalEntry({
    required this.dateKey,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        dateKey: j['dateKey'] as String,
        text: j['text'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

String todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String dateKeyFor(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String formatFriendly(String key) {
  final parts = key.split('-');
  final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  const months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[dt.month]} ${dt.day}, ${dt.year}';
}

String formatShort(String key) {
  final parts = key.split('-');
  final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month]} ${dt.day}';
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME
// ─────────────────────────────────────────────────────────────────────────────
class GlimpseHome extends StatefulWidget {
  GlimpseHome({super.key});

  @override
  State<GlimpseHome> createState() => _GlimpseHomeState();
}

class _GlimpseHomeState extends State<GlimpseHome> {
  Map<String, JournalEntry> _entries = {};
  int _promptIndex = 0;
  bool _didAnimate = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _promptIndex = DateTime.now().millisecondsSinceEpoch % kPrompts.length;
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('glimpse_entries');
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _entries = {for (final j in list) j['dateKey'] as String: JournalEntry.fromJson(j)};
    }
    setState(() => _didAnimate = true);
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('glimpse_entries', jsonEncode(_entries.values.map((e) => e.toJson()).toList()));
  }

  JournalEntry? get _todayEntry => _entries[todayKey()];

  int get _streak {
    int count = 0;
    DateTime check = DateTime.now();
    while (true) {
      final k = dateKeyFor(check);
      if (_entries.containsKey(k)) {
        count++;
        check = check.subtract(Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }

  List<JournalEntry> get _recentEntries {
    final sorted = _entries.values.toList()..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    // Exclude today if it exists in recent list rendered separately
    return sorted.where((e) => e.dateKey != todayKey()).take(7).toList();
  }

  void _openWrite({JournalEntry? existing}) async {
    final result = await showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteSheet(
        prompt: kPrompts[_promptIndex % kPrompts.length],
        existing: existing,
        dateKey: existing?.dateKey ?? todayKey(),
      ),
    );
    if (result != null) {
      HapticFeedback.mediumImpact();
      setState(() => _entries[result.dateKey] = result);
      _saveEntries();
    }
  }

  void _deleteEntry(String key) {
    HapticFeedback.mediumImpact();
    setState(() => _entries.remove(key));
    _saveEntries();
  }

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    final today = todayKey();
    final todayEntry = _todayEntry;
    final recent = _recentEntries;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        titleSpacing: 24,
        title: Text(
          "glimpse.",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: p.cream,
            letterSpacing: -1.5,
            fontFamily: 'Georgia',
          ),
        ),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              tooltip: "Calendar",
              icon: Icon(Icons.calendar_month_outlined, color: p.muted),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CalendarView(entries: _entries, onDelete: _deleteEntry)),
              ),
            ),
          ThemeToggleButton(color: p.muted),
          SizedBox(width: 8),
        ],
      ),
      body: AnimatedOpacity(
        opacity: _didAnimate ? 1.0 : 0.0,
        duration: Duration(milliseconds: 500),
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Stats row
            if (_entries.isNotEmpty) ...[
              _StatsRow(streak: _streak, total: _entries.length),
              SizedBox(height: 20),
            ],

            // Today card
            _TodayCard(
              entry: todayEntry,
              prompt: kPrompts[_promptIndex % kPrompts.length],
              onTap: () => _openWrite(existing: todayEntry),
            ),

            // Recent entries
            if (recent.isNotEmpty) ...[
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.only(left: 2, bottom: 14),
                child: Text(
                  "recent",
                  style: TextStyle(
                    fontSize: 11,
                    color: p.muted,
                    letterSpacing: 2,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              ...recent.map((e) => _EntryTile(
                entry: e,
                onTap: () => _openWrite(existing: e),
                onDelete: () => _deleteEntry(e.dateKey),
              )),
            ],

            if (_entries.isEmpty)
              _EmptyHint(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int streak;
  final int total;
  _StatsRow({required this.streak, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(icon: "✦", value: "$total", label: "entries"),
        SizedBox(width: 10),
        _StatBox(icon: "◌", value: "$streak", label: streak == 1 ? "day streak" : "day streak", highlight: streak > 1),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final bool highlight;

  _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    return Expanded(
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: TextStyle(color: highlight ? p.gold : p.muted, fontSize: 11)),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: highlight ? p.gold : p.cream,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: p.muted, fontFamily: 'Georgia')),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TODAY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final JournalEntry? entry;
  final String prompt;
  final VoidCallback onTap;

  _TodayCard({required this.entry, required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    final hasEntry = entry != null;
    final now = DateTime.now();
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = '${months[now.month]} ${now.day}';

    return _PressableButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasEntry ? p.gold.withOpacity(0.3) : p.border,
            width: hasEntry ? 1.5 : 1,
          ),
          boxShadow: hasEntry
              ? [BoxShadow(color: p.gold.withOpacity(0.06), blurRadius: 24, spreadRadius: 4)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: p.gold,
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.2,
                  ),
                ),
                Spacer(),
                if (hasEntry)
                  Text("✓", style: TextStyle(color: p.gold, fontSize: 14))
                else
                  Text("today", style: TextStyle(color: p.dim, fontSize: 12, fontFamily: 'Georgia')),
              ],
            ),
            SizedBox(height: 16),
            if (hasEntry) ...[
              Text(
                entry!.text,
                style: TextStyle(
                  fontSize: 18,
                  color: p.cream,
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  height: 1.55,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 14),
              Text(
                "tap to edit",
                style: TextStyle(fontSize: 11, color: p.dim, fontFamily: 'Georgia'),
              ),
            ] else ...[
              Text(
                prompt,
                style: TextStyle(
                  fontSize: 16,
                  color: p.muted,
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: p.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "write today's glimpse →",
                  style: TextStyle(
                    color: p.bg,
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY TILE (recent list)
// ─────────────────────────────────────────────────────────────────────────────
class _EntryTile extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  _EntryTile({required this.entry, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    return Dismissible(
      key: ValueKey(entry.dateKey),
      background: Container(
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 24),
        child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
      ),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Color(0xFF141210),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Delete this glimpse?", style: TextStyle(fontFamily: 'Georgia')),
            content: Text(
              formatFriendly(entry.dateKey),
              style: TextStyle(color: Colors.white54, fontFamily: 'Georgia', fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel", style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.8)),
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete"),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: _PressableButton(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date column
              SizedBox(
                width: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.dateKey.split('-')[2].replaceAll(RegExp(r'^0'), ''),
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: p.cream,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      formatShort(entry.dateKey).split(' ')[0].toUpperCase(),
                      style: TextStyle(fontSize: 9, color: p.gold, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 48, color: p.border, margin: EdgeInsets.only(right: 16)),
              Expanded(
                child: Text(
                  entry.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB8AEA0),
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WRITE SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _WriteSheet extends StatefulWidget {
  final String prompt;
  final JournalEntry? existing;
  final String dateKey;

  _WriteSheet({required this.prompt, this.existing, required this.dateKey});

  @override
  State<_WriteSheet> createState() => _WriteSheetState();
}

class _WriteSheetState extends State<_WriteSheet> {
  late TextEditingController _ctrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.existing?.text ?? '');
    _isEditing = widget.existing != null;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      JournalEntry(dateKey: widget.dateKey, text: text, createdAt: DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        28, 16, 28, MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: p.dim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 24),

          // Date label
          Text(
            formatFriendly(widget.dateKey),
            style: TextStyle(
              fontSize: 12,
              color: p.gold,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),

          SizedBox(height: 6),

          // Prompt
          Text(
            widget.prompt,
            style: TextStyle(
              fontSize: 17,
              color: p.muted,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),

          SizedBox(height: 20),

          // Gold divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p.gold, Colors.transparent]),
            ),
          ),

          SizedBox(height: 20),

          // Text field
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: null,
            minLines: 3,
            style: TextStyle(
              fontSize: 18,
              color: p.cream,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              height: 1.6,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: "one sentence…",
              hintStyle: TextStyle(
                color: p.dim,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            cursorColor: p.gold,
            cursorWidth: 1.5,
            textCapitalization: TextCapitalization.sentences,
          ),

          SizedBox(height: 24),

          // Save button
          _PressableButton(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: p.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _isEditing ? "save changes" : "save glimpse",
                  style: TextStyle(
                    color: p.bg,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                    letterSpacing: 0.2,
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

// ─────────────────────────────────────────────────────────────────────────────
// CALENDAR VIEW
// ─────────────────────────────────────────────────────────────────────────────
class CalendarView extends StatefulWidget {
  final Map<String, JournalEntry> entries;
  final void Function(String key) onDelete;

  CalendarView({required this.entries, required this.onDelete, super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  JournalEntry? _entryFor(DateTime day) => widget.entries[dateKeyFor(day)];

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    final selected = _selectedDay != null ? _entryFor(_selectedDay!) : null;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: p.muted),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "glimpse.",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: p.cream,
            letterSpacing: -1,
            fontFamily: 'Georgia',
          ),
        ),
        actions: [
          ThemeToggleButton(color: p.muted),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.now().add(Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) =>
                setState(() { _selectedDay = selected; _focusedDay = focused; }),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: p.calDefault, fontFamily: 'Georgia'),
              weekendTextStyle: TextStyle(color: p.calWeekend, fontFamily: 'Georgia'),
              outsideTextStyle: TextStyle(color: p.calOutside, fontFamily: 'Georgia'),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: p.gold.withOpacity(0.5)),
              ),
              todayTextStyle: TextStyle(color: p.gold, fontFamily: 'Georgia'),
              selectedDecoration: BoxDecoration(color: p.cream, shape: BoxShape.circle),
              selectedTextStyle: TextStyle(color: p.bg, fontWeight: FontWeight.w800, fontFamily: 'Georgia'),
              cellMargin: EdgeInsets.all(4),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                fontFamily: 'Georgia',
                letterSpacing: -0.3,
                color: p.cream,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: p.muted, size: 20),
              rightChevronIcon: Icon(Icons.chevron_right, color: p.muted, size: 20),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: p.dim, fontSize: 11, fontFamily: 'Georgia'),
              weekendStyle: TextStyle(color: p.dim, fontSize: 11, fontFamily: 'Georgia'),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, _) {
                final entry = _entryFor(day);
                if (entry == null) return null;
                return Positioned(
                  bottom: 5,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            onPageChanged: (fd) => setState(() => _focusedDay = fd),
          ),

          SizedBox(height: 12),

          // Divider
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, p.border, Colors.transparent],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Selected entry or hint
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _selectedDay == null
                  ? Center(
                      child: Text(
                        "tap a day to read your glimpse",
                        style: TextStyle(color: p.dim, fontFamily: 'Georgia', fontStyle: FontStyle.italic, fontSize: 14),
                      ),
                    )
                  : selected == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatFriendly(dateKeyFor(_selectedDay!)),
                              style: TextStyle(fontSize: 13, color: p.gold, fontFamily: 'Georgia', fontStyle: FontStyle.italic),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "nothing here.",
                              style: TextStyle(color: p.dim, fontFamily: 'Georgia', fontStyle: FontStyle.italic, fontSize: 16),
                            ),
                          ],
                        )
                      : _CalendarEntryCard(
                          entry: selected,
                          onDelete: () {
                            widget.onDelete(selected.dateKey);
                            setState(() => _selectedDay = null);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onDelete;

  _CalendarEntryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.gold.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: p.gold.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatFriendly(entry.dateKey),
            style: TextStyle(
              fontSize: 12,
              color: p.gold,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 14),
          Text(
            entry.text,
            style: TextStyle(
              fontSize: 18,
              color: p.cream,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              height: 1.65,
              letterSpacing: -0.2,
            ),
          ),
          Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, size: 15, color: p.dim),
              label: Text(
                "delete",
                style: TextStyle(fontSize: 12, color: p.dim, fontFamily: 'Georgia'),
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY HINT
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final p = PaletteScope.of(context);
    return Padding(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(
            "glimpse.",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: p.border,
              letterSpacing: -3,
              fontFamily: 'Georgia',
            ),
          ),
          SizedBox(height: 12),
          Text(
            "your story starts today.",
            style: TextStyle(
              fontSize: 15,
              color: p.dim,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRESSABLE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _PressableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  _PressableButton({required this.onTap, required this.child});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME TOGGLE
// ─────────────────────────────────────────────────────────────────────────────
class ThemeToggleButton extends StatelessWidget {
  final Color color;
  const ThemeToggleButton({required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeController,
      builder: (context, isDark, __) {
        return IconButton(
          tooltip: isDark ? "Switch to light mode" : "Switch to dark mode",
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: color),
          onPressed: () => themeController.toggle(),
        );
      },
    );
  }
}