import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../theme/app_theme.dart';
import '../ai/ai_report_page.dart';
import '../records/records_page.dart';
import '../training/training_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    final active = session.user?.membership.active == true;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            _header(context, session.user?.displayName),
            const SizedBox(height: 18),
            _membershipBanner(context, active),
            const SizedBox(height: 18),
            _todayHero(context),
            const SizedBox(height: 18),
            _weekStrip(context),
            const SizedBox(height: 18),
            _statsRow(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.fitness_center,
                    title: '查看训练',
                    subtitle: '当前计划和日历',
                    color: AppColors.blue,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TrainingPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.restaurant_outlined,
                    title: '记录今天',
                    subtitle: '训练和饮食',
                    color: AppColors.orange,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RecordsPage()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiReportPage()),
              ),
              child: _insightCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String? name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dateLabel(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '今天是训练日',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
              ),
              if (name != null && name.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  '准备好，$name。',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person, color: AppColors.blue),
        ),
      ],
    );
  }

  Widget _membershipBanner(BuildContext context, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEAF8F0) : const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.workspace_premium : Icons.lock_outline,
            color: active ? AppColors.green : AppColors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              active ? '年度会员已开通，全部功能可用。' : '开通年度会员，解锁 AI 计划和训练记录。',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _todayHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '今日训练',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
              ),
              Spacer(),
              Icon(Icons.local_fire_department, color: Color(0xFFFFB15C)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '上肢推',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            '5 个动作 · 约 45 分钟',
            style: TextStyle(color: Color(0xFFDCE7FF)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TrainingPage()),
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

  Widget _weekStrip(BuildContext context) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '本周节奏',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(7, (index) {
            final date = monday.add(Duration(days: index));
            final selected = date.day == today.day;
            final trained = index < 3;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? AppColors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(15),
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
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      trained ? Icons.check_circle : Icons.circle_outlined,
                      size: 15,
                      color: selected
                          ? Colors.white
                          : trained
                              ? AppColors.green
                              : AppColors.border,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _statsRow() {
    return const Row(
      children: [
        Expanded(child: _HomeStat(value: '4', label: '连续训练')),
        SizedBox(width: 10),
        Expanded(child: _HomeStat(value: '3', label: '本周训练')),
        SizedBox(width: 10),
        Expanded(child: _HomeStat(value: '86%', label: '完成率')),
      ],
    );
  }

  Widget _insightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0DE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日建议',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                Text(
                  '训练前完成 5 分钟热身，正式动作保持稳定节奏，不要为了追求重量牺牲动作质量。',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel() {
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${weekdays[now.weekday - 1]} · ${now.month} 月 ${now.day} 日';
  }
}

class _HomeStat extends StatelessWidget {
  const _HomeStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


