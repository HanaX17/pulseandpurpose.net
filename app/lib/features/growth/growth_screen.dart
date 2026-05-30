import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models.dart';
import '../../data/repository.dart';

/// Height / weight / milestone records. A real growth chart is a Premium
/// feature (see PremiumFeature.growthReport) and left as a TODO.
class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(currentFamilyProvider);
    if (family == null) {
      return const Scaffold(body: Center(child: Text('No family selected')));
    }
    final records = ref.watch(growthProvider(family.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Growth')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, ref, family.id),
        icon: const Icon(Icons.add),
        label: const Text('Record'),
      ),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No growth records yet'))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _RecordTile(record: list[i]),
              ),
      ),
    );
  }

  Future<void> _addDialog(
      BuildContext context, WidgetRef ref, String familyId) async {
    var metric = 'height';
    final value = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add growth record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: metric,
                items: const [
                  DropdownMenuItem(value: 'height', child: Text('Height (cm)')),
                  DropdownMenuItem(value: 'weight', child: Text('Weight (kg)')),
                  DropdownMenuItem(value: 'head', child: Text('Head (cm)')),
                  DropdownMenuItem(
                      value: 'milestone', child: Text('Milestone')),
                ],
                onChanged: (v) => setState(() => metric = v ?? 'height'),
              ),
              const SizedBox(height: 12),
              if (metric != 'milestone')
                TextField(
                  controller: value,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Value'),
                ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await ref.read(repositoryProvider).addGrowth(
          familyId: familyId,
          metric: metric,
          value: metric == 'milestone' ? null : double.tryParse(value.text),
          unit: metric == 'weight'
              ? 'kg'
              : (metric == 'milestone' ? null : 'cm'),
          note: note.text.trim().isEmpty ? null : note.text.trim(),
          recordedAt: DateTime.now(),
        );
    ref.invalidate(growthProvider(familyId));
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final GrowthRecord record;

  @override
  Widget build(BuildContext context) {
    final icon = switch (record.metric) {
      'height' => Icons.height,
      'weight' => Icons.monitor_weight_outlined,
      'head' => Icons.face_outlined,
      _ => Icons.star_outline,
    };
    final title = record.value != null
        ? '${record.metric}: ${record.value} ${record.unit ?? ''}'
        : (record.note ?? 'Milestone');
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: record.note != null && record.value != null
          ? Text(record.note!)
          : null,
      trailing: Text(DateFormat.yMMMd().format(record.recordedAt)),
    );
  }
}
