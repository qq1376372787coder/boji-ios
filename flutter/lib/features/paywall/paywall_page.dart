import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../services/purchase_service.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final purchase = context.watch<PurchaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('开通会员')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.workspace_premium, size: 72, color: Color(0xFFE3A008)),
          const SizedBox(height: 14),
          const Text(
            '薄肌俱乐部年度会员',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            '一人一账号，完整使用 AI 训练计划、训练日历和记录功能。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6C778C)),
          ),
          const SizedBox(height: 20),
          Text(
            purchase.product?.price ?? '¥6',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
          ),
          const Text(
            '12 个月自动续费',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6C778C)),
          ),
          const SizedBox(height: 22),
          const _Benefit(icon: Icons.auto_awesome, text: 'AI 根据身体情况生成训练计划'),
          const _Benefit(icon: Icons.calendar_month, text: '自动生成训练日历'),
          const _Benefit(icon: Icons.download, text: '导入自己的训练计划'),
          const _Benefit(icon: Icons.notifications, text: '训练和会员到期提醒'),
          const SizedBox(height: 16),
          if (purchase.message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                purchase.message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          FilledButton(
            onPressed: purchase.purchasing ? null : purchase.purchase,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: Text(purchase.purchasing ? '处理中…' : '通过 Apple 开通'),
          ),
          TextButton(
            onPressed: purchase.purchasing ? null : purchase.restore,
            child: const Text('恢复购买'),
          ),
          const SizedBox(height: 12),
          const Text(
            '订阅通过 Apple 账户自动续费。你可以随时在 Apple ID 设置中取消。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF7A8496)),
          ),
          TextButton(
            onPressed: () => context.read<SessionStore>().refreshUser(),
            child: const Text('刷新会员状态'),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2F6FED)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

