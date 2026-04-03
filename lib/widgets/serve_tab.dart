import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart'
    as cp;
import '../theme/app_theme.dart';
import '../models/person.dart';
import '../models/care_log.dart';
import '../models/serve_group.dart';
import '../models/constants.dart';
import '../screens/home_screen.dart';
import 'bottom_sheet_modal.dart';
import 'chip_selector.dart';

const _contactsChannel =
    MethodChannel('com.flutterplaza.pray_and_serve/contacts');

class ServeTab extends StatefulWidget {
  final String role;
  final int reminderDays;
  final List<Person> flock;
  final List<CareLog> careLogs;
  final List<ServeGroup> groups;
  final void Function(List<Person> Function(List<Person>)) onUpdateFlock;
  final void Function(List<CareLog> Function(List<CareLog>)) onUpdateCareLogs;
  final void Function(List<ServeGroup> Function(List<ServeGroup>))
      onUpdateGroups;
  final String? pendingText;
  final VoidCallback? onPendingConsumed;

  const ServeTab({
    super.key,
    required this.role,
    required this.reminderDays,
    required this.flock,
    required this.careLogs,
    required this.groups,
    required this.onUpdateFlock,
    required this.onUpdateCareLogs,
    required this.onUpdateGroups,
    this.pendingText,
    this.onPendingConsumed,
  });

  @override
  State<ServeTab> createState() => _ServeTabState();
}

class _ServeTabState extends State<ServeTab> {
  int _subTab = 0;
  String _searchText = '';
  final _searchController = TextEditingController();

  @override
  void didUpdateWidget(ServeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pendingText != null &&
        widget.pendingText != oldWidget.pendingText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showPersonModal(prefillNotes: widget.pendingText!);
          widget.onPendingConsumed?.call();
        }
      });
    }
  }

  String get _sectionTitle {
    switch (widget.role) {
      case 'Pastor':
        return 'My Flock';
      case 'Elder':
        return 'My Shepherding';
      case 'Deacon':
        return 'Those I Serve';
      default:
        return 'People On My Heart';
    }
  }

  List<Person> get _filteredFlock => widget.flock.where((p) {
        if (_searchText.isEmpty) return true;
        return p.name.toLowerCase().contains(_searchText.toLowerCase());
      }).toList();

  List<Person> get _overdueFlock => _filteredFlock
      .where((p) =>
          daysAgo(p.lastContact) >
          contactFreqToDays(p.contactFreq, widget.reminderDays))
      .toList();

  final _contactPicker = cp.FlutterNativeContactPicker();

  Future<void> _importFromContacts() async {
    try {
      final contact = await _contactPicker.selectContact();
      if (contact == null || !mounted) return;
      String? email;
      if (contact.fullName != null) {
        try {
          email = await _contactsChannel.invokeMethod<String>(
            'getEmailForContact',
            {'displayName': contact.fullName},
          );
        } catch (_) {
          // Email lookup not available — user can enter manually.
        }
      }
      if (!mounted) return;
      _showPersonModal(
        prefillName: contact.fullName,
        prefillEmail: email,
        prefillNotes: contact.phoneNumbers?.join(', '),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open contacts.')),
        );
      }
    }
  }

  void _showPersonModal({
    Person? existing,
    String? prefillNotes,
    String? prefillName,
    String? prefillEmail,
  }) {
    var name = existing?.name ?? (prefillName ?? '');
    var notes = existing?.notes ?? (prefillNotes ?? '');
    var email = existing?.email ?? (prefillEmail ?? '');
    var selectedTags = List<String>.from(existing?.tags ?? []);
    var selectedNeeds = List<String>.from(existing?.needs ?? []);
    var contactFreq = existing?.contactFreq ?? 'Monthly';

    showAppBottomSheet(
      context: context,
      title: existing != null ? 'Edit Person' : 'Add Someone to Care For',
      saveLabel: existing != null ? 'Update' : 'Add Person',
      canSave: () => name.trim().isNotEmpty,
      onSave: () {
        if (existing != null) {
          widget.onUpdateFlock((prev) => prev.map((p) {
                if (p.id == existing.id) {
                  p.name = name;
                  p.notes = notes;
                  p.email = email;
                  p.tags = selectedTags;
                  p.needs = selectedNeeds;
                  p.contactFreq = contactFreq;
                }
                return p;
              }).toList());
        } else {
          widget.onUpdateFlock((prev) => [
                Person(
                  id: const Uuid().v4(),
                  name: name,
                  notes: notes,
                  email: email,
                  tags: selectedTags,
                  needs: selectedNeeds,
                  contactFreq: contactFreq,
                ),
                ...prev,
              ]);
        }
      },
      bodyBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFieldLabel('Name'),
            TextField(
              autofocus: true,
              controller: TextEditingController(text: name),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Their name...',
              ),
              onChanged: (v) => name = v,
            ),
            buildFieldLabel('Email'),
            TextField(
              controller: TextEditingController(text: email),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'email@example.com (optional)',
              ),
              onChanged: (v) => email = v,
            ),
            buildFieldLabel('Notes about their situation'),
            TextField(
              controller: TextEditingController(text: notes),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What should you remember about them?',
              ),
              onChanged: (v) => notes = v,
            ),
            buildFieldLabel('Desired contact frequency'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: contactFreq,
                  isExpanded: true,
                  dropdownColor: AppColors.bgCard,
                  style: GoogleFonts.sourceSans3(
                      fontSize: 14, color: AppColors.textPrimary),
                  items: contactFrequencies
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => contactFreq = v ?? contactFreq),
                ),
              ),
            ),
            buildFieldLabel('Tags'),
            ChipSelector(
              options: careTags,
              selected: selectedTags,
              onToggle: (tag) {
                setModalState(() {
                  if (selectedTags.contains(tag)) {
                    selectedTags.remove(tag);
                  } else {
                    selectedTags.add(tag);
                  }
                });
              },
            ),
            if (['Deacon', 'Elder', 'Pastor'].contains(widget.role)) ...[
              buildFieldLabel('Needs'),
              ChipSelector(
                options: needTypes,
                selected: selectedNeeds,
                onToggle: (need) {
                  setModalState(() {
                    if (selectedNeeds.contains(need)) {
                      selectedNeeds.remove(need);
                    } else {
                      selectedNeeds.add(need);
                    }
                  });
                },
              ),
            ],
          ],
        );
      },
    );
  }

  List<Person> get _flockWithEmail =>
      widget.flock.where((p) => p.email.trim().isNotEmpty).toList();

  void _showGroupEmailModal() {
    final withEmail = _flockWithEmail;
    if (withEmail.isEmpty) return;

    final selected = <String>{...withEmail.map((p) => p.id)};
    var subject = '';
    var body = '';

    showAppBottomSheet(
      context: context,
      title: 'Email Group',
      saveLabel: 'Open Email App',
      canSave: () =>
          subject.trim().isNotEmpty &&
          body.trim().isNotEmpty &&
          selected.isNotEmpty,
      onSave: () {
        // Log a CareLog for each selected person.
        final now = todayStr();
        final logNote = 'Subject: $subject\n\n$body';
        for (final personId in selected) {
          widget.onUpdateCareLogs((prev) => [
                CareLog(
                  id: const Uuid().v4(),
                  personId: personId,
                  date: now,
                  type: 'Email',
                  note: logNote,
                ),
                ...prev,
              ]);
          widget.onUpdateFlock((prev) => prev.map((p) {
                if (p.id == personId) p.lastContact = now;
                return p;
              }).toList());
        }

        // Build mailto: with BCC.
        final bcc = withEmail
            .where((p) => selected.contains(p.id))
            .map((p) => p.email.trim())
            .join(',');
        final uri = Uri(
          scheme: 'mailto',
          query: 'bcc=${Uri.encodeComponent(bcc)}'
              '&subject=${Uri.encodeComponent(subject)}'
              '&body=${Uri.encodeComponent(body)}',
        );
        launchUrl(uri).then((launched) {
          if (!launched && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'No email app found. The email has been logged.')),
            );
          }
        });
      },
      bodyBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFieldLabel('Recipients (BCC)'),
            ...withEmail.map((p) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.gold,
                  checkColor: AppColors.bgDark,
                  title: Text(
                    '${p.name} (${p.email})',
                    style: GoogleFonts.sourceSans3(
                        fontSize: 13, color: AppColors.textPrimary),
                  ),
                  value: selected.contains(p.id),
                  onChanged: (v) {
                    setModalState(() {
                      if (v == true) {
                        selected.add(p.id);
                      } else {
                        selected.remove(p.id);
                      }
                    });
                  },
                )),
            const SizedBox(height: 4),
            Text(
              'Recipients will be in BCC — they won\'t see each other\'s email.',
              style: GoogleFonts.sourceSans3(
                  fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
            buildFieldLabel('Subject'),
            TextField(
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Email subject…',
              ),
              onChanged: (v) => subject = v,
            ),
            buildFieldLabel('Body'),
            TextField(
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Write your message…',
              ),
              onChanged: (v) => body = v,
            ),
          ],
        );
      },
    );
  }

  void _showLogContactModal(Person person) {
    var type = 'Call';
    var note = '';

    showAppBottomSheet(
      context: context,
      title: 'Log Contact \u2014 ${person.name}',
      saveLabel: 'Log Contact',
      canSave: () => note.trim().isNotEmpty,
      onSave: () {
        widget.onUpdateCareLogs((prev) => [
              CareLog(
                id: const Uuid().v4(),
                personId: person.id,
                date: todayStr(),
                type: type,
                note: note,
              ),
              ...prev,
            ]);
        widget.onUpdateFlock((prev) => prev.map((p) {
              if (p.id == person.id) {
                p.lastContact = todayStr();
              }
              return p;
            }).toList());
      },
      bodyBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFieldLabel('Contact type'),
            ChipSelector(
              options: contactTypes,
              selected: [type],
              singleSelect: true,
              onToggle: (t) => setModalState(() => type = t),
            ),
            buildFieldLabel('Notes'),
            TextField(
              autofocus: true,
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'How is ${person.name} doing? What did you talk about?',
              ),
              onChanged: (v) => note = v,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          // Title + actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _sectionTitle,
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_flockWithEmail.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.mail_outline,
                          size: 20, color: AppColors.gold),
                      tooltip: 'Email group',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: _showGroupEmailModal,
                    ),
                  IconButton(
                    icon: const Icon(Icons.contacts_outlined,
                        size: 20, color: AppColors.gold),
                    tooltip: 'From contacts',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: _importFromContacts,
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () => _showPersonModal(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Person'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sub-tabs
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildSubTab(0, 'People'),
                _buildSubTab(
                    1, 'Need Contact (${_overdueFlock.length})'),
                _buildSubTab(2, 'Groups'),
                _buildSubTab(3, 'Care Log'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Content based on sub-tab
          Expanded(
            child: IndexedStack(
              index: _subTab,
              children: [
                _buildPeopleList(),
                _buildOverdueList(),
                _buildGroupsList(),
                _buildCareLogList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab(int index, String label) {
    final selected = _subTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _subTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.bgChip : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.sourceSans3(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.gold : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ---- PEOPLE LIST ----
  Widget _buildPeopleList() {
    final sorted = List<Person>.from(_filteredFlock)
      ..sort((a, b) => daysAgo(b.lastContact).compareTo(daysAgo(a.lastContact)));

    return Column(
      children: [
        // Search
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.sourceSans3(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search people...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: GoogleFonts.sourceSans3(
                        fontSize: 14, color: AppColors.textDim),
                  ),
                  onChanged: (v) => setState(() => _searchText = v),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? _buildEmptyPeople()
              : ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildPersonCard(sorted[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyPeople() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u{1F91D}',
                style: TextStyle(
                    fontSize: 48,
                    color: AppColors.textMuted.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            Text(
              'No one added yet.',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Add the people God has placed on your heart to care for.',
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textDim),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard(Person person) {
    final overdue = daysAgo(person.lastContact) >
        contactFreqToDays(person.contactFreq, widget.reminderDays);
    final daysSince = daysAgo(person.lastContact);
    final daysText = daysSince >= 999999
        ? 'Never contacted'
        : daysSince == 0
            ? 'Today'
            : '${daysSince}d ago';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      foregroundDecoration: overdue
          ? BoxDecoration(
              border:
                  Border(left: BorderSide(color: AppColors.coral, width: 3)),
              borderRadius: BorderRadius.circular(14),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  person.name.isNotEmpty
                      ? person.name[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bgDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (person.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: person.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgChip,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag.toUpperCase(),
                                      style: GoogleFonts.sourceSans3(
                                        fontSize: 10,
                                        color: AppColors.gold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              // Days indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (overdue)
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: AppColors.coral),
                  Text(
                    daysText,
                    style: GoogleFonts.sourceSans3(
                      fontSize: 13,
                      color: overdue ? AppColors.coral : AppColors.textMuted,
                      fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Needs row
          if (person.needs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    'NEEDS:',
                    style: GoogleFonts.sourceSans3(
                      fontSize: 12,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: person.needs
                          .map((n) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  n,
                                  style: GoogleFonts.sourceSans3(
                                      fontSize: 11,
                                      color: AppColors.textPrimary),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

          // Notes
          if (person.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                person.notes,
                style: GoogleFonts.sourceSans3(
                    fontSize: 13, color: AppColors.textMuted, height: 1.5),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                _buildLogContactButton(person),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 14, color: AppColors.textMuted),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  onPressed: () => _showPersonModal(existing: person),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 14, color: AppColors.textMuted),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  onPressed: () => _confirmDeletePerson(person),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogContactButton(Person person) {
    return GestureDetector(
      onTap: () => _showLogContactModal(person),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgChip,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_outlined,
                size: 14, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(
              'Log Contact',
              style: GoogleFonts.sourceSans3(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePerson(Person person) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Remove ${person.name}?',
            style: GoogleFonts.cormorantGaramond(
                color: AppColors.textPrimary, fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onUpdateFlock(
                  (prev) => prev.where((x) => x.id != person.id).toList());
              widget.onUpdateCareLogs((prev) =>
                  prev.where((x) => x.personId != person.id).toList());
              Navigator.pop(ctx);
            },
            child:
                const Text('Remove', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  // ---- OVERDUE LIST ----
  Widget _buildOverdueList() {
    final overdue = _overdueFlock
      ..sort(
          (a, b) => daysAgo(b.lastContact).compareTo(daysAgo(a.lastContact)));

    if (overdue.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\u2713',
                  style: TextStyle(
                      fontSize: 48,
                      color: AppColors.textMuted.withValues(alpha: 0.6))),
              const SizedBox(height: 16),
              Text(
                'Everyone is cared for!',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 20, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Everyone is within their contact schedule.',
                style: GoogleFonts.sourceSans3(
                    fontSize: 14, color: AppColors.textDim),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: overdue.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final person = overdue[i];
        final daysSince = daysAgo(person.lastContact);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundDecoration: BoxDecoration(
            border:
                Border(left: BorderSide(color: AppColors.coral, width: 3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      person.name[0].toUpperCase(),
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          daysSince >= 999999
                              ? 'Never contacted'
                              : '$daysSince days since last contact',
                          style: GoogleFonts.sourceSans3(
                            fontSize: 13,
                            color: AppColors.coral,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showLogContactModal(person),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bgChip,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 14, color: AppColors.gold),
                          const SizedBox(width: 6),
                          Text(
                            'Reach Out',
                            style: GoogleFonts.sourceSans3(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (person.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    person.notes,
                    style: GoogleFonts.sourceSans3(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.5),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ---- GROUPS LIST ----
  Widget _buildGroupsList() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showGroupModal(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Group'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: widget.groups.isEmpty
              ? Center(
                  child: Text(
                    'Create groups to email or text\nmultiple people at once.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sourceSans3(
                        fontSize: 14, color: AppColors.textMuted),
                  ),
                )
              : ListView.separated(
                  itemCount: widget.groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) =>
                      _buildGroupCard(widget.groups[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(ServeGroup group) {
    final members =
        widget.flock.where((p) => group.personIds.contains(p.id)).toList();
    final memberNames =
        members.map((p) => p.name).join(', ');
    final emailCount = members.where((p) => p.email.trim().isNotEmpty).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
              Text(
                '${members.length} people',
                style: GoogleFonts.sourceSans3(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          if (memberNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              memberNames,
              style: GoogleFonts.sourceSans3(
                  fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (emailCount > 0)
                _groupActionButton(
                  icon: Icons.mail_outline,
                  label: 'BCC Email',
                  onTap: () => _showGroupEmailModalForGroup(group),
                ),
              if (emailCount > 0) const SizedBox(width: 8),
              _groupActionButton(
                icon: Icons.sms_outlined,
                label: 'Broadcast Text',
                onTap: () => _showBroadcastTextModal(group),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.textMuted),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () => _showGroupModal(existing: group),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.textMuted),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () {
                  widget.onUpdateGroups(
                      (prev) => prev.where((g) => g.id != group.id).toList());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: const BorderSide(color: AppColors.gold),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: GoogleFonts.sourceSans3(fontSize: 12),
      ),
    );
  }

  void _showGroupModal({ServeGroup? existing}) {
    var name = existing?.name ?? '';
    var selectedIds = <String>{...existing?.personIds ?? []};

    showAppBottomSheet(
      context: context,
      title: existing != null ? 'Edit Group' : 'New Group',
      saveLabel: existing != null ? 'Update' : 'Create Group',
      canSave: () => name.trim().isNotEmpty && selectedIds.isNotEmpty,
      onSave: () {
        if (existing != null) {
          widget.onUpdateGroups((prev) => prev.map((g) {
                if (g.id == existing.id) {
                  g.name = name;
                  g.personIds = selectedIds.toList();
                }
                return g;
              }).toList());
        } else {
          widget.onUpdateGroups((prev) => [
                ServeGroup(
                  id: const Uuid().v4(),
                  name: name,
                  personIds: selectedIds.toList(),
                ),
                ...prev,
              ]);
        }
      },
      bodyBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFieldLabel('Group Name'),
            TextField(
              autofocus: true,
              controller: TextEditingController(text: name),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g., Small Group, Elders, Youth…',
              ),
              onChanged: (v) => name = v,
            ),
            buildFieldLabel('Members'),
            ...widget.flock.map((p) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.gold,
                  checkColor: AppColors.bgDark,
                  title: Text(
                    p.name,
                    style: GoogleFonts.sourceSans3(
                        fontSize: 13, color: AppColors.textPrimary),
                  ),
                  subtitle: p.email.trim().isNotEmpty
                      ? Text(p.email,
                          style: GoogleFonts.sourceSans3(
                              fontSize: 11, color: AppColors.textMuted))
                      : null,
                  value: selectedIds.contains(p.id),
                  onChanged: (v) {
                    setModalState(() {
                      if (v == true) {
                        selectedIds.add(p.id);
                      } else {
                        selectedIds.remove(p.id);
                      }
                    });
                  },
                )),
          ],
        );
      },
    );
  }

  void _showGroupEmailModalForGroup(ServeGroup group) {
    final members =
        widget.flock.where((p) => group.personIds.contains(p.id)).toList();
    final withEmail = members.where((p) => p.email.trim().isNotEmpty).toList();
    if (withEmail.isEmpty) return;

    final selected = <String>{...withEmail.map((p) => p.id)};
    var subject = '';
    var body = '';

    showAppBottomSheet(
      context: context,
      title: 'Email \u2014 ${group.name}',
      saveLabel: 'Open Email App',
      canSave: () =>
          subject.trim().isNotEmpty &&
          body.trim().isNotEmpty &&
          selected.isNotEmpty,
      onSave: () {
        final now = todayStr();
        final logNote = 'Subject: $subject\n\n$body';
        for (final personId in selected) {
          widget.onUpdateCareLogs((prev) => [
                CareLog(
                  id: const Uuid().v4(),
                  personId: personId,
                  date: now,
                  type: 'Email',
                  note: logNote,
                ),
                ...prev,
              ]);
          widget.onUpdateFlock((prev) => prev.map((p) {
                if (p.id == personId) p.lastContact = now;
                return p;
              }).toList());
        }

        final bcc = withEmail
            .where((p) => selected.contains(p.id))
            .map((p) => p.email.trim())
            .join(',');
        final uri = Uri(
          scheme: 'mailto',
          query: 'bcc=${Uri.encodeComponent(bcc)}'
              '&subject=${Uri.encodeComponent(subject)}'
              '&body=${Uri.encodeComponent(body)}',
        );
        launchUrl(uri);
      },
      bodyBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFieldLabel('Recipients (BCC)'),
            ...withEmail.map((p) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.gold,
                  checkColor: AppColors.bgDark,
                  title: Text(
                    '${p.name} (${p.email})',
                    style: GoogleFonts.sourceSans3(
                        fontSize: 13, color: AppColors.textPrimary),
                  ),
                  value: selected.contains(p.id),
                  onChanged: (v) {
                    setModalState(() {
                      if (v == true) {
                        selected.add(p.id);
                      } else {
                        selected.remove(p.id);
                      }
                    });
                  },
                )),
            const SizedBox(height: 4),
            Text(
              'Recipients will be in BCC \u2014 they won\'t see each other\'s email.',
              style: GoogleFonts.sourceSans3(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic),
            ),
            buildFieldLabel('Subject'),
            TextField(
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Email subject\u2026'),
              onChanged: (v) => subject = v,
            ),
            buildFieldLabel('Body'),
            TextField(
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              maxLines: 6,
              decoration:
                  const InputDecoration(hintText: 'Write your message\u2026'),
              onChanged: (v) => body = v,
            ),
          ],
        );
      },
    );
  }

  void _showBroadcastTextModal(ServeGroup group) {
    final members =
        widget.flock.where((p) => group.personIds.contains(p.id)).toList();
    final withPhone = members
        .where((p) => p.notes.trim().isNotEmpty)
        .toList();
    var message = '';

    showAppBottomSheet(
      context: context,
      title: 'Text \u2014 ${group.name}',
      saveLabel: 'Open Messages App',
      canSave: () => message.trim().isNotEmpty,
      onSave: () {
        final now = todayStr();
        // Log contact for each member.
        for (final person in members) {
          widget.onUpdateCareLogs((prev) => [
                CareLog(
                  id: const Uuid().v4(),
                  personId: person.id,
                  date: now,
                  type: 'Text',
                  note: message,
                ),
                ...prev,
              ]);
          widget.onUpdateFlock((prev) => prev.map((p) {
                if (p.id == person.id) p.lastContact = now;
                return p;
              }).toList());
        }

        // Build sms: URI with all phone numbers.
        final phones = withPhone
            .map((p) => p.notes.split(',').first.trim())
            .where((n) => n.isNotEmpty)
            .join(',');
        if (phones.isNotEmpty) {
          final uri = Uri(
            scheme: 'sms',
            path: phones,
            queryParameters: {'body': message},
          );
          launchUrl(uri);
        }
      },
      bodyBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFieldLabel(
                'Sending to ${members.length} people in ${group.name}'),
            ...members.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '\u2022 ${p.name}',
                    style: GoogleFonts.sourceSans3(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                )),
            buildFieldLabel('Message'),
            TextField(
              autofocus: true,
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write your message\u2026',
              ),
              onChanged: (v) => message = v,
            ),
          ],
        );
      },
    );
  }

  // ---- CARE LOG LIST ----
  Widget _buildCareLogList() {
    final sorted = List<CareLog>.from(widget.careLogs)
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sorted.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\u{1F4DD}',
                  style: TextStyle(
                      fontSize: 48,
                      color: AppColors.textMuted.withValues(alpha: 0.6))),
              const SizedBox(height: 16),
              Text(
                'No care logs yet.',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 20, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Log your contacts and visits to keep track of your care.',
                style: GoogleFonts.sourceSans3(
                    fontSize: 14, color: AppColors.textDim),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final log = sorted[i];
        final person = widget.flock.where((p) => p.id == log.personId).firstOrNull;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      person != null ? person.name[0] : '?',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person?.name ?? 'Unknown',
                          style: GoogleFonts.sourceSans3(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          formatDate(log.date),
                          style: GoogleFonts.sourceSans3(
                              fontSize: 12, color: AppColors.textDim),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.bgChip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.type,
                      style: GoogleFonts.sourceSans3(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 13, color: AppColors.textMuted),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () => widget.onUpdateCareLogs(
                        (prev) => prev.where((x) => x.id != log.id).toList()),
                  ),
                ],
              ),
              if (log.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    log.note,
                    style: GoogleFonts.sourceSans3(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
