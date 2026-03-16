import 'package:flutter/material.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import 'plaza/plaza_page.dart';
import 'dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(l.homeTabPlaza)),
                ButtonSegment(value: 1, label: Text(l.homeTabDashboard)),
              ],
              selected: {_selectedIndex},
              onSelectionChanged: (v) => setState(() => _selectedIndex = v.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.accentPrimary;
                  }
                  return AppColors.bgSecondary;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppColors.textSecondary;
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: AppColors.borderDefault),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: const [
              PlazaPage(),
              DashboardPage(),
            ],
          ),
        ),
      ],
    );
  }
}
