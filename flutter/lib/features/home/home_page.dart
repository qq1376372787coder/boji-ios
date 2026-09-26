import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../services/push_service.dart';
import '../paywall/paywall_page.dart';
import '../plan/plan_flow_page.dart';
import '../profile/profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    final active = session.user?.membership.active == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('薄肌俱乐部'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _membershipCard(context, active),
          const SizedBox(height: 14),
          Row(
            children: [
              _action(
                context,
                icon: Icons.auto_awesome,
                title: '生成计划',
                subtitle: 'AI 自动生成',
                onTap: () => _openPlan(context, PlanMode.generate),
              ),
              const SizedBox(width: 10),
              _action(
                context,
                icon: Icons.download,
                title: '导入计划',
                subtitle: '文字导入',
                onTap: () => _openPlan(context, PlanMode.importText),
              ),
              const SizedBox(width: 10),
              _action(
                context,
                icon: Icons.fitness_center,
                title: '自由训练',
                subtitle: '直接记录',
                onTap: () => _openPlan(context, PlanMode.free),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _todayCard(context),
          const SizedBox(height: 14),
          _reminderCard(context),
        ],
      ),
    );
  }

  void _openPlan(BuildContext context, PlanMode mode) {
    final active = context.read<SessionStore>().user?.membership.active == true;
    if (!active) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallPage()),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlanFlowPage(initialMode: mode)),
    );
  }

  Widget _membershipCard(BuildContext context, bool active) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF172C55), Color(0xFF2F6FED)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Color(0xFFFFD76A)),
              const SizedBox(width: 8),
              const Text(
                '年度会员',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x29FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  active ? '已开通' : '未开通',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            active ? '完整使用 AI 计划、日历和记录功能。' : '开通 6 元年度会员后即可使用全部功能。',
            style: const TextStyle(color: Color(0xFFDBE7FF)),
          ),
          if (!active) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallPage()),
              ),
              child: const Text('开通 6 元年度会员'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 128,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF2F6FED)),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8791A3)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _todayCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日训练', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text('完成建档后，AI 会生成适合你的训练计划。'),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => _openPlan(context, PlanMode.generate),
            child: const Text('开始生成训练计划'),
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('训练提醒', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('开启通知，在训练日及时收到提醒。'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => PushService.instance.requestPermission(),
            child: const Text('开启通知'),
          ),
        ],
      ),
    );
  }
}


