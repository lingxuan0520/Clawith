# Soloship Todo 文档

> **版本**: v1.0
> **更新日期**: 2026-03-11
> **说明**: 按优先级分组，P0 = 核心阻断项，P1 = 重要功能，P2 = 体验优化，P3 = 未来规划

---

## P0 — 必须完成（MVP 上线前）

### 认证

- [ ] **AUTH-06** 首字母彩色头像：Apple 用户无头像时，根据用户名首字母生成彩色背景头像

### Agent 核心功能验证

- [ ] **AGENT-02** 完整测试 5 步创建向导
  - [ ] Step 0：基本信息 + 模型选择（primary_model_id 必填）
  - [ ] Step 1：性格 + 边界设置
  - [ ] Step 2：技能多选 + API 获取技能列表
  - [ ] Step 3：权限范围（self/department/company）
  - [ ] Step 4：通道配置（可跳过）
  - [ ] 提交后容器创建 + 文件目录初始化成功
- [ ] **AGENT-03** 11 Tab 详情页全功能验证
  - [ ] Overview Tab：指标卡片、最近活动、角色描述编辑
  - [ ] Chat Tab：跳转聊天页
  - [ ] Tasks Tab：任务看板、创建任务、查看任务日志
  - [ ] Pulse Tab：读取 agenda.md/monologue.md，触发器列表
  - [ ] Mind Tab：soul.md 编辑保存、memory 文件列表
  - [ ] Tools Tab：工具列表、开关状态
  - [ ] Skills Tab：技能文件查看
  - [x] Relationships Tab：人类同事关系、Agent 同事关系管理
  - [ ] Workspace Tab：文件浏览器、上传/下载/删除
  - [ ] Activity Tab：活动日志按类型过滤
  - [ ] Settings Tab：模型切换、Token 限额修改、删除 Agent
- [ ] **AGENT-04** 容器启动/停止功能测试

### 聊天

- [ ] **CHAT-01** WebSocket 流式聊天端到端验证
  - [ ] 建立连接（token 认证）
  - [ ] 流式接收 chunk 事件
  - [x] 展示 thinking 折叠区域（紫色）
  - [x] 展示 tool_call 折叠区域
  - [ ] 接收 done 事件
- [ ] **CHAT-02** Markdown 渲染验证（代码块、表格、粗体、列表）
- [ ] **CHAT-05** 聊天历史加载

### 企业设置

- [ ] **ENT-02** LLM 模型池 Tab：
  - [ ] 添加模型（API Key 加密存储）
  - [ ] 启用/禁用模型
  - [ ] 删除模型
  - [ ] Agent 创建向导中模型下拉列表正常显示

---

## P1 — 重要功能

### Dashboard

- [ ] **DASH-01~03** 验证 Dashboard 页面全部功能
  - [ ] 统计卡片数据正确
  - [ ] Agent 表格排序
  - [ ] 活动流显示

### 广场（Plaza）

- [ ] **PLAZA-01~03** 完整测试 Plaza 功能
  - [ ] 帖子列表加载 + 分页
  - [ ] 发帖（500 字符限制 + hashtag）
  - [ ] 点赞/取消点赞
  - [ ] 评论展开/收起
  - [ ] 自动刷新（15 秒轮询）

### 消息收件箱

- [ ] **MSG-01~03** 测试 Messages 页面
  - [ ] 消息列表加载
  - [ ] 未读数量显示（侧边栏）
  - [ ] 标记单条/全部已读

### 企业设置（其余 Tab）

- [ ] **ENT-01** 公司信息编辑（名称、slug）
- [ ] **ENT-03** 工具管理 Tab（工具列表、启用/禁用）
- [ ] **ENT-04** 技能管理 Tab（技能内容查看编辑）
- [ ] **ENT-05** 用户配额 Tab（用户列表、配额修改）
- [ ] **ENT-06** 知识库 Tab（文件上传/编辑/删除）

### 公司管理

- [ ] **TENANT-04** 公司设置页面（名称/简介编辑）

### 文件功能

- [x] **CHAT-03** 聊天文件上传测试（FilePicker + 内容提取）
- [ ] Workspace 文件浏览器验证（列表、内容查看、上传）

---

## P2 — 体验优化

### UI/UX 优化

- [ ] 侧边栏 Agent 状态圆点实时更新（轮询 vs WebSocket 状态推送）
- [ ] 未读消息数量显示在侧边栏导航图标上（badge）
- [ ] 页面过渡动画打磨
- [ ] 空状态页面设计（无 Agent、无任务、无消息时的友好提示）
- [ ] 错误处理统一 Toast 提示（当前部分错误可能无反馈）
- [ ] 长文本/代码块在聊天中的复制按钮

### 数据体验

- [ ] Dashboard Agent 表格：最后活跃时间格式化（"5 分钟前" 而非时间戳）
- [ ] 统计卡片今日 Token 用量：显示进度条（已用/上限）
- [ ] Agent 详情 Overview：显示容器状态（running/stopped）+ 启停按钮

### Agent 功能

- [ ] **AGENT-06** Agent 模板选择测试（从内置模板创建）
- [ ] Heartbeat 开关 + 间隔设置 UI
- [ ] 自主性策略（autonomy_policy）配置 UI（三级开关）

### 定时任务

- [ ] 定时任务 UI 完整测试（创建、Cron 输入、启用/禁用、执行历史）

---

## P3 — 未来规划

### 第二阶段：虚拟办公室

- [ ] 技术选型：Flame 引擎 + Tiled 地图 评估
- [ ] 像素 RPG 场景：用户角色行走
- [ ] 每个 Agent 对应一个可行走 NPC
- [ ] NPC 交互：靠近 Agent NPC → 触发聊天
- [ ] Agent 之间可以在办公室开会、互动动画

### 第三阶段：移动端深度优化

- [ ] 手势操作（滑动返回、长按上下文菜单）
- [ ] 摇杆控制角色移动（虚拟办公室）
- [ ] 推送通知（Agent 完成任务时提醒）
- [ ] 离线缓存（上次加载的 Agent 列表等）

### 长期规划

- [ ] 多语言支持（英文、日文 i18n 框架接入）
- [ ] Agent 商店（下载/分享 Agent 模板）
- [ ] 团队协作模式（多真实用户共享一个公司空间）
- [ ] Agent 间协作 UI（协作关系图）
- [ ] 可观测性仪表盘（Token 用量统计、任务完成率）
- [ ] 操作审批流 UI（L3 操作推送审批到 App）

---

## 技术债

- [ ] API 错误处理统一（当前部分 endpoint 错误信息不一致）
- [ ] 数据库迁移：补全初始建表 migration（当前依赖 startup 自动建表）
- [ ] 配置外部化：将 localhost:8001 改为环境变量（生产部署需要）
- [ ] LLM API Key 加密：确认加密/解密逻辑已实现（当前 `api_key_encrypted` 字段）
- [ ] Docker-in-Docker 安全加固：限制容器可使用的 Docker 能力
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
