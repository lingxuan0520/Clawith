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
    final tabs = [l.homeTabPlaza, l.homeTabDashboard];

    return Column(
      children: [
        // ── Tab switcher ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = _selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accentPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: selected
                            ? [BoxShadow(color: AppColors.accentPrimary.withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tabs[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? Colors.white : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        // ── Content ──
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
