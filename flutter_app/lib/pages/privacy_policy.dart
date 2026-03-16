import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: Text(l.privacyTitle, style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.privacyMainTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                SizedBox(height: 8),
                Text(l.privacyLastUpdated, style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                SizedBox(height: 24),

                _Section(title: l.privacySection1Title, content: l.privacySection1Body),
                _Section(title: l.privacySection2Title, content: l.privacySection2Body),
                _Section(title: l.privacySection3Title, content: l.privacySection3Body),
                _Section(title: l.privacySection4Title, content: l.privacySection4Body),
                _Section(title: l.privacySection5Title, content: l.privacySection5Body),
                _Section(title: l.privacySection6Title, content: l.privacySection6Body),
                _Section(title: l.privacySection7Title, content: l.privacySection7Body),
                _Section(title: l.privacySection8Title, content: l.privacySection8Body),
                _Section(title: l.privacySection9Title, content: l.privacySection9Body),

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.7)),
        ],
      ),
    );
  }
}
