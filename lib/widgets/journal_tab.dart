import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/journal_entry.dart';
import '../screens/home_screen.dart';
import 'bottom_sheet_modal.dart';

class JournalTab extends StatelessWidget {
  final List<JournalEntry> journal;
  final void Function(List<JournalEntry> Function(List<JournalEntry>)) onUpdate;

  const JournalTab({super.key, required this.journal, required this.onUpdate});

  void _showJournalModal(BuildContext context, {JournalEntry? existing}) {
    var title = existing?.title ?? '';
    var body = existing?.body ?? '';
    var scripture = existing?.scripture ?? '';
    var reflection = existing?.reflection ?? '';

    showAppBottomSheet(
      context: context,
      title: existing != null ? 'Edit Entry' : 'Journal Entry',
      saveLabel: existing != null ? 'Update' : 'Save Entry',
      canSave: () => body.trim().isNotEmpty,
      onSave: () {
        if (existing != null) {
          onUpdate((prev) => prev.map((j) {
                if (j.id == existing.id) {
                  j.title = title;
                  j.body = body;
                  j.scripture = scripture;
                  j.reflection = reflection;
                }
                return j;
              }).toList());
        } else {
          onUpdate((prev) => [
                JournalEntry(
                  id: const Uuid().v4(),
                  date: todayStr(),
                  title: title,
                  body: body,
                  scripture: scripture,
                  reflection: reflection,
                ),
                ...prev,
              ]);
        }
      },
      bodyBuilder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFieldLabel('Title (optional)'),
            TextField(
              autofocus: true,
              controller: TextEditingController(text: title),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'A word for today...',
              ),
              onChanged: (v) => title = v,
            ),
            buildFieldLabel("What's on your heart?"),
            TextField(
              controller: TextEditingController(text: body),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Write freely...',
              ),
              onChanged: (v) => body = v,
            ),
            buildFieldLabel('Scripture reference (optional)'),
            TextField(
              controller: TextEditingController(text: scripture),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g., Psalm 23',
              ),
              onChanged: (v) => scripture = v,
            ),
            buildFieldLabel('What is God teaching me? (optional)'),
            TextField(
              controller: TextEditingController(text: reflection),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reflect on His voice...',
              ),
              onChanged: (v) => reflection = v,
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Delete this entry?',
            style: GoogleFonts.cormorantGaramond(
                color: AppColors.textPrimary, fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onUpdate(
                  (prev) => prev.where((x) => x.id != entry.id).toList());
              Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<JournalEntry>.from(journal)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          // Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Prayer Journal',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showJournalModal(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Entry'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Entries list
          Expanded(
            child: sorted.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) =>
                        _buildJournalCard(context, sorted[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u{1F4D6}',
                style: TextStyle(
                    fontSize: 48,
                    color: AppColors.textMuted.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            Text(
              'Your journal is empty.',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Write what God is placing on your heart.',
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.textDim),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalCard(BuildContext context, JournalEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDate(entry.date),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 14, color: AppColors.textMuted),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () =>
                        _showJournalModal(context, existing: entry),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 14, color: AppColors.textMuted),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _confirmDelete(context, entry),
                  ),
                ],
              ),
            ],
          ),
          if (entry.title.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.title,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            entry.body,
            style: GoogleFonts.sourceSans3(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (entry.scripture.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '\u{1F4D6} ${entry.scripture}',
              style: GoogleFonts.sourceSans3(
                fontSize: 13,
                color: AppColors.gold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (entry.reflection.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgChip,
                borderRadius: BorderRadius.circular(10),
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'What is God teaching me: ',
                      style: GoogleFonts.sourceSans3(
                        fontSize: 13,
                        color: AppColors.gold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(
                      text: entry.reflection,
                      style: GoogleFonts.sourceSans3(
                        fontSize: 13,
                        color: AppColors.gold,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
