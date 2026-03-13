import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Text('隐私政策', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Soloship 隐私政策', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                SizedBox(height: 8),
                Text('最后更新：2026 年 3 月 14 日', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                SizedBox(height: 24),

                _Section(title: '1. 我们收集的信息', content:
                  '当你使用 Soloship 时，我们会收集以下信息：\n\n'
                  '• 账户信息：你的姓名、电子邮件地址（通过 Google 或 Apple 登录获取）\n'
                  '• 使用数据：你与 AI Agent 的对话内容、创建的任务和文件\n'
                  '• 设备信息：设备类型、操作系统版本（用于改善兼容性）\n'
                  '• 支付信息：订阅状态（具体支付信息由 Apple/Google 处理，我们不存储信用卡号）'),

                _Section(title: '2. 我们如何使用信息', content:
                  '我们使用收集的信息用于：\n\n'
                  '• 提供和维护 Soloship 服务\n'
                  '• 处理你与 AI Agent 的对话请求\n'
                  '• 改善产品体验和修复问题\n'
                  '• 发送重要的服务通知'),

                _Section(title: '3. AI 对话数据', content:
                  '你与 AI Agent 的对话内容会被发送到第三方大语言模型服务商（如 OpenAI、Anthropic 等）进行处理。'
                  '我们会保存对话历史以提供持续的服务体验。你可以随时在 App 内删除对话记录。'),

                _Section(title: '4. 数据存储与安全', content:
                  '• 你的数据存储在安全的云服务器上\n'
                  '• 我们使用 HTTPS 加密所有数据传输\n'
                  '• API 密钥等敏感信息在服务器端加密存储\n'
                  '• 我们不会出售你的个人数据给第三方'),

                _Section(title: '5. 数据删除', content:
                  '你可以随时在 App 内删除你的账号。删除账号将永久移除你的所有数据，包括：\n\n'
                  '• 个人资料和账户信息\n'
                  '• 所有 AI Agent 及其配置\n'
                  '• 聊天记录和任务数据\n'
                  '• 上传的文件和工作区内容\n\n'
                  '此操作不可撤回。'),

                _Section(title: '6. 第三方服务', content:
                  '我们使用以下第三方服务：\n\n'
                  '• Firebase Authentication（Google）— 身份验证\n'
                  '• Apple Sign-In — 身份验证\n'
                  '• 大语言模型 API — AI 对话处理\n\n'
                  '这些服务有各自的隐私政策，请参阅其官方文档。'),

                _Section(title: '7. 儿童隐私', content:
                  'Soloship 不面向 13 岁以下的儿童。我们不会故意收集儿童的个人信息。'),

                _Section(title: '8. 隐私政策变更', content:
                  '我们可能会不时更新本隐私政策。更新后的政策将在 App 内发布，并更新"最后更新"日期。'
                  '继续使用 Soloship 即表示你同意修改后的政策。'),

                _Section(title: '9. 联系我们', content:
                  '如果你对本隐私政策有任何疑问，请通过以下方式联系我们：\n\n'
                  '• 电子邮件：support@soloship.app'),

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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.7)),
        ],
      ),
    );
  }
}
