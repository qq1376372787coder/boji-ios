import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass.dart';

class AiReportPage extends StatefulWidget {
  const AiReportPage({super.key});

  @override
  State<AiReportPage> createState() => _AiReportPageState();
}

class _AiReportPageState extends State<AiReportPage> {
  Map<String, dynamic>? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<SessionStore>().api.post('/api/ai/summary');
      setState(() => _report = Map<String, dynamic>.from(data['parsed'] as Map? ?? const {}));
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('AI 日报'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _generate,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(42),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _errorView()
          else if (_report != null)
            ..._reportView(_report!),
        ],
      ),
    );
  }

  List<Widget> _reportView(Map<String, dynamic> report) {
    return [
      GlassPanel(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue]),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFFFD166)),
                SizedBox(width: 8),
                Text(
                  'AI 训练日报',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              report['title']?.toString() ?? '最近总结',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '根据你的训练和记录生成的个性化摘要。',
              style: TextStyle(color: Color(0xFFDCE7FF)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _section(
        icon: Icons.timeline,
        title: '训练节奏',
        text: report['rhythm']?.toString() ?? '暂无训练节奏数据。',
        color: AppColors.blue,
      ),
      _section(
        icon: Icons.restaurant_outlined,
        title: '饮食摄入',
        text: report['nutrition']?.toString() ?? '暂无饮食数据。',
        color: AppColors.orange,
      ),
      _section(
        icon: Icons.tips_and_updates_outlined,
        title: '调整建议',
        text: report['advice']?.toString() ?? '暂无调整建议。',
        color: AppColors.green,
      ),
      const SizedBox(height: 8),
      const Text(
        'AI 只提供训练和饮食参考，不替代医生或专业康复建议。',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    ];
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
  }) {
    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassPanel(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
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
          OutlinedButton(onPressed: _generate, child: const Text('重新生成')),
        ],
      ),
    );
  }
}

