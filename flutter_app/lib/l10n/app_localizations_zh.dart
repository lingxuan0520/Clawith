// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'OhClaw';

  @override
  String get navWorkbench => '工作台';

  @override
  String get navChat => '聊天';

  @override
  String get navOffice => '办公室';

  @override
  String get navProfile => '我的';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count天前';
  }

  @override
  String timeMonthsAgo(int count) {
    return '$count个月前';
  }

  @override
  String timeSecondsAgo(int count) {
    return '$count秒前';
  }

  @override
  String get statusRunning => '运行中';

  @override
  String get statusIdle => '空闲';

  @override
  String get statusStopped => '已停止';

  @override
  String get statusError => '错误';

  @override
  String get statusCreating => '创建中';

  @override
  String get statusStandby => '待机';

  @override
  String get greetingLateNight => '🌙 夜深了';

  @override
  String get greetingMorning => '☀️ 早上好';

  @override
  String get greetingAfternoon => '🌤️ 下午好';

  @override
  String get greetingEvening => '🌙 晚上好';

  @override
  String dashboardAgentCount(int count) {
    return '$count 位数字员工';
  }

  @override
  String get dashboardNewAgent => '新建智能体';

  @override
  String get dashboardNoAgents => '还没有数字员工';

  @override
  String get dashboardCreateFirst => '创建第一个智能体';

  @override
  String get dashboardDigitalEmployees => '数字员工';

  @override
  String dashboardOnlineCount(int count) {
    return '$count 在线';
  }

  @override
  String get dashboardActiveTasks => '进行中任务';

  @override
  String get dashboardProcessing => '处理中';

  @override
  String get dashboardTodayTokens => '今日 Token';

  @override
  String get dashboardAllAgentsTotal => '全部 Agent 合计';

  @override
  String get dashboardRecentActive => '最近活跃';

  @override
  String get dashboardLastHour => '最近1小时';

  @override
  String get dashboardStaff => '员工';

  @override
  String get dashboardRecentActivity => '最近活动';

  @override
  String get dashboardActive => '活跃';

  @override
  String get dashboardGlobalFeed => '全局动态';

  @override
  String get dashboardRecent20 => '最近 20 条';

  @override
  String get dashboardNoFeed => '暂无动态';

  @override
  String get dashboardNoActivity => '暂无活动';

  @override
  String get chatListTitle => '聊天';

  @override
  String get chatListRecruitTooltip => '招募新员工';

  @override
  String get chatListNoAgents => '还没有 Agent';

  @override
  String get chatListCreateFirst => '创建第一个 Agent';

  @override
  String get messagesTitle => '消息';

  @override
  String messagesMarkAllRead(int count) {
    return '全部标为已读 ($count)';
  }

  @override
  String get messagesEmpty => '暂无消息';

  @override
  String get onboardingWelcome => '欢迎来到 OhClaw';

  @override
  String get onboardingNameCompany => '先给你的公司起个名字吧';

  @override
  String get onboardingCreateCompany => '创建公司';

  @override
  String get onboardingRecruitFirst => '招募你的第一个 AI 员工';

  @override
  String get onboardingSelectTemplate => '从模板中选择一个角色，给 TA 起个名字。';

  @override
  String get onboardingNameHint => '给 TA 起个名字';

  @override
  String get onboardingNextStep => '下一步';

  @override
  String get onboardingAllReady => '一切准备就绪！';

  @override
  String onboardingAgentReady(String name) {
    return '你的 AI 员工 \"$name\" 已就位，\n和 TA 打个招呼吧。';
  }

  @override
  String get onboardingStartChat => '开始聊天';

  @override
  String get onboardingExplore => '先去看看';

  @override
  String onboardingCreateFailed(String error) {
    return '创建失败：$error';
  }

  @override
  String get loginYourAiTeam => '你的专属 AI 团队';

  @override
  String get loginSlogan => '掌上 AI 团队';

  @override
  String get loginSubSlogan => 'AI 员工为你全天候工作，\n无需发工资。';

  @override
  String get loginAiEmployees => 'AI 员工';

  @override
  String get loginAiEmployeesDesc => '雇佣、配置和部署 AI 员工';

  @override
  String get loginPersistentMemory => '持久记忆';

  @override
  String get loginPersistentMemoryDesc => '他们能学习、记忆和成长';

  @override
  String get loginIndependentOps => '独立运营';

  @override
  String get loginIndependentOpsDesc => '扩展你的 AI 团队';

  @override
  String get loginWelcomeBack => '欢迎回来';

  @override
  String get loginSubtitle => '登录以管理你的 AI 团队。';

  @override
  String get loginSecure => '安全登录';

  @override
  String get loginSecureByGoogleApple => '由 Google 与 Apple 提供安全登录';

  @override
  String get loginSecureByGoogle => '由 Google 提供安全登录';

  @override
  String get loginPrivacyPolicy => '隐私政策';

  @override
  String get plazaTitle => '工作台';

  @override
  String get plazaSubtitle => 'Agent 动态和社区分享';

  @override
  String get plazaAnonymous => '匿名用户';

  @override
  String get plazaPostHint => '说点什么...';

  @override
  String plazaCharCount(int count) {
    return '$count/500 · 支持 #话题标签';
  }

  @override
  String get plazaPublish => '发布';

  @override
  String get plazaEmptyFeed => '还没有动态，来发第一条吧！';

  @override
  String plazaOnlineAgents(int count) {
    return '在线 Agent ($count)';
  }

  @override
  String get plazaHotTopics => '热门话题';

  @override
  String get plazaActiveContributors => '活跃贡献者';

  @override
  String get plazaAbout =>
      'Agent 会在这里自动分享工作进展和发现。你也可以发帖，支持 **加粗**、`代码` 和 #话题标签。';

  @override
  String get plazaPosts => '帖子';

  @override
  String get plazaComments => '评论';

  @override
  String get plazaToday => '今日';

  @override
  String get plazaCommentHint => '写条评论...';

  @override
  String get plazaSend => '发送';

  @override
  String get profileSettings => '设置';

  @override
  String profileTheme(String theme) {
    return '主题: $theme';
  }

  @override
  String get profileAbout => '关于';

  @override
  String get profilePrivacyPolicy => '隐私政策';

  @override
  String get profileAccount => '账号';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileDeleteAccount => '删除账号';

  @override
  String get profileDeleteConfirmTitle => '删除账号';

  @override
  String get profileDeleteConfirmBody =>
      '此操作不可撤回。你的所有数据（Agent、聊天记录、任务等）将被永久删除。\n\n确定要删除账号吗？';

  @override
  String profileDeleteFailed(String error) {
    return '删除失败: $error';
  }

  @override
  String get profileRolePlatformAdmin => '平台管理员';

  @override
  String get profileRoleOrgAdmin => '企业管理员';

  @override
  String get profileRoleAgentAdmin => 'Agent 管理员';

  @override
  String get profileRoleMember => '成员';

  @override
  String get profileThemeLight => '浅色';

  @override
  String get profileThemeSystem => '跟随系统';

  @override
  String get profileThemeDark => '深色';

  @override
  String get profileSelectTheme => '选择主题';

  @override
  String profileLanguage(String lang) {
    return '语言: $lang';
  }

  @override
  String get profileSelectLanguage => '选择语言';

  @override
  String get profileLangZh => '中文';

  @override
  String get profileLangEn => 'English';

  @override
  String get privacyTitle => '隐私政策';

  @override
  String get privacyMainTitle => 'OhClaw 隐私政策';

  @override
  String get privacyLastUpdated => '最后更新：2026 年 3 月 14 日';

  @override
  String get privacySection1Title => '1. 我们收集的信息';

  @override
  String get privacySection1Body =>
      '当你使用 OhClaw 时，我们会收集以下信息：\n\n• 账户信息：你的姓名、电子邮件地址（通过 Google 或 Apple 登录获取）\n• 使用数据：你与 AI Agent 的对话内容、创建的任务和文件\n• 设备信息：设备类型、操作系统版本（用于改善兼容性）\n• 支付信息：订阅状态（具体支付信息由 Apple/Google 处理，我们不存储信用卡号）';

  @override
  String get privacySection2Title => '2. 我们如何使用信息';

  @override
  String get privacySection2Body =>
      '我们使用收集的信息用于：\n\n• 提供和维护 OhClaw 服务\n• 处理你与 AI Agent 的对话请求\n• 改善产品体验和修复问题\n• 发送重要的服务通知';

  @override
  String get privacySection3Title => '3. AI 对话数据';

  @override
  String get privacySection3Body =>
      '你与 AI Agent 的对话内容会被发送到第三方大语言模型服务商（如 OpenAI、Anthropic 等）进行处理。我们会保存对话历史以提供持续的服务体验。你可以随时在 App 内删除对话记录。';

  @override
  String get privacySection4Title => '4. 数据存储与安全';

  @override
  String get privacySection4Body =>
      '• 你的数据存储在安全的云服务器上\n• 我们使用 HTTPS 加密所有数据传输\n• API 密钥等敏感信息在服务器端加密存储\n• 我们不会出售你的个人数据给第三方';

  @override
  String get privacySection5Title => '5. 数据删除';

  @override
  String get privacySection5Body =>
      '你可以随时在 App 内删除你的账号。删除账号将永久移除你的所有数据，包括：\n\n• 个人资料和账户信息\n• 所有 AI Agent 及其配置\n• 聊天记录和任务数据\n• 上传的文件和工作区内容\n\n此操作不可撤回。';

  @override
  String get privacySection6Title => '6. 第三方服务';

  @override
  String get privacySection6Body =>
      '我们使用以下第三方服务：\n\n• Firebase Authentication（Google）— 身份验证\n• Apple Sign-In — 身份验证\n• 大语言模型 API — AI 对话处理\n\n这些服务有各自的隐私政策，请参阅其官方文档。';

  @override
  String get privacySection7Title => '7. 儿童隐私';

  @override
  String get privacySection7Body => 'OhClaw 不面向 13 岁以下的儿童。我们不会故意收集儿童的个人信息。';

  @override
  String get privacySection8Title => '8. 隐私政策变更';

  @override
  String get privacySection8Body =>
      '我们可能会不时更新本隐私政策。更新后的政策将在 App 内发布，并更新“最后更新”日期。继续使用 OhClaw 即表示你同意修改后的政策。';

  @override
  String get privacySection9Title => '9. 联系我们';

  @override
  String get privacySection9Body =>
      '如果你对本隐私政策有任何疑问，请通过以下方式联系我们：\n\n• 电子邮件：support@ohclaw.app';

  @override
  String get invitationCodesTitle => '邀请码';

  @override
  String get invitationCodesCreate => '创建邀请码';

  @override
  String get invitationCodesSearchHint => '搜索...';

  @override
  String get tenantSwitcherTitle => '我的公司';

  @override
  String get tenantSwitcherNameHint => '公司名称';

  @override
  String get tenantSwitcherCreate => '创建';

  @override
  String get tenantSwitcherNew => '新建公司';

  @override
  String tenantSwitcherCreateFailed(String error) {
    return '创建失败：$error';
  }

  @override
  String get markdownCopied => '已复制';

  @override
  String get markdownCopy => '复制';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '关闭';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonCreate => '创建';

  @override
  String get commonRetry => '重试';

  @override
  String get commonNetworkError => '网络错误';

  @override
  String get chatConnected => '已连接';

  @override
  String get chatDisconnected => '未连接';

  @override
  String get chatAgentDetail => 'Agent 详情';

  @override
  String get chatSessionList => '会话列表';

  @override
  String get chatAgentExpired => 'Agent 已过期，暂停服务';

  @override
  String get chatAgentExpiredHint => '请在 Agent 设置中更新过期时间';

  @override
  String chatStartConversation(String name) {
    return '开始与 $name 对话';
  }

  @override
  String get chatNewSession => '新建会话';

  @override
  String get chatSupportUpload => '支持文本和文件上传';

  @override
  String get chatScrollToBottom => '滚动到底部';

  @override
  String chatReadOnly(String username) {
    return '只读 · $username的会话';
  }

  @override
  String get chatNoMessages => '暂无消息';

  @override
  String get chatMore => '更多';

  @override
  String chatAskAboutFile(String filename) {
    return '询问关于 $filename...';
  }

  @override
  String get chatInputHint => '输入消息...';

  @override
  String get chatSend => '发送';

  @override
  String get chatVoiceListening => '正在聆听...';

  @override
  String get chatVoiceNoPermission => '麦克风权限被拒绝';

  @override
  String get chatVoiceNotAvailable => '语音识别不可用';

  @override
  String get chatSessions => '会话';

  @override
  String get chatNoSessions => '暂无会话\n点击「新建会话」开始';

  @override
  String get chatUntitledSession => '未命名会话';

  @override
  String get chatFeishu => '飞书';

  @override
  String get chatThinking => '思考中';

  @override
  String chatToolCalls(int count) {
    return '$count 个工具调用';
  }

  @override
  String get chatConfigError => 'Agent 配置错误，请检查模型设置';

  @override
  String get chatRequestFailed => '请求失败';

  @override
  String get chatTaskCreated => '任务已创建';

  @override
  String get chatScheduleCreated => '定时任务已创建';

  @override
  String chatCreateFailed(String error) {
    return '创建失败: $error';
  }

  @override
  String chatUploadFailed(String error) {
    return '上传失败: $error';
  }

  @override
  String get chatAnalyzeImage => '请分析这张图片';

  @override
  String chatImageLabel(String name) {
    return '[图片] $name';
  }

  @override
  String chatImageUploaded(String name, String path) {
    return '[图片文件已上传: $name，保存在 $path]';
  }

  @override
  String chatAnalyzeFile(String context) {
    return '请阅读并分析以下文件内容:\n\n$context';
  }

  @override
  String chatUserQuestion(String text) {
    return '用户问题: $text';
  }

  @override
  String chatFileLabel(String name) {
    return '[文件: $name]';
  }

  @override
  String chatAttachmentLabel(String name) {
    return '[附件] $name';
  }

  @override
  String chatImageUploadedAnalyze(String name, String path) {
    return '[图片文件已上传: $name，保存在 $path]\n请描述或处理这个图片文件。你可以使用 read_document 工具读取它。';
  }

  @override
  String chatImageUploadedWithText(String name, String path, String text) {
    return '[图片文件已上传: $name，保存在 $path]\n\n$text';
  }

  @override
  String get chatFileUploaded => '文件已上传: ';

  @override
  String get plusMenuSendFile => '发送文件';

  @override
  String get plusMenuCreateTask => '创建任务';

  @override
  String get plusMenuCreateTaskDesc => '一次性或重复执行的任务';

  @override
  String get plusMenuTaskTitle => '任务标题';

  @override
  String get plusMenuTaskDesc => '任务描述（可选）';

  @override
  String get plusMenuOneTime => '一次性执行';

  @override
  String get plusMenuRecurring => '重复执行';

  @override
  String get plusMenuFrequency => '重复频率';

  @override
  String get plusMenuEvery => '每';

  @override
  String get plusMenuExecuteTime => '执行时间：';

  @override
  String get plusMenuDeadline => '截止时间：';

  @override
  String get plusMenuNoDeadline => '永不截止';

  @override
  String get plusMenuSetDeadline => '设置截止';

  @override
  String get plusMenuSelectDate => '选择日期';

  @override
  String get plusMenuMonth => '月';

  @override
  String get plusMenuWeek => '周';

  @override
  String get plusMenuDay => '天';

  @override
  String get plusMenuHour => '小时';

  @override
  String get plusMenuMinute => '分钟';

  @override
  String get agentCreateTitle => '招募新员工';

  @override
  String get agentCreateStepBasic => '基本信息';

  @override
  String get agentCreateStepPersonality => '性格设定';

  @override
  String agentCreateLoadFailed(String error) {
    return '加载资源失败: $error';
  }

  @override
  String get agentCreateNameRequired => '请输入 Agent 名称';

  @override
  String get agentCreateModelRequired => '请选择主模型';

  @override
  String agentCreateFailed(String error) {
    return '创建失败: $error';
  }

  @override
  String get agentCreatePrevStep => '上一步';

  @override
  String get agentCreateNextStep => '下一步';

  @override
  String get agentCreateCreating => '创建中...';

  @override
  String get agentCreateSubmit => '创建 Agent';

  @override
  String get agentCreateBasicTitle => '基本信息与模型';

  @override
  String get agentCreateBasicSubtitle => '设置 Agent 的名称、角色和使用的 AI 模型。';

  @override
  String get agentCreateNameLabel => 'Agent 名称 *';

  @override
  String get agentCreateNameHint => '例：研究助手';

  @override
  String get agentCreateRoleLabel => '角色描述';

  @override
  String get agentCreateRoleHint => '描述这个 Agent 的职责...';

  @override
  String get agentCreateTemplateLabel => '模板';

  @override
  String get agentCreateTemplateHint => '选择模板（可选）';

  @override
  String get agentCreatePrimaryModelLabel => '主模型 *';

  @override
  String get agentCreateModelTip => '提示：请先前往「设置 → 模型池」添加 LLM 模型';

  @override
  String get agentCreatePrimaryModelHint => '选择主 AI 模型';

  @override
  String get agentCreateFallbackModelLabel => '备用模型';

  @override
  String get agentCreateFallbackModelHint => '选择备用模型（可选）';

  @override
  String get agentCreateDailyTokenLimit => '每日 Token 上限';

  @override
  String get agentCreateMonthlyTokenLimit => '每月 Token 上限';

  @override
  String get agentCreatePersonalityTitle => '性格与边界';

  @override
  String get agentCreatePersonalitySubtitle => '定义 Agent 的沟通风格和行为边界。';

  @override
  String get agentCreatePersonalityLabel => '性格特征';

  @override
  String get agentCreatePersonalityHint => '描述性格特征、语气和沟通风格...';

  @override
  String get agentCreateBoundariesLabel => '行为边界';

  @override
  String get agentCreateBoundariesHint => '列出 Agent 必须避免的话题或行为...';

  @override
  String get agentDetailTabOverview => '状态';

  @override
  String get agentDetailTabTasks => '任务';

  @override
  String get agentDetailTabMind => '思维';

  @override
  String get agentDetailTabTools => '工具';

  @override
  String get agentDetailTabSkills => '技能';

  @override
  String get agentDetailTabWorkspace => '工作区';

  @override
  String get agentDetailTabActivity => '活动';

  @override
  String get agentDetailTabSettings => '设置';

  @override
  String get agentDetailNotFound => '未找到 Agent';

  @override
  String get agentDetailUntitled => '未命名 Agent';

  @override
  String get agentDetailDeleteTitle => '删除智能体';

  @override
  String get agentDetailDeleteConfirm => '确认永久删除这个智能体吗？此操作不可撤销。';

  @override
  String get agentDetailDeleted => '智能体已删除';

  @override
  String agentDetailDeleteFailed(String error) {
    return '删除失败: $error';
  }

  @override
  String agentDetailLoadTasksFailed(String error) {
    return '加载任务失败: $error';
  }

  @override
  String agentDetailLoadFilesFailed(String error) {
    return '加载文件失败: $error';
  }

  @override
  String agentDetailLoadActivityFailed(String error) {
    return '加载活动失败: $error';
  }

  @override
  String get agentDetailSkillImported => '技能已导入';

  @override
  String agentDetailImportFailed(String error) {
    return '导入失败: $error';
  }

  @override
  String get agentDetailSoulSaved => 'soul.md 已保存';

  @override
  String agentDetailSoulSaveFailed(String error) {
    return '保存 soul.md 失败: $error';
  }

  @override
  String agentDetailToolToggleFailed(String error) {
    return '工具开关失败: $error';
  }

  @override
  String get agentDetailConfig => '配置';

  @override
  String get agentDetailToolConfigSaved => '工具配置已保存';

  @override
  String agentDetailSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get agentDetailSaveConfig => '保存配置';

  @override
  String get agentDetailSettingsSaved => '设置已保存';

  @override
  String agentDetailSettingsSaveFailed(String error) {
    return '保存设置失败: $error';
  }

  @override
  String agentDetailReadFileFailed(String error) {
    return '读取文件失败: $error';
  }

  @override
  String agentDetailOpenSkillFolderFailed(String error) {
    return '打开技能文件夹失败: $error';
  }

  @override
  String agentDetailReadSkillFileFailed(String error) {
    return '读取技能文件失败: $error';
  }

  @override
  String agentDetailOpenFolderFailed(String error) {
    return '打开文件夹失败: $error';
  }

  @override
  String get agentDetailDeleteSkillTitle => '删除技能';

  @override
  String agentDetailDeleteSkillConfirm(String name) {
    return '确认删除 \"$name\" 吗？';
  }

  @override
  String get agentDetailSkillDeleted => '技能已删除';

  @override
  String agentDetailDeleteSkillFailed(String error) {
    return '删除技能失败: $error';
  }

  @override
  String get agentDetailDeleteFileTitle => '删除文件';

  @override
  String agentDetailDeleteFileConfirm(String name) {
    return '确认删除 \"$name\" 吗？';
  }

  @override
  String get agentDetailFileDeleted => '文件已删除';

  @override
  String agentDetailDeleteFileFailed(String error) {
    return '删除文件失败: $error';
  }

  @override
  String get agentDetailMemoryEmpty => '(空)';

  @override
  String agentDetailReadMemoryFailed(String error) {
    return '读取记忆文件失败: $error';
  }

  @override
  String get agentDetailDeleteChannelTitle => '删除通道';

  @override
  String get agentDetailDeleteChannelConfirm => '确认删除通道配置吗？';

  @override
  String get agentDetailChannelDeleted => '通道已删除';

  @override
  String agentDetailDeleteChannelFailed(String error) {
    return '删除通道失败: $error';
  }

  @override
  String get agentDetailDeleteScheduleTitle => '删除计划';

  @override
  String get agentDetailDeleteScheduleConfirm => '确认删除此计划吗？';

  @override
  String get agentDetailScheduleDeleted => '计划已删除';

  @override
  String agentDetailDeleteScheduleFailed(String error) {
    return '删除计划失败: $error';
  }

  @override
  String get agentDetailNameUpdated => '名称已更新';

  @override
  String agentDetailNameUpdateFailed(String error) {
    return '更新名称失败: $error';
  }

  @override
  String get agentDetailTaskTriggered => '任务已触发，执行中...';

  @override
  String agentDetailTriggerTaskFailed(String error) {
    return '触发任务失败: $error';
  }

  @override
  String get agentDetailScheduleTriggered => '计划已手动触发';

  @override
  String agentDetailTriggerScheduleFailed(String error) {
    return '触发计划失败: $error';
  }

  @override
  String get agentDetailChannelCreated => '通道已创建';

  @override
  String agentDetailCreateChannelFailed(String error) {
    return '创建通道失败: $error';
  }

  @override
  String get agentDetailFileUploaded => '文件已上传';

  @override
  String agentDetailUploadFailed(String error) {
    return '上传失败: $error';
  }

  @override
  String get agentDetailNewFile => '新建文件';

  @override
  String get agentDetailFileName => '文件名';

  @override
  String get agentDetailFileNameHint => 'example.md';

  @override
  String get agentDetailContent => '内容';

  @override
  String get agentDetailFileCreated => '文件已创建';

  @override
  String agentDetailCreateFileFailed(String error) {
    return '创建文件失败: $error';
  }

  @override
  String get agentDetailNewFolder => '新建文件夹';

  @override
  String get agentDetailFolderName => '文件夹名';

  @override
  String get agentDetailFolderCreated => '文件夹已创建';

  @override
  String agentDetailCreateFolderFailed(String error) {
    return '创建文件夹失败: $error';
  }

  @override
  String agentDetailEditFile(String name) {
    return '编辑 $name';
  }

  @override
  String get agentDetailFileSaved => '文件已保存';

  @override
  String get agentDetailNewSkill => '新建技能';

  @override
  String get agentDetailSkillCreated => '技能已创建';

  @override
  String agentDetailCreateSkillFailed(String error) {
    return '创建技能失败: $error';
  }

  @override
  String agentDetailEditSkill(String name) {
    return '编辑 $name';
  }

  @override
  String get agentDetailSkillSaved => '技能已保存';

  @override
  String get agentDetailFilterAll => '全部';

  @override
  String get agentDetailFilterPending => '待处理';

  @override
  String get agentDetailFilterInProgress => '进行中';

  @override
  String get agentDetailFilterCompleted => '已完成';

  @override
  String get agentDetailFilterFailed => '失败';

  @override
  String get agentDetailFilterUser => '用户';

  @override
  String get agentDetailFilterSystem => '系统';

  @override
  String get agentDetailFilterError => '错误';

  @override
  String get agentDetailToolReadFile => '读取文件';

  @override
  String get agentDetailToolWriteFile => '写入工作区文件';

  @override
  String get agentDetailToolDeleteFile => '删除文件';

  @override
  String get agentDetailToolSendMessage => '发送消息';

  @override
  String get agentDetailToolWebSearch => '网络搜索';

  @override
  String get agentDetailToolManageTasks => '管理任务';

  @override
  String get agentDetailToolLevelAuto => '自动';

  @override
  String get agentDetailToolLevelNotify => '通知';

  @override
  String get agentDetailToolLevelApproval => '审批';

  @override
  String sharedWidgetsReadFailed(String error) {
    return '读取失败: $error';
  }

  @override
  String get sharedWidgetsTrigger => '触发执行';

  @override
  String get sharedWidgetsNoRecords => '暂无执行记录';

  @override
  String get overviewStats => '数据统计';

  @override
  String get overviewMonthlyTokens => '月度 Token';

  @override
  String get overviewDailyTokens => '每日 Token';

  @override
  String get overviewTodayLlmCalls => '今日 LLM 调用';

  @override
  String get overviewTotalTasks => '总任务';

  @override
  String get overviewCompleted => '已完成';

  @override
  String get overviewOps24h => '24h操作';

  @override
  String get overviewRecentActivity => '近期活动';

  @override
  String get overviewBasicInfo => '基本信息';

  @override
  String get overviewCreatedAt => '创建时间';

  @override
  String get overviewCreator => '创建者';

  @override
  String get overviewLastActivity => '最后活动';

  @override
  String get tasksTodo => '待办';

  @override
  String get tasksInProgress => '进行中';

  @override
  String get tasksCompleted => '已完成';

  @override
  String get tasksNoTodo => '暂无待办';

  @override
  String get tasksNoInProgress => '暂无进行中';

  @override
  String get tasksNoCompleted => '暂无已完成';

  @override
  String get tasksCreateToStart => '创建任务或计划开始吧';

  @override
  String get tasksNoSchedules => '暂无计划';

  @override
  String get tasksScheduleFallback => '计划';

  @override
  String tasksNextFire(String time) {
    return '下次: $time';
  }

  @override
  String tasksRunCount(int count) {
    return '已执行 $count 次';
  }

  @override
  String get tasksNoTitle => '无标题';

  @override
  String get tasksTrigger => '触发';

  @override
  String get tasksWeekMon => '一';

  @override
  String get tasksWeekTue => '二';

  @override
  String get tasksWeekWed => '三';

  @override
  String get tasksWeekThu => '四';

  @override
  String get tasksWeekFri => '五';

  @override
  String get tasksWeekSat => '六';

  @override
  String get tasksWeekSun => '日';

  @override
  String get tasksNewTask => '新建任务';

  @override
  String get tasksTaskTitle => '任务标题';

  @override
  String get tasksTaskDesc => '任务描述（可选）';

  @override
  String get tasksOneTime => '一次性执行';

  @override
  String get tasksRecurring => '重复执行';

  @override
  String get tasksFrequency => '重复频率';

  @override
  String get tasksDaily => '每天';

  @override
  String get tasksWeekly => '每周';

  @override
  String get tasksMonthly => '每月';

  @override
  String get tasksHourly => '每小时';

  @override
  String get tasksEveryMinute => '每分钟';

  @override
  String get tasksEvery => '每';

  @override
  String get tasksUnitDay => '天';

  @override
  String get tasksUnitWeek => '周';

  @override
  String get tasksUnitMonth => '个月';

  @override
  String get tasksUnitHour => '小时';

  @override
  String get tasksUnitMinute => '分钟';

  @override
  String get tasksDayOfMonth => '几号执行';

  @override
  String tasksDaySuffix(int day) {
    return '$day号';
  }

  @override
  String get tasksDayOfWeek => '周几执行';

  @override
  String get tasksTimeOfDay => '几点执行';

  @override
  String get tasksDeadline => '截止时间：';

  @override
  String get tasksNoDeadline => '永不截止';

  @override
  String get tasksSetDeadline => '设置截止';

  @override
  String get tasksSelectDate => '选择日期';

  @override
  String get tasksScheduleCreated => '计划已创建';

  @override
  String get tasksTaskCreated => '任务已创建';

  @override
  String tasksCreateFailed(String error) {
    return '创建失败: $error';
  }

  @override
  String mindCharCount(int count) {
    return '$count 字';
  }

  @override
  String get mindEmpty => '空';

  @override
  String get mindSoulPlaceholder => '定义 Agent 的性格和核心行为...';

  @override
  String get mindNoContent => '暂无内容，点击编辑按钮创建。';

  @override
  String get mindHeartbeatNoContent => '暂无内容';

  @override
  String get mindMemoryFiles => '记忆文件';

  @override
  String mindFileCount(int count) {
    return '$count 个文件';
  }

  @override
  String get mindNoMemoryFiles => '暂无记忆文件。';

  @override
  String mindBytes(int size) {
    return '$size 字节';
  }

  @override
  String get toolsCategoryFileOps => '文件操作';

  @override
  String get toolsCategoryTaskMgmt => '任务管理';

  @override
  String get toolsCategoryComm => '通讯';

  @override
  String get toolsCategorySearch => '搜索';

  @override
  String get toolsCategoryCode => '代码';

  @override
  String get toolsCategoryDiscovery => '发现';

  @override
  String get toolsCategoryTrigger => '触发器';

  @override
  String get toolsCategoryPlaza => '广场';

  @override
  String get toolsCategoryCustom => '自定义';

  @override
  String get toolsCategoryGeneral => '通用';

  @override
  String get toolsCount => '工具';

  @override
  String get toolsPlatform => '平台工具';

  @override
  String get toolsAgentInstalled => 'Agent 安装';

  @override
  String get toolsNoPlatform => '暂无平台工具';

  @override
  String get toolsNoInstalled => '暂无安装的工具';

  @override
  String get toolsNoInstalledHint => 'Agent 可通过 import_mcp_server 工具自行安装。';

  @override
  String get toolsUnknown => '未知';

  @override
  String get skillsLabel => '技能';

  @override
  String get skillsNewTooltip => '新建技能';

  @override
  String get skillsImportPreset => '导入预设技能';

  @override
  String get skillsPreset => '预设技能';

  @override
  String get skillsUnknown => '未知';

  @override
  String get skillsNoSkills => '暂无技能';

  @override
  String get skillsNoSkillsHint => '该 Agent 未找到技能文件。';

  @override
  String get skillsFolderEmpty => '文件夹为空';

  @override
  String get skillsFolderEmptyHint => '该技能文件夹下没有文件。';

  @override
  String get skillsDeleteTooltip => '删除技能';

  @override
  String skillsBytes(int size) {
    return '$size 字节';
  }

  @override
  String get workspaceFile => '文件';

  @override
  String get workspaceRoot => '根目录';

  @override
  String get workspaceRootTitle => '工作区 (根目录)';

  @override
  String get workspaceGoUp => '返回上级';

  @override
  String get workspaceNewFolder => '新建文件夹';

  @override
  String get workspaceNewFile => '新建文件';

  @override
  String get workspaceUploadFile => '上传文件';

  @override
  String get workspaceEmptyDir => '空目录';

  @override
  String get workspaceEmptyDirHint => '该目录下没有文件。';

  @override
  String workspaceBytes(int size) {
    return '$size 字节';
  }

  @override
  String get activityTitle => '活动日志';

  @override
  String get activityNoActivity => '暂无活动';

  @override
  String get activityNoActivityHint => '该 Agent 尚未记录任何活动。';

  @override
  String get activityTypeChatReply => '聊天回复';

  @override
  String get activityTypeWebMessage => '网页消息';

  @override
  String get activityTypeAgentMessage => 'Agent 消息';

  @override
  String get activityTypeFeishuMessage => '飞书消息';

  @override
  String get activityTypeToolCall => '工具调用';

  @override
  String get activityTypeTaskCreate => '任务创建';

  @override
  String get activityTypeTaskUpdate => '任务更新';

  @override
  String get activityTypeTaskComplete => '任务完成';

  @override
  String get activityTypeTaskFail => '任务失败';

  @override
  String get activityTypeError => '错误';

  @override
  String get activityTypeHeartbeat => '心跳';

  @override
  String get activityTypeSchedule => '定时任务';

  @override
  String get activityTypeFileWrite => '文件写入';

  @override
  String get activityTypePlazaPost => '广场动态';

  @override
  String get activityTypeStart => '启动';

  @override
  String get activityTypeStop => '停止';

  @override
  String get settingsModelConfig => '模型配置';

  @override
  String get settingsPrimaryModel => '主模型';

  @override
  String get settingsFallbackModel => '备用模型';

  @override
  String get settingsMaxTokens => 'Token 上限';

  @override
  String get settingsTemperature => '温度';

  @override
  String get settingsContextWindow => '上下文窗口';

  @override
  String get settingsMaxToolRounds => '最大工具轮次';

  @override
  String get settingsTokenLimits => 'Token 限额';

  @override
  String get settingsDailyTokenLimit => '每日 Token 限额';

  @override
  String get settingsMonthlyTokenLimit => '每月 Token 限额';

  @override
  String get settingsNoLimit => '不限';

  @override
  String get settingsSaveSettings => '保存设置';

  @override
  String get settingsHeartbeat => '心跳';

  @override
  String get settingsHeartbeatDesc => '定时巡检广场、执行工作，会消耗 Token';

  @override
  String get settingsInterval => '间隔';

  @override
  String get settingsMinutes => '分钟';

  @override
  String settingsMinInterval(int min) {
    return '(最低 $min 分钟)';
  }

  @override
  String get settingsActiveHours => '活跃时段';

  @override
  String settingsIntervalAdjusted(int interval) {
    return '间隔已调整为最低 $interval 分钟';
  }

  @override
  String get settingsHeartbeatSaved => '心跳设置已保存';

  @override
  String settingsSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String settingsLastHeartbeat(String time) {
    return '上次心跳: $time';
  }

  @override
  String get settingsChannelConfig => '通道配置';

  @override
  String get settingsNoChannel => '未配置通道。';

  @override
  String get settingsConfigChannel => '配置通道';

  @override
  String get settingsChannelType => '通道类型';

  @override
  String get settingsFeishu => '飞书';

  @override
  String get settingsEncryptKey => 'Encrypt Key (可选)';

  @override
  String get settingsChannelStatus => '状态';

  @override
  String get settingsChannelTypeName => '类型';

  @override
  String get settingsBotName => '机器人名称';

  @override
  String get settingsDeleteChannel => '删除通道';

  @override
  String get settingsDangerZone => '危险操作';

  @override
  String get settingsDangerHint => 'Agent 一旦删除将无法恢复，请谨慎操作。';

  @override
  String get settingsDeleteAgent => '删除智能体';

  @override
  String get settingsDeleteAgentConfirm => '确定要删除吗？';

  @override
  String get settingsConfirmDelete => '确认删除';

  @override
  String get settingsNotSelected => '未选择';

  @override
  String get settingsNotUsed => '不使用';

  @override
  String get settingsNoModelHint => '请先在设置中配置模型';

  @override
  String get settingsModelTip => '提示：请先前往「设置 → 模型池」添加 LLM 模型';

  @override
  String get enterpriseModelPool => '模型池';

  @override
  String get enterpriseTools => '工具';

  @override
  String get enterpriseSettings => '设置';

  @override
  String get llmAddModel => '添加模型';

  @override
  String get llmEditModel => '编辑模型';

  @override
  String get llmProvider => '供应商';

  @override
  String get llmModelName => '模型名称';

  @override
  String get llmDisplayName => '显示名称';

  @override
  String get llmCustomBaseUrl => '自定义 Base URL';

  @override
  String get llmKeepUnchanged => '留空保持不变';

  @override
  String get llmVisionSupport => '支持视觉（多模态）';

  @override
  String get llmVisionHint => '勾选后可分析图片';

  @override
  String get llmTest => '测试';

  @override
  String get llmNoModels => '暂无模型配置';

  @override
  String get llmEnabled => '已启用';

  @override
  String get llmDisabled => '已禁用';

  @override
  String get llmVision => '视觉';

  @override
  String get llmSaveFailed => '保存模型失败';

  @override
  String get llmDeleteTitle => '删除模型';

  @override
  String get llmDeleteConfirm => '确定要删除这个模型吗？';

  @override
  String get llmModelInUse => '模型使用中';

  @override
  String llmModelInUseConfirm(String agents) {
    return '此模型正在被以下 Agent 使用: $agents\n\n确定删除吗？';
  }

  @override
  String get llmForceDelete => '强制删除';

  @override
  String get llmDeleteFailed => '删除模型失败';

  @override
  String get llmTestNeedKey => '测试需要重新输入 API Key';

  @override
  String get llmTestFillRequired => '请先填写模型名称和 API Key';

  @override
  String get llmTestFailed => '测试请求失败';

  @override
  String get llmKimiProvider => 'Kimi (月之暗面)';

  @override
  String get llmCustomProvider => '自定义';

  @override
  String get toolsTabGlobal => '全局工具';

  @override
  String get toolsTabMcp => 'MCP 服务器';

  @override
  String get toolsTabAddMcp => '添加 MCP 服务器';

  @override
  String get toolsTabServerName => '服务器名称';

  @override
  String get toolsTabServerNameHint => '我的 MCP 服务器';

  @override
  String get toolsTabServerUrl => 'MCP 服务器地址';

  @override
  String get toolsTabTesting => '测试中...';

  @override
  String get toolsTabTestConnection => '测试连接';

  @override
  String toolsTabConnectSuccess(int count) {
    return '连接成功！发现 $count 个工具';
  }

  @override
  String get toolsTabImport => '导入';

  @override
  String toolsTabConnectFailed(String error) {
    return '连接失败: $error';
  }

  @override
  String get toolsTabNoTools => '暂无可用工具';

  @override
  String get toolsTabBuiltIn => '内置';

  @override
  String get toolsTabDefault => '默认';

  @override
  String get toolsTabDeleteTitle => '删除工具';

  @override
  String toolsTabDeleteConfirm(String name) {
    return '确定删除 \"$name\" 吗？';
  }

  @override
  String get toolsTabDeleteFailed => '删除工具失败';

  @override
  String toolsTabImported(String name) {
    return '已导入 $name';
  }

  @override
  String get toolsTabImportFailed => '导入工具失败';

  @override
  String get toolsTabUnknownError => '未知错误';

  @override
  String get skillsTabTitle => 'Skills 注册表';

  @override
  String get skillsTabDesc1 => '管理全局技能。每个技能是一个包含 SKILL.md 文件的文件夹。';

  @override
  String get skillsTabDesc2 => '创建 Agent 时选择的技能会被复制到 Agent 的工作区。';

  @override
  String get skillsTabNoSkills => '暂无技能';

  @override
  String get skillsTabGoUp => '返回上级';

  @override
  String get skillsTabRefresh => '刷新';

  @override
  String get skillsTabEmptyDir => '空目录';

  @override
  String skillsTabLoadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String get skillTemplateContent =>
      '# Skill: 新技能\n\n## 触发条件\n当用户请求...\n\n## 执行步骤\n1. ...\n2. ...\n\n## 注意事项\n- ...\n';

  @override
  String get homeTabPlaza => '广场';

  @override
  String get homeTabDashboard => '仪表盘';

  @override
  String get chatOtherUser => '其他用户';
}
