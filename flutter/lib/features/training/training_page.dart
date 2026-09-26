import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass.dart';
import 'workout_session_page.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  PlanPreview? _plan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<SessionStore>().api.post('/api/plan/generate');
      setState(() => _plan = PlanPreview.fromJson(data));
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练')),
      body: RefreshIndicator(
        onRefresh: _loadPlan,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _weekStrip(context),
            const SizedBox(height: 18),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(36),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _errorView()
            else if (_plan == null || _plan!.days.isEmpty)
              _emptyPlan()
            else ...[
              _planHero(context, _plan!),
              const SizedBox(height: 18),
              _statsRow(),
              const SizedBox(height: 18),
              Text(
                '训练安排',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              ..._plan!.days.asMap().entries.map(
                    (entry) => _planDayCard(context, entry.key, entry.value),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _weekStrip(BuildContext context) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return Row(
      children: List.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        final selected = date.day == today.day &&
            date.month == today.month &&
            date.year == today.year;

        return Expanded(
          child: GlassPanel(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.blue : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.blue : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                Text(
                  const ['一', '二', '三', '四', '五', '六', '日'][index],
                  style: TextStyle(
                    color: selected ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _planHero(BuildContext context, PlanPreview plan) {
    final day = plan.days.first;

    return GlassPanel(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF172C55), AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x24FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '今日推荐',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const Spacer(),
              const Icon(Icons.local_fire_department, color: Color(0xFFFFB15C)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            day.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${day.exercises.length} 个动作 · 约 45 分钟',
            style: const TextStyle(color: Color(0xFFDCE7FF), fontSize: 14),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorkoutSessionPage(day: day),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.blue,
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始训练'),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return const Row(
      children: [
        Expanded(child: _MiniStat(label: '本周训练', value: '3 次')),
        SizedBox(width: 10),
        Expanded(child: _MiniStat(label: '连续训练', value: '4 天')),
        SizedBox(width: 10),
        Expanded(child: _MiniStat(label: '完成率', value: '86%')),
      ],
    );
  }

  Widget _planDayCard(BuildContext context, int index, PlanDay day) {
    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassPanel(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  day.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            day.exercises.map((exercise) => exercise.name).join('、'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPlan() {
    return GlassPanel(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.fitness_center, size: 54, color: AppColors.blue),
          SizedBox(height: 14),
          Text(
            '还没有训练计划',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            '生成一份适合你的训练计划，然后从今天开始训练。',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return GlassPanel(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _loadPlan, child: const Text('重新加载')),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

