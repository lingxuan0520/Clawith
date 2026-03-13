# Soloship Todo 文档

> **版本**: v2.0
> **更新日期**: 2026-03-13
> **说明**: 按优先级分组，P0 = MVP 上线前必须，P1 = 核心差异化，P2 = 体验优化，P3 = 未来规划

---

## P0 — MVP 上线前

### 认证

- [ ] **AUTH-06** 首字母彩色头像：Apple 用户无头像时，根据用户名首字母生成彩色背景头像

### 2C 体验改造

- [ ] **UX-01** 新手引导（Onboarding）：首次登录 3 步引导
  - [ ] "给你的公司起个名字" → 自动创建 Tenant
  - [ ] "招募你的第一个 AI 员工" → 模板快速创建
  - [ ] "和 TA 打个招呼" → 跳转聊天
- [ ] **UX-02** Agent 模板快速创建：选模板 → 起名字 → 选模型 → 完成（2 步）
  - [ ] 预置 6-8 个模板（研究助手、写作助手、数据分析师、项目经理、社媒运营等）
  - [ ] 高级用户仍可用完整向导
- [ ] **UX-03** 导航重构：底部 Tab 栏替代侧边栏
  - [ ] 工作台（Agent 动态流，替代原 Plaza）
  - [ ] 聊天（Agent 列表 + 最近对话）
  - [ ] 办公室（虚拟 RPG 场景，预留入口）
  - [ ] 我的（公司设置、订阅、模型池、账号）
- [ ] **UX-04** 隐藏企业级 UI（代码保留，界面不展示）
  - [ ] 隐藏部门管理 Tab
  - [ ] 隐藏组织成员同步
  - [ ] 隐藏 IM 通道配置（飞书/钉钉/企业微信）
  - [ ] 隐藏用户配额管理（ENT-05）
  - [ ] 创建向导：权限范围简化为"仅自己"，跳过通道步骤
- [ ] **UX-05** Plaza → 动态流（工作台）
  - [ ] 改名为"工作台"或"动态"
  - [ ] 展示所有 Agent 的活动日志时间线
  - [ ] 保留发帖、点赞、评论功能

### Agent 核心功能验证

- [ ] **AGENT-02** 完整测试创建向导
  - [ ] 模板快速创建流程
  - [ ] 完整 5 步向导（高级模式）
  - [ ] 提交后文件目录初始化成功
- [ ] **AGENT-03** Agent 详情页功能验证
  - [ ] Overview Tab：指标卡片、最近活动、角色描述编辑
  - [ ] Chat Tab：跳转聊天页
  - [ ] Tasks Tab：任务看板、创建任务、查看任务日志
  - [ ] Pulse Tab：读取 agenda.md/monologue.md，触发器列表
  - [ ] Mind Tab：soul.md 编辑保存、memory 文件列表
  - [ ] Tools Tab：工具列表、开关状态
  - [ ] Skills Tab：技能文件查看
  - [x] Relationships Tab：人类同事关系、Agent 同事关系管理 → **已隐藏（2C 暂不需要）**
  - [ ] Workspace Tab：文件浏览器、上传/下载/删除
  - [ ] Activity Tab：活动日志按类型过滤
  - [ ] Settings Tab：模型切换、Token 限额修改、删除 Agent
- [ ] **AGENT-04** Agent 启动/停止功能测试（状态切换）

### 聊天

- [ ] **CHAT-01** WebSocket 流式聊天端到端验证
  - [ ] 建立连接（token 认证）
  - [ ] 流式接收 chunk 事件
  - [x] 展示 thinking 折叠区域（紫色）
  - [x] 展示 tool_call 折叠区域
  - [ ] 接收 done 事件
- [ ] **CHAT-02** Markdown 渲染验证（代码块、表格、粗体、列表）
- [ ] **CHAT-05** 聊天历史加载

### 企业设置（2C 用户可见部分）

- [ ] **ENT-02** LLM 模型池：
  - [ ] 添加模型（API Key 存储）
  - [ ] 启用/禁用模型
  - [ ] 删除模型
  - [ ] Agent 创建向导中模型下拉列表正常显示

### 上架必做

- [ ] **LAUNCH-01** App 进入后台时停止前端轮询（AppLifecycleListener）
- [ ] **LAUNCH-02** 账号删除功能（Apple App Store 强制要求）
- [ ] **LAUNCH-03** 隐私政策页面
- [x] **LAUNCH-04** WebSocket 重连机制：exponential backoff（2s→4s→8s→...→30s 上限，最多 10 次）+ App 回前台时主动重连

---

## P1 — 核心差异化

### 虚拟办公室（RPG 动画系统）

> 这是产品最核心的差异化特性，动画效果要做到极致

- [ ] **RPG-01** Bonfire 引擎（基于 Flame）+ Tiled 地图（已有本地 patch 版 Bonfire 3.16.1）
- [ ] **RPG-02** 像素 RPG 场景：用户角色行走、摇杆控制
- [ ] **RPG-03** 每个 Agent 对应一个可行走 NPC
- [ ] **RPG-04** NPC 交互：靠近 Agent NPC → 触发聊天
- [ ] **RPG-05** Agent 之间互动动画（开会、协作、工作）
- [ ] **RPG-06** 办公室装饰/自定义（用户成就感）

### 订阅与计费

- [ ] **SUB-01** 订阅套餐系统
  - [ ] 数据库：subscription_plans 表 + 用户 token_budget_balance
  - [ ] iOS：Flutter `in_app_purchase` 包 + Apple IAP
  - [ ] Android：Flutter `in_app_purchase` 包 + Google Play Billing
  - [ ] 网页：Stripe 付费通道（手续费仅 2.9%，App 内不引导）
  - [ ] 免费档 + 付费档套餐设计
- [ ] **SUB-02** Token 预算余额展示 + 消耗扣除（每次对话后按模型单价扣预算）
  - [ ] Token 用量进度条可视化（已用/剩余百分比）
- [ ] **SUB-03** 月度定时任务：发放新预算 + 旧预算结转

### Agent 功能增强

- [ ] **AGENT-06** Agent 模板选择测试（从内置模板创建）
- [ ] **AGENT-07** 审批页面：Agent 发起的「需要审批」请求列表 + 批准/拒绝操作（后端 `approval_requests` 已有，缺 App UI）
- [ ] **AGENT-08** 通知展示：Agent「执行并通知」类行动在 App 内展示（当前只写 activity_log，无推送）
- [ ] Heartbeat 开关 + 间隔设置 UI
- [ ] 自主性策略配置 UI（自动执行 / 执行并通知 / 需要审批 三级开关）

### Dashboard

- [ ] **DASH-01~03** 验证 Dashboard 页面全部功能
  - [ ] 统计卡片数据正确
  - [ ] Agent 表格排序
  - [ ] 活动流显示

### 消息

- [ ] **MSG-01~03** 测试 Messages 页面
  - [ ] 消息列表加载
  - [ ] 未读数量显示（底部 Tab badge）
  - [ ] 标记单条/全部已读

### 企业设置（其余功能）

- [ ] **ENT-01** 公司信息编辑（名称、slug）
- [ ] **ENT-03** 工具管理 Tab（工具列表、启用/禁用）
- [ ] **ENT-04** 技能管理 Tab（技能内容查看编辑）
- [ ] **ENT-06** 知识库 Tab（文件上传/编辑/删除）
- [ ] **TENANT-04** 公司设置页面（名称/简介编辑）

---

## P2 — 体验优化

### UI/UX

- [ ] 空状态页面设计（无 Agent、无任务、无消息时的友好插画 + 引导按钮）
- [ ] 页面过渡动画打磨
- [ ] 错误处理统一 Toast 提示
- [ ] 长文本/代码块在聊天中的复制按钮
- [ ] Agent 卡片化展示（首页卡片网格替代列表）

### 数据体验

- [ ] Agent 表格：最后活跃时间格式化（"5 分钟前" 而非时间戳）
- [ ] Token 用量趋势图（周/月维度）
- [ ] Agent 级别的 Token 消耗排行
- [ ] Agent 详情 Overview：显示状态（running/stopped）+ 启停按钮

### 定时任务

- [ ] 定时任务 UI 完整测试（创建、Cron 输入、启用/禁用、执行历史）

### Agent 成长系统

- [ ] 经验值/等级（对话越多等级越高）
- [ ] 成就徽章（完成 N 个任务、发 N 条帖子）
- [ ] 纯前端展示，增加用户粘性

---

## P3 — 未来规划

### 移动端深度优化

- [ ] 手势操作（滑动返回、长按上下文菜单）
- [ ] 推送通知（Agent 完成任务时提醒）
- [ ] 离线缓存（上次加载的 Agent 列表等）

### 社交增强

- [ ] Agent 作品分享（Agent 写的文章、分析报告）
- [ ] 关注/粉丝机制（关注其他用户的 Agent 动态）
- [ ] Agent 商店（下载/分享 Agent 模板）

### 长期规划

- [ ] 多语言支持（英文、日文 i18n 框架接入）
- [ ] 团队协作模式（多真实用户共享一个公司空间）
- [ ] Agent 间协作 UI（协作关系图）
- [ ] 可观测性仪表盘（Token 用量统计、任务完成率）

---

## 技术债

- [ ] API 错误处理统一（当前部分 endpoint 错误信息不一致）
- [ ] 数据库迁移：补全初始建表 migration（当前依赖 startup 自动建表）
- [ ] 配置外部化：将 localhost:8001 改为环境变量（生产部署需要）
- [ ] LLM API Key 加密：确认加密/解密逻辑已实现（当前 `api_key_encrypted` 字段）
- [ ] ~~Docker-in-Docker 安全加固~~（已改为单容器架构，docker.sock 已移除）
- [ ] Flutter 依赖升级：检查 pubspec.yaml 各包版本，升级到最新稳定版
- [ ] 单元测试：核心 API（auth、agents、tasks）缺少测试覆盖

---

## 已完成 ✅

- [x] Firebase Google + Apple Sign-In
- [x] JWT 认证 + SharedPreferences 持久化
- [x] 启动页 (Splash) + 路由守卫
- [x] 侧边栏 + 公司切换菜单
- [x] 创建公司（Tenant）
- [x] Agent 列表（侧边栏）+ 状态圆点
- [x] Dashboard 统计 + Agent 表格 + 活动流
- [x] 暗色/亮色主题切换
- [x] `platform_admin` 默认角色
- [x] 用户头像从 Firebase 同步
- [x] 聊天消息左右气泡布局（用户右、Agent 左）
- [x] 全量中文本地化（所有页面 UI 文字）
- [x] Agent 详情页「关系」Tab（人类同事 + Agent 同事）
- [x] Tool call / Thinking 折叠展示
- [x] 聊天文件上传 + 图片预览
- [x] 移除 docker.sock 挂载（单容器架构不需要）
- [x] 移除所有 admin 角色校验（2C 全员 platform_admin）
