import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记录')),
      body: ListView(
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
          if (_tab == 0) _trainingRecords(),
          if (_tab == 1) _nutritionRecords(),
          if (_tab == 2) _bodyRecords(),
        ],
      ),
    );
  }

  Widget _trainingRecords() {
    return Column(
      children: [
        _summaryCard(),
        const SizedBox(height: 16),
        _emptyState(
          icon: Icons.fitness_center,
          title: '完成第一次训练后，记录会出现在这里',
          description: '训练重量、次数和总容量会自动整理成趋势。',
          action: '去训练',
        ),
      ],
    );
  }

  Widget _nutritionRecords() {
    return Column(
      children: [
        _macroCard(),
        const SizedBox(height: 16),
        _emptyState(
          icon: Icons.restaurant_outlined,
          title: '还没有饮食记录',
          description: '拍照或手动记录今天吃了什么。',
          action: '记录饮食',
        ),
      ],
    );
  }

  Widget _bodyRecords() {
    return Column(
      children: [
        _bodyMetricCard(),
        const SizedBox(height: 16),
        _emptyState(
          icon: Icons.monitor_weight_outlined,
          title: '还没有身体数据',
          description: '记录体重和身体状态，观察长期变化。',
          action: '记录身体状态',
        ),
      ],
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '近 30 天训练',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _GradientStat(value: '3', label: '训练次数')),
              Expanded(child: _GradientStat(value: '126', label: '总组数')),
              Expanded(child: _GradientStat(value: '86%', label: '完成率')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今天摄入',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Macro(label: '热量', value: '0 / 2100')),
              Expanded(child: _Macro(label: '蛋白质', value: '0 / 130g')),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Macro(label: '碳水', value: '0 / 240g')),
              Expanded(child: _Macro(label: '脂肪', value: '0 / 70g')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bodyMetricCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '身体趋势',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Macro(label: '当前体重', value: '-- kg')),
              Expanded(child: _Macro(label: '目标体重', value: '-- kg')),
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
  }) {
    return Container(
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
          OutlinedButton(onPressed: () {}, child: Text(action)),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
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

