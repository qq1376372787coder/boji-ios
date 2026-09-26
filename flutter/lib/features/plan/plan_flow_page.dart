import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../models/models.dart';

enum PlanMode { generate, importText, free }

class PlanFlowPage extends StatefulWidget {
  const PlanFlowPage({super.key, required this.initialMode});

  final PlanMode initialMode;

  @override
  State<PlanFlowPage> createState() => _PlanFlowPageState();
}

class _PlanFlowPageState extends State<PlanFlowPage> {
  late PlanMode mode;
  final _importController = TextEditingController();
  PlanPreview? _preview;
  bool _loading = false;
  bool _saving = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode;
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final data = await context.read<SessionStore>().api.post('/api/plan/generate');
      setState(() => _preview = PlanPreview.fromJson(data));
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _import() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final data = await context.read<SessionStore>().api.post(
        '/api/plan/import',
        body: {'text': _importController.text.trim()},
      );
      final preview = PlanPreview.fromJson(data);
      setState(() => _preview = preview);
      if (preview.days.isEmpty) {
        setState(() => _error = '没有识别出训练动作，请把动作、组数和次数写清楚一些。');
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<SessionStore>().api.post(
        '/api/plan/version',
        body: {
          'member': 'me',
          'plans': preview.days
              .map((day) => {
                    'name': day.name,
                    'note': day.note,
                    'exercises': day.exercises
                        .map((exercise) => [
                              exercise.name,
                              exercise.sets,
                              exercise.reps,
                              exercise.type,
                            ])
                        .toList(),
                  })
              .toList(),
        },
      );
      setState(() => _message = '计划已保存为正式计划。');
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练计划')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SegmentedButton<PlanMode>(
            segments: const [
              ButtonSegment(value: PlanMode.generate, label: Text('AI 生成')),
              ButtonSegment(value: PlanMode.importText, label: Text('导入计划')),
              ButtonSegment(value: PlanMode.free, label: Text('自由训练')),
            ],
            selected: {mode},
            onSelectionChanged: (selection) {
              setState(() {
                mode = selection.first;
                _preview = null;
                _message = null;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 18),
          if (mode == PlanMode.generate) _generateView(),
          if (mode == PlanMode.importText) _importView(),
          if (mode == PlanMode.free) _freeView(),
          if (_preview != null) _previewView(_preview!),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!, style: const TextStyle(color: Colors.green)),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _generateView() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI 会根据身体情况、目标、器械和训练时间生成计划。',
            style: TextStyle(color: Color(0xFF6C778C)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_loading ? '生成中…' : '生成训练计划'),
          ),
        ],
      ),
    );
  }

  Widget _importView() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('粘贴训练计划，AI 只整理格式，不会擅自删除动作。'),
          const SizedBox(height: 12),
          TextField(
            controller: _importController,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '训练计划原文',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _loading ? null : _import,
            icon: const Icon(Icons.document_scanner),
            label: Text(_loading ? '识别中…' : '识别并整理计划'),
          ),
        ],
      ),
    );
  }

  Widget _freeView() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('自由训练', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('不设置固定计划，直接从今天开始记录训练。'),
          SizedBox(height: 14),
          FilledButton.icon(
            onPressed: null,
            icon: Icon(Icons.fitness_center),
            label: Text('开始自由训练'),
          ),
        ],
      ),
    );
  }

  Widget _previewView(PlanPreview preview) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.summary,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final day in preview.days) ...[
            Text(day.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (day.note.isNotEmpty)
              Text(day.note, style: const TextStyle(color: Color(0xFF6C778C))),
            const SizedBox(height: 8),
            for (final exercise in day.exercises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(exercise.name)),
                    Text('${exercise.sets} 组 × ${exercise.reps}'),
                  ],
                ),
              ),
            const Divider(height: 24),
          ],
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? '保存中…' : '确认保存为正式计划'),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
