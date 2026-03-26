import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../models/prayer.dart';
import '../models/journal_entry.dart';
import '../models/person.dart';
import '../models/care_log.dart';
import '../models/constants.dart';
import '../widgets/pray_tab.dart';
import '../widgets/journal_tab.dart';
import '../widgets/serve_tab.dart';

int daysAgo(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 999999;
  final diff = DateTime.now().difference(DateTime.parse(dateStr));
  return diff.inDays;
}

String todayStr() => DateTime.now().toIso8601String().split('T')[0];

String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'Never';
  final d = DateTime.parse(dateStr);
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

int contactFreqToDays(String freq, int fallback) {
  switch (freq) {
    case 'Weekly':
      return 7;
    case 'Biweekly':
      return 14;
    case 'Monthly':
      return 30;
    case 'Quarterly':
      return 90;
    default:
      return fallback;
  }
}

class HomeScreen extends StatefulWidget {
  final StorageService storage;
  final NotificationService notifications;
  const HomeScreen({
    super.key,
    required this.storage,
    required this.notifications,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  String _role = 'Member';
  int _reminderDays = 14;
  bool _showSettings = false;

  List<Prayer> _prayers = [];
  List<JournalEntry> _journal = [];
  List<Person> _flock = [];
  List<CareLog> _careLogs = [];

  bool _prayReminderEnabled = false;
  TimeOfDay _prayReminderTime = const TimeOfDay(hour: 7, minute: 0);
  bool _journalReminderEnabled = false;
  TimeOfDay _journalReminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _serveReminderEnabled = false;
  TimeOfDay _serveReminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _role = widget.storage.getRole();
      _reminderDays = widget.storage.getReminderDays();
      _prayers = widget.storage.getPrayers();
      _journal = widget.storage.getJournal();
      _flock = widget.storage.getFlock();
      _careLogs = widget.storage.getCareLogs();
      _prayReminderEnabled = widget.storage.getPrayReminderEnabled();
      _prayReminderTime = TimeOfDay(
        hour: widget.storage.getPrayReminderHour(),
        minute: widget.storage.getPrayReminderMinute(),
      );
      _journalReminderEnabled = widget.storage.getJournalReminderEnabled();
      _journalReminderTime = TimeOfDay(
        hour: widget.storage.getJournalReminderHour(),
        minute: widget.storage.getJournalReminderMinute(),
      );
      _serveReminderEnabled = widget.storage.getServeReminderEnabled();
      _serveReminderTime = TimeOfDay(
        hour: widget.storage.getServeReminderHour(),
        minute: widget.storage.getServeReminderMinute(),
      );
    });
  }

  // Stats
  int get totalPrayers => _prayers.length;
  int get answeredPrayers => _prayers.where((p) => p.answered).length;
  int get pressingPrayers =>
      _prayers.where((p) => p.urgency == 'Pressing' && !p.answered).length;
  int get overdueContacts => _flock
      .where((p) =>
          daysAgo(p.lastContact) >
          contactFreqToDays(p.contactFreq, _reminderDays))
      .length;

  // Prayer CRUD
  void updatePrayers(List<Prayer> Function(List<Prayer>) fn) {
    setState(() {
      _prayers = fn(List.from(_prayers));
      widget.storage.savePrayers(_prayers);
    });
  }

  // Journal CRUD
  void updateJournal(List<JournalEntry> Function(List<JournalEntry>) fn) {
    setState(() {
      _journal = fn(List.from(_journal));
      widget.storage.saveJournal(_journal);
    });
  }

  // Flock CRUD
  void updateFlock(List<Person> Function(List<Person>) fn) {
    setState(() {
      _flock = fn(List.from(_flock));
      widget.storage.saveFlock(_flock);
    });
  }

  // CareLog CRUD
  void updateCareLogs(List<CareLog> Function(List<CareLog>) fn) {
    setState(() {
      _careLogs = fn(List.from(_careLogs));
      widget.storage.saveCareLogs(_careLogs);
    });
  }

  void _setRole(String role) {
    setState(() => _role = role);
    widget.storage.setRole(role);
  }

  void _setReminderDays(int days) {
    setState(() => _reminderDays = days);
    widget.storage.setReminderDays(days);
  }

  // Notification toggles
  Future<void> _togglePrayReminder(bool enabled) async {
    if (enabled) {
      await widget.notifications.requestPermission();
      await widget.notifications.scheduleDailyPrayerReminder(_prayReminderTime);
    } else {
      await widget.notifications.cancelPrayerReminder();
    }
    setState(() => _prayReminderEnabled = enabled);
    widget.storage.setPrayReminderEnabled(enabled);
  }

  Future<void> _pickPrayReminderTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: _prayReminderTime);
    if (picked != null) {
      setState(() => _prayReminderTime = picked);
      widget.storage.setPrayReminderTime(picked.hour, picked.minute);
      if (_prayReminderEnabled) {
        await widget.notifications.scheduleDailyPrayerReminder(picked);
      }
    }
  }

  Future<void> _toggleJournalReminder(bool enabled) async {
    if (enabled) {
      await widget.notifications.requestPermission();
      await widget.notifications
          .scheduleJournalReminder(_journalReminderTime);
    } else {
      await widget.notifications.cancelJournalReminder();
    }
    setState(() => _journalReminderEnabled = enabled);
    widget.storage.setJournalReminderEnabled(enabled);
  }

  Future<void> _pickJournalReminderTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: _journalReminderTime);
    if (picked != null) {
      setState(() => _journalReminderTime = picked);
      widget.storage.setJournalReminderTime(picked.hour, picked.minute);
      if (_journalReminderEnabled) {
        await widget.notifications.scheduleJournalReminder(picked);
      }
    }
  }

  Future<void> _toggleServeReminder(bool enabled) async {
    if (enabled) {
      await widget.notifications.requestPermission();
      await widget.notifications
          .scheduleServeCheckReminder(_serveReminderTime);
    } else {
      await widget.notifications.cancelServeReminder();
    }
    setState(() => _serveReminderEnabled = enabled);
    widget.storage.setServeReminderEnabled(enabled);
  }

  Future<void> _pickServeReminderTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: _serveReminderTime);
    if (picked != null) {
      setState(() => _serveReminderTime = picked);
      widget.storage.setServeReminderTime(picked.hour, picked.minute);
      if (_serveReminderEnabled) {
        await widget.notifications.scheduleServeCheckReminder(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Reserve at least 150px for tab content; cap header height on short screens.
    final maxHeaderHeight = (screenHeight - 150).clamp(150.0, screenHeight);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      body: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeaderHeight),
            child: _buildHeader(),
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                PrayTab(
                  prayers: _prayers,
                  onUpdate: updatePrayers,
                ),
                JournalTab(
                  journal: _journal,
                  onUpdate: updateJournal,
                ),
                ServeTab(
                  role: _role,
                  reminderDays: _reminderDays,
                  flock: _flock,
                  careLogs: _careLogs,
                  onUpdateFlock: updateFlock,
                  onUpdateCareLogs: updateCareLogs,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgHeader, AppColors.bgDark],
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo & Settings
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Text(
                    '\u271D',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pray & Serve',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 1,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'YOUR PRIVATE WALK WITH GOD',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.sourceSans3(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          size: 18, color: AppColors.gold),
                      onPressed: () =>
                          setState(() => _showSettings = !_showSettings),
                    ),
                  ),
                ],
              ),
            ),

            // Settings Panel + Stats (scrollable when space is tight)
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showSettings) _buildSettingsPanel(),
                    _buildStatsBar(),
                  ],
                ),
              ),
            ),

            // Tab Bar
            _buildTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgSubtle,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Role',
                  style: GoogleFonts.sourceSans3(
                      fontSize: 14, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _role,
                    dropdownColor: AppColors.bgCard,
                    style: GoogleFonts.sourceSans3(
                        fontSize: 14, color: AppColors.textPrimary),
                    items: roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _setRole(v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Contact Reminder (days)',
                  style: GoogleFonts.sourceSans3(
                      fontSize: 14, color: AppColors.textSecondary)),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: TextEditingController(
                      text: _reminderDays.toString()),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.sourceSans3(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  onSubmitted: (v) {
                    final days = int.tryParse(v) ?? 7;
                    _setReminderDays(days);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('REMINDERS',
                style: GoogleFonts.sourceSans3(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 4),
          _buildReminderRow(
            label: 'Pray',
            enabled: _prayReminderEnabled,
            time: _prayReminderTime,
            onToggle: _togglePrayReminder,
            onPickTime: _pickPrayReminderTime,
          ),
          _buildReminderRow(
            label: 'Journal',
            enabled: _journalReminderEnabled,
            time: _journalReminderTime,
            onToggle: _toggleJournalReminder,
            onPickTime: _pickJournalReminderTime,
          ),
          _buildReminderRow(
            label: 'Serve',
            enabled: _serveReminderEnabled,
            time: _serveReminderTime,
            onToggle: _toggleServeReminder,
            onPickTime: _pickServeReminderTime,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderRow({
    required String label,
    required bool enabled,
    required TimeOfDay time,
    required Future<void> Function(bool) onToggle,
    required Future<void> Function() onPickTime,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.sourceSans3(
                fontSize: 14, color: AppColors.textSecondary)),
        Row(
          children: [
            if (enabled)
              GestureDetector(
                onTap: onPickTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    time.format(context),
                    style: GoogleFonts.sourceSans3(
                        fontSize: 13, color: AppColors.gold),
                  ),
                ),
              ),
            SizedBox(
              height: 32,
              child: Switch.adaptive(
                value: enabled,
                activeTrackColor: AppColors.gold,
                onChanged: onToggle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStat(totalPrayers.toString(), 'Prayers', AppColors.gold),
            _buildStatDivider(),
            _buildStat(
                answeredPrayers.toString(), 'Answered', AppColors.green),
            _buildStatDivider(),
            _buildStat(
                pressingPrayers.toString(),
                'Pressing',
                pressingPrayers > 0 ? AppColors.coral : AppColors.gold),
            if (_role != 'Member') ...[
              _buildStatDivider(),
              _buildStat(
                  overdueContacts.toString(),
                  'Need Contact',
                  overdueContacts > 0 ? AppColors.coral : AppColors.gold),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.sourceSans3(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      _TabDef(icon: Icons.favorite_outline, label: 'Pray', badge: 0),
      _TabDef(icon: Icons.menu_book_outlined, label: 'Journal', badge: 0),
      _TabDef(
          icon: Icons.people_outline,
          label: 'Serve',
          badge: overdueContacts),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final selected = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          selected ? AppColors.gold : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 16,
                          color: selected
                              ? AppColors.gold
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            tab.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.sourceSans3(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (tab.badge > 0)
                      Positioned(
                        top: -4,
                        right: 16,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tab.badge.toString(),
                            style: GoogleFonts.sourceSans3(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final String label;
  final int badge;
  _TabDef({required this.icon, required this.label, this.badge = 0});
}
