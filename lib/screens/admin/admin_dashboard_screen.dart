import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/data/metro_data.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await context.read<AppAuthProvider>().signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF12172E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF3333)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Panel',
                              style: Theme.of(context).textTheme.headlineMedium),
                          const Text('Mumbai Metro Control Center',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.error),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 16),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(icon: Icon(Icons.campaign_rounded, size: 18),
                        text: 'Alerts'),
                    Tab(icon: Icon(Icons.speed_rounded, size: 18),
                        text: 'Peak Hrs'),
                    Tab(icon: Icon(Icons.schedule_rounded, size: 18),
                        text: 'Timetable'),
                    Tab(icon: Icon(Icons.build_circle_rounded, size: 18),
                        text: 'Operations'),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _AnnouncementsTab(),
                    _PeakHoursTab(),
                    _TimetableTab(),
                    _OperationsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 1: ANNOUNCEMENTS MANAGER
// ═══════════════════════════════════════════════════════════

class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();
  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  final _msgController = TextEditingController();
  String _category = 'Delay';
  String _line = 'blue';
  bool _isPublishing = false;

  static const _categories = ['Delay', 'Cancellation', 'General'];
  static const _lines = {
    'blue': ('Blue Line', AppColors.blueLine),
    'yellow': ('Yellow Line', AppColors.yellowLine),
    'red': ('Red Line', AppColors.redLine),
    'aqua': ('Aqua Line', AppColors.aquaLine),
  };

  IconData _catIcon(String c) => switch (c) {
        'Delay' => Icons.schedule_rounded,
        'Cancellation' => Icons.cancel_rounded,
        _ => Icons.info_rounded,
      };

  Color _catColor(String c) => switch (c) {
        'Delay' => AppColors.warning,
        'Cancellation' => AppColors.error,
        _ => AppColors.info,
      };

  Future<void> _publish() async {
    final msg = _msgController.text.trim();
    if (msg.isEmpty) return;
    setState(() => _isPublishing = true);
    final ok = await context.read<AdminProvider>().publishAnnouncement(
          message: msg,
          category: _category,
          line: _line,
        );
    setState(() => _isPublishing = false);
    if (ok) {
      _msgController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement published ✓')),
        );
      }
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Compose Form ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Announcement',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                TextField(
                  controller: _msgController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Train delayed by 15 mins on Blue Line',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                            labelText: 'Category',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10)),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(children: [
                                  Icon(_catIcon(c),
                                      size: 16, color: _catColor(c)),
                                  const SizedBox(width: 6),
                                  Text(c),
                                ])))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _line,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                            labelText: 'Metro Line',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10)),
                        items: _lines.entries
                            .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Row(children: [
                                  Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                          color: e.value.$2,
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text(e.value.$1,
                                      style: const TextStyle(fontSize: 12)),
                                ])))
                            .toList(),
                        onChanged: (v) => setState(() => _line = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isPublishing ? null : _publish,
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_isPublishing ? 'Publishing…' : 'Publish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Live list ──
          const Text('Active Announcements',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: admin.announcementsStream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('No announcements yet',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final cat = data['category'] ?? 'General';
                  final lineName =
                      _lines[data['line']]?.$1 ?? data['line'] ?? '';
                  final lineColor =
                      _lines[data['line']]?.$2 ?? AppColors.textMuted;
                  final ts = (data['createdAt'] as Timestamp?)?.toDate();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _catColor(cat).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(_catIcon(cat), color: _catColor(cat), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['message'] ?? '',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Row(children: [
                                _badge(cat, _catColor(cat)),
                                const SizedBox(width: 6),
                                _badge(lineName, lineColor),
                                if (ts != null) ...[
                                  const Spacer(),
                                  Text(_timeAgo(ts),
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10)),
                                ],
                              ]),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                              onPressed: () => _editAnnouncementDialog(context, admin, docs[i].id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              onPressed: () => _confirmDeleteAnnouncement(context, admin, docs[i].id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _editAnnouncementDialog(BuildContext context, AdminProvider admin, String docId, Map<String, dynamic> data) {
    final msgCtrl = TextEditingController(text: data['message']);
    String cat = data['category'] ?? 'General';
    String line = data['line'] ?? 'blue';
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Edit Announcement', style: TextStyle(color: AppColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: msgCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: cat,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => cat = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: line,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Metro Line'),
                    items: _lines.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.$1))).toList(),
                    onChanged: (v) => setState(() => line = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
              ElevatedButton(
                onPressed: () {
                  if (msgCtrl.text.isNotEmpty) {
                    admin.editAnnouncement(docId, msgCtrl.text.trim(), cat, line);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _confirmDeleteAnnouncement(BuildContext context, AdminProvider admin, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Announcement?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              admin.deleteAnnouncement(docId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 2: PEAK HOUR TOGGLES
// ═══════════════════════════════════════════════════════════

class _PeakHoursTab extends StatelessWidget {
  const _PeakHoursTab();

  static const _lineInfo = <String, (String, String, Color)>{
    'blue': ('Blue Line', 'Line 1 · Versova ↔ Ghatkopar', AppColors.blueLine),
    'yellow': ('Yellow Line', 'Line 2A · Dahisar ↔ D.N. Nagar', AppColors.yellowLine),
    'red': ('Red Line', 'Line 7 · Gundavali ↔ Dahisar', AppColors.redLine),
    'aqua': ('Aqua Line', 'Line 3 · Cuffe Parade ↔ Aarey', AppColors.aquaLine),
  };

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();
    return StreamBuilder<DocumentSnapshot>(
      stream: admin.peakHoursStream,
      builder: (ctx, snap) {
        final data =
            (snap.data?.data() as Map<String, dynamic>?) ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Toggle peak hours ON to alert commuters about crowded conditions on specific metro lines.',
                        style: TextStyle(
                            color: AppColors.warning.withValues(alpha: 0.9),
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ..._lineInfo.entries.map((e) {
                final isActive = data[e.key] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isActive
                            ? e.value.$3.withValues(alpha: 0.5)
                            : AppColors.textMuted.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: e.value.$3.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.train_rounded,
                            color: e.value.$3, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.$1,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            Text(e.value.$2,
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Switch(
                            value: isActive,
                            activeThumbColor: e.value.$3,
                            onChanged: (val) =>
                                admin.togglePeakHour(e.key, val),
                          ),
                          Text(isActive ? 'PEAK' : 'OFF',
                              style: TextStyle(
                                  color: isActive
                                      ? AppColors.warning
                                      : AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 3: TIMETABLE EDITOR
// ═══════════════════════════════════════════════════════════

class _TimetableTab extends StatefulWidget {
  const _TimetableTab();
  @override
  State<_TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends State<_TimetableTab> {
  String _selectedLineId = 'blue';

  static const _lineDefaults = <String, (String, String, String)>{
    'blue': ('05:30', '23:50', '4'),
    'yellow': ('05:55', '22:30', '10'),
    'red': ('06:00', '22:00', '5'),
    'aqua': ('06:30', '22:30', '4'),
  };

  static const _lineLabels = <String, (String, Color)>{
    'blue': ('Blue Line (Line 1)', AppColors.blueLine),
    'yellow': ('Yellow Line (Line 2A)', AppColors.yellowLine),
    'red': ('Red Line (Line 7)', AppColors.redLine),
    'aqua': ('Aqua Line (Line 3)', AppColors.aquaLine),
  };

  @override
  Widget build(BuildContext context) {
    final metroData = MetroData();
    final admin = context.read<AdminProvider>();
    final selectedLine = metroData.getLine(_selectedLineId);
    final defaults = _lineDefaults[_selectedLineId]!;
    final label = _lineLabels[_selectedLineId]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Line Selector ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: label.$2.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Metro Line',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLineId,
                  dropdownColor: AppColors.surfaceLight,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: _lineLabels.entries
                      .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Row(children: [
                            Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: e.value.$2,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Text(e.value.$1),
                          ])))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedLineId = v);
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: label.$2.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: label.$2.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.schedule_rounded, color: label.$2, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Default: ${defaults.$1} – ${defaults.$2}  ·  Every ${defaults.$3} min',
                        style: TextStyle(
                            color: label.$2,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Line-Level Timing Editor ──
          _buildLineTimingEditor(context, admin, defaults, label),

          const SizedBox(height: 16),

          // ── Station List ──
          Text('Stations · ${selectedLine?.stations.length ?? 0}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          if (selectedLine != null)
            StreamBuilder<DocumentSnapshot>(
              stream: admin.timetableStream(_selectedLineId),
              builder: (ctx, snap) {
                final overrides =
                    (snap.data?.data() as Map<String, dynamic>?) ?? {};
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedLine.stations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, j) {
                    final station = selectedLine.stations[j];
                    final ov =
                        overrides[station.id] as Map<String, dynamic>?;
                    final hasOv = ov != null;
                    final dFirst = ov?['firstTrain'] ?? defaults.$1;
                    final dLast = ov?['lastTrain'] ?? defaults.$2;
                    final dFreq =
                        ov?['frequency']?.toString() ?? defaults.$3;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: hasOv
                            ? Border.all(
                                color: AppColors.success
                                    .withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              label.$2.withValues(alpha: 0.15),
                          child: Text('${j + 1}',
                              style: TextStyle(
                                  color: label.$2,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(
                                  child: Text(station.name,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ),
                                if (hasOv) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: const Text('CUSTOM',
                                        style: TextStyle(
                                            color: AppColors.success,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ]),
                              const SizedBox(height: 2),
                              Text(
                                  '$dFirst – $dLast · Every $dFreq min',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showStationEditDialog(
                              context, admin, selectedLine, station,
                              dFirst, dLast, dFreq),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: label.$2.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.edit_rounded,
                                color: label.$2, size: 14),
                          ),
                        ),
                      ]),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLineTimingEditor(
    BuildContext context,
    AdminProvider admin,
    (String, String, String) defaults,
    (String, Color) label,
  ) {
    final firstCtrl = TextEditingController(text: defaults.$1);
    final lastCtrl = TextEditingController(text: defaults.$2);
    final freqCtrl = TextEditingController(text: defaults.$3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: label.$2.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.edit_calendar_rounded, color: label.$2, size: 18),
            const SizedBox(width: 8),
            const Text('Edit Line Operating Hours',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextField(
                controller: firstCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'First Train',
                  prefixIcon: Icon(Icons.wb_sunny_outlined,
                      size: 16, color: AppColors.yellowLine),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: lastCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Last Train',
                  prefixIcon: Icon(Icons.nightlight_round,
                      size: 16, color: AppColors.aquaLine),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: freqCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Frequency (minutes)',
              prefixIcon: Icon(Icons.timer_outlined,
                  size: 16, color: AppColors.primary),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () async {
                await admin.saveStationTiming(
                  lineId: _selectedLineId,
                  stationId: '_line_config',
                  stationName: _lineLabels[_selectedLineId]!.$1,
                  firstTrain: firstCtrl.text.trim(),
                  lastTrain: lastCtrl.text.trim(),
                  frequency: int.tryParse(freqCtrl.text.trim()) ?? 5,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '${_lineLabels[_selectedLineId]!.$1} timings updated ✓')),
                  );
                }
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Line Timings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: label.$2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStationEditDialog(
    BuildContext context, AdminProvider admin, dynamic line, dynamic station,
    String curFirst, String curLast, String curFreq,
  ) {
    final firstCtrl = TextEditingController(text: curFirst);
    final lastCtrl = TextEditingController(text: curLast);
    final freqCtrl = TextEditingController(text: curFreq);
    final lineColor = _lineLabels[_selectedLineId]!.$2;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.edit_rounded, color: lineColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Edit ${station.name}',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'First Train', hintText: 'e.g. 05:30'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lastCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Last Train', hintText: 'e.g. 23:50'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: freqCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Frequency (min)', hintText: 'e.g. 5'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<AdminProvider>().saveStationTiming(
                    lineId: line.id,
                    stationId: station.id,
                    stationName: station.name,
                    firstTrain: firstCtrl.text.trim(),
                    lastTrain: lastCtrl.text.trim(),
                    frequency: int.tryParse(freqCtrl.text.trim()) ?? 5,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${station.name} timing saved ✓')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: lineColor),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 4: OPERATIONS (EMERGENCY & STATION STATUS)
// ═══════════════════════════════════════════════════════════

class _OperationsTab extends StatefulWidget {
  const _OperationsTab();
  @override
  State<_OperationsTab> createState() => _OperationsTabState();
}

class _OperationsTabState extends State<_OperationsTab> {
  final _emergencyMsgController = TextEditingController();
  String _emergencyType = 'Critical';
  
  String _selectedStationId = 'blue_andheri';
  final MetroData _metroData = MetroData();

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();
    // Get all stations across all lines for the dropdown
    final allStations = _metroData.lines.expand((line) => line.stations.map((s) => (line, s))).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- EMERGENCY ALERT ---
          const Text('Emergency Operations',
              style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<DocumentSnapshot>(
            stream: admin.emergencyStatusStream,
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final isActive = data['isActive'] ?? false;
              if (isActive && _emergencyMsgController.text.isEmpty) {
                _emergencyMsgController.text = data['message'] ?? '';
                _emergencyType = data['type'] ?? 'Critical';
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.error.withValues(alpha: 0.15) : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isActive ? AppColors.error : AppColors.surfaceLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Global Emergency Alert', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Switch(
                          value: isActive,
                          activeColor: AppColors.error,
                          onChanged: (val) {
                            if (!val) {
                              admin.setEmergencyAlert(isActive: false);
                              _emergencyMsgController.clear();
                            } else {
                              admin.setEmergencyAlert(isActive: true, message: _emergencyMsgController.text, type: _emergencyType);
                            }
                          },
                        ),
                      ],
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emergencyMsgController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Emergency Message'),
                        onChanged: (val) => admin.setEmergencyAlert(isActive: true, message: val, type: _emergencyType),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _emergencyType,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Severity Type'),
                        items: ['Critical', 'Warning'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _emergencyType = val);
                            admin.setEmergencyAlert(isActive: true, message: _emergencyMsgController.text, type: val);
                          }
                        },
                      ),
                    ]
                  ],
                ),
              );
            }
          ),

          const SizedBox(height: 24),

          // --- STATION MANAGEMENT ---
          const Text('Station Management',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          DropdownButtonFormField<String>(
            value: _selectedStationId,
            isExpanded: true,
            dropdownColor: AppColors.surfaceLight,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Select Station to Manage'),
            items: allStations.map((e) => DropdownMenuItem(
              value: e.$2.id,
              child: Text('${e.$2.name} (${e.$1.name})'),
            )).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedStationId = val);
            },
          ),
          
          const SizedBox(height: 16),

          StreamBuilder<DocumentSnapshot>(
            stream: admin.stationStatusStream(_selectedStationId),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final crowdLevel = data['crowdLevel'] as int? ?? 1;
              final facilities = Map<String, bool>.from(data['facilities'] as Map? ?? {
                'gate1': true,
                'gate2': true,
                'escalator': true,
                'lift': true,
              });

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Manual Crowd Density (Override)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('1 (Empty)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: crowdLevel.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: crowdLevel.toString(),
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              admin.updateStationStatus(_selectedStationId, crowdLevel: val.toInt());
                            },
                          ),
                        ),
                        const Text('5 (Overcrowded)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),

                    const Divider(color: AppColors.surfaceLight, height: 30),

                    const Text('Facility Status (Gates/Lifts)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    ...facilities.entries.map((e) => SwitchListTile(
                      title: Text(e.key.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                      subtitle: Text(e.value ? 'Operational' : 'Out of Service', style: TextStyle(color: e.value ? AppColors.success : AppColors.error, fontSize: 12)),
                      value: e.value,
                      activeColor: AppColors.success,
                      inactiveTrackColor: AppColors.error.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.error,
                      onChanged: (val) {
                        final updatedFacilities = Map<String, bool>.from(facilities);
                        updatedFacilities[e.key] = val;
                        admin.updateStationStatus(_selectedStationId, facilities: updatedFacilities);
                      },
                    )),
                  ],
                ),
              );
            }
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

