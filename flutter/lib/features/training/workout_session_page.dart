import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class WorkoutSessionPage extends StatefulWidget {
  const WorkoutSessionPage({super.key, required this.day});

  final PlanDay day;

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  final Map<int, Set<int>> _completedSets = {};
  int _restSeconds = 0;
  Timer? _timer;
  int _elapsedSeconds = 0;
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  int get _totalSets {
    return widget.day.exercises.fold(0, (sum, exercise) => sum + exercise.sets);
  }

  int get _completedCount {
    return _completedSets.values.fold(0, (sum, values) => sum + values.length);
  }

  void _completeSet(int exerciseIndex, int setIndex) {
    setState(() {
      final values = _completedSets.putIfAbsent(exerciseIndex, () => <int>{});
      if (!values.add(setIndex)) values.remove(setIndex);
    });

    if (_completedSets[exerciseIndex]?.contains(setIndex) == true) {
      _startRest();
    }
  }

  void _startRest() {
    _timer?.cancel();
    setState(() => _restSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds <= 1) {
        timer.cancel();
        setState(() => _restSeconds = 0);
      } else {
        setState(() => _restSeconds--);
      }
    });
  }

  Future<void> _finishWorkout() async {
    final completed = _completedCount;
    try {
      await context.read<SessionStore>().api.post(
        '/api/checkin',
        body: {
          'kind': 'workout',
          'checkin_date': DateTime.now().toIso8601String().substring(0, 10),
          'payload': {
            'title': widget.day.name,
            'duration_seconds': _elapsedSeconds,
            'total_sets': _totalSets,
            'completed_sets': completed,
          },
        },
      );
    } catch (_) {
      // Keep the workout usable when history saving is unavailable.
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('训练完成'),
        content: Text(
          '完成 $completed / $_totalSets 组，用时 ${_formatDuration(_elapsedSeconds)}。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('继续查看'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSets == 0 ? 0.0 : _completedCount / _totalSets;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.day.name),
        actions: [
          TextButton(onPressed: _finishWorkout, child: const Text('完成训练')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          _progressCard(progress),
          const SizedBox(height: 18),
          ...widget.day.exercises.asMap().entries.map(
                (entry) => _exerciseCard(entry.key, entry.value),
              ),
        ],
      ),
      bottomNavigationBar: _restSeconds > 0 ? _restBar() : null,
    );
  }

  Widget _progressCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '训练进度',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '$_completedCount / $_totalSets 组',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.blueSoft,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '用时 ${_formatDuration(_elapsedSeconds)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(int exerciseIndex, PlanExercise exercise) {
    final completed = _completedSets[exerciseIndex] ?? <int>{};

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${exercise.sets} × ${exercise.reps}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(exercise.sets, (setIndex) {
            final isDone = completed.contains(setIndex);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      '第 ${setIndex + 1} 组',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: exercise.type == 'bodyweight' ? '' : '20',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '重量 kg',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: exercise.reps.split('-').first,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '次数',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () => _completeSet(exerciseIndex, setIndex),
                    icon: Icon(
                      isDone ? Icons.check : Icons.done,
                      color: isDone ? Colors.white : AppColors.blue,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDone ? AppColors.green : AppColors.blueSoft,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _restBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              '休息 $_restSeconds 秒',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _restSeconds = 0),
              child: const Text(
                '跳过',
                style: TextStyle(color: Colors.white),
              ),
            ),
            FilledButton(
              onPressed: () => setState(() => _restSeconds += 15),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                minimumSize: const Size(92, 44),
              ),
              child: const Text('+15 秒'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}




