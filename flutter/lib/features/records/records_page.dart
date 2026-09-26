import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass.dart';
import 'trends_page.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  int _tab = 0;
  List<CheckinRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<SessionStore>().api.get('/api/checkins');
      final records = (data['records'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => CheckinRecord.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      setState(() => _records = records);
    } catch (_) {
      setState(() => _records = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CheckinRecord> _byKind(String kind) {
    return _records.where((record) => record.kind == kind).toList();
  }

  Future<void> _saveCheckin(String kind, Map<String, dynamic> payload) async {
    await context.read<SessionStore>().api.post(
      '/api/checkin',
      body: {
        'kind': kind,
        'checkin_date': DateTime.now().toIso8601String().substring(0, 10),
        'payload': payload,
      },
    );
    if (mounted) await _loadRecords();
  }

  Future<Map<String, dynamic>?> _recognizeMeal() async {
    try {
      final api = context.read<SessionStore>().api;
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return null;
      final data = await api.post(
        '/api/ai/evaluate',
        body: {
          'task': 'meal',
          'imageData': 'mock-image',
        },
      );
      final items = (data['parsed']?['items'] as List? ?? const []);
      if (items.isEmpty) return null;
      return Map<String, dynamic>.from(items.first as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _showMealDialog() async {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '记录饮食',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '吃了什么'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '热量 kcal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: proteinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '蛋白质 g'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await _recognizeMeal();
                if (result != null && sheetContext.mounted) {
                  nameController.text = result['name']?.toString() ?? nameController.text;
                  caloriesController.text = (result['calories'] ?? 0).toString();
                  proteinController.text = (result['protein'] ?? 0).toString();
                }
              },
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('拍照 / 选图识别'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                await _saveCheckin('meal', {
                  'title': nameController.text.trim().isEmpty
                      ? '饮食记录'
                      : nameController.text.trim(),
                  'calories': int.tryParse(caloriesController.text) ?? 0,
                  'protein': double.tryParse(proteinController.text) ?? 0,
                });
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
              child: const Text('保存饮食记录'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBodyDialog() async {
    final weightController = TextEditingController();
    final noteController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '记录身体状态',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '当前体重 kg'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: '今天的身体状态（可选）'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                await _saveCheckin('body', {
                  'weight_kg': double.tryParse(weightController.text),
                  'note': noteController.text.trim(),
                });
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
              child: const Text('保存身体状态'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('记录'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrendsPage(records: _records),
              ),
            ),
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('训练')),
                ButtonSegment(value: 1, label: Text('饮食')),
                ButtonSegment(value: 2, label: Text('身体')),
              ],
              selected: {_tab},
              onSelectionChanged: (selection) => setState(() => _tab = selection.first),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_tab == 0)
              _trainingRecords()
            else if (_tab == 1)
              _nutritionRecords()
            else
              _bodyRecords(),
          ],
        ),
      ),
    );
  }

  Widget _trainingRecords() {
    final records = _byKind('workout');
    final totalSets = records.fold<int>(
      0,
      (sum, record) => sum + ((record.payload['completed_sets'] as num?)?.toInt() ?? 0),
    );

    return Column(
      children: [
        _summaryCard(records.length, totalSets),
        const SizedBox(height: 16),
        if (records.isEmpty)
          _emptyState(
            icon: Icons.fitness_center,
            title: '完成第一次训练后，记录会出现在这里',
            description: '训练重量、次数和总容量会自动整理成趋势。',
            action: '去训练',
            onAction: () {},
          )
        else
          ...records.map(_recordTile),
      ],
    );
  }

  Widget _nutritionRecords() {
    final records = _byKind('meal');

    return Column(
      children: [
        _macroCard(records),
        const SizedBox(height: 16),
        if (records.isEmpty)
          _emptyState(
            icon: Icons.restaurant_outlined,
            title: '还没有饮食记录',
            description: '记录今天吃了什么，之后可以接入拍照识别。',
            action: '记录饮食',
            onAction: _showMealDialog,
          )
        else ...[
          FilledButton.icon(
            onPressed: _showMealDialog,
            icon: const Icon(Icons.add),
            label: const Text('继续记录饮食'),
          ),
          const SizedBox(height: 14),
          ...records.map(_recordTile),
        ],
      ],
    );
  }

  Widget _bodyRecords() {
    final records = _byKind('body');

    return Column(
      children: [
        _bodyMetricCard(records),
        const SizedBox(height: 16),
        if (records.isEmpty)
          _emptyState(
            icon: Icons.monitor_weight_outlined,
            title: '还没有身体数据',
            description: '记录体重和身体状态，观察长期变化。',
            action: '记录身体状态',
            onAction: _showBodyDialog,
          )
        else ...[
          FilledButton.icon(
            onPressed: _showBodyDialog,
            icon: const Icon(Icons.add),
            label: const Text('继续记录身体状态'),
          ),
          const SizedBox(height: 14),
          ...records.map(_recordTile),
        ],
      ],
    );
  }

  Widget _recordTile(CheckinRecord record) {
    final title = record.payload['title']?.toString() ??
        (record.kind == 'body' ? '身体状态' : record.kind == 'meal' ? '饮食记录' : '训练记录');
    final subtitle = switch (record.kind) {
      'meal' => '${record.payload['calories'] ?? 0} kcal · 蛋白 ${record.payload['protein'] ?? 0} g',
      'body' => '${record.payload['weight_kg'] ?? '--'} kg${record.payload['note'] == null ? '' : ' · ${record.payload['note']}'}',
      _ => '${record.payload['completed_sets'] ?? 0}/${record.payload['total_sets'] ?? 0} 组',
    };

    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          GlassPanel(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              record.kind == 'meal'
                  ? Icons.restaurant_outlined
                  : record.kind == 'body'
                      ? Icons.monitor_weight_outlined
                      : Icons.fitness_center,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${record.date.month}/${record.date.day}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(int completed, int totalSets) {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '近 30 天训练',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _GradientStat(value: '$completed', label: '训练次数')),
              Expanded(child: _GradientStat(value: '$totalSets', label: '总组数')),
              Expanded(
                child: _GradientStat(
                  value: completed == 0 ? '0%' : '${(completed * 20).clamp(0, 100)}%',
                  label: '完成率',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroCard(List<CheckinRecord> records) {
    final calories = records.fold<int>(
      0,
      (sum, record) => sum + ((record.payload['calories'] as num?)?.toInt() ?? 0),
    );
    final protein = records.fold<double>(
      0,
      (sum, record) => sum + ((record.payload['protein'] as num?)?.toDouble() ?? 0),
    );

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今天摄入', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Macro(label: '热量', value: '$calories / 2100')),
              Expanded(child: _Macro(label: '蛋白质', value: '${protein.toStringAsFixed(1)} / 130g')),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _Macro(label: '碳水', value: '0 / 240g')),
              Expanded(child: _Macro(label: '脂肪', value: '0 / 70g')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bodyMetricCard(List<CheckinRecord> records) {
    final weight = records.isEmpty ? '--' : '${records.first.payload['weight_kg'] ?? '--'} kg';

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('身体趋势', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Macro(label: '当前体重', value: weight)),
              const Expanded(child: _Macro(label: '目标体重', value: '-- kg')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String description,
    required String action,
    required VoidCallback onAction,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.blue),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _GradientStat extends StatelessWidget {
  const _GradientStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}


