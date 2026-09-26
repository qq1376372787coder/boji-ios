import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass.dart';
import '../ai/ai_report_page.dart';
import '../records/records_page.dart';
import '../training/training_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _selectDate(DateTime date) {
    HapticFeedback.selectionClick();
    SoundService.instance.tick();
    setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();


    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            _header(context, session.user?.displayName),
            const SizedBox(height: 18),
            _calendarCard(context),
            const SizedBox(height: 18),
            _hero(context),
            const SizedBox(height: 18),
            _progressRow(context),
            const SizedBox(height: 18),
            _quickActions(context),
            const SizedBox(height: 18),
            _insightCard(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String? name) {
    return Row(
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
                name == null || name.isEmpty ? '今天练什么？' : '今天练什么，$name？',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.1,
                    ),
              ),
            ],
          ),
        ),
        _GlassCircleButton(
          icon: Icons.person_outline,
          onTap: () {
            HapticFeedback.lightImpact();
            SoundService.instance.tick();
          },
        ),
      ],
    );
  }

  Widget _calendarCard(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0x66FFFFFF), Color(0x33DDEAFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x55FFFFFF)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '${now.year} 年 ${now.month} 月',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const GlassBadge(
                  label: '训练日',
                  icon: Icons.local_fire_department,
                  color: AppColors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(7, (index) {
                final date = monday.add(Duration(days: index));
                final selected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                final trained = index < 3;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => _selectDate(date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? AppColors.blue
                                : const Color(0x1A000000),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              const ['一', '二', '三', '四', '五', '六', '日'][index],
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 17,
                                color: selected ? Colors.white : AppColors.text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Icon(
                              trained ? Icons.check_circle : Icons.circle_outlined,
                              size: 13,
                              color: selected
                                  ? Colors.white
                                  : trained
                                      ? AppColors.green
                                      : AppColors.border,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
      ),
      child: GlassPanel(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A84FF), Color(0xFF5AC8FA), Color(0xFF8ED8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x55FFFFFF), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GlassBadge(
                  label: '今日训练',
                  icon: Icons.bolt,
                  color: Colors.white,
                ),
                const Spacer(),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '上肢推',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '5 个动作  ·  45 分钟  ·  中等强度',
              style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 14),
            ),
            const SizedBox(height: 24),
            LiquidButton(
              label: '开始训练',
              icon: Icons.play_arrow_rounded,
              colors: const [Colors.white, Color(0xFFDDF4FF)],
              onPressed: () {
                HapticFeedback.mediumImpact();
                SoundService.instance.complete();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrainingPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _metric('连续训练', '4', '天', Icons.local_fire_department, AppColors.orange)),
        const SizedBox(width: 10),
        Expanded(child: _metric('本周训练', '3', '次', Icons.fitness_center, AppColors.blue)),
        const SizedBox(width: 10),
        Expanded(child: _metric('完成率', '86', '%', Icons.trending_up, AppColors.green)),
      ],
    );
  }

  Widget _metric(String label, String value, String unit, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0x66FFFFFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                text: value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                children: [
                  TextSpan(
                    text: unit,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.calendar_month,
            title: '训练计划',
            subtitle: '日历与动作',
            color: AppColors.blue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TrainingPage()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.restaurant_outlined,
            title: '记录今天',
            subtitle: '饮食与身体',
            color: AppColors.orange,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecordsPage()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        SoundService.instance.tick();
        onTap();
      },
      child: GlassPanel(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0x66FFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        SoundService.instance.success();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiReportPage()),
        );
      },
      child: GlassPanel(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0x55FFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6D9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.orange),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI 今日建议', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text(
                    '训练前完成 5 分钟热身，动作质量比重量更重要。',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  String _dateLabel() {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${weekdays[_selectedDate.weekday - 1]} · ${_selectedDate.month} 月 ${_selectedDate.day} 日';
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        width: 48,
        height: 48,
        padding: EdgeInsets.zero,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x66FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Icon(icon, color: AppColors.text),
      ),
    );
  }
}

