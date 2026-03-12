import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/prayer.dart';
import '../models/constants.dart';
import '../screens/home_screen.dart';
import 'bottom_sheet_modal.dart';

class PrayTab extends StatefulWidget {
  final List<Prayer> prayers;
  final void Function(List<Prayer> Function(List<Prayer>)) onUpdate;

  const PrayTab({super.key, required this.prayers, required this.onUpdate});

  @override
  State<PrayTab> createState() => _PrayTabState();
}

class _PrayTabState extends State<PrayTab> {
  String _filter = 'all';
  String _searchText = '';
  final _searchController = TextEditingController();

  List<Prayer> get _filteredPrayers {
    return widget.prayers.where((p) {
      if (_filter == 'answered') return p.answered;
      if (_filter == 'unanswered') return !p.answered;
      if (_filter == 'pressing') return p.urgency == 'Pressing' && !p.answered;
      if (categories.contains(_filter)) {
        return p.category == _filter && !p.answered;
      }
      return !p.answered;
    }).where((p) {
      if (_searchText.isEmpty) return true;
      final q = _searchText.toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.details.toLowerCase().contains(q);
    }).toList();
  }

  void _showPrayerModal({Prayer? existing}) {
    var title = existing?.title ?? '';
    var details = existing?.details ?? '';
    var category = existing?.category ?? 'Personal';
    var urgency = existing?.urgency ?? 'Ongoing';
    var scripture = existing?.scripture ?? '';
    var recurrence = existing?.recurrence ?? 'None';

    showAppBottomSheet(
      context: context,
      title: existing != null ? 'Edit Prayer' : 'New Prayer Request',
      saveLabel: existing != null ? 'Update' : 'Add Prayer',
      canSave: () => title.trim().isNotEmpty,
      onSave: () {
        if (existing != null) {
          widget.onUpdate((prev) => prev.map((p) {
                if (p.id == existing.id) {
                  p.title = title;
                  p.details = details;
                  p.category = category;
                  p.urgency = urgency;
                  p.scripture = scripture;
                  p.recurrence = recurrence;
                }
                return p;
              }).toList());
        } else {
          widget.onUpdate((prev) => [
                Prayer(
                  id: const Uuid().v4(),
                  title: title,
                  details: details,
                  category: category,
                  urgency: urgency,
                  scripture: scripture,
                  recurrence: recurrence,
                  createdAt: todayStr(),
                ),
                ...prev,
              ]);
        }
      },
      bodyBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFieldLabel('What would you like to pray for?'),
            TextField(
              autofocus: true,
              controller: TextEditingController(text: title),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g., Healing for Mom\'s recovery',
              ),
              onChanged: (v) => title = v,
            ),
            buildFieldLabel('Details (optional)'),
            TextField(
              controller: TextEditingController(text: details),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Pour out your heart...',
              ),
              onChanged: (v) => details = v,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildFieldLabel('Category'),
                      _buildDropdown(
                        value: category,
                        items: categories,
                        onChanged: (v) =>
                            setModalState(() => category = v ?? category),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildFieldLabel('Urgency'),
                      _buildDropdown(
                        value: urgency,
                        items: urgencyLevels,
                        onChanged: (v) =>
                            setModalState(() => urgency = v ?? urgency),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            buildFieldLabel('Recurring'),
            _buildDropdown(
              value: recurrence,
              items: recurrenceOptions,
              onChanged: (v) =>
                  setModalState(() => recurrence = v ?? recurrence),
            ),
            buildFieldLabel('Scripture to pray through (optional)'),
            TextField(
              controller: TextEditingController(text: scripture),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g., Philippians 4:6-7',
              ),
              onChanged: (v) => scripture = v,
            ),
          ],
        );
      },
    );
  }

  void _showAnswerModal(Prayer prayer) {
    var note = '';

    showAppBottomSheet(
      context: context,
      title: '\u{1F64C} Prayer Answered!',
      saveLabel: 'Mark as Answered',
      saveColor: AppColors.green,
      onSave: () {
        widget.onUpdate((prev) => prev.map((p) {
              if (p.id == prayer.id) {
                p.answered = true;
                p.answeredAt = todayStr();
                p.answerNote = note;
              }
              return p;
            }).toList());
      },
      bodyBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${prayer.title}"',
              style: GoogleFonts.sourceSans3(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            buildFieldLabel('How did God answer this prayer?'),
            TextField(
              autofocus: true,
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Record God\'s faithfulness...',
              ),
              onChanged: (v) => note = v,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.bgCard,
          style:
              GoogleFonts.sourceSans3(fontSize: 14, color: AppColors.textPrimary),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPrayers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          // Search & Add button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.sourceSans3(
                              fontSize: 14, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search prayers...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: true,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: GoogleFonts.sourceSans3(
                              fontSize: 14,
                              color: AppColors.textDim,
                            ),
                          ),
                          onChanged: (v) => setState(() => _searchText = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showPrayerModal(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Prayer'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...['all', 'unanswered', 'pressing', 'answered'].map(
                  (f) => _buildFilterChip(
                    f == 'all' ? 'Active' : '${f[0].toUpperCase()}${f.substring(1)}',
                    f,
                  ),
                ),
                ...categories.map((c) => _buildFilterChip(c, c)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Prayer list
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _buildPrayerCard(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() {
          if (categories.contains(value)) {
            _filter = _filter == value ? 'all' : value;
          } else {
            _filter = value;
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.sourceSans3(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.bgDark : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u{1F64F}',
                style: const TextStyle(fontSize: 48).copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            Text(
              _filter == 'answered'
                  ? 'No answered prayers yet \u2014 keep trusting God.'
                  : 'No prayers here yet.',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Pour out your heart to Him.',
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textDim),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(Prayer p) {
    final urgencyColor = p.urgency == 'Pressing'
        ? AppColors.coral
        : p.urgency == 'Ongoing'
            ? AppColors.gold
            : AppColors.olive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        // Left border accent
      ),
      foregroundDecoration: p.answered
          ? BoxDecoration(
              border: Border(
                  left: BorderSide(color: AppColors.green, width: 3)),
              borderRadius: BorderRadius.circular(14),
            )
          : p.urgency == 'Pressing'
              ? BoxDecoration(
                  border: Border(
                      left: BorderSide(color: AppColors.coral, width: 3)),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: urgencyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      p.category.toUpperCase(),
                      style: GoogleFonts.sourceSans3(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (p.recurrence != 'None')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.bgChip,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '\u21BB ${p.recurrence}',
                          style: GoogleFonts.sourceSans3(
                              fontSize: 11, color: AppColors.gold),
                        ),
                      ),
                    if (p.answered)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.greenBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '\u2713 Answered',
                          style: GoogleFonts.sourceSans3(
                            fontSize: 11,
                            color: AppColors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!p.answered)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline,
                          size: 16, color: AppColors.green),
                      tooltip: 'Mark Answered',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: () => _showAnswerModal(p),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 14, color: AppColors.textMuted),
                    tooltip: 'Edit',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _showPrayerModal(existing: p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 14, color: AppColors.textMuted),
                    tooltip: 'Delete',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _confirmDelete(p),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            p.title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (p.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(p.details,
                style: GoogleFonts.sourceSans3(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ],
          if (p.scripture.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '\u{1F4D6} ${p.scripture}',
              style: GoogleFonts.sourceSans3(
                fontSize: 13,
                color: AppColors.gold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (p.answered && p.answerNote != null && p.answerNote!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'How God Answered: ',
                      style: GoogleFonts.sourceSans3(
                        fontSize: 14,
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: p.answerNote,
                      style: GoogleFonts.sourceSans3(
                        fontSize: 14,
                        color: AppColors.greenText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          // Footer dates
          Row(
            children: [
              Text('Created ${formatDate(p.createdAt)}',
                  style: GoogleFonts.sourceSans3(
                      fontSize: 12, color: AppColors.textDim)),
              if (p.answered && p.answeredAt != null) ...[
                const SizedBox(width: 16),
                Text('Answered ${formatDate(p.answeredAt)}',
                    style: GoogleFonts.sourceSans3(
                        fontSize: 12, color: AppColors.textDim)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Prayer p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Remove this prayer?',
            style: GoogleFonts.cormorantGaramond(
                color: AppColors.textPrimary, fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onUpdate(
                  (prev) => prev.where((x) => x.id != p.id).toList());
              Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }
}
