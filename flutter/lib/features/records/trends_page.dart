import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass.dart';

class TrendsPage extends StatelessWidget {
  const TrendsPage({super.key, required this.records});

  final List<CheckinRecord> records;

  @override
  Widget build(BuildContext context) {
    final workoutRecords = records.where((record) => record.kind == 'workout').toList();
    final bodyRecords = records.where((record) => record.kind == 'body').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('趋势分析')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _header(bodyRecords),
          const SizedBox(height: 18),
          _chartCard(
            title: '训练节奏',
            subtitle: '最近 7 天完成组数',
            child: SizedBox(
              height: 190,
              child: CustomPaint(
                painter: _BarChartPainter(_weeklySets(workoutRecords)),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _chartCard(
            title: '体重变化',
            subtitle: '最近身体记录',
            child: SizedBox(
              height: 190,
              child: CustomPaint(
                painter: _LineChartPainter(_weights(bodyRecords)),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _insightCard(workoutRecords, bodyRecords),
        ],
      ),
    );
  }

  Widget _header(List<CheckinRecord> bodyRecords) {
    final totalSets = records.fold<int>(
      0,
      (sum, record) => sum + ((record.payload['completed_sets'] as num?)?.toInt() ?? 0),
    );

    return GlassPanel(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '坚持正在变成趋势',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '用数据看清训练节奏、体重和身体变化。',
            style: TextStyle(color: Color(0xFFDCE7FF)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _GradientMetric(value: '${records.where((r) => r.kind == 'workout').length}', label: '训练记录')),
              Expanded(child: _GradientMetric(value: '$totalSets', label: '完成组数')),
              Expanded(child: _GradientMetric(value: '${bodyRecords.length}', label: '身体记录')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _insightCard(
    List<CheckinRecord> workoutRecords,
    List<CheckinRecord> bodyRecords,
  ) {
    final workoutText = workoutRecords.isEmpty
        ? '完成训练后，这里会分析你的训练节奏。'
        : '最近已经完成 ${workoutRecords.length} 次训练，继续保持稳定频率。';
    final bodyText = bodyRecords.isEmpty
        ? '记录体重后，这里会显示长期变化。'
        : '最近记录了 ${bodyRecords.length} 次身体数据，建议固定时间测量。';

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
          const Text('数据建议', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _InsightRow(icon: Icons.fitness_center, text: workoutText),
          const SizedBox(height: 12),
          _InsightRow(icon: Icons.monitor_weight_outlined, text: bodyText),
        ],
      ),
    );
  }

  List<int> _weeklySets(List<CheckinRecord> workoutRecords) {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day - (6 - index));
      return workoutRecords
          .where((record) =>
              record.date.year == day.year &&
              record.date.month == day.month &&
              record.date.day == day.day)
          .fold<int>(
            0,
            (sum, record) => sum + ((record.payload['completed_sets'] as num?)?.toInt() ?? 0),
          );
    });
  }

  List<double> _weights(List<CheckinRecord> bodyRecords) {
    return bodyRecords.reversed
        .map((record) => (record.payload['weight_kg'] as num?)?.toDouble() ?? 0)
        .where((value) => value > 0)
        .toList();
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final max = math.max(1, values.fold<int>(0, math.max));
    final barWidth = size.width / (values.length * 1.6);
    final gap = barWidth * 0.6;

    for (var i = 0; i < values.length; i++) {
      final height = values[i] == 0 ? 4.0 : (values[i] / max) * (size.height - 28);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (barWidth + gap), size.height - height - 20, barWidth, height),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, Paint()..color = values[i] == 0 ? AppColors.border : AppColors.blue);
      final textPainter = TextPainter(
        text: TextSpan(
          text: values[i].toString(),
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(i * (barWidth + gap) + barWidth / 2 - textPainter.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) => oldDelegate.values != values;
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final range = max == min ? 1.0 : max - min;
    final paint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : i * (size.width / (values.length - 1));
      final y = size.height - 28 - ((values[i] - min) / range) * (size.height - 56);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = AppColors.orange);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) => oldDelegate.values != values;
}

class _GradientMetric extends StatelessWidget {
  const _GradientMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
        ),
      ],
    );
  }
}

