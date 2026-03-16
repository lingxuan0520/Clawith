import 'package:flutter/material.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';

/// Bottom sheet with tenant list + inline create form (matches Web sidebar pattern).
/// Shared between profile_page.dart and onboarding.dart.
class TenantSwitcherSheet extends StatefulWidget {
  final List<Map<String, dynamic>> tenants;
  final String currentTenantId;
  final ValueChanged<String> onSelect;
  final void Function(String id, String name)? onDelete;
  final Future<void> Function(String name) onCreate;

  const TenantSwitcherSheet({
    super.key,
    required this.tenants,
    required this.currentTenantId,
    required this.onSelect,
    this.onDelete,
    required this.onCreate,
  });

  @override
  State<TenantSwitcherSheet> createState() => _TenantSwitcherSheetState();
}

class _TenantSwitcherSheetState extends State<TenantSwitcherSheet> {
  bool _showNewForm = false;
  final _nameCtl = TextEditingController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    // If no tenants yet, show the create form directly
    if (widget.tenants.isEmpty) {
      _showNewForm = true;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _doCreate() async {
    if (_nameCtl.text.trim().isEmpty) return;
    setState(() => _creating = true);
    try {
      await widget.onCreate(_nameCtl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.tenantSwitcherCreateFailed(e.toString()))),
        );
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.tenantSwitcherTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            // Tenant list
            ...widget.tenants.map((t) {
              final id = t['id'] as String;
              final name = t['name'] as String;
              final isSelected = id == widget.currentTenantId;
              return ListTile(
                title: Text(name, style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.accentPrimary : AppColors.textPrimary,
                )),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) const Icon(Icons.check, color: AppColors.accentPrimary, size: 18),
                    if (widget.onDelete != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => widget.onDelete!(id, name),
                        child: Icon(Icons.delete_outline, size: 18, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
                onTap: () => widget.onSelect(id),
              );
            }),
            const Divider(height: 1),
            // Inline create form (like Web sidebar)
            if (_showNewForm)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _nameCtl,
                          autofocus: true,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: l.tenantSwitcherNameHint,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onSubmitted: (_) => _doCreate(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _creating ? null : _doCreate,
                        child: _creating
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(l.tenantSwitcherCreate),
                      ),
                    ),
                    // Only show cancel button if there are existing tenants
                    if (widget.tenants.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() { _showNewForm = false; _nameCtl.clear(); }),
                        child: Icon(Icons.close, size: 20, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              )
            else
              ListTile(
                leading: Icon(Icons.add, color: AppColors.textTertiary),
                title: Text(l.tenantSwitcherNew, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                onTap: () => setState(() => _showNewForm = true),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
