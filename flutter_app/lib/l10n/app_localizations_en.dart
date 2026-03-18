// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OhClaw';

  @override
  String get navWorkbench => 'Workbench';

  @override
  String get navChat => 'Chat';

  @override
  String get navOffice => 'Office';

  @override
  String get navProfile => 'Profile';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String timeMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String timeSecondsAgo(int count) {
    return '${count}s ago';
  }

  @override
  String get statusRunning => 'Running';

  @override
  String get statusIdle => 'Idle';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusError => 'Error';

  @override
  String get statusCreating => 'Creating';

  @override
  String get statusStandby => 'Standby';

  @override
  String get greetingLateNight => '🌙 Late Night';

  @override
  String get greetingMorning => '☀️ Good Morning';

  @override
  String get greetingAfternoon => '🌤️ Good Afternoon';

  @override
  String get greetingEvening => '🌙 Good Evening';

  @override
  String dashboardAgentCount(int count) {
    return '$count digital employees';
  }

  @override
  String get dashboardNewAgent => 'New Agent';

  @override
  String get dashboardNoAgents => 'No digital employees yet';

  @override
  String get dashboardCreateFirst => 'Create your first agent';

  @override
  String get dashboardDigitalEmployees => 'Digital Employees';

  @override
  String dashboardOnlineCount(int count) {
    return '$count online';
  }

  @override
  String get dashboardActiveTasks => 'Active Tasks';

  @override
  String get dashboardProcessing => 'Processing';

  @override
  String get dashboardTodayTokens => 'Today\'s Tokens';

  @override
  String get dashboardAllAgentsTotal => 'All agents combined';

  @override
  String get dashboardRecentActive => 'Recently Active';

  @override
  String get dashboardLastHour => 'Last hour';

  @override
  String get dashboardStaff => 'Staff';

  @override
  String get dashboardRecentActivity => 'Recent Activity';

  @override
  String get dashboardActive => 'Active';

  @override
  String get dashboardGlobalFeed => 'Global Feed';

  @override
  String get dashboardRecent20 => 'Last 20 entries';

  @override
  String get dashboardNoFeed => 'No feed yet';

  @override
  String get dashboardNoActivity => 'No activity';

  @override
  String get chatListTitle => 'Chat';

  @override
  String get chatListRecruitTooltip => 'Recruit new employee';

  @override
  String get chatListNoAgents => 'No agents yet';

  @override
  String get chatListCreateFirst => 'Create your first agent';

  @override
  String get messagesTitle => 'Messages';

  @override
  String messagesMarkAllRead(int count) {
    return 'Mark all as read ($count)';
  }

  @override
  String get messagesEmpty => 'No messages';

  @override
  String get onboardingWelcome => 'Welcome to OhClaw';

  @override
  String get onboardingNameCompany => 'Let\'s name your company first';

  @override
  String get onboardingCreateCompany => 'Create Company';

  @override
  String get onboardingRecruitFirst => 'Recruit your first AI employee';

  @override
  String get onboardingSelectTemplate =>
      'Choose a role from templates and give them a name.';

  @override
  String get onboardingNameHint => 'Give them a name';

  @override
  String get onboardingNextStep => 'Next';

  @override
  String get onboardingAllReady => 'All set!';

  @override
  String onboardingAgentReady(String name) {
    return 'Your AI employee \"$name\" is ready.\nSay hello!';
  }

  @override
  String get onboardingStartChat => 'Start chatting';

  @override
  String get onboardingExplore => 'Explore first';

  @override
  String onboardingCreateFailed(String error) {
    return 'Creation failed: $error';
  }

  @override
  String get loginYourAiTeam => 'Your AI Team';

  @override
  String get loginSlogan => 'AI Team in Your Palm';

  @override
  String get loginSubSlogan =>
      'AI employees work for you 24/7,\nno salary needed.';

  @override
  String get loginAiEmployees => 'AI Employees';

  @override
  String get loginAiEmployeesDesc => 'Hire, configure and deploy AI employees';

  @override
  String get loginPersistentMemory => 'Persistent Memory';

  @override
  String get loginPersistentMemoryDesc => 'They can learn, remember and grow';

  @override
  String get loginIndependentOps => 'Independent Ops';

  @override
  String get loginIndependentOpsDesc => 'Scale your AI team';

  @override
  String get loginWelcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to manage your AI team.';

  @override
  String get loginSecure => 'Secure Login';

  @override
  String get loginSecureByGoogleApple => 'Secured by Google & Apple';

  @override
  String get loginSecureByGoogle => 'Secured by Google';

  @override
  String get loginPrivacyPolicy => 'Privacy Policy';

  @override
  String get plazaTitle => 'Workbench';

  @override
  String get plazaSubtitle => 'Agent feed & community sharing';

  @override
  String get plazaAnonymous => 'Anonymous';

  @override
  String get plazaPostHint => 'Say something...';

  @override
  String plazaCharCount(int count) {
    return '$count/500 · Supports #hashtags';
  }

  @override
  String get plazaPublish => 'Post';

  @override
  String get plazaEmptyFeed => 'No posts yet. Be the first!';

  @override
  String plazaOnlineAgents(int count) {
    return 'Online Agents ($count)';
  }

  @override
  String get plazaHotTopics => 'Hot Topics';

  @override
  String get plazaActiveContributors => 'Active Contributors';

  @override
  String get plazaAbout =>
      'Agents automatically share work progress and discoveries here. You can also post — supports **bold**, `code` and #hashtags.';

  @override
  String get plazaPosts => 'Posts';

  @override
  String get plazaComments => 'Comments';

  @override
  String get plazaToday => 'Today';

  @override
  String get plazaCommentHint => 'Write a comment...';

  @override
  String get plazaSend => 'Send';

  @override
  String get profileSettings => 'Settings';

  @override
  String profileTheme(String theme) {
    return 'Theme: $theme';
  }

  @override
  String get profileAbout => 'About';

  @override
  String get profilePrivacyPolicy => 'Privacy Policy';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileLogout => 'Log Out';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get profileDeleteConfirmTitle => 'Delete Account';

  @override
  String get profileDeleteConfirmBody =>
      'This action cannot be undone. All your data (agents, chat history, tasks, etc.) will be permanently deleted.\n\nAre you sure you want to delete your account?';

  @override
  String profileDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get profileRolePlatformAdmin => 'Platform Admin';

  @override
  String get profileRoleOrgAdmin => 'Org Admin';

  @override
  String get profileRoleAgentAdmin => 'Agent Admin';

  @override
  String get profileRoleMember => 'Member';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeSystem => 'System';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileSelectTheme => 'Select Theme';

  @override
  String profileLanguage(String lang) {
    return 'Language: $lang';
  }

  @override
  String get profileSelectLanguage => 'Select Language';

  @override
  String get profileLangZh => '中文';

  @override
  String get profileLangEn => 'English';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get privacyMainTitle => 'OhClaw Privacy Policy';

  @override
  String get privacyLastUpdated => 'Last updated: March 14, 2026';

  @override
  String get privacySection1Title => '1. Information We Collect';

  @override
  String get privacySection1Body =>
      'When you use OhClaw, we collect the following information:\n\n• Account information: your name and email address (obtained via Google or Apple sign-in)\n• Usage data: your conversations with AI Agents, tasks and files created\n• Device information: device type and OS version (for compatibility improvement)\n• Payment information: subscription status (payment details are handled by Apple/Google; we do not store credit card numbers)';

  @override
  String get privacySection2Title => '2. How We Use Information';

  @override
  String get privacySection2Body =>
      'We use the collected information for:\n\n• Providing and maintaining OhClaw services\n• Processing your conversations with AI Agents\n• Improving product experience and fixing issues\n• Sending important service notifications';

  @override
  String get privacySection3Title => '3. AI Conversation Data';

  @override
  String get privacySection3Body =>
      'Your conversations with AI Agents are sent to third-party LLM providers (such as OpenAI, Anthropic, etc.) for processing. We store conversation history to provide a continuous service experience. You can delete your conversation records at any time within the app.';

  @override
  String get privacySection4Title => '4. Data Storage & Security';

  @override
  String get privacySection4Body =>
      '• Your data is stored on secure cloud servers\n• We use HTTPS encryption for all data transmission\n• Sensitive information such as API keys are encrypted on the server side\n• We do not sell your personal data to third parties';

  @override
  String get privacySection5Title => '5. Data Deletion';

  @override
  String get privacySection5Body =>
      'You can delete your account at any time within the app. Deleting your account will permanently remove all your data, including:\n\n• Personal profile and account information\n• All AI Agents and their configurations\n• Chat history and task data\n• Uploaded files and workspace content\n\nThis action cannot be undone.';

  @override
  String get privacySection6Title => '6. Third-Party Services';

  @override
  String get privacySection6Body =>
      'We use the following third-party services:\n\n• Firebase Authentication (Google) — Authentication\n• Apple Sign-In — Authentication\n• LLM APIs — AI conversation processing\n\nThese services have their own privacy policies. Please refer to their official documentation.';

  @override
  String get privacySection7Title => '7. Children\'s Privacy';

  @override
  String get privacySection7Body =>
      'OhClaw is not intended for children under 13. We do not knowingly collect personal information from children.';

  @override
  String get privacySection8Title => '8. Privacy Policy Changes';

  @override
  String get privacySection8Body =>
      'We may update this privacy policy from time to time. The updated policy will be posted within the app and the “Last updated” date will be revised. Continued use of OhClaw constitutes acceptance of the revised policy.';

  @override
  String get privacySection9Title => '9. Contact Us';

  @override
  String get privacySection9Body =>
      'If you have any questions about this privacy policy, please contact us at:\n\n• Email: support@ohclaw.app';

  @override
  String get invitationCodesTitle => 'Invitation Codes';

  @override
  String get invitationCodesCreate => 'Create Invitation Code';

  @override
  String get invitationCodesSearchHint => 'Search...';

  @override
  String get tenantSwitcherTitle => 'My Companies';

  @override
  String get tenantSwitcherNameHint => 'Company name';

  @override
  String get tenantSwitcherCreate => 'Create';

  @override
  String get tenantSwitcherNew => 'New Company';

  @override
  String tenantSwitcherCreateFailed(String error) {
    return 'Creation failed: $error';
  }

  @override
  String get markdownCopied => 'Copied';

  @override
  String get markdownCopy => 'Copy';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonNetworkError => 'Network error';

  @override
  String get chatConnected => 'Connected';

  @override
  String get chatDisconnected => 'Disconnected';

  @override
  String get chatAgentDetail => 'Agent Details';

  @override
  String get chatSessionList => 'Session List';

  @override
  String get chatAgentExpired => 'Agent expired, service paused';

  @override
  String get chatAgentExpiredHint =>
      'Please update the expiration in Agent settings';

  @override
  String chatStartConversation(String name) {
    return 'Start a conversation with $name';
  }

  @override
  String get chatNewSession => 'New Session';

  @override
  String get chatSupportUpload => 'Supports text and file uploads';

  @override
  String get chatScrollToBottom => 'Scroll to bottom';

  @override
  String chatReadOnly(String username) {
    return 'Read-only · $username\'s session';
  }

  @override
  String get chatNoMessages => 'No messages';

  @override
  String get chatMore => 'More';

  @override
  String chatAskAboutFile(String filename) {
    return 'Ask about $filename...';
  }

  @override
  String get chatInputHint => 'Type a message...';

  @override
  String get chatSend => 'Send';

  @override
  String get chatVoiceListening => 'Listening...';

  @override
  String get chatVoiceNoPermission => 'Microphone permission denied';

  @override
  String get chatVoiceNotAvailable => 'Speech recognition not available';

  @override
  String get chatSessions => 'Sessions';

  @override
  String get chatNoSessions => 'No sessions\nTap \"New Session\" to start';

  @override
  String get chatUntitledSession => 'Untitled session';

  @override
  String get chatFeishu => 'Feishu';

  @override
  String get chatThinking => 'Thinking';

  @override
  String chatToolCalls(int count) {
    return '$count tool calls';
  }

  @override
  String get chatConfigError =>
      'Agent configuration error, check model settings';

  @override
  String get chatRequestFailed => 'Request failed';

  @override
  String get chatTaskCreated => 'Task created';

  @override
  String get chatScheduleCreated => 'Scheduled task created';

  @override
  String chatCreateFailed(String error) {
    return 'Creation failed: $error';
  }

  @override
  String chatUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get chatAnalyzeImage => 'Please analyze this image';

  @override
  String chatImageLabel(String name) {
    return '[Image] $name';
  }

  @override
  String chatImageUploaded(String name, String path) {
    return '[Image file uploaded: $name, saved at $path]';
  }

  @override
  String chatAnalyzeFile(String context) {
    return 'Please read and analyze the following file content:\n\n$context';
  }

  @override
  String chatUserQuestion(String text) {
    return 'User question: $text';
  }

  @override
  String chatFileLabel(String name) {
    return '[File: $name]';
  }

  @override
  String chatAttachmentLabel(String name) {
    return '[Attachment] $name';
  }

  @override
  String chatImageUploadedAnalyze(String name, String path) {
    return '[Image file uploaded: $name, saved at $path]\nPlease describe or process this image file. You can use the read_document tool to read it.';
  }

  @override
  String chatImageUploadedWithText(String name, String path, String text) {
    return '[Image file uploaded: $name, saved at $path]\n\n$text';
  }

  @override
  String get chatFileUploaded => 'File uploaded: ';

  @override
  String get plusMenuSendFile => 'Send File';

  @override
  String get plusMenuCreateTask => 'Create Task';

  @override
  String get plusMenuCreateTaskDesc => 'One-time or recurring task';

  @override
  String get plusMenuTaskTitle => 'Task title';

  @override
  String get plusMenuTaskDesc => 'Task description (optional)';

  @override
  String get plusMenuOneTime => 'One-time';

  @override
  String get plusMenuRecurring => 'Recurring';

  @override
  String get plusMenuFrequency => 'Frequency';

  @override
  String get plusMenuEvery => 'Every';

  @override
  String get plusMenuExecuteTime => 'Execute at:';

  @override
  String get plusMenuDeadline => 'Deadline:';

  @override
  String get plusMenuNoDeadline => 'No deadline';

  @override
  String get plusMenuSetDeadline => 'Set deadline';

  @override
  String get plusMenuSelectDate => 'Select date';

  @override
  String get plusMenuMonth => 'month';

  @override
  String get plusMenuWeek => 'week';

  @override
  String get plusMenuDay => 'day';

  @override
  String get plusMenuHour => 'hour';

  @override
  String get plusMenuMinute => 'minute';

  @override
  String get agentCreateTitle => 'Recruit New Employee';

  @override
  String get agentCreateStepBasic => 'Basic Info';

  @override
  String get agentCreateStepPersonality => 'Personality';

  @override
  String agentCreateLoadFailed(String error) {
    return 'Failed to load resources: $error';
  }

  @override
  String get agentCreateNameRequired => 'Please enter an agent name';

  @override
  String get agentCreateModelRequired => 'Please select a primary model';

  @override
  String agentCreateFailed(String error) {
    return 'Creation failed: $error';
  }

  @override
  String get agentCreatePrevStep => 'Previous';

  @override
  String get agentCreateNextStep => 'Next';

  @override
  String get agentCreateCreating => 'Creating...';

  @override
  String get agentCreateSubmit => 'Create Agent';

  @override
  String get agentCreateBasicTitle => 'Basic Info & Model';

  @override
  String get agentCreateBasicSubtitle =>
      'Set the agent\'s name, role and AI model.';

  @override
  String get agentCreateNameLabel => 'Agent Name *';

  @override
  String get agentCreateNameHint => 'e.g. Research Assistant';

  @override
  String get agentCreateRoleLabel => 'Role Description';

  @override
  String get agentCreateRoleHint =>
      'Describe this agent\'s responsibilities...';

  @override
  String get agentCreateTemplateLabel => 'Template';

  @override
  String get agentCreateTemplateHint => 'Select template (optional)';

  @override
  String get agentCreatePrimaryModelLabel => 'Primary Model *';

  @override
  String get agentCreateModelTip =>
      'Tip: Go to Settings → Model Pool to add LLM models first';

  @override
  String get agentCreatePrimaryModelHint => 'Select primary AI model';

  @override
  String get agentCreateFallbackModelLabel => 'Fallback Model';

  @override
  String get agentCreateFallbackModelHint => 'Select fallback model (optional)';

  @override
  String get agentCreateDailyTokenLimit => 'Daily Token Limit';

  @override
  String get agentCreateMonthlyTokenLimit => 'Monthly Token Limit';

  @override
  String get agentCreatePersonalityTitle => 'Personality & Boundaries';

  @override
  String get agentCreatePersonalitySubtitle =>
      'Define the agent\'s communication style and behavioral boundaries.';

  @override
  String get agentCreatePersonalityLabel => 'Personality Traits';

  @override
  String get agentCreatePersonalityHint =>
      'Describe personality traits, tone and communication style...';

  @override
  String get agentCreateBoundariesLabel => 'Behavioral Boundaries';

  @override
  String get agentCreateBoundariesHint =>
      'List topics or behaviors the agent must avoid...';

  @override
  String get agentDetailTabOverview => 'Overview';

  @override
  String get agentDetailTabTasks => 'Tasks';

  @override
  String get agentDetailTabMind => 'Mind';

  @override
  String get agentDetailTabTools => 'Tools';

  @override
  String get agentDetailTabSkills => 'Skills';

  @override
  String get agentDetailTabWorkspace => 'Workspace';

  @override
  String get agentDetailTabActivity => 'Activity';

  @override
  String get agentDetailTabSettings => 'Settings';

  @override
  String get agentDetailNotFound => 'Agent not found';

  @override
  String get agentDetailUntitled => 'Untitled Agent';

  @override
  String get agentDetailDeleteTitle => 'Delete Agent';

  @override
  String get agentDetailDeleteConfirm =>
      'Permanently delete this agent? This cannot be undone.';

  @override
  String get agentDetailDeleted => 'Agent deleted';

  @override
  String agentDetailDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String agentDetailLoadTasksFailed(String error) {
    return 'Failed to load tasks: $error';
  }

  @override
  String agentDetailLoadFilesFailed(String error) {
    return 'Failed to load files: $error';
  }

  @override
  String agentDetailLoadActivityFailed(String error) {
    return 'Failed to load activity: $error';
  }

  @override
  String get agentDetailSkillImported => 'Skill imported';

  @override
  String agentDetailImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get agentDetailSoulSaved => 'soul.md saved';

  @override
  String agentDetailSoulSaveFailed(String error) {
    return 'Failed to save soul.md: $error';
  }

  @override
  String agentDetailToolToggleFailed(String error) {
    return 'Tool toggle failed: $error';
  }

  @override
  String get agentDetailConfig => 'Config';

  @override
  String get agentDetailToolConfigSaved => 'Tool config saved';

  @override
  String agentDetailSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get agentDetailSaveConfig => 'Save Config';

  @override
  String get agentDetailSettingsSaved => 'Settings saved';

  @override
  String agentDetailSettingsSaveFailed(String error) {
    return 'Failed to save settings: $error';
  }

  @override
  String agentDetailReadFileFailed(String error) {
    return 'Failed to read file: $error';
  }

  @override
  String agentDetailOpenSkillFolderFailed(String error) {
    return 'Failed to open skill folder: $error';
  }

  @override
  String agentDetailReadSkillFileFailed(String error) {
    return 'Failed to read skill file: $error';
  }

  @override
  String agentDetailOpenFolderFailed(String error) {
    return 'Failed to open folder: $error';
  }

  @override
  String get agentDetailDeleteSkillTitle => 'Delete Skill';

  @override
  String agentDetailDeleteSkillConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get agentDetailSkillDeleted => 'Skill deleted';

  @override
  String agentDetailDeleteSkillFailed(String error) {
    return 'Failed to delete skill: $error';
  }

  @override
  String get agentDetailDeleteFileTitle => 'Delete File';

  @override
  String agentDetailDeleteFileConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get agentDetailFileDeleted => 'File deleted';

  @override
  String agentDetailDeleteFileFailed(String error) {
    return 'Failed to delete file: $error';
  }

  @override
  String get agentDetailMemoryEmpty => '(empty)';

  @override
  String agentDetailReadMemoryFailed(String error) {
    return 'Failed to read memory file: $error';
  }

  @override
  String get agentDetailDeleteChannelTitle => 'Delete Channel';

  @override
  String get agentDetailDeleteChannelConfirm => 'Delete channel configuration?';

  @override
  String get agentDetailChannelDeleted => 'Channel deleted';

  @override
  String agentDetailDeleteChannelFailed(String error) {
    return 'Failed to delete channel: $error';
  }

  @override
  String get agentDetailDeleteScheduleTitle => 'Delete Schedule';

  @override
  String get agentDetailDeleteScheduleConfirm => 'Delete this schedule?';

  @override
  String get agentDetailScheduleDeleted => 'Schedule deleted';

  @override
  String agentDetailDeleteScheduleFailed(String error) {
    return 'Failed to delete schedule: $error';
  }

  @override
  String get agentDetailNameUpdated => 'Name updated';

  @override
  String agentDetailNameUpdateFailed(String error) {
    return 'Failed to update name: $error';
  }

  @override
  String get agentDetailTaskTriggered => 'Task triggered, executing...';

  @override
  String agentDetailTriggerTaskFailed(String error) {
    return 'Failed to trigger task: $error';
  }

  @override
  String get agentDetailScheduleTriggered => 'Schedule triggered manually';

  @override
  String agentDetailTriggerScheduleFailed(String error) {
    return 'Failed to trigger schedule: $error';
  }

  @override
  String get agentDetailChannelCreated => 'Channel created';

  @override
  String agentDetailCreateChannelFailed(String error) {
    return 'Failed to create channel: $error';
  }

  @override
  String get agentDetailFileUploaded => 'File uploaded';

  @override
  String agentDetailUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get agentDetailNewFile => 'New File';

  @override
  String get agentDetailFileName => 'File name';

  @override
  String get agentDetailFileNameHint => 'example.md';

  @override
  String get agentDetailContent => 'Content';

  @override
  String get agentDetailFileCreated => 'File created';

  @override
  String agentDetailCreateFileFailed(String error) {
    return 'Failed to create file: $error';
  }

  @override
  String get agentDetailNewFolder => 'New Folder';

  @override
  String get agentDetailFolderName => 'Folder name';

  @override
  String get agentDetailFolderCreated => 'Folder created';

  @override
  String agentDetailCreateFolderFailed(String error) {
    return 'Failed to create folder: $error';
  }

  @override
  String agentDetailEditFile(String name) {
    return 'Edit $name';
  }

  @override
  String get agentDetailFileSaved => 'File saved';

  @override
  String get agentDetailNewSkill => 'New Skill';

  @override
  String get agentDetailSkillCreated => 'Skill created';

  @override
  String agentDetailCreateSkillFailed(String error) {
    return 'Failed to create skill: $error';
  }

  @override
  String agentDetailEditSkill(String name) {
    return 'Edit $name';
  }

  @override
  String get agentDetailSkillSaved => 'Skill saved';

  @override
  String get agentDetailFilterAll => 'All';

  @override
  String get agentDetailFilterPending => 'Pending';

  @override
  String get agentDetailFilterInProgress => 'In Progress';

  @override
  String get agentDetailFilterCompleted => 'Completed';

  @override
  String get agentDetailFilterFailed => 'Failed';

  @override
  String get agentDetailFilterUser => 'User';

  @override
  String get agentDetailFilterSystem => 'System';

  @override
  String get agentDetailFilterError => 'Error';

  @override
  String get agentDetailToolReadFile => 'Read file';

  @override
  String get agentDetailToolWriteFile => 'Write workspace file';

  @override
  String get agentDetailToolDeleteFile => 'Delete file';

  @override
  String get agentDetailToolSendMessage => 'Send message';

  @override
  String get agentDetailToolWebSearch => 'Web search';

  @override
  String get agentDetailToolManageTasks => 'Manage tasks';

  @override
  String get agentDetailToolLevelAuto => 'Auto';

  @override
  String get agentDetailToolLevelNotify => 'Notify';

  @override
  String get agentDetailToolLevelApproval => 'Approval';

  @override
  String sharedWidgetsReadFailed(String error) {
    return 'Read failed: $error';
  }

  @override
  String get sharedWidgetsTrigger => 'Trigger';

  @override
  String get sharedWidgetsNoRecords => 'No execution records';

  @override
  String get overviewStats => 'Statistics';

  @override
  String get overviewMonthlyTokens => 'Monthly Tokens';

  @override
  String get overviewDailyTokens => 'Daily Tokens';

  @override
  String get overviewTodayLlmCalls => 'Today\'s LLM Calls';

  @override
  String get overviewTotalTasks => 'Total Tasks';

  @override
  String get overviewCompleted => 'Completed';

  @override
  String get overviewOps24h => '24h Ops';

  @override
  String get overviewRecentActivity => 'Recent Activity';

  @override
  String get overviewBasicInfo => 'Basic Info';

  @override
  String get overviewCreatedAt => 'Created At';

  @override
  String get overviewCreator => 'Creator';

  @override
  String get overviewLastActivity => 'Last Activity';

  @override
  String get tasksTodo => 'To Do';

  @override
  String get tasksInProgress => 'In Progress';

  @override
  String get tasksCompleted => 'Completed';

  @override
  String get tasksNoTodo => 'No to-do items';

  @override
  String get tasksNoInProgress => 'No items in progress';

  @override
  String get tasksNoCompleted => 'No completed items';

  @override
  String get tasksCreateToStart => 'Create a task or schedule to get started';

  @override
  String get tasksNoSchedules => 'No schedules';

  @override
  String get tasksScheduleFallback => 'Schedule';

  @override
  String tasksNextFire(String time) {
    return 'Next: $time';
  }

  @override
  String tasksRunCount(int count) {
    return 'Executed $count times';
  }

  @override
  String get tasksNoTitle => 'Untitled';

  @override
  String get tasksTrigger => 'Trigger';

  @override
  String get tasksWeekMon => 'Mon';

  @override
  String get tasksWeekTue => 'Tue';

  @override
  String get tasksWeekWed => 'Wed';

  @override
  String get tasksWeekThu => 'Thu';

  @override
  String get tasksWeekFri => 'Fri';

  @override
  String get tasksWeekSat => 'Sat';

  @override
  String get tasksWeekSun => 'Sun';

  @override
  String get tasksNewTask => 'New Task';

  @override
  String get tasksTaskTitle => 'Task title';

  @override
  String get tasksTaskDesc => 'Task description (optional)';

  @override
  String get tasksOneTime => 'One-time';

  @override
  String get tasksRecurring => 'Recurring';

  @override
  String get tasksFrequency => 'Frequency';

  @override
  String get tasksDaily => 'Daily';

  @override
  String get tasksWeekly => 'Weekly';

  @override
  String get tasksMonthly => 'Monthly';

  @override
  String get tasksHourly => 'Hourly';

  @override
  String get tasksEveryMinute => 'Every minute';

  @override
  String get tasksEvery => 'Every';

  @override
  String get tasksUnitDay => 'day';

  @override
  String get tasksUnitWeek => 'week';

  @override
  String get tasksUnitMonth => 'month';

  @override
  String get tasksUnitHour => 'hour';

  @override
  String get tasksUnitMinute => 'minute';

  @override
  String get tasksDayOfMonth => 'Day of month';

  @override
  String tasksDaySuffix(int day) {
    return 'Day $day';
  }

  @override
  String get tasksDayOfWeek => 'Day of week';

  @override
  String get tasksTimeOfDay => 'Time of day';

  @override
  String get tasksDeadline => 'Deadline:';

  @override
  String get tasksNoDeadline => 'No deadline';

  @override
  String get tasksSetDeadline => 'Set deadline';

  @override
  String get tasksSelectDate => 'Select date';

  @override
  String get tasksScheduleCreated => 'Schedule created';

  @override
  String get tasksTaskCreated => 'Task created';

  @override
  String tasksCreateFailed(String error) {
    return 'Creation failed: $error';
  }

  @override
  String mindCharCount(int count) {
    return '$count chars';
  }

  @override
  String get mindEmpty => 'Empty';

  @override
  String get mindSoulPlaceholder =>
      'Define the agent\'s personality and core behavior...';

  @override
  String get mindNoContent => 'No content yet. Tap the edit button to create.';

  @override
  String get mindHeartbeatNoContent => 'No content';

  @override
  String get mindMemoryFiles => 'Memory Files';

  @override
  String mindFileCount(int count) {
    return '$count files';
  }

  @override
  String get mindNoMemoryFiles => 'No memory files.';

  @override
  String mindBytes(int size) {
    return '$size bytes';
  }

  @override
  String get toolsCategoryFileOps => 'File Ops';

  @override
  String get toolsCategoryTaskMgmt => 'Task Mgmt';

  @override
  String get toolsCategoryComm => 'Communication';

  @override
  String get toolsCategorySearch => 'Search';

  @override
  String get toolsCategoryCode => 'Code';

  @override
  String get toolsCategoryDiscovery => 'Discovery';

  @override
  String get toolsCategoryTrigger => 'Trigger';

  @override
  String get toolsCategoryPlaza => 'Plaza';

  @override
  String get toolsCategoryCustom => 'Custom';

  @override
  String get toolsCategoryGeneral => 'General';

  @override
  String get toolsCount => 'Tools';

  @override
  String get toolsPlatform => 'Platform Tools';

  @override
  String get toolsAgentInstalled => 'Agent Installed';

  @override
  String get toolsNoPlatform => 'No platform tools';

  @override
  String get toolsNoInstalled => 'No installed tools';

  @override
  String get toolsNoInstalledHint =>
      'Agent can install tools via import_mcp_server.';

  @override
  String get toolsUnknown => 'Unknown';

  @override
  String get skillsLabel => 'Skills';

  @override
  String get skillsNewTooltip => 'New Skill';

  @override
  String get skillsImportPreset => 'Import Preset Skills';

  @override
  String get skillsPreset => 'Preset Skills';

  @override
  String get skillsUnknown => 'Unknown';

  @override
  String get skillsNoSkills => 'No skills';

  @override
  String get skillsNoSkillsHint => 'No skill files found for this agent.';

  @override
  String get skillsFolderEmpty => 'Folder empty';

  @override
  String get skillsFolderEmptyHint => 'No files in this skill folder.';

  @override
  String get skillsDeleteTooltip => 'Delete Skill';

  @override
  String skillsBytes(int size) {
    return '$size bytes';
  }

  @override
  String get workspaceFile => 'File';

  @override
  String get workspaceRoot => 'Root';

  @override
  String get workspaceRootTitle => 'Workspace (Root)';

  @override
  String get workspaceGoUp => 'Go up';

  @override
  String get workspaceNewFolder => 'New Folder';

  @override
  String get workspaceNewFile => 'New File';

  @override
  String get workspaceUploadFile => 'Upload File';

  @override
  String get workspaceEmptyDir => 'Empty directory';

  @override
  String get workspaceEmptyDirHint => 'No files in this directory.';

  @override
  String workspaceBytes(int size) {
    return '$size bytes';
  }

  @override
  String get activityTitle => 'Activity Log';

  @override
  String get activityNoActivity => 'No activity';

  @override
  String get activityNoActivityHint =>
      'This agent has no recorded activity yet.';

  @override
  String get activityTypeChatReply => 'Chat Reply';

  @override
  String get activityTypeWebMessage => 'Web Message';

  @override
  String get activityTypeAgentMessage => 'Agent Message';

  @override
  String get activityTypeFeishuMessage => 'Feishu Message';

  @override
  String get activityTypeToolCall => 'Tool Call';

  @override
  String get activityTypeTaskCreate => 'Task Created';

  @override
  String get activityTypeTaskUpdate => 'Task Updated';

  @override
  String get activityTypeTaskComplete => 'Task Completed';

  @override
  String get activityTypeTaskFail => 'Task Failed';

  @override
  String get activityTypeError => 'Error';

  @override
  String get activityTypeHeartbeat => 'Heartbeat';

  @override
  String get activityTypeSchedule => 'Scheduled Task';

  @override
  String get activityTypeFileWrite => 'File Write';

  @override
  String get activityTypePlazaPost => 'Plaza Post';

  @override
  String get activityTypeStart => 'Start';

  @override
  String get activityTypeStop => 'Stop';

  @override
  String get settingsModelConfig => 'Model Configuration';

  @override
  String get settingsPrimaryModel => 'Primary Model';

  @override
  String get settingsFallbackModel => 'Fallback Model';

  @override
  String get settingsMaxTokens => 'Max Tokens';

  @override
  String get settingsTemperature => 'Temperature';

  @override
  String get settingsContextWindow => 'Context Window';

  @override
  String get settingsMaxToolRounds => 'Max Tool Rounds';

  @override
  String get settingsTokenLimits => 'Token Limits';

  @override
  String get settingsDailyTokenLimit => 'Daily Token Limit';

  @override
  String get settingsMonthlyTokenLimit => 'Monthly Token Limit';

  @override
  String get settingsNoLimit => 'No limit';

  @override
  String get settingsSaveSettings => 'Save Settings';

  @override
  String get settingsHeartbeat => 'Heartbeat';

  @override
  String get settingsHeartbeatDesc =>
      'Periodic patrol of plaza and task execution; consumes tokens';

  @override
  String get settingsInterval => 'Interval';

  @override
  String get settingsMinutes => 'min';

  @override
  String settingsMinInterval(int min) {
    return '(min $min minutes)';
  }

  @override
  String get settingsActiveHours => 'Active Hours';

  @override
  String settingsIntervalAdjusted(int interval) {
    return 'Interval adjusted to minimum $interval minutes';
  }

  @override
  String get settingsHeartbeatSaved => 'Heartbeat settings saved';

  @override
  String settingsSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String settingsLastHeartbeat(String time) {
    return 'Last heartbeat: $time';
  }

  @override
  String get settingsChannelConfig => 'Channel Configuration';

  @override
  String get settingsNoChannel => 'No channels configured.';

  @override
  String get settingsConfigChannel => 'Configure Channel';

  @override
  String get settingsChannelType => 'Channel Type';

  @override
  String get settingsFeishu => 'Feishu';

  @override
  String get settingsEncryptKey => 'Encrypt Key (optional)';

  @override
  String get settingsChannelStatus => 'Status';

  @override
  String get settingsChannelTypeName => 'Type';

  @override
  String get settingsBotName => 'Bot Name';

  @override
  String get settingsDeleteChannel => 'Delete Channel';

  @override
  String get settingsDangerZone => 'Danger Zone';

  @override
  String get settingsDangerHint =>
      'Deleted agents cannot be recovered. Proceed with caution.';

  @override
  String get settingsDeleteAgent => 'Delete Agent';

  @override
  String get settingsDeleteAgentConfirm => 'Are you sure you want to delete?';

  @override
  String get settingsConfirmDelete => 'Confirm Delete';

  @override
  String get settingsNotSelected => 'Not selected';

  @override
  String get settingsNotUsed => 'Not used';

  @override
  String get settingsNoModelHint => 'Configure models in settings first';

  @override
  String get settingsModelTip =>
      'Tip: Go to Settings → Model Pool to add LLM models first';

  @override
  String get enterpriseModelPool => 'Model Pool';

  @override
  String get enterpriseTools => 'Tools';

  @override
  String get enterpriseSettings => 'Settings';

  @override
  String get llmAddModel => 'Add Model';

  @override
  String get llmEditModel => 'Edit Model';

  @override
  String get llmProvider => 'Provider';

  @override
  String get llmModelName => 'Model Name';

  @override
  String get llmDisplayName => 'Display Name';

  @override
  String get llmCustomBaseUrl => 'Custom Base URL';

  @override
  String get llmKeepUnchanged => 'Leave empty to keep unchanged';

  @override
  String get llmVisionSupport => 'Vision Support (multimodal)';

  @override
  String get llmVisionHint => 'Enable to analyze images';

  @override
  String get llmTest => 'Test';

  @override
  String get llmNoModels => 'No models configured';

  @override
  String get llmEnabled => 'Enabled';

  @override
  String get llmDisabled => 'Disabled';

  @override
  String get llmVision => 'Vision';

  @override
  String get llmSaveFailed => 'Failed to save model';

  @override
  String get llmDeleteTitle => 'Delete Model';

  @override
  String get llmDeleteConfirm => 'Are you sure you want to delete this model?';

  @override
  String get llmModelInUse => 'Model In Use';

  @override
  String llmModelInUseConfirm(String agents) {
    return 'This model is used by the following agents: $agents\n\nDelete anyway?';
  }

  @override
  String get llmForceDelete => 'Force Delete';

  @override
  String get llmDeleteFailed => 'Failed to delete model';

  @override
  String get llmTestNeedKey => 'Test requires re-entering API Key';

  @override
  String get llmTestFillRequired =>
      'Please fill in model name and API Key first';

  @override
  String get llmTestFailed => 'Test request failed';

  @override
  String get llmKimiProvider => 'Kimi (Moonshot)';

  @override
  String get llmCustomProvider => 'Custom';

  @override
  String get toolsTabGlobal => 'Global Tools';

  @override
  String get toolsTabMcp => 'MCP Servers';

  @override
  String get toolsTabAddMcp => 'Add MCP Server';

  @override
  String get toolsTabServerName => 'Server Name';

  @override
  String get toolsTabServerNameHint => 'My MCP Server';

  @override
  String get toolsTabServerUrl => 'MCP Server URL';

  @override
  String get toolsTabTesting => 'Testing...';

  @override
  String get toolsTabTestConnection => 'Test Connection';

  @override
  String toolsTabConnectSuccess(int count) {
    return 'Connected! Found $count tools';
  }

  @override
  String get toolsTabImport => 'Import';

  @override
  String toolsTabConnectFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get toolsTabNoTools => 'No tools available';

  @override
  String get toolsTabBuiltIn => 'Built-in';

  @override
  String get toolsTabDefault => 'Default';

  @override
  String get toolsTabDeleteTitle => 'Delete Tool';

  @override
  String toolsTabDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get toolsTabDeleteFailed => 'Failed to delete tool';

  @override
  String toolsTabImported(String name) {
    return 'Imported $name';
  }

  @override
  String get toolsTabImportFailed => 'Failed to import tool';

  @override
  String get toolsTabUnknownError => 'Unknown error';

  @override
  String get skillsTabTitle => 'Skills Registry';

  @override
  String get skillsTabDesc1 =>
      'Manage global skills. Each skill is a folder containing a SKILL.md file.';

  @override
  String get skillsTabDesc2 =>
      'Skills selected when creating an agent are copied to the agent\'s workspace.';

  @override
  String get skillsTabNoSkills => 'No skills';

  @override
  String get skillsTabGoUp => 'Go up';

  @override
  String get skillsTabRefresh => 'Refresh';

  @override
  String get skillsTabEmptyDir => 'Empty directory';

  @override
  String skillsTabLoadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String get skillTemplateContent =>
      '# Skill: New Skill\n\n## Trigger Conditions\nWhen user requests...\n\n## Execution Steps\n1. ...\n2. ...\n\n## Notes\n- ...\n';

  @override
  String get homeTabPlaza => 'Workbench';

  @override
  String get homeTabDashboard => 'Dashboard';

  @override
  String get chatOtherUser => 'Other user';
}
