import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    final user = session.user;

    return Scaffold(backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('个人中心')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _card(
            title: '账号',
            children: [
              _row('手机号', user?.phone ?? '—'),
              if (user?.displayName?.isNotEmpty == true)
                _row('昵称', user!.displayName!),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            title: '会员',
            children: [
              _row('状态', user?.membership.active == true ? '已开通' : '未开通'),
              if (user?.membership.expiresAt != null)
                _row('有效期至', user!.membership.expiresAt.toString()),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            title: '隐私',
            children: const [
              ListTile(title: Text('用户协议')),
              ListTile(title: Text('隐私政策')),
              ListTile(title: Text('账号注销')),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () async {
              await context.read<SessionStore>().logout();
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.logout),
            label: const Text('退出登录'),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(value),
    );
  }
}
