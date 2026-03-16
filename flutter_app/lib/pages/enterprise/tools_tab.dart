import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import '../../services/api.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import 'section_card.dart';

Dio get _dio => ApiClient.instance.dio;

// ═══════════════════════════════════════════════════════════════
//  TOOLS TAB
// ═══════════════════════════════════════════════════════════════
class ToolsTab extends StatefulWidget {
  const ToolsTab({super.key});
  @override
  State<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _tools = [];
  bool _loading = true;

  // MCP add form
  bool _showAddMCP = false;
  final _mcpUrlCtl = TextEditingController();
  final _mcpNameCtl = TextEditingController();
  bool _mcpTesting = false;
  Map<String, dynamic>? _mcpTestResult;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listTools();
      _tools = data.cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleTool(String toolId, bool enabled) async {
    try {
      await _dio
          .put('/tools/$toolId', data: {'enabled': enabled});
      _loadTools();
    } catch (_) {}
  }

  Future<void> _deleteTool(String toolId, String displayName) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text(l.toolsTabDeleteTitle,
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(l.toolsTabDeleteConfirm(displayName),
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(l.commonDelete, style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _dio.delete('/tools/$toolId');
      _loadTools();
    } catch (_) {
      _showError(l.toolsTabDeleteFailed);
    }
  }

  Future<void> _testMcpConnection() async {
    setState(() {
      _mcpTesting = true;
      _mcpTestResult = null;
    });
    try {
      final r = await _dio.post('/tools/test-mcp',
          data: {'server_url': _mcpUrlCtl.text.trim()});
      setState(() => _mcpTestResult = r.data as Map<String, dynamic>);
    } catch (e) {
      setState(() => _mcpTestResult = {'ok': false, 'error': e.toString()});
    }
    setState(() => _mcpTesting = false);
  }

  Future<void> _importMcpTool(Map<String, dynamic> tool) async {
    try {
      await _dio.post('/tools', data: {
        'name': 'mcp_${tool['name']}',
        'display_name': tool['name'],
        'description': tool['description'] ?? '',
        'type': 'mcp',
        'category': 'custom',
        'icon': '\u00b7',
        'mcp_server_url': _mcpUrlCtl.text.trim(),
        'mcp_server_name': _mcpNameCtl.text.trim().isNotEmpty
            ? _mcpNameCtl.text.trim()
            : _mcpUrlCtl.text.trim(),
        'mcp_tool_name': tool['name'],
        'parameters_schema': tool['inputSchema'] ?? {},
        'is_default': false,
      });
      _loadTools();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.toolsTabImported(tool['name'] as String? ?? ''))),
        );
      }
    } catch (_) {
      _showError(AppLocalizations.of(context)!.toolsTabImportFailed);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l.toolsTabGlobal,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showAddMCP = true),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l.toolsTabMcp),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // MCP add form
        if (_showAddMCP) ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.toolsTabAddMcp,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Text(l.toolsTabServerName,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: _mcpNameCtl,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(hintText: 'My MCP Server'),
                ),
                const SizedBox(height: 10),
                Text(l.toolsTabServerUrl,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: _mcpUrlCtl,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                      hintText: 'http://localhost:3000/mcp'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _mcpTesting || _mcpUrlCtl.text.trim().isEmpty
                          ? null
                          : _testMcpConnection,
                      child: Text(
                          _mcpTesting ? l.toolsTabTesting : l.toolsTabTestConnection),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _showAddMCP = false;
                        _mcpTestResult = null;
                      }),
                      child: Text(l.commonCancel),
                    ),
                  ],
                ),
                // Test result
                if (_mcpTestResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _mcpTestResult!['ok'] == true
                          ? const Color(0x1A22C55E)
                          : const Color(0x1AEF4444),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _mcpTestResult!['ok'] == true
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: _mcpTestResult!['ok'] == true
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.toolsTabConnectSuccess((_mcpTestResult!['tools'] as List?)?.length ?? 0),
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              ...(_mcpTestResult!['tools'] as List? ?? [])
                                  .map<Widget>((tool) {
                                final t = tool as Map<String, dynamic>;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(t['name'] as String? ?? '',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textPrimary)),
                                            if (t['description'] != null)
                                              Text(
                                                (t['description'] as String)
                                                    .substring(
                                                        0,
                                                        (t['description']
                                                                        as String)
                                                                    .length >
                                                                80
                                                            ? 80
                                                            : (t['description']
                                                                    as String)
                                                                .length),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors
                                                        .textTertiary),
                                              ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _importMcpTool(t),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          textStyle:
                                              const TextStyle(fontSize: 11),
                                        ),
                                        child: Text(l.toolsTabImport),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          )
                        : Text(
                            l.toolsTabConnectFailed(_mcpTestResult!['error']?.toString() ?? l.toolsTabUnknownError),
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Tool list
        if (_tools.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(l.toolsTabNoTools,
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          ..._tools.map(_buildToolCard),
      ],
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    final l = AppLocalizations.of(context)!;
    final enabled = tool['enabled'] == true;
    final isMcp = tool['type'] == 'mcp';
    final isBuiltin = tool['type'] == 'builtin';
    final displayName = (tool['display_name'] ?? tool['name'] ?? '') as String;
    final description = (tool['description'] ?? '') as String;
    final mcpServerName = (tool['mcp_server_name'] ?? '') as String;
    final isDefault = tool['is_default'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            SizedBox(
              width: 28,
              child: Text(
                (tool['icon'] ?? '\u00b7') as String,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildBadge(
                        isMcp ? 'MCP' : l.toolsTabBuiltIn,
                        isMcp
                            ? AppColors.accentPrimary
                            : AppColors.bgTertiary,
                        textColor: isMcp
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 4),
                        _buildBadge(l.toolsTabDefault, AppColors.success,
                            textColor: Colors.white),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description.length > 60
                        ? '${description.substring(0, 60)}...'
                        : description +
                            (mcpServerName.isNotEmpty
                                ? ' \u00b7 $mcpServerName'
                                : ''),
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Actions
            if (!isBuiltin)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.error),
                onPressed: () =>
                    _deleteTool(tool['id'] as String, displayName),
                tooltip: l.commonDelete,
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(width: 4),
            // Enable/disable switch
            SizedBox(
              width: 44,
              height: 24,
              child: Switch(
                value: enabled,
                onChanged: (v) =>
                    _toggleTool(tool['id'] as String, v),
                activeTrackColor: AppColors.success,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mcpUrlCtl.dispose();
    _mcpNameCtl.dispose();
    super.dispose();
  }
}

Widget _buildBadge(String text, Color bgColor, {Color? textColor}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bgColor.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textColor ?? bgColor,
      ),
    ),
  );
}
