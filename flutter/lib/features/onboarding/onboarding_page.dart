// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../models/models.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  String gender = 'male';
  String experience = 'beginner';
  String environment = 'home';
  String goal = 'muscle_gain';
  final Set<String> equipment = {'bodyweight'};
  double age = 25;
  double height = 175;
  double weight = 70;
  double daysPerWeek = 3;
  double sessionMinutes = 45;
  final _limitationsController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _limitationsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final payload = OnboardingPayload(
        gender: gender,
        age: age.round(),
        heightCm: height,
        weightKg: weight,
        experience: experience,
        environment: environment,
        equipment: equipment.toList()..sort(),
        daysPerWeek: daysPerWeek.round(),
        sessionMinutes: sessionMinutes.round(),
        goal: goal,
        limitations: _limitationsController.text.trim(),
      );
      await context.read<SessionStore>().completeOnboarding(payload);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('建立训练档案')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _section(
            context,
            title: '身体情况',
            children: [
              _dropdown<String>(
                label: '性别',
                value: gender,
                items: const {
                  'male': '男',
                  'female': '女',
                  'other': '不透露',
                },
                onChanged: (value) => setState(() => gender = value!),
              ),
              _slider('年龄', age, 16, 80, 1, '${age.round()} 岁'),
              _slider('身高', height, 120, 230, 1, '${height.round()} cm'),
              _slider('体重', weight, 30, 250, 0.5, '${weight.toStringAsFixed(1)} kg'),
            ],
          ),
          const SizedBox(height: 14),
          _section(
            context,
            title: '训练条件',
            children: [
              _dropdown<String>(
                label: '训练经验',
                value: experience,
                items: const {
                  'beginner': '零基础',
                  'novice': '入门',
                  'intermediate': '有经验',
                },
                onChanged: (value) => setState(() => experience = value!),
              ),
              _dropdown<String>(
                label: '训练场地',
                value: environment,
                items: const {
                  'home': '在家',
                  'gym': '健身房',
                  'outdoor': '户外',
                },
                onChanged: (value) => setState(() => environment = value!),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: {
                  'bodyweight': '徒手',
                  'mat': '瑜伽垫',
                  'bands': '弹力带',
                  'dumbbell': '哑铃',
                  'barbell': '杠铃',
                  'gym': '健身房器械',
                }.entries.map((entry) {
                  final selected = equipment.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          equipment.add(entry.key);
                        } else {
                          equipment.remove(entry.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              _slider('每周训练天数', daysPerWeek, 2, 6, 1, '${daysPerWeek.round()} 天'),
              _slider('每次训练时长', sessionMinutes, 20, 90, 5, '${sessionMinutes.round()} 分钟'),
            ],
          ),
          const SizedBox(height: 14),
          _section(
            context,
            title: '训练目标',
            children: [
              _dropdown<String>(
                label: '目标',
                value: goal,
                items: const {
                  'muscle_gain': '增肌',
                  'fat_loss': '减脂',
                  'strength': '增力',
                  'posture': '改善体态',
                  'fitness': '保持健康',
                },
                onChanged: (value) => setState(() => goal = value!),
              ),
              TextField(
                controller: _limitationsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '伤病、疼痛或动作限制（可选）',
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving || equipment.isEmpty ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('保存并生成训练计划'),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    double divisions,
    String display,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(display)],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / divisions).round(),
          onChanged: (next) {
            setState(() {
              if (label == '年龄') age = next;
              if (label == '身高') height = next;
              if (label == '体重') weight = next;
              if (label == '每周训练天数') daysPerWeek = next;
              if (label == '每次训练时长') sessionMinutes = next;
            });
          },
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items.entries
            .map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}



