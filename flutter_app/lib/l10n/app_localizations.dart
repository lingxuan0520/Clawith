import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'OhClaw'**
  String get appName;

  /// No description provided for @navWorkbench.
  ///
  /// In zh, this message translates to:
  /// **'工作台'**
  String get navWorkbench;

  /// No description provided for @navChat.
  ///
  /// In zh, this message translates to:
  /// **'聊天'**
  String get navChat;

  /// No description provided for @navOffice.
  ///
  /// In zh, this message translates to:
  /// **'办公室'**
  String get navOffice;

  /// No description provided for @navProfile.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get navProfile;

  /// No description provided for @timeJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count}分钟前'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count}小时前'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count}天前'**
  String timeDaysAgo(int count);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count}个月前'**
  String timeMonthsAgo(int count);

  /// No description provided for @timeSecondsAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count}秒前'**
  String timeSecondsAgo(int count);

  /// No description provided for @statusRunning.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get statusRunning;

  /// No description provided for @statusIdle.
  ///
  /// In zh, this message translates to:
  /// **'空闲'**
  String get statusIdle;

  /// No description provided for @statusStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停止'**
  String get statusStopped;

  /// No description provided for @statusError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get statusError;

  /// No description provided for @statusCreating.
  ///
  /// In zh, this message translates to:
  /// **'创建中'**
  String get statusCreating;

  /// No description provided for @statusStandby.
  ///
  /// In zh, this message translates to:
  /// **'待机'**
  String get statusStandby;

  /// No description provided for @greetingLateNight.
  ///
  /// In zh, this message translates to:
  /// **'🌙 夜深了'**
  String get greetingLateNight;

  /// No description provided for @greetingMorning.
  ///
  /// In zh, this message translates to:
  /// **'☀️ 早上好'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In zh, this message translates to:
  /// **'🌤️ 下午好'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In zh, this message translates to:
  /// **'🌙 晚上好'**
  String get greetingEvening;

  /// No description provided for @dashboardAgentCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 位数字员工'**
  String dashboardAgentCount(int count);

  /// No description provided for @dashboardNewAgent.
  ///
  /// In zh, this message translates to:
  /// **'新建智能体'**
  String get dashboardNewAgent;

  /// No description provided for @dashboardNoAgents.
  ///
  /// In zh, this message translates to:
  /// **'还没有数字员工'**
  String get dashboardNoAgents;

  /// No description provided for @dashboardCreateFirst.
  ///
  /// In zh, this message translates to:
  /// **'创建第一个智能体'**
  String get dashboardCreateFirst;

  /// No description provided for @dashboardDigitalEmployees.
  ///
  /// In zh, this message translates to:
  /// **'数字员工'**
  String get dashboardDigitalEmployees;

  /// No description provided for @dashboardOnlineCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 在线'**
  String dashboardOnlineCount(int count);

  /// No description provided for @dashboardActiveTasks.
  ///
  /// In zh, this message translates to:
  /// **'进行中任务'**
  String get dashboardActiveTasks;

  /// No description provided for @dashboardProcessing.
  ///
  /// In zh, this message translates to:
  /// **'处理中'**
  String get dashboardProcessing;

  /// No description provided for @dashboardTodayTokens.
  ///
  /// In zh, this message translates to:
  /// **'今日 Token'**
  String get dashboardTodayTokens;

  /// No description provided for @dashboardAllAgentsTotal.
  ///
  /// In zh, this message translates to:
  /// **'全部 Agent 合计'**
  String get dashboardAllAgentsTotal;

  /// No description provided for @dashboardRecentActive.
  ///
  /// In zh, this message translates to:
  /// **'最近活跃'**
  String get dashboardRecentActive;

  /// No description provided for @dashboardLastHour.
  ///
  /// In zh, this message translates to:
  /// **'最近1小时'**
  String get dashboardLastHour;

  /// No description provided for @dashboardStaff.
  ///
  /// In zh, this message translates to:
  /// **'员工'**
  String get dashboardStaff;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In zh, this message translates to:
  /// **'最近活动'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardActive.
  ///
  /// In zh, this message translates to:
  /// **'活跃'**
  String get dashboardActive;

  /// No description provided for @dashboardGlobalFeed.
  ///
  /// In zh, this message translates to:
  /// **'全局动态'**
  String get dashboardGlobalFeed;

  /// No description provided for @dashboardRecent20.
  ///
  /// In zh, this message translates to:
  /// **'最近 20 条'**
  String get dashboardRecent20;

  /// No description provided for @dashboardNoFeed.
  ///
  /// In zh, this message translates to:
  /// **'暂无动态'**
  String get dashboardNoFeed;

  /// No description provided for @dashboardNoActivity.
  ///
  /// In zh, this message translates to:
  /// **'暂无活动'**
  String get dashboardNoActivity;

  /// No description provided for @chatListTitle.
  ///
  /// In zh, this message translates to:
  /// **'聊天'**
  String get chatListTitle;

  /// No description provided for @chatListRecruitTooltip.
  ///
  /// In zh, this message translates to:
  /// **'招募新员工'**
  String get chatListRecruitTooltip;

  /// No description provided for @chatListNoAgents.
  ///
  /// In zh, this message translates to:
  /// **'还没有 Agent'**
  String get chatListNoAgents;

  /// No description provided for @chatListCreateFirst.
  ///
  /// In zh, this message translates to:
  /// **'创建第一个 Agent'**
  String get chatListCreateFirst;

  /// No description provided for @messagesTitle.
  ///
  /// In zh, this message translates to:
  /// **'消息'**
  String get messagesTitle;

  /// No description provided for @messagesMarkAllRead.
  ///
  /// In zh, this message translates to:
  /// **'全部标为已读 ({count})'**
  String messagesMarkAllRead(int count);

  /// No description provided for @messagesEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无消息'**
  String get messagesEmpty;

  /// No description provided for @onboardingWelcome.
  ///
  /// In zh, this message translates to:
  /// **'欢迎来到 OhClaw'**
  String get onboardingWelcome;

  /// No description provided for @onboardingNameCompany.
  ///
  /// In zh, this message translates to:
  /// **'先给你的公司起个名字吧'**
  String get onboardingNameCompany;

  /// No description provided for @onboardingCreateCompany.
  ///
  /// In zh, this message translates to:
  /// **'创建公司'**
  String get onboardingCreateCompany;

  /// No description provided for @onboardingRecruitFirst.
  ///
  /// In zh, this message translates to:
  /// **'招募你的第一个 AI 员工'**
  String get onboardingRecruitFirst;

  /// No description provided for @onboardingSelectTemplate.
  ///
  /// In zh, this message translates to:
  /// **'从模板中选择一个角色，给 TA 起个名字。'**
  String get onboardingSelectTemplate;

  /// No description provided for @onboardingNameHint.
  ///
  /// In zh, this message translates to:
  /// **'给 TA 起个名字'**
  String get onboardingNameHint;

  /// No description provided for @onboardingNextStep.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get onboardingNextStep;

  /// No description provided for @onboardingAllReady.
  ///
  /// In zh, this message translates to:
  /// **'一切准备就绪！'**
  String get onboardingAllReady;

  /// No description provided for @onboardingAgentReady.
  ///
  /// In zh, this message translates to:
  /// **'你的 AI 员工 \"{name}\" 已就位，\n和 TA 打个招呼吧。'**
  String onboardingAgentReady(String name);

  /// No description provided for @onboardingStartChat.
  ///
  /// In zh, this message translates to:
  /// **'开始聊天'**
  String get onboardingStartChat;

  /// No description provided for @onboardingExplore.
  ///
  /// In zh, this message translates to:
  /// **'先去看看'**
  String get onboardingExplore;

  /// No description provided for @onboardingCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败：{error}'**
  String onboardingCreateFailed(String error);

  /// No description provided for @loginYourAiTeam.
  ///
  /// In zh, this message translates to:
  /// **'你的专属 AI 团队'**
  String get loginYourAiTeam;

  /// No description provided for @loginSlogan.
  ///
  /// In zh, this message translates to:
  /// **'掌上 AI 团队'**
  String get loginSlogan;

  /// No description provided for @loginSubSlogan.
  ///
  /// In zh, this message translates to:
  /// **'AI 员工为你全天候工作，\n无需发工资。'**
  String get loginSubSlogan;

  /// No description provided for @loginAiEmployees.
  ///
  /// In zh, this message translates to:
  /// **'AI 员工'**
  String get loginAiEmployees;

  /// No description provided for @loginAiEmployeesDesc.
  ///
  /// In zh, this message translates to:
  /// **'雇佣、配置和部署 AI 员工'**
  String get loginAiEmployeesDesc;

  /// No description provided for @loginPersistentMemory.
  ///
  /// In zh, this message translates to:
  /// **'持久记忆'**
  String get loginPersistentMemory;

  /// No description provided for @loginPersistentMemoryDesc.
  ///
  /// In zh, this message translates to:
  /// **'他们能学习、记忆和成长'**
  String get loginPersistentMemoryDesc;

  /// No description provided for @loginIndependentOps.
  ///
  /// In zh, this message translates to:
  /// **'独立运营'**
  String get loginIndependentOps;

  /// No description provided for @loginIndependentOpsDesc.
  ///
  /// In zh, this message translates to:
  /// **'扩展你的 AI 团队'**
  String get loginIndependentOpsDesc;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In zh, this message translates to:
  /// **'欢迎回来'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'登录以管理你的 AI 团队。'**
  String get loginSubtitle;

  /// No description provided for @loginSecure.
  ///
  /// In zh, this message translates to:
  /// **'安全登录'**
  String get loginSecure;

  /// No description provided for @loginSecureByGoogleApple.
  ///
  /// In zh, this message translates to:
  /// **'由 Google 与 Apple 提供安全登录'**
  String get loginSecureByGoogleApple;

  /// No description provided for @loginSecureByGoogle.
  ///
  /// In zh, this message translates to:
  /// **'由 Google 提供安全登录'**
  String get loginSecureByGoogle;

  /// No description provided for @loginPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get loginPrivacyPolicy;

  /// No description provided for @plazaTitle.
  ///
  /// In zh, this message translates to:
  /// **'工作台'**
  String get plazaTitle;

  /// No description provided for @plazaSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'Agent 动态和社区分享'**
  String get plazaSubtitle;

  /// No description provided for @plazaAnonymous.
  ///
  /// In zh, this message translates to:
  /// **'匿名用户'**
  String get plazaAnonymous;

  /// No description provided for @plazaPostHint.
  ///
  /// In zh, this message translates to:
  /// **'说点什么...'**
  String get plazaPostHint;

  /// No description provided for @plazaCharCount.
  ///
  /// In zh, this message translates to:
  /// **'{count}/500 · 支持 #话题标签'**
  String plazaCharCount(int count);

  /// No description provided for @plazaPublish.
  ///
  /// In zh, this message translates to:
  /// **'发布'**
  String get plazaPublish;

  /// No description provided for @plazaEmptyFeed.
  ///
  /// In zh, this message translates to:
  /// **'还没有动态，来发第一条吧！'**
  String get plazaEmptyFeed;

  /// No description provided for @plazaOnlineAgents.
  ///
  /// In zh, this message translates to:
  /// **'在线 Agent ({count})'**
  String plazaOnlineAgents(int count);

  /// No description provided for @plazaHotTopics.
  ///
  /// In zh, this message translates to:
  /// **'热门话题'**
  String get plazaHotTopics;

  /// No description provided for @plazaActiveContributors.
  ///
  /// In zh, this message translates to:
  /// **'活跃贡献者'**
  String get plazaActiveContributors;

  /// No description provided for @plazaAbout.
  ///
  /// In zh, this message translates to:
  /// **'Agent 会在这里自动分享工作进展和发现。你也可以发帖，支持 **加粗**、`代码` 和 #话题标签。'**
  String get plazaAbout;

  /// No description provided for @plazaPosts.
  ///
  /// In zh, this message translates to:
  /// **'帖子'**
  String get plazaPosts;

  /// No description provided for @plazaComments.
  ///
  /// In zh, this message translates to:
  /// **'评论'**
  String get plazaComments;

  /// No description provided for @plazaToday.
  ///
  /// In zh, this message translates to:
  /// **'今日'**
  String get plazaToday;

  /// No description provided for @plazaCommentHint.
  ///
  /// In zh, this message translates to:
  /// **'写条评论...'**
  String get plazaCommentHint;

  /// No description provided for @plazaSend.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get plazaSend;

  /// No description provided for @profileSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get profileSettings;

  /// No description provided for @profileTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题: {theme}'**
  String profileTheme(String theme);

  /// No description provided for @profileAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get profileAbout;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get profilePrivacyPolicy;

  /// No description provided for @profileAccount.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get profileAccount;

  /// No description provided for @profileLogout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get profileLogout;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In zh, this message translates to:
  /// **'删除账号'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除账号'**
  String get profileDeleteConfirmTitle;

  /// No description provided for @profileDeleteConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'此操作不可撤回。你的所有数据（Agent、聊天记录、任务等）将被永久删除。\n\n确定要删除账号吗？'**
  String get profileDeleteConfirmBody;

  /// No description provided for @profileDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败: {error}'**
  String profileDeleteFailed(String error);

  /// No description provided for @profileRolePlatformAdmin.
  ///
  /// In zh, this message translates to:
  /// **'平台管理员'**
  String get profileRolePlatformAdmin;

  /// No description provided for @profileRoleOrgAdmin.
  ///
  /// In zh, this message translates to:
  /// **'企业管理员'**
  String get profileRoleOrgAdmin;

  /// No description provided for @profileRoleAgentAdmin.
  ///
  /// In zh, this message translates to:
  /// **'Agent 管理员'**
  String get profileRoleAgentAdmin;

  /// No description provided for @profileRoleMember.
  ///
  /// In zh, this message translates to:
  /// **'成员'**
  String get profileRoleMember;

  /// No description provided for @profileThemeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get profileThemeLight;

  /// No description provided for @profileThemeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get profileThemeSystem;

  /// No description provided for @profileThemeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get profileThemeDark;

  /// No description provided for @profileSelectTheme.
  ///
  /// In zh, this message translates to:
  /// **'选择主题'**
  String get profileSelectTheme;

  /// No description provided for @profileLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言: {lang}'**
  String profileLanguage(String lang);

  /// No description provided for @profileSelectLanguage.
  ///
  /// In zh, this message translates to:
  /// **'选择语言'**
  String get profileSelectLanguage;

  /// No description provided for @profileLangZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get profileLangZh;

  /// No description provided for @profileLangEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get profileLangEn;

  /// No description provided for @privacyTitle.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacyTitle;

  /// No description provided for @privacyMainTitle.
  ///
  /// In zh, this message translates to:
  /// **'OhClaw 隐私政策'**
  String get privacyMainTitle;

  /// No description provided for @privacyLastUpdated.
  ///
  /// In zh, this message translates to:
  /// **'最后更新：2026 年 3 月 14 日'**
  String get privacyLastUpdated;

  /// No description provided for @privacySection1Title.
  ///
  /// In zh, this message translates to:
  /// **'1. 我们收集的信息'**
  String get privacySection1Title;

  /// No description provided for @privacySection1Body.
  ///
  /// In zh, this message translates to:
  /// **'当你使用 OhClaw 时，我们会收集以下信息：\n\n• 账户信息：你的姓名、电子邮件地址（通过 Google 或 Apple 登录获取）\n• 使用数据：你与 AI Agent 的对话内容、创建的任务和文件\n• 设备信息：设备类型、操作系统版本（用于改善兼容性）\n• 支付信息：订阅状态（具体支付信息由 Apple/Google 处理，我们不存储信用卡号）'**
  String get privacySection1Body;

  /// No description provided for @privacySection2Title.
  ///
  /// In zh, this message translates to:
  /// **'2. 我们如何使用信息'**
  String get privacySection2Title;

  /// No description provided for @privacySection2Body.
  ///
  /// In zh, this message translates to:
  /// **'我们使用收集的信息用于：\n\n• 提供和维护 OhClaw 服务\n• 处理你与 AI Agent 的对话请求\n• 改善产品体验和修复问题\n• 发送重要的服务通知'**
  String get privacySection2Body;

  /// No description provided for @privacySection3Title.
  ///
  /// In zh, this message translates to:
  /// **'3. AI 对话数据'**
  String get privacySection3Title;

  /// No description provided for @privacySection3Body.
  ///
  /// In zh, this message translates to:
  /// **'你与 AI Agent 的对话内容会被发送到第三方大语言模型服务商（如 OpenAI、Anthropic 等）进行处理。我们会保存对话历史以提供持续的服务体验。你可以随时在 App 内删除对话记录。'**
  String get privacySection3Body;

  /// No description provided for @privacySection4Title.
  ///
  /// In zh, this message translates to:
  /// **'4. 数据存储与安全'**
  String get privacySection4Title;

  /// No description provided for @privacySection4Body.
  ///
  /// In zh, this message translates to:
  /// **'• 你的数据存储在安全的云服务器上\n• 我们使用 HTTPS 加密所有数据传输\n• API 密钥等敏感信息在服务器端加密存储\n• 我们不会出售你的个人数据给第三方'**
  String get privacySection4Body;

  /// No description provided for @privacySection5Title.
  ///
  /// In zh, this message translates to:
  /// **'5. 数据删除'**
  String get privacySection5Title;

  /// No description provided for @privacySection5Body.
  ///
  /// In zh, this message translates to:
  /// **'你可以随时在 App 内删除你的账号。删除账号将永久移除你的所有数据，包括：\n\n• 个人资料和账户信息\n• 所有 AI Agent 及其配置\n• 聊天记录和任务数据\n• 上传的文件和工作区内容\n\n此操作不可撤回。'**
  String get privacySection5Body;

  /// No description provided for @privacySection6Title.
  ///
  /// In zh, this message translates to:
  /// **'6. 第三方服务'**
  String get privacySection6Title;

  /// No description provided for @privacySection6Body.
  ///
  /// In zh, this message translates to:
  /// **'我们使用以下第三方服务：\n\n• Firebase Authentication（Google）— 身份验证\n• Apple Sign-In — 身份验证\n• 大语言模型 API — AI 对话处理\n\n这些服务有各自的隐私政策，请参阅其官方文档。'**
  String get privacySection6Body;

  /// No description provided for @privacySection7Title.
  ///
  /// In zh, this message translates to:
  /// **'7. 儿童隐私'**
  String get privacySection7Title;

  /// No description provided for @privacySection7Body.
  ///
  /// In zh, this message translates to:
  /// **'OhClaw 不面向 13 岁以下的儿童。我们不会故意收集儿童的个人信息。'**
  String get privacySection7Body;

  /// No description provided for @privacySection8Title.
  ///
  /// In zh, this message translates to:
  /// **'8. 隐私政策变更'**
  String get privacySection8Title;

  /// No description provided for @privacySection8Body.
  ///
  /// In zh, this message translates to:
  /// **'我们可能会不时更新本隐私政策。更新后的政策将在 App 内发布，并更新“最后更新”日期。继续使用 OhClaw 即表示你同意修改后的政策。'**
  String get privacySection8Body;

  /// No description provided for @privacySection9Title.
  ///
  /// In zh, this message translates to:
  /// **'9. 联系我们'**
  String get privacySection9Title;

  /// No description provided for @privacySection9Body.
  ///
  /// In zh, this message translates to:
  /// **'如果你对本隐私政策有任何疑问，请通过以下方式联系我们：\n\n• 电子邮件：support@ohclaw.app'**
  String get privacySection9Body;

  /// No description provided for @invitationCodesTitle.
  ///
  /// In zh, this message translates to:
  /// **'邀请码'**
  String get invitationCodesTitle;

  /// No description provided for @invitationCodesCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建邀请码'**
  String get invitationCodesCreate;

  /// No description provided for @invitationCodesSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索...'**
  String get invitationCodesSearchHint;

  /// No description provided for @tenantSwitcherTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的公司'**
  String get tenantSwitcherTitle;

  /// No description provided for @tenantSwitcherNameHint.
  ///
  /// In zh, this message translates to:
  /// **'公司名称'**
  String get tenantSwitcherNameHint;

  /// No description provided for @tenantSwitcherCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get tenantSwitcherCreate;

  /// No description provided for @tenantSwitcherNew.
  ///
  /// In zh, this message translates to:
  /// **'新建公司'**
  String get tenantSwitcherNew;

  /// No description provided for @tenantSwitcherCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败：{error}'**
  String tenantSwitcherCreateFailed(String error);

  /// No description provided for @markdownCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get markdownCopied;

  /// No description provided for @markdownCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get markdownCopy;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get commonCreate;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @commonNetworkError.
  ///
  /// In zh, this message translates to:
  /// **'网络错误'**
  String get commonNetworkError;

  /// No description provided for @chatConnected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get chatConnected;

  /// No description provided for @chatDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'未连接'**
  String get chatDisconnected;

  /// No description provided for @chatAgentDetail.
  ///
  /// In zh, this message translates to:
  /// **'Agent 详情'**
  String get chatAgentDetail;

  /// No description provided for @chatSessionList.
  ///
  /// In zh, this message translates to:
  /// **'会话列表'**
  String get chatSessionList;

  /// No description provided for @chatAgentExpired.
  ///
  /// In zh, this message translates to:
  /// **'Agent 已过期，暂停服务'**
  String get chatAgentExpired;

  /// No description provided for @chatAgentExpiredHint.
  ///
  /// In zh, this message translates to:
  /// **'请在 Agent 设置中更新过期时间'**
  String get chatAgentExpiredHint;

  /// No description provided for @chatStartConversation.
  ///
  /// In zh, this message translates to:
  /// **'开始与 {name} 对话'**
  String chatStartConversation(String name);

  /// No description provided for @chatNewSession.
  ///
  /// In zh, this message translates to:
  /// **'新建会话'**
  String get chatNewSession;

  /// No description provided for @chatSupportUpload.
  ///
  /// In zh, this message translates to:
  /// **'支持文本和文件上传'**
  String get chatSupportUpload;

  /// No description provided for @chatScrollToBottom.
  ///
  /// In zh, this message translates to:
  /// **'滚动到底部'**
  String get chatScrollToBottom;

  /// No description provided for @chatReadOnly.
  ///
  /// In zh, this message translates to:
  /// **'只读 · {username}的会话'**
  String chatReadOnly(String username);

  /// No description provided for @chatNoMessages.
  ///
  /// In zh, this message translates to:
  /// **'暂无消息'**
  String get chatNoMessages;

  /// No description provided for @chatMore.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get chatMore;

  /// No description provided for @chatAskAboutFile.
  ///
  /// In zh, this message translates to:
  /// **'询问关于 {filename}...'**
  String chatAskAboutFile(String filename);

  /// No description provided for @chatInputHint.
  ///
  /// In zh, this message translates to:
  /// **'输入消息...'**
  String get chatInputHint;

  /// No description provided for @chatSend.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get chatSend;

  /// No description provided for @chatSessions.
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get chatSessions;

  /// No description provided for @chatNoSessions.
  ///
  /// In zh, this message translates to:
  /// **'暂无会话\n点击「新建会话」开始'**
  String get chatNoSessions;

  /// No description provided for @chatUntitledSession.
  ///
  /// In zh, this message translates to:
  /// **'未命名会话'**
  String get chatUntitledSession;

  /// No description provided for @chatFeishu.
  ///
  /// In zh, this message translates to:
  /// **'飞书'**
  String get chatFeishu;

  /// No description provided for @chatThinking.
  ///
  /// In zh, this message translates to:
  /// **'思考中'**
  String get chatThinking;

  /// No description provided for @chatToolCalls.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个工具调用'**
  String chatToolCalls(int count);

  /// No description provided for @chatConfigError.
  ///
  /// In zh, this message translates to:
  /// **'Agent 配置错误，请检查模型设置'**
  String get chatConfigError;

  /// No description provided for @chatRequestFailed.
  ///
  /// In zh, this message translates to:
  /// **'请求失败'**
  String get chatRequestFailed;

  /// No description provided for @chatTaskCreated.
  ///
  /// In zh, this message translates to:
  /// **'任务已创建'**
  String get chatTaskCreated;

  /// No description provided for @chatScheduleCreated.
  ///
  /// In zh, this message translates to:
  /// **'定时任务已创建'**
  String get chatScheduleCreated;

  /// No description provided for @chatCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败: {error}'**
  String chatCreateFailed(String error);

  /// No description provided for @chatUploadFailed.
  ///
  /// In zh, this message translates to:
  /// **'上传失败: {error}'**
  String chatUploadFailed(String error);

  /// No description provided for @chatAnalyzeImage.
  ///
  /// In zh, this message translates to:
  /// **'请分析这张图片'**
  String get chatAnalyzeImage;

  /// No description provided for @chatImageLabel.
  ///
  /// In zh, this message translates to:
  /// **'[图片] {name}'**
  String chatImageLabel(String name);

  /// No description provided for @chatImageUploaded.
  ///
  /// In zh, this message translates to:
  /// **'[图片文件已上传: {name}，保存在 {path}]'**
  String chatImageUploaded(String name, String path);

  /// No description provided for @chatAnalyzeFile.
  ///
  /// In zh, this message translates to:
  /// **'请阅读并分析以下文件内容:\n\n{context}'**
  String chatAnalyzeFile(String context);

  /// No description provided for @chatUserQuestion.
  ///
  /// In zh, this message translates to:
  /// **'用户问题: {text}'**
  String chatUserQuestion(String text);

  /// No description provided for @chatFileLabel.
  ///
  /// In zh, this message translates to:
  /// **'[文件: {name}]'**
  String chatFileLabel(String name);

  /// No description provided for @chatAttachmentLabel.
  ///
  /// In zh, this message translates to:
  /// **'[附件] {name}'**
  String chatAttachmentLabel(String name);

  /// No description provided for @chatImageUploadedAnalyze.
  ///
  /// In zh, this message translates to:
  /// **'[图片文件已上传: {name}，保存在 {path}]\n请描述或处理这个图片文件。你可以使用 read_document 工具读取它。'**
  String chatImageUploadedAnalyze(String name, String path);

  /// No description provided for @chatImageUploadedWithText.
  ///
  /// In zh, this message translates to:
  /// **'[图片文件已上传: {name}，保存在 {path}]\n\n{text}'**
  String chatImageUploadedWithText(String name, String path, String text);

  /// No description provided for @chatFileUploaded.
  ///
  /// In zh, this message translates to:
  /// **'文件已上传: '**
  String get chatFileUploaded;

  /// No description provided for @plusMenuSendFile.
  ///
  /// In zh, this message translates to:
  /// **'发送文件'**
  String get plusMenuSendFile;

  /// No description provided for @plusMenuCreateTask.
  ///
  /// In zh, this message translates to:
  /// **'创建任务'**
  String get plusMenuCreateTask;

  /// No description provided for @plusMenuCreateTaskDesc.
  ///
  /// In zh, this message translates to:
  /// **'一次性或重复执行的任务'**
  String get plusMenuCreateTaskDesc;

  /// No description provided for @plusMenuTaskTitle.
  ///
  /// In zh, this message translates to:
  /// **'任务标题'**
  String get plusMenuTaskTitle;

  /// No description provided for @plusMenuTaskDesc.
  ///
  /// In zh, this message translates to:
  /// **'任务描述（可选）'**
  String get plusMenuTaskDesc;

  /// No description provided for @plusMenuOneTime.
  ///
  /// In zh, this message translates to:
  /// **'一次性执行'**
  String get plusMenuOneTime;

  /// No description provided for @plusMenuRecurring.
  ///
  /// In zh, this message translates to:
  /// **'重复执行'**
  String get plusMenuRecurring;

  /// No description provided for @plusMenuFrequency.
  ///
  /// In zh, this message translates to:
  /// **'重复频率'**
  String get plusMenuFrequency;

  /// No description provided for @plusMenuEvery.
  ///
  /// In zh, this message translates to:
  /// **'每'**
  String get plusMenuEvery;

  /// No description provided for @plusMenuExecuteTime.
  ///
  /// In zh, this message translates to:
  /// **'执行时间：'**
  String get plusMenuExecuteTime;

  /// No description provided for @plusMenuDeadline.
  ///
  /// In zh, this message translates to:
  /// **'截止时间：'**
  String get plusMenuDeadline;

  /// No description provided for @plusMenuNoDeadline.
  ///
  /// In zh, this message translates to:
  /// **'永不截止'**
  String get plusMenuNoDeadline;

  /// No description provided for @plusMenuSetDeadline.
  ///
  /// In zh, this message translates to:
  /// **'设置截止'**
  String get plusMenuSetDeadline;

  /// No description provided for @plusMenuSelectDate.
  ///
  /// In zh, this message translates to:
  /// **'选择日期'**
  String get plusMenuSelectDate;

  /// No description provided for @plusMenuMonth.
  ///
  /// In zh, this message translates to:
  /// **'月'**
  String get plusMenuMonth;

  /// No description provided for @plusMenuWeek.
  ///
  /// In zh, this message translates to:
  /// **'周'**
  String get plusMenuWeek;

  /// No description provided for @plusMenuDay.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get plusMenuDay;

  /// No description provided for @plusMenuHour.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get plusMenuHour;

  /// No description provided for @plusMenuMinute.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get plusMenuMinute;

  /// No description provided for @agentCreateTitle.
  ///
  /// In zh, this message translates to:
  /// **'招募新员工'**
  String get agentCreateTitle;

  /// No description provided for @agentCreateStepBasic.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get agentCreateStepBasic;

  /// No description provided for @agentCreateStepPersonality.
  ///
  /// In zh, this message translates to:
  /// **'性格设定'**
  String get agentCreateStepPersonality;

  /// No description provided for @agentCreateLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载资源失败: {error}'**
  String agentCreateLoadFailed(String error);

  /// No description provided for @agentCreateNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入 Agent 名称'**
  String get agentCreateNameRequired;

  /// No description provided for @agentCreateModelRequired.
  ///
  /// In zh, this message translates to:
  /// **'请选择主模型'**
  String get agentCreateModelRequired;

  /// No description provided for @agentCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败: {error}'**
  String agentCreateFailed(String error);

  /// No description provided for @agentCreatePrevStep.
  ///
  /// In zh, this message translates to:
  /// **'上一步'**
  String get agentCreatePrevStep;

  /// No description provided for @agentCreateNextStep.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get agentCreateNextStep;

  /// No description provided for @agentCreateCreating.
  ///
  /// In zh, this message translates to:
  /// **'创建中...'**
  String get agentCreateCreating;

  /// No description provided for @agentCreateSubmit.
  ///
  /// In zh, this message translates to:
  /// **'创建 Agent'**
  String get agentCreateSubmit;

  /// No description provided for @agentCreateBasicTitle.
  ///
  /// In zh, this message translates to:
  /// **'基本信息与模型'**
  String get agentCreateBasicTitle;

  /// No description provided for @agentCreateBasicSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'设置 Agent 的名称、角色和使用的 AI 模型。'**
  String get agentCreateBasicSubtitle;

  /// No description provided for @agentCreateNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'Agent 名称 *'**
  String get agentCreateNameLabel;

  /// No description provided for @agentCreateNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例：研究助手'**
  String get agentCreateNameHint;

  /// No description provided for @agentCreateRoleLabel.
  ///
  /// In zh, this message translates to:
  /// **'角色描述'**
  String get agentCreateRoleLabel;

  /// No description provided for @agentCreateRoleHint.
  ///
  /// In zh, this message translates to:
  /// **'描述这个 Agent 的职责...'**
  String get agentCreateRoleHint;

  /// No description provided for @agentCreateTemplateLabel.
  ///
  /// In zh, this message translates to:
  /// **'模板'**
  String get agentCreateTemplateLabel;

  /// No description provided for @agentCreateTemplateHint.
  ///
  /// In zh, this message translates to:
  /// **'选择模板（可选）'**
  String get agentCreateTemplateHint;

  /// No description provided for @agentCreatePrimaryModelLabel.
  ///
  /// In zh, this message translates to:
  /// **'主模型 *'**
  String get agentCreatePrimaryModelLabel;

  /// No description provided for @agentCreateModelTip.
  ///
  /// In zh, this message translates to:
  /// **'提示：请先前往「设置 → 模型池」添加 LLM 模型'**
  String get agentCreateModelTip;

  /// No description provided for @agentCreatePrimaryModelHint.
  ///
  /// In zh, this message translates to:
  /// **'选择主 AI 模型'**
  String get agentCreatePrimaryModelHint;

  /// No description provided for @agentCreateFallbackModelLabel.
  ///
  /// In zh, this message translates to:
  /// **'备用模型'**
  String get agentCreateFallbackModelLabel;

  /// No description provided for @agentCreateFallbackModelHint.
  ///
  /// In zh, this message translates to:
  /// **'选择备用模型（可选）'**
  String get agentCreateFallbackModelHint;

  /// No description provided for @agentCreateDailyTokenLimit.
  ///
  /// In zh, this message translates to:
  /// **'每日 Token 上限'**
  String get agentCreateDailyTokenLimit;

  /// No description provided for @agentCreateMonthlyTokenLimit.
  ///
  /// In zh, this message translates to:
  /// **'每月 Token 上限'**
  String get agentCreateMonthlyTokenLimit;

  /// No description provided for @agentCreatePersonalityTitle.
  ///
  /// In zh, this message translates to:
  /// **'性格与边界'**
  String get agentCreatePersonalityTitle;

  /// No description provided for @agentCreatePersonalitySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'定义 Agent 的沟通风格和行为边界。'**
  String get agentCreatePersonalitySubtitle;

  /// No description provided for @agentCreatePersonalityLabel.
  ///
  /// In zh, this message translates to:
  /// **'性格特征'**
  String get agentCreatePersonalityLabel;

  /// No description provided for @agentCreatePersonalityHint.
  ///
  /// In zh, this message translates to:
  /// **'描述性格特征、语气和沟通风格...'**
  String get agentCreatePersonalityHint;

  /// No description provided for @agentCreateBoundariesLabel.
  ///
  /// In zh, this message translates to:
  /// **'行为边界'**
  String get agentCreateBoundariesLabel;

  /// No description provided for @agentCreateBoundariesHint.
  ///
  /// In zh, this message translates to:
  /// **'列出 Agent 必须避免的话题或行为...'**
  String get agentCreateBoundariesHint;

  /// No description provided for @agentDetailTabOverview.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get agentDetailTabOverview;

  /// No description provided for @agentDetailTabTasks.
  ///
  /// In zh, this message translates to:
  /// **'任务'**
  String get agentDetailTabTasks;

  /// No description provided for @agentDetailTabMind.
  ///
  /// In zh, this message translates to:
  /// **'思维'**
  String get agentDetailTabMind;

  /// No description provided for @agentDetailTabTools.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get agentDetailTabTools;

  /// No description provided for @agentDetailTabSkills.
  ///
  /// In zh, this message translates to:
  /// **'技能'**
  String get agentDetailTabSkills;

  /// No description provided for @agentDetailTabWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'工作区'**
  String get agentDetailTabWorkspace;

  /// No description provided for @agentDetailTabActivity.
  ///
  /// In zh, this message translates to:
  /// **'活动'**
  String get agentDetailTabActivity;

  /// No description provided for @agentDetailTabSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get agentDetailTabSettings;

  /// No description provided for @agentDetailNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到 Agent'**
  String get agentDetailNotFound;

  /// No description provided for @agentDetailUntitled.
  ///
  /// In zh, this message translates to:
  /// **'未命名 Agent'**
  String get agentDetailUntitled;

  /// No description provided for @agentDetailDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除智能体'**
  String get agentDetailDeleteTitle;

  /// No description provided for @agentDetailDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认永久删除这个智能体吗？此操作不可撤销。'**
  String get agentDetailDeleteConfirm;

  /// No description provided for @agentDetailDeleted.
  ///
  /// In zh, this message translates to:
  /// **'智能体已删除'**
  String get agentDetailDeleted;

  /// No description provided for @agentDetailDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败: {error}'**
  String agentDetailDeleteFailed(String error);

  /// No description provided for @agentDetailLoadTasksFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载任务失败: {error}'**
  String agentDetailLoadTasksFailed(String error);

  /// No description provided for @agentDetailLoadFilesFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载文件失败: {error}'**
  String agentDetailLoadFilesFailed(String error);

  /// No description provided for @agentDetailLoadActivityFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载活动失败: {error}'**
  String agentDetailLoadActivityFailed(String error);

  /// No description provided for @agentDetailSkillImported.
  ///
  /// In zh, this message translates to:
  /// **'技能已导入'**
  String get agentDetailSkillImported;

  /// No description provided for @agentDetailImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {error}'**
  String agentDetailImportFailed(String error);

  /// No description provided for @agentDetailSoulSaved.
  ///
  /// In zh, this message translates to:
  /// **'soul.md 已保存'**
  String get agentDetailSoulSaved;

  /// No description provided for @agentDetailSoulSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存 soul.md 失败: {error}'**
  String agentDetailSoulSaveFailed(String error);

  /// No description provided for @agentDetailToolToggleFailed.
  ///
  /// In zh, this message translates to:
  /// **'工具开关失败: {error}'**
  String agentDetailToolToggleFailed(String error);

  /// No description provided for @agentDetailConfig.
  ///
  /// In zh, this message translates to:
  /// **'配置'**
  String get agentDetailConfig;

  /// No description provided for @agentDetailToolConfigSaved.
  ///
  /// In zh, this message translates to:
  /// **'工具配置已保存'**
  String get agentDetailToolConfigSaved;

  /// No description provided for @agentDetailSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败: {error}'**
  String agentDetailSaveFailed(String error);

  /// No description provided for @agentDetailSaveConfig.
  ///
  /// In zh, this message translates to:
  /// **'保存配置'**
  String get agentDetailSaveConfig;

  /// No description provided for @agentDetailSettingsSaved.
  ///
  /// In zh, this message translates to:
  /// **'设置已保存'**
  String get agentDetailSettingsSaved;

  /// No description provided for @agentDetailSettingsSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存设置失败: {error}'**
  String agentDetailSettingsSaveFailed(String error);

  /// No description provided for @agentDetailReadFileFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取文件失败: {error}'**
  String agentDetailReadFileFailed(String error);

  /// No description provided for @agentDetailOpenSkillFolderFailed.
  ///
  /// In zh, this message translates to:
  /// **'打开技能文件夹失败: {error}'**
  String agentDetailOpenSkillFolderFailed(String error);

  /// No description provided for @agentDetailReadSkillFileFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取技能文件失败: {error}'**
  String agentDetailReadSkillFileFailed(String error);

  /// No description provided for @agentDetailOpenFolderFailed.
  ///
  /// In zh, this message translates to:
  /// **'打开文件夹失败: {error}'**
  String agentDetailOpenFolderFailed(String error);

  /// No description provided for @agentDetailDeleteSkillTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除技能'**
  String get agentDetailDeleteSkillTitle;

  /// No description provided for @agentDetailDeleteSkillConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除 \"{name}\" 吗？'**
  String agentDetailDeleteSkillConfirm(String name);

  /// No description provided for @agentDetailSkillDeleted.
  ///
  /// In zh, this message translates to:
  /// **'技能已删除'**
  String get agentDetailSkillDeleted;

  /// No description provided for @agentDetailDeleteSkillFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除技能失败: {error}'**
  String agentDetailDeleteSkillFailed(String error);

  /// No description provided for @agentDetailDeleteFileTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除文件'**
  String get agentDetailDeleteFileTitle;

  /// No description provided for @agentDetailDeleteFileConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除 \"{name}\" 吗？'**
  String agentDetailDeleteFileConfirm(String name);

  /// No description provided for @agentDetailFileDeleted.
  ///
  /// In zh, this message translates to:
  /// **'文件已删除'**
  String get agentDetailFileDeleted;

  /// No description provided for @agentDetailDeleteFileFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除文件失败: {error}'**
  String agentDetailDeleteFileFailed(String error);

  /// No description provided for @agentDetailMemoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'(空)'**
  String get agentDetailMemoryEmpty;

  /// No description provided for @agentDetailReadMemoryFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取记忆文件失败: {error}'**
  String agentDetailReadMemoryFailed(String error);

  /// No description provided for @agentDetailDeleteChannelTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除通道'**
  String get agentDetailDeleteChannelTitle;

  /// No description provided for @agentDetailDeleteChannelConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除通道配置吗？'**
  String get agentDetailDeleteChannelConfirm;

  /// No description provided for @agentDetailChannelDeleted.
  ///
  /// In zh, this message translates to:
  /// **'通道已删除'**
  String get agentDetailChannelDeleted;

  /// No description provided for @agentDetailDeleteChannelFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除通道失败: {error}'**
  String agentDetailDeleteChannelFailed(String error);

  /// No description provided for @agentDetailDeleteScheduleTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除计划'**
  String get agentDetailDeleteScheduleTitle;

  /// No description provided for @agentDetailDeleteScheduleConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除此计划吗？'**
  String get agentDetailDeleteScheduleConfirm;

  /// No description provided for @agentDetailScheduleDeleted.
  ///
  /// In zh, this message translates to:
  /// **'计划已删除'**
  String get agentDetailScheduleDeleted;

  /// No description provided for @agentDetailDeleteScheduleFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除计划失败: {error}'**
  String agentDetailDeleteScheduleFailed(String error);

  /// No description provided for @agentDetailNameUpdated.
  ///
  /// In zh, this message translates to:
  /// **'名称已更新'**
  String get agentDetailNameUpdated;

  /// No description provided for @agentDetailNameUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'更新名称失败: {error}'**
  String agentDetailNameUpdateFailed(String error);

  /// No description provided for @agentDetailTaskTriggered.
  ///
  /// In zh, this message translates to:
  /// **'任务已触发，执行中...'**
  String get agentDetailTaskTriggered;

  /// No description provided for @agentDetailTriggerTaskFailed.
  ///
  /// In zh, this message translates to:
  /// **'触发任务失败: {error}'**
  String agentDetailTriggerTaskFailed(String error);

  /// No description provided for @agentDetailScheduleTriggered.
  ///
  /// In zh, this message translates to:
  /// **'计划已手动触发'**
  String get agentDetailScheduleTriggered;

  /// No description provided for @agentDetailTriggerScheduleFailed.
  ///
  /// In zh, this message translates to:
  /// **'触发计划失败: {error}'**
  String agentDetailTriggerScheduleFailed(String error);

  /// No description provided for @agentDetailChannelCreated.
  ///
  /// In zh, this message translates to:
  /// **'通道已创建'**
  String get agentDetailChannelCreated;

  /// No description provided for @agentDetailCreateChannelFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建通道失败: {error}'**
  String agentDetailCreateChannelFailed(String error);

  /// No description provided for @agentDetailFileUploaded.
  ///
  /// In zh, this message translates to:
  /// **'文件已上传'**
  String get agentDetailFileUploaded;

  /// No description provided for @agentDetailUploadFailed.
  ///
  /// In zh, this message translates to:
  /// **'上传失败: {error}'**
  String agentDetailUploadFailed(String error);

  /// No description provided for @agentDetailNewFile.
  ///
  /// In zh, this message translates to:
  /// **'新建文件'**
  String get agentDetailNewFile;

  /// No description provided for @agentDetailFileName.
  ///
  /// In zh, this message translates to:
  /// **'文件名'**
  String get agentDetailFileName;

  /// No description provided for @agentDetailFileNameHint.
  ///
  /// In zh, this message translates to:
  /// **'example.md'**
  String get agentDetailFileNameHint;

  /// No description provided for @agentDetailContent.
  ///
  /// In zh, this message translates to:
  /// **'内容'**
  String get agentDetailContent;

  /// No description provided for @agentDetailFileCreated.
  ///
  /// In zh, this message translates to:
  /// **'文件已创建'**
  String get agentDetailFileCreated;

  /// No description provided for @agentDetailCreateFileFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建文件失败: {error}'**
  String agentDetailCreateFileFailed(String error);

  /// No description provided for @agentDetailNewFolder.
  ///
  /// In zh, this message translates to:
  /// **'新建文件夹'**
  String get agentDetailNewFolder;

  /// No description provided for @agentDetailFolderName.
  ///
  /// In zh, this message translates to:
  /// **'文件夹名'**
  String get agentDetailFolderName;

  /// No description provided for @agentDetailFolderCreated.
  ///
  /// In zh, this message translates to:
  /// **'文件夹已创建'**
  String get agentDetailFolderCreated;

  /// No description provided for @agentDetailCreateFolderFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建文件夹失败: {error}'**
  String agentDetailCreateFolderFailed(String error);

  /// No description provided for @agentDetailEditFile.
  ///
  /// In zh, this message translates to:
  /// **'编辑 {name}'**
  String agentDetailEditFile(String name);

  /// No description provided for @agentDetailFileSaved.
  ///
  /// In zh, this message translates to:
  /// **'文件已保存'**
  String get agentDetailFileSaved;

  /// No description provided for @agentDetailNewSkill.
  ///
  /// In zh, this message translates to:
  /// **'新建技能'**
  String get agentDetailNewSkill;

  /// No description provided for @agentDetailSkillCreated.
  ///
  /// In zh, this message translates to:
  /// **'技能已创建'**
  String get agentDetailSkillCreated;

  /// No description provided for @agentDetailCreateSkillFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建技能失败: {error}'**
  String agentDetailCreateSkillFailed(String error);

  /// No description provided for @agentDetailEditSkill.
  ///
  /// In zh, this message translates to:
  /// **'编辑 {name}'**
  String agentDetailEditSkill(String name);

  /// No description provided for @agentDetailSkillSaved.
  ///
  /// In zh, this message translates to:
  /// **'技能已保存'**
  String get agentDetailSkillSaved;

  /// No description provided for @agentDetailFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get agentDetailFilterAll;

  /// No description provided for @agentDetailFilterPending.
  ///
  /// In zh, this message translates to:
  /// **'待处理'**
  String get agentDetailFilterPending;

  /// No description provided for @agentDetailFilterInProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get agentDetailFilterInProgress;

  /// No description provided for @agentDetailFilterCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get agentDetailFilterCompleted;

  /// No description provided for @agentDetailFilterFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get agentDetailFilterFailed;

  /// No description provided for @agentDetailFilterUser.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get agentDetailFilterUser;

  /// No description provided for @agentDetailFilterSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get agentDetailFilterSystem;

  /// No description provided for @agentDetailFilterError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get agentDetailFilterError;

  /// No description provided for @agentDetailToolReadFile.
  ///
  /// In zh, this message translates to:
  /// **'读取文件'**
  String get agentDetailToolReadFile;

  /// No description provided for @agentDetailToolWriteFile.
  ///
  /// In zh, this message translates to:
  /// **'写入工作区文件'**
  String get agentDetailToolWriteFile;

  /// No description provided for @agentDetailToolDeleteFile.
  ///
  /// In zh, this message translates to:
  /// **'删除文件'**
  String get agentDetailToolDeleteFile;

  /// No description provided for @agentDetailToolSendMessage.
  ///
  /// In zh, this message translates to:
  /// **'发送消息'**
  String get agentDetailToolSendMessage;

  /// No description provided for @agentDetailToolWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'网络搜索'**
  String get agentDetailToolWebSearch;

  /// No description provided for @agentDetailToolManageTasks.
  ///
  /// In zh, this message translates to:
  /// **'管理任务'**
  String get agentDetailToolManageTasks;

  /// No description provided for @agentDetailToolLevelAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get agentDetailToolLevelAuto;

  /// No description provided for @agentDetailToolLevelNotify.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get agentDetailToolLevelNotify;

  /// No description provided for @agentDetailToolLevelApproval.
  ///
  /// In zh, this message translates to:
  /// **'审批'**
  String get agentDetailToolLevelApproval;

  /// No description provided for @sharedWidgetsReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取失败: {error}'**
  String sharedWidgetsReadFailed(String error);

  /// No description provided for @sharedWidgetsTrigger.
  ///
  /// In zh, this message translates to:
  /// **'触发执行'**
  String get sharedWidgetsTrigger;

  /// No description provided for @sharedWidgetsNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无执行记录'**
  String get sharedWidgetsNoRecords;

  /// No description provided for @overviewStats.
  ///
  /// In zh, this message translates to:
  /// **'数据统计'**
  String get overviewStats;

  /// No description provided for @overviewMonthlyTokens.
  ///
  /// In zh, this message translates to:
  /// **'月度 Token'**
  String get overviewMonthlyTokens;

  /// No description provided for @overviewDailyTokens.
  ///
  /// In zh, this message translates to:
  /// **'每日 Token'**
  String get overviewDailyTokens;

  /// No description provided for @overviewTodayLlmCalls.
  ///
  /// In zh, this message translates to:
  /// **'今日 LLM 调用'**
  String get overviewTodayLlmCalls;

  /// No description provided for @overviewTotalTasks.
  ///
  /// In zh, this message translates to:
  /// **'总任务'**
  String get overviewTotalTasks;

  /// No description provided for @overviewCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get overviewCompleted;

  /// No description provided for @overviewOps24h.
  ///
  /// In zh, this message translates to:
  /// **'24h操作'**
  String get overviewOps24h;

  /// No description provided for @overviewRecentActivity.
  ///
  /// In zh, this message translates to:
  /// **'近期活动'**
  String get overviewRecentActivity;

  /// No description provided for @overviewBasicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get overviewBasicInfo;

  /// No description provided for @overviewCreatedAt.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get overviewCreatedAt;

  /// No description provided for @overviewCreator.
  ///
  /// In zh, this message translates to:
  /// **'创建者'**
  String get overviewCreator;

  /// No description provided for @overviewLastActivity.
  ///
  /// In zh, this message translates to:
  /// **'最后活动'**
  String get overviewLastActivity;

  /// No description provided for @tasksTodo.
  ///
  /// In zh, this message translates to:
  /// **'待办'**
  String get tasksTodo;

  /// No description provided for @tasksInProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get tasksInProgress;

  /// No description provided for @tasksCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get tasksCompleted;

  /// No description provided for @tasksNoTodo.
  ///
  /// In zh, this message translates to:
  /// **'暂无待办'**
  String get tasksNoTodo;

  /// No description provided for @tasksNoInProgress.
  ///
  /// In zh, this message translates to:
  /// **'暂无进行中'**
  String get tasksNoInProgress;

  /// No description provided for @tasksNoCompleted.
  ///
  /// In zh, this message translates to:
  /// **'暂无已完成'**
  String get tasksNoCompleted;

  /// No description provided for @tasksCreateToStart.
  ///
  /// In zh, this message translates to:
  /// **'创建任务或计划开始吧'**
  String get tasksCreateToStart;

  /// No description provided for @tasksNoSchedules.
  ///
  /// In zh, this message translates to:
  /// **'暂无计划'**
  String get tasksNoSchedules;

  /// No description provided for @tasksScheduleFallback.
  ///
  /// In zh, this message translates to:
  /// **'计划'**
  String get tasksScheduleFallback;

  /// No description provided for @tasksNextFire.
  ///
  /// In zh, this message translates to:
  /// **'下次: {time}'**
  String tasksNextFire(String time);

  /// No description provided for @tasksRunCount.
  ///
  /// In zh, this message translates to:
  /// **'已执行 {count} 次'**
  String tasksRunCount(int count);

  /// No description provided for @tasksNoTitle.
  ///
  /// In zh, this message translates to:
  /// **'无标题'**
  String get tasksNoTitle;

  /// No description provided for @tasksTrigger.
  ///
  /// In zh, this message translates to:
  /// **'触发'**
  String get tasksTrigger;

  /// No description provided for @tasksWeekMon.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get tasksWeekMon;

  /// No description provided for @tasksWeekTue.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get tasksWeekTue;

  /// No description provided for @tasksWeekWed.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get tasksWeekWed;

  /// No description provided for @tasksWeekThu.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get tasksWeekThu;

  /// No description provided for @tasksWeekFri.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get tasksWeekFri;

  /// No description provided for @tasksWeekSat.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get tasksWeekSat;

  /// No description provided for @tasksWeekSun.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get tasksWeekSun;

  /// No description provided for @tasksNewTask.
  ///
  /// In zh, this message translates to:
  /// **'新建任务'**
  String get tasksNewTask;

  /// No description provided for @tasksTaskTitle.
  ///
  /// In zh, this message translates to:
  /// **'任务标题'**
  String get tasksTaskTitle;

  /// No description provided for @tasksTaskDesc.
  ///
  /// In zh, this message translates to:
  /// **'任务描述（可选）'**
  String get tasksTaskDesc;

  /// No description provided for @tasksOneTime.
  ///
  /// In zh, this message translates to:
  /// **'一次性执行'**
  String get tasksOneTime;

  /// No description provided for @tasksRecurring.
  ///
  /// In zh, this message translates to:
  /// **'重复执行'**
  String get tasksRecurring;

  /// No description provided for @tasksFrequency.
  ///
  /// In zh, this message translates to:
  /// **'重复频率'**
  String get tasksFrequency;

  /// No description provided for @tasksDaily.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get tasksDaily;

  /// No description provided for @tasksWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周'**
  String get tasksWeekly;

  /// No description provided for @tasksMonthly.
  ///
  /// In zh, this message translates to:
  /// **'每月'**
  String get tasksMonthly;

  /// No description provided for @tasksHourly.
  ///
  /// In zh, this message translates to:
  /// **'每小时'**
  String get tasksHourly;

  /// No description provided for @tasksEveryMinute.
  ///
  /// In zh, this message translates to:
  /// **'每分钟'**
  String get tasksEveryMinute;

  /// No description provided for @tasksEvery.
  ///
  /// In zh, this message translates to:
  /// **'每'**
  String get tasksEvery;

  /// No description provided for @tasksUnitDay.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get tasksUnitDay;

  /// No description provided for @tasksUnitWeek.
  ///
  /// In zh, this message translates to:
  /// **'周'**
  String get tasksUnitWeek;

  /// No description provided for @tasksUnitMonth.
  ///
  /// In zh, this message translates to:
  /// **'个月'**
  String get tasksUnitMonth;

  /// No description provided for @tasksUnitHour.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get tasksUnitHour;

  /// No description provided for @tasksUnitMinute.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get tasksUnitMinute;

  /// No description provided for @tasksDayOfMonth.
  ///
  /// In zh, this message translates to:
  /// **'几号执行'**
  String get tasksDayOfMonth;

  /// No description provided for @tasksDaySuffix.
  ///
  /// In zh, this message translates to:
  /// **'{day}号'**
  String tasksDaySuffix(int day);

  /// No description provided for @tasksDayOfWeek.
  ///
  /// In zh, this message translates to:
  /// **'周几执行'**
  String get tasksDayOfWeek;

  /// No description provided for @tasksTimeOfDay.
  ///
  /// In zh, this message translates to:
  /// **'几点执行'**
  String get tasksTimeOfDay;

  /// No description provided for @tasksDeadline.
  ///
  /// In zh, this message translates to:
  /// **'截止时间：'**
  String get tasksDeadline;

  /// No description provided for @tasksNoDeadline.
  ///
  /// In zh, this message translates to:
  /// **'永不截止'**
  String get tasksNoDeadline;

  /// No description provided for @tasksSetDeadline.
  ///
  /// In zh, this message translates to:
  /// **'设置截止'**
  String get tasksSetDeadline;

  /// No description provided for @tasksSelectDate.
  ///
  /// In zh, this message translates to:
  /// **'选择日期'**
  String get tasksSelectDate;

  /// No description provided for @tasksScheduleCreated.
  ///
  /// In zh, this message translates to:
  /// **'计划已创建'**
  String get tasksScheduleCreated;

  /// No description provided for @tasksTaskCreated.
  ///
  /// In zh, this message translates to:
  /// **'任务已创建'**
  String get tasksTaskCreated;

  /// No description provided for @tasksCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败: {error}'**
  String tasksCreateFailed(String error);

  /// No description provided for @mindCharCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 字'**
  String mindCharCount(int count);

  /// No description provided for @mindEmpty.
  ///
  /// In zh, this message translates to:
  /// **'空'**
  String get mindEmpty;

  /// No description provided for @mindSoulPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'定义 Agent 的性格和核心行为...'**
  String get mindSoulPlaceholder;

  /// No description provided for @mindNoContent.
  ///
  /// In zh, this message translates to:
  /// **'暂无内容，点击编辑按钮创建。'**
  String get mindNoContent;

  /// No description provided for @mindHeartbeatNoContent.
  ///
  /// In zh, this message translates to:
  /// **'暂无内容'**
  String get mindHeartbeatNoContent;

  /// No description provided for @mindMemoryFiles.
  ///
  /// In zh, this message translates to:
  /// **'记忆文件'**
  String get mindMemoryFiles;

  /// No description provided for @mindFileCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个文件'**
  String mindFileCount(int count);

  /// No description provided for @mindNoMemoryFiles.
  ///
  /// In zh, this message translates to:
  /// **'暂无记忆文件。'**
  String get mindNoMemoryFiles;

  /// No description provided for @mindBytes.
  ///
  /// In zh, this message translates to:
  /// **'{size} 字节'**
  String mindBytes(int size);

  /// No description provided for @toolsCategoryFileOps.
  ///
  /// In zh, this message translates to:
  /// **'文件操作'**
  String get toolsCategoryFileOps;

  /// No description provided for @toolsCategoryTaskMgmt.
  ///
  /// In zh, this message translates to:
  /// **'任务管理'**
  String get toolsCategoryTaskMgmt;

  /// No description provided for @toolsCategoryComm.
  ///
  /// In zh, this message translates to:
  /// **'通讯'**
  String get toolsCategoryComm;

  /// No description provided for @toolsCategorySearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get toolsCategorySearch;

  /// No description provided for @toolsCategoryCode.
  ///
  /// In zh, this message translates to:
  /// **'代码'**
  String get toolsCategoryCode;

  /// No description provided for @toolsCategoryDiscovery.
  ///
  /// In zh, this message translates to:
  /// **'发现'**
  String get toolsCategoryDiscovery;

  /// No description provided for @toolsCategoryTrigger.
  ///
  /// In zh, this message translates to:
  /// **'触发器'**
  String get toolsCategoryTrigger;

  /// No description provided for @toolsCategoryPlaza.
  ///
  /// In zh, this message translates to:
  /// **'广场'**
  String get toolsCategoryPlaza;

  /// No description provided for @toolsCategoryCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get toolsCategoryCustom;

  /// No description provided for @toolsCategoryGeneral.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get toolsCategoryGeneral;

  /// No description provided for @toolsCount.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get toolsCount;

  /// No description provided for @toolsPlatform.
  ///
  /// In zh, this message translates to:
  /// **'平台工具'**
  String get toolsPlatform;

  /// No description provided for @toolsAgentInstalled.
  ///
  /// In zh, this message translates to:
  /// **'Agent 安装'**
  String get toolsAgentInstalled;

  /// No description provided for @toolsNoPlatform.
  ///
  /// In zh, this message translates to:
  /// **'暂无平台工具'**
  String get toolsNoPlatform;

  /// No description provided for @toolsNoInstalled.
  ///
  /// In zh, this message translates to:
  /// **'暂无安装的工具'**
  String get toolsNoInstalled;

  /// No description provided for @toolsNoInstalledHint.
  ///
  /// In zh, this message translates to:
  /// **'Agent 可通过 import_mcp_server 工具自行安装。'**
  String get toolsNoInstalledHint;

  /// No description provided for @toolsUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get toolsUnknown;

  /// No description provided for @skillsLabel.
  ///
  /// In zh, this message translates to:
  /// **'技能'**
  String get skillsLabel;

  /// No description provided for @skillsNewTooltip.
  ///
  /// In zh, this message translates to:
  /// **'新建技能'**
  String get skillsNewTooltip;

  /// No description provided for @skillsImportPreset.
  ///
  /// In zh, this message translates to:
  /// **'导入预设技能'**
  String get skillsImportPreset;

  /// No description provided for @skillsPreset.
  ///
  /// In zh, this message translates to:
  /// **'预设技能'**
  String get skillsPreset;

  /// No description provided for @skillsUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get skillsUnknown;

  /// No description provided for @skillsNoSkills.
  ///
  /// In zh, this message translates to:
  /// **'暂无技能'**
  String get skillsNoSkills;

  /// No description provided for @skillsNoSkillsHint.
  ///
  /// In zh, this message translates to:
  /// **'该 Agent 未找到技能文件。'**
  String get skillsNoSkillsHint;

  /// No description provided for @skillsFolderEmpty.
  ///
  /// In zh, this message translates to:
  /// **'文件夹为空'**
  String get skillsFolderEmpty;

  /// No description provided for @skillsFolderEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'该技能文件夹下没有文件。'**
  String get skillsFolderEmptyHint;

  /// No description provided for @skillsDeleteTooltip.
  ///
  /// In zh, this message translates to:
  /// **'删除技能'**
  String get skillsDeleteTooltip;

  /// No description provided for @skillsBytes.
  ///
  /// In zh, this message translates to:
  /// **'{size} 字节'**
  String skillsBytes(int size);

  /// No description provided for @workspaceFile.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get workspaceFile;

  /// No description provided for @workspaceRoot.
  ///
  /// In zh, this message translates to:
  /// **'根目录'**
  String get workspaceRoot;

  /// No description provided for @workspaceRootTitle.
  ///
  /// In zh, this message translates to:
  /// **'工作区 (根目录)'**
  String get workspaceRootTitle;

  /// No description provided for @workspaceGoUp.
  ///
  /// In zh, this message translates to:
  /// **'返回上级'**
  String get workspaceGoUp;

  /// No description provided for @workspaceNewFolder.
  ///
  /// In zh, this message translates to:
  /// **'新建文件夹'**
  String get workspaceNewFolder;

  /// No description provided for @workspaceNewFile.
  ///
  /// In zh, this message translates to:
  /// **'新建文件'**
  String get workspaceNewFile;

  /// No description provided for @workspaceUploadFile.
  ///
  /// In zh, this message translates to:
  /// **'上传文件'**
  String get workspaceUploadFile;

  /// No description provided for @workspaceEmptyDir.
  ///
  /// In zh, this message translates to:
  /// **'空目录'**
  String get workspaceEmptyDir;

  /// No description provided for @workspaceEmptyDirHint.
  ///
  /// In zh, this message translates to:
  /// **'该目录下没有文件。'**
  String get workspaceEmptyDirHint;

  /// No description provided for @workspaceBytes.
  ///
  /// In zh, this message translates to:
  /// **'{size} 字节'**
  String workspaceBytes(int size);

  /// No description provided for @activityTitle.
  ///
  /// In zh, this message translates to:
  /// **'活动日志'**
  String get activityTitle;

  /// No description provided for @activityNoActivity.
  ///
  /// In zh, this message translates to:
  /// **'暂无活动'**
  String get activityNoActivity;

  /// No description provided for @activityNoActivityHint.
  ///
  /// In zh, this message translates to:
  /// **'该 Agent 尚未记录任何活动。'**
  String get activityNoActivityHint;

  /// No description provided for @activityTypeChatReply.
  ///
  /// In zh, this message translates to:
  /// **'聊天回复'**
  String get activityTypeChatReply;

  /// No description provided for @activityTypeWebMessage.
  ///
  /// In zh, this message translates to:
  /// **'网页消息'**
  String get activityTypeWebMessage;

  /// No description provided for @activityTypeAgentMessage.
  ///
  /// In zh, this message translates to:
  /// **'Agent 消息'**
  String get activityTypeAgentMessage;

  /// No description provided for @activityTypeFeishuMessage.
  ///
  /// In zh, this message translates to:
  /// **'飞书消息'**
  String get activityTypeFeishuMessage;

  /// No description provided for @activityTypeToolCall.
  ///
  /// In zh, this message translates to:
  /// **'工具调用'**
  String get activityTypeToolCall;

  /// No description provided for @activityTypeTaskCreate.
  ///
  /// In zh, this message translates to:
  /// **'任务创建'**
  String get activityTypeTaskCreate;

  /// No description provided for @activityTypeTaskUpdate.
  ///
  /// In zh, this message translates to:
  /// **'任务更新'**
  String get activityTypeTaskUpdate;

  /// No description provided for @activityTypeTaskComplete.
  ///
  /// In zh, this message translates to:
  /// **'任务完成'**
  String get activityTypeTaskComplete;

  /// No description provided for @activityTypeTaskFail.
  ///
  /// In zh, this message translates to:
  /// **'任务失败'**
  String get activityTypeTaskFail;

  /// No description provided for @activityTypeError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get activityTypeError;

  /// No description provided for @activityTypeHeartbeat.
  ///
  /// In zh, this message translates to:
  /// **'心跳'**
  String get activityTypeHeartbeat;

  /// No description provided for @activityTypeSchedule.
  ///
  /// In zh, this message translates to:
  /// **'定时任务'**
  String get activityTypeSchedule;

  /// No description provided for @activityTypeFileWrite.
  ///
  /// In zh, this message translates to:
  /// **'文件写入'**
  String get activityTypeFileWrite;

  /// No description provided for @activityTypePlazaPost.
  ///
  /// In zh, this message translates to:
  /// **'广场动态'**
  String get activityTypePlazaPost;

  /// No description provided for @activityTypeStart.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get activityTypeStart;

  /// No description provided for @activityTypeStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get activityTypeStop;

  /// No description provided for @settingsModelConfig.
  ///
  /// In zh, this message translates to:
  /// **'模型配置'**
  String get settingsModelConfig;

  /// No description provided for @settingsPrimaryModel.
  ///
  /// In zh, this message translates to:
  /// **'主模型'**
  String get settingsPrimaryModel;

  /// No description provided for @settingsFallbackModel.
  ///
  /// In zh, this message translates to:
  /// **'备用模型'**
  String get settingsFallbackModel;

  /// No description provided for @settingsMaxTokens.
  ///
  /// In zh, this message translates to:
  /// **'Token 上限'**
  String get settingsMaxTokens;

  /// No description provided for @settingsTemperature.
  ///
  /// In zh, this message translates to:
  /// **'温度'**
  String get settingsTemperature;

  /// No description provided for @settingsContextWindow.
  ///
  /// In zh, this message translates to:
  /// **'上下文窗口'**
  String get settingsContextWindow;

  /// No description provided for @settingsMaxToolRounds.
  ///
  /// In zh, this message translates to:
  /// **'最大工具轮次'**
  String get settingsMaxToolRounds;

  /// No description provided for @settingsTokenLimits.
  ///
  /// In zh, this message translates to:
  /// **'Token 限额'**
  String get settingsTokenLimits;

  /// No description provided for @settingsDailyTokenLimit.
  ///
  /// In zh, this message translates to:
  /// **'每日 Token 限额'**
  String get settingsDailyTokenLimit;

  /// No description provided for @settingsMonthlyTokenLimit.
  ///
  /// In zh, this message translates to:
  /// **'每月 Token 限额'**
  String get settingsMonthlyTokenLimit;

  /// No description provided for @settingsNoLimit.
  ///
  /// In zh, this message translates to:
  /// **'不限'**
  String get settingsNoLimit;

  /// No description provided for @settingsSaveSettings.
  ///
  /// In zh, this message translates to:
  /// **'保存设置'**
  String get settingsSaveSettings;

  /// No description provided for @settingsHeartbeat.
  ///
  /// In zh, this message translates to:
  /// **'心跳'**
  String get settingsHeartbeat;

  /// No description provided for @settingsHeartbeatDesc.
  ///
  /// In zh, this message translates to:
  /// **'定时巡检广场、执行工作，会消耗 Token'**
  String get settingsHeartbeatDesc;

  /// No description provided for @settingsInterval.
  ///
  /// In zh, this message translates to:
  /// **'间隔'**
  String get settingsInterval;

  /// No description provided for @settingsMinutes.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get settingsMinutes;

  /// No description provided for @settingsMinInterval.
  ///
  /// In zh, this message translates to:
  /// **'(最低 {min} 分钟)'**
  String settingsMinInterval(int min);

  /// No description provided for @settingsActiveHours.
  ///
  /// In zh, this message translates to:
  /// **'活跃时段'**
  String get settingsActiveHours;

  /// No description provided for @settingsIntervalAdjusted.
  ///
  /// In zh, this message translates to:
  /// **'间隔已调整为最低 {interval} 分钟'**
  String settingsIntervalAdjusted(int interval);

  /// No description provided for @settingsHeartbeatSaved.
  ///
  /// In zh, this message translates to:
  /// **'心跳设置已保存'**
  String get settingsHeartbeatSaved;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败: {error}'**
  String settingsSaveFailed(String error);

  /// No description provided for @settingsLastHeartbeat.
  ///
  /// In zh, this message translates to:
  /// **'上次心跳: {time}'**
  String settingsLastHeartbeat(String time);

  /// No description provided for @settingsChannelConfig.
  ///
  /// In zh, this message translates to:
  /// **'通道配置'**
  String get settingsChannelConfig;

  /// No description provided for @settingsNoChannel.
  ///
  /// In zh, this message translates to:
  /// **'未配置通道。'**
  String get settingsNoChannel;

  /// No description provided for @settingsConfigChannel.
  ///
  /// In zh, this message translates to:
  /// **'配置通道'**
  String get settingsConfigChannel;

  /// No description provided for @settingsChannelType.
  ///
  /// In zh, this message translates to:
  /// **'通道类型'**
  String get settingsChannelType;

  /// No description provided for @settingsFeishu.
  ///
  /// In zh, this message translates to:
  /// **'飞书'**
  String get settingsFeishu;

  /// No description provided for @settingsEncryptKey.
  ///
  /// In zh, this message translates to:
  /// **'Encrypt Key (可选)'**
  String get settingsEncryptKey;

  /// No description provided for @settingsChannelStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get settingsChannelStatus;

  /// No description provided for @settingsChannelTypeName.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get settingsChannelTypeName;

  /// No description provided for @settingsBotName.
  ///
  /// In zh, this message translates to:
  /// **'机器人名称'**
  String get settingsBotName;

  /// No description provided for @settingsDeleteChannel.
  ///
  /// In zh, this message translates to:
  /// **'删除通道'**
  String get settingsDeleteChannel;

  /// No description provided for @settingsDangerZone.
  ///
  /// In zh, this message translates to:
  /// **'危险操作'**
  String get settingsDangerZone;

  /// No description provided for @settingsDangerHint.
  ///
  /// In zh, this message translates to:
  /// **'Agent 一旦删除将无法恢复，请谨慎操作。'**
  String get settingsDangerHint;

  /// No description provided for @settingsDeleteAgent.
  ///
  /// In zh, this message translates to:
  /// **'删除智能体'**
  String get settingsDeleteAgent;

  /// No description provided for @settingsDeleteAgentConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除吗？'**
  String get settingsDeleteAgentConfirm;

  /// No description provided for @settingsConfirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get settingsConfirmDelete;

  /// No description provided for @settingsNotSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择'**
  String get settingsNotSelected;

  /// No description provided for @settingsNotUsed.
  ///
  /// In zh, this message translates to:
  /// **'不使用'**
  String get settingsNotUsed;

  /// No description provided for @settingsNoModelHint.
  ///
  /// In zh, this message translates to:
  /// **'请先在设置中配置模型'**
  String get settingsNoModelHint;

  /// No description provided for @settingsModelTip.
  ///
  /// In zh, this message translates to:
  /// **'提示：请先前往「设置 → 模型池」添加 LLM 模型'**
  String get settingsModelTip;

  /// No description provided for @enterpriseModelPool.
  ///
  /// In zh, this message translates to:
  /// **'模型池'**
  String get enterpriseModelPool;

  /// No description provided for @enterpriseTools.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get enterpriseTools;

  /// No description provided for @enterpriseSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get enterpriseSettings;

  /// No description provided for @llmAddModel.
  ///
  /// In zh, this message translates to:
  /// **'添加模型'**
  String get llmAddModel;

  /// No description provided for @llmEditModel.
  ///
  /// In zh, this message translates to:
  /// **'编辑模型'**
  String get llmEditModel;

  /// No description provided for @llmProvider.
  ///
  /// In zh, this message translates to:
  /// **'供应商'**
  String get llmProvider;

  /// No description provided for @llmModelName.
  ///
  /// In zh, this message translates to:
  /// **'模型名称'**
  String get llmModelName;

  /// No description provided for @llmDisplayName.
  ///
  /// In zh, this message translates to:
  /// **'显示名称'**
  String get llmDisplayName;

  /// No description provided for @llmCustomBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'自定义 Base URL'**
  String get llmCustomBaseUrl;

  /// No description provided for @llmKeepUnchanged.
  ///
  /// In zh, this message translates to:
  /// **'留空保持不变'**
  String get llmKeepUnchanged;

  /// No description provided for @llmVisionSupport.
  ///
  /// In zh, this message translates to:
  /// **'支持视觉（多模态）'**
  String get llmVisionSupport;

  /// No description provided for @llmVisionHint.
  ///
  /// In zh, this message translates to:
  /// **'勾选后可分析图片'**
  String get llmVisionHint;

  /// No description provided for @llmTest.
  ///
  /// In zh, this message translates to:
  /// **'测试'**
  String get llmTest;

  /// No description provided for @llmNoModels.
  ///
  /// In zh, this message translates to:
  /// **'暂无模型配置'**
  String get llmNoModels;

  /// No description provided for @llmEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get llmEnabled;

  /// No description provided for @llmDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get llmDisabled;

  /// No description provided for @llmVision.
  ///
  /// In zh, this message translates to:
  /// **'视觉'**
  String get llmVision;

  /// No description provided for @llmSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存模型失败'**
  String get llmSaveFailed;

  /// No description provided for @llmDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除模型'**
  String get llmDeleteTitle;

  /// No description provided for @llmDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这个模型吗？'**
  String get llmDeleteConfirm;

  /// No description provided for @llmModelInUse.
  ///
  /// In zh, this message translates to:
  /// **'模型使用中'**
  String get llmModelInUse;

  /// No description provided for @llmModelInUseConfirm.
  ///
  /// In zh, this message translates to:
  /// **'此模型正在被以下 Agent 使用: {agents}\n\n确定删除吗？'**
  String llmModelInUseConfirm(String agents);

  /// No description provided for @llmForceDelete.
  ///
  /// In zh, this message translates to:
  /// **'强制删除'**
  String get llmForceDelete;

  /// No description provided for @llmDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除模型失败'**
  String get llmDeleteFailed;

  /// No description provided for @llmTestNeedKey.
  ///
  /// In zh, this message translates to:
  /// **'测试需要重新输入 API Key'**
  String get llmTestNeedKey;

  /// No description provided for @llmTestFillRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先填写模型名称和 API Key'**
  String get llmTestFillRequired;

  /// No description provided for @llmTestFailed.
  ///
  /// In zh, this message translates to:
  /// **'测试请求失败'**
  String get llmTestFailed;

  /// No description provided for @llmKimiProvider.
  ///
  /// In zh, this message translates to:
  /// **'Kimi (月之暗面)'**
  String get llmKimiProvider;

  /// No description provided for @llmCustomProvider.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get llmCustomProvider;

  /// No description provided for @toolsTabGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局工具'**
  String get toolsTabGlobal;

  /// No description provided for @toolsTabMcp.
  ///
  /// In zh, this message translates to:
  /// **'MCP 服务器'**
  String get toolsTabMcp;

  /// No description provided for @toolsTabAddMcp.
  ///
  /// In zh, this message translates to:
  /// **'添加 MCP 服务器'**
  String get toolsTabAddMcp;

  /// No description provided for @toolsTabServerName.
  ///
  /// In zh, this message translates to:
  /// **'服务器名称'**
  String get toolsTabServerName;

  /// No description provided for @toolsTabServerNameHint.
  ///
  /// In zh, this message translates to:
  /// **'我的 MCP 服务器'**
  String get toolsTabServerNameHint;

  /// No description provided for @toolsTabServerUrl.
  ///
  /// In zh, this message translates to:
  /// **'MCP 服务器地址'**
  String get toolsTabServerUrl;

  /// No description provided for @toolsTabTesting.
  ///
  /// In zh, this message translates to:
  /// **'测试中...'**
  String get toolsTabTesting;

  /// No description provided for @toolsTabTestConnection.
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get toolsTabTestConnection;

  /// No description provided for @toolsTabConnectSuccess.
  ///
  /// In zh, this message translates to:
  /// **'连接成功！发现 {count} 个工具'**
  String toolsTabConnectSuccess(int count);

  /// No description provided for @toolsTabImport.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get toolsTabImport;

  /// No description provided for @toolsTabConnectFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接失败: {error}'**
  String toolsTabConnectFailed(String error);

  /// No description provided for @toolsTabNoTools.
  ///
  /// In zh, this message translates to:
  /// **'暂无可用工具'**
  String get toolsTabNoTools;

  /// No description provided for @toolsTabBuiltIn.
  ///
  /// In zh, this message translates to:
  /// **'内置'**
  String get toolsTabBuiltIn;

  /// No description provided for @toolsTabDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get toolsTabDefault;

  /// No description provided for @toolsTabDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除工具'**
  String get toolsTabDeleteTitle;

  /// No description provided for @toolsTabDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除 \"{name}\" 吗？'**
  String toolsTabDeleteConfirm(String name);

  /// No description provided for @toolsTabDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除工具失败'**
  String get toolsTabDeleteFailed;

  /// No description provided for @toolsTabImported.
  ///
  /// In zh, this message translates to:
  /// **'已导入 {name}'**
  String toolsTabImported(String name);

  /// No description provided for @toolsTabImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入工具失败'**
  String get toolsTabImportFailed;

  /// No description provided for @toolsTabUnknownError.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get toolsTabUnknownError;

  /// No description provided for @skillsTabTitle.
  ///
  /// In zh, this message translates to:
  /// **'Skills 注册表'**
  String get skillsTabTitle;

  /// No description provided for @skillsTabDesc1.
  ///
  /// In zh, this message translates to:
  /// **'管理全局技能。每个技能是一个包含 SKILL.md 文件的文件夹。'**
  String get skillsTabDesc1;

  /// No description provided for @skillsTabDesc2.
  ///
  /// In zh, this message translates to:
  /// **'创建 Agent 时选择的技能会被复制到 Agent 的工作区。'**
  String get skillsTabDesc2;

  /// No description provided for @skillsTabNoSkills.
  ///
  /// In zh, this message translates to:
  /// **'暂无技能'**
  String get skillsTabNoSkills;

  /// No description provided for @skillsTabGoUp.
  ///
  /// In zh, this message translates to:
  /// **'返回上级'**
  String get skillsTabGoUp;

  /// No description provided for @skillsTabRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get skillsTabRefresh;

  /// No description provided for @skillsTabEmptyDir.
  ///
  /// In zh, this message translates to:
  /// **'空目录'**
  String get skillsTabEmptyDir;

  /// No description provided for @skillsTabLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败: {error}'**
  String skillsTabLoadFailed(String error);

  /// No description provided for @skillTemplateContent.
  ///
  /// In zh, this message translates to:
  /// **'# Skill: 新技能\n\n## 触发条件\n当用户请求...\n\n## 执行步骤\n1. ...\n2. ...\n\n## 注意事项\n- ...\n'**
  String get skillTemplateContent;

  /// No description provided for @homeTabPlaza.
  ///
  /// In zh, this message translates to:
  /// **'工作台'**
  String get homeTabPlaza;

  /// No description provided for @homeTabDashboard.
  ///
  /// In zh, this message translates to:
  /// **'仪表盘'**
  String get homeTabDashboard;

  /// No description provided for @chatOtherUser.
  ///
  /// In zh, this message translates to:
  /// **'其他用户'**
  String get chatOtherUser;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
