import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const GlimpseApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color kBg = Color(0xFF0C0A08);
const Color kCard = Color(0xFF111009);
const Color kGold = Color(0xFFC8973E);
const Color kCream = Color(0xFFF0EAE0);
const Color kMuted = Color(0xFF5A5049);
const Color kDim = Color(0xFF3A342E);
const Color kBorder = Color(0xFF201C18);

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
  const GlimpseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'glimpse.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBg,
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Georgia'),
      ),
      home: const AppEntry(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY
// ─────────────────────────────────────────────────────────────────────────────
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _showIntro;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('glimpse_seen_intro') ?? false;
    setState(() => _showIntro = !seen);
  }

  void _onIntroComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glimpse_seen_intro', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GlimpseHome(),
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro == null) return const Scaffold(backgroundColor: kBg);
    if (_showIntro!) return IntroScreen(onComplete: _onIntroComplete);
    return const GlimpseHome();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTRO SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class IntroScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const IntroScreen({required this.onComplete, super.key});

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
    _titleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _lineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _subCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _featCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _titleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _lineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _subCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    _featCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
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
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOut));

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),

              // Title
              FadeTransition(
                opacity: _fade(_titleCtrl),
                child: SlideTransition(
                  position: _slide(_titleCtrl),
                  child: const Text(
                    "glimpse.",
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: kCream,
                      letterSpacing: -4,
                      height: 1.0,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Gold line
              AnimatedBuilder(
                animation: _lineCtrl,
                builder: (_, __) => Container(
                  height: 1,
                  width: _lineCtrl.value * (w - 72),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kGold, Colors.transparent],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Tagline
              FadeTransition(
                opacity: _fade(_subCtrl),
                child: const Text(
                  "one sentence.\nevery day.\nforever.",
                  style: TextStyle(
                    fontSize: 20,
                    color: kMuted,
                    fontStyle: FontStyle.italic,
                    height: 1.75,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Features
              FadeTransition(
                opacity: _fade(_featCtrl),
                child: Column(
                  children: const [
                    _IntroFeature(icon: "✦", text: "Write one sentence about your day"),
                    SizedBox(height: 16),
                    _IntroFeature(icon: "◈", text: "Build a constellation of moments"),
                    SizedBox(height: 16),
                    _IntroFeature(icon: "◌", text: "Revisit your days on a calendar"),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // CTA
              FadeTransition(
                opacity: _fade(_btnCtrl),
                child: _PressableButton(
                  onTap: widget.onComplete,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: kCream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        "begin →",
                        style: TextStyle(
                          color: kBg,
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

              const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroFeature extends StatelessWidget {
  final String icon;
  final String text;
  const _IntroFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(color: kGold, fontSize: 13)),
        const SizedBox(width: 14),
        Text(text, style: const TextStyle(color: kDim, fontSize: 14, fontFamily: 'Georgia')),
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
  const GlimpseHome({super.key});

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
        check = check.subtract(const Duration(days: 1));
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
    final today = todayKey();
    final todayEntry = _todayEntry;
    final recent = _recentEntries;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        titleSpacing: 24,
        title: const Text(
          "glimpse.",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: kCream,
            letterSpacing: -1.5,
            fontFamily: 'Georgia',
          ),
        ),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              tooltip: "Calendar",
              icon: const Icon(Icons.calendar_month_outlined, color: Colors.white38),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CalendarView(entries: _entries, onDelete: _deleteEntry)),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedOpacity(
        opacity: _didAnimate ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Stats row
            if (_entries.isNotEmpty) ...[
              _StatsRow(streak: _streak, total: _entries.length),
              const SizedBox(height: 20),
            ],

            // Today card
            _TodayCard(
              entry: todayEntry,
              prompt: kPrompts[_promptIndex % kPrompts.length],
              onTap: () => _openWrite(existing: todayEntry),
            ),

            // Recent entries
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 14),
                child: Text(
                  "recent",
                  style: TextStyle(
                    fontSize: 11,
                    color: kMuted,
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
              const _EmptyHint(),
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
  const _StatsRow({required this.streak, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(icon: "✦", value: "$total", label: "entries"),
        const SizedBox(width: 10),
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

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: TextStyle(color: highlight ? kGold : kMuted, fontSize: 11)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: highlight ? kGold : kCream,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: kMuted, fontFamily: 'Georgia')),
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

  const _TodayCard({required this.entry, required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasEntry = entry != null;
    final now = DateTime.now();
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = '${months[now.month]} ${now.day}';

    return _PressableButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasEntry ? kGold.withOpacity(0.3) : kBorder,
            width: hasEntry ? 1.5 : 1,
          ),
          boxShadow: hasEntry
              ? [BoxShadow(color: kGold.withOpacity(0.06), blurRadius: 24, spreadRadius: 4)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kGold,
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                if (hasEntry)
                  const Text("✓", style: TextStyle(color: kGold, fontSize: 14))
                else
                  const Text("today", style: TextStyle(color: kDim, fontSize: 12, fontFamily: 'Georgia')),
              ],
            ),
            const SizedBox(height: 16),
            if (hasEntry) ...[
              Text(
                entry!.text,
                style: const TextStyle(
                  fontSize: 18,
                  color: kCream,
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  height: 1.55,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "tap to edit",
                style: TextStyle(fontSize: 11, color: kDim, fontFamily: 'Georgia'),
              ),
            ] else ...[
              Text(
                prompt,
                style: const TextStyle(
                  fontSize: 16,
                  color: kMuted,
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: kCream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "write today's glimpse →",
                  style: TextStyle(
                    color: kBg,
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

  const _EntryTile({required this.entry, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.dateKey),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
      ),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF141210),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Delete this glimpse?", style: TextStyle(fontFamily: 'Georgia')),
            content: Text(
              formatFriendly(entry.dateKey),
              style: const TextStyle(color: Colors.white54, fontFamily: 'Georgia', fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.8)),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: _PressableButton(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
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
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: kCream,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatShort(entry.dateKey).split(' ')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 9, color: kGold, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 48, color: kBorder, margin: const EdgeInsets.only(right: 16)),
              Expanded(
                child: Text(
                  entry.text,
                  style: const TextStyle(
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

  const _WriteSheet({required this.prompt, this.existing, required this.dateKey});

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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111009),
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
                color: kDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Date label
          Text(
            formatFriendly(widget.dateKey),
            style: const TextStyle(
              fontSize: 12,
              color: kGold,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 6),

          // Prompt
          Text(
            widget.prompt,
            style: const TextStyle(
              fontSize: 17,
              color: kMuted,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Gold divider
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [kGold, Colors.transparent]),
            ),
          ),

          const SizedBox(height: 20),

          // Text field
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: null,
            minLines: 3,
            style: const TextStyle(
              fontSize: 18,
              color: kCream,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              height: 1.6,
              letterSpacing: -0.2,
            ),
            decoration: const InputDecoration(
              hintText: "one sentence…",
              hintStyle: TextStyle(
                color: kDim,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            cursorColor: kGold,
            cursorWidth: 1.5,
            textCapitalization: TextCapitalization.sentences,
          ),

          const SizedBox(height: 24),

          // Save button
          _PressableButton(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _isEditing ? "save changes" : "save glimpse",
                  style: const TextStyle(
                    color: kBg,
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

  const CalendarView({required this.entries, required this.onDelete, super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  JournalEntry? _entryFor(DateTime day) => widget.entries[dateKeyFor(day)];

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay != null ? _entryFor(_selectedDay!) : null;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white38),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "glimpse.",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: kCream,
            letterSpacing: -1,
            fontFamily: 'Georgia',
          ),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) =>
                setState(() { _selectedDay = selected; _focusedDay = focused; }),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Color(0xFF8A7E70), fontFamily: 'Georgia'),
              weekendTextStyle: const TextStyle(color: Color(0xFF6A5E50), fontFamily: 'Georgia'),
              outsideTextStyle: const TextStyle(color: Color(0xFF3A342E), fontFamily: 'Georgia'),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: kGold.withOpacity(0.5)),
              ),
              todayTextStyle: const TextStyle(color: kGold, fontFamily: 'Georgia'),
              selectedDecoration: const BoxDecoration(color: kCream, shape: BoxShape.circle),
              selectedTextStyle: const TextStyle(color: kBg, fontWeight: FontWeight.w800, fontFamily: 'Georgia'),
              cellMargin: const EdgeInsets.all(4),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                fontFamily: 'Georgia',
                letterSpacing: -0.3,
                color: kCream,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white38, size: 20),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white38, size: 20),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: kDim, fontSize: 11, fontFamily: 'Georgia'),
              weekendStyle: TextStyle(color: kDim, fontSize: 11, fontFamily: 'Georgia'),
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
                    decoration: const BoxDecoration(
                      color: kGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            onPageChanged: (fd) => setState(() => _focusedDay = fd),
          ),

          const SizedBox(height: 12),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, kBorder, Colors.transparent],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Selected entry or hint
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _selectedDay == null
                  ? Center(
                      child: Text(
                        "tap a day to read your glimpse",
                        style: TextStyle(color: kDim, fontFamily: 'Georgia', fontStyle: FontStyle.italic, fontSize: 14),
                      ),
                    )
                  : selected == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatFriendly(dateKeyFor(_selectedDay!)),
                              style: const TextStyle(fontSize: 13, color: kGold, fontFamily: 'Georgia', fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "nothing here.",
                              style: TextStyle(color: kDim, fontFamily: 'Georgia', fontStyle: FontStyle.italic, fontSize: 16),
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

  const _CalendarEntryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGold.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: kGold.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatFriendly(entry.dateKey),
            style: const TextStyle(
              fontSize: 12,
              color: kGold,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            entry.text,
            style: const TextStyle(
              fontSize: 18,
              color: kCream,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              height: 1.65,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 15, color: Colors.white24),
              label: const Text(
                "delete",
                style: TextStyle(fontSize: 12, color: Colors.white24, fontFamily: 'Georgia'),
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
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: const [
          Text(
            "glimpse.",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1A16),
              letterSpacing: -3,
              fontFamily: 'Georgia',
            ),
          ),
          SizedBox(height: 12),
          Text(
            "your story starts today.",
            style: TextStyle(
              fontSize: 15,
              color: kDim,
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
  const _PressableButton({required this.onTap, required this.child});

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
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}