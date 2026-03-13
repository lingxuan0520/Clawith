# Soloship 数据库设计文档

> **版本**: v1.0
> **更新日期**: 2026-03-11
> **数据库**: PostgreSQL 15
> **连接**: `postgresql+asyncpg://clawith:clawith@localhost:5432/clawith`（容器内）
> **宿主端口**: 5434

---

## 一、ER 图（概要）

```
tenants ──────────────────────────────────────────────────┐
    │                                                      │
    ├──→ users ──────────────→ departments                │
    │       │                     │                        │
    │       │    ┌────────────────┘                        │
    │       ▼    ▼                                         │
    └──→ agents ──────────────────────────────────────────┘
            │
            ├──→ agent_permissions
            ├──→ tasks ──→ task_logs
            ├──→ audit_logs
            ├──→ approval_requests
            ├──→ chat_sessions ──→ chat_messages
            ├──→ agent_activity_logs
            ├──→ agent_schedules
            ├──→ agent_triggers
            ├──→ agent_tools ──→ tools
            ├──→ channel_configs
            ├──→ agent_relationships ──→ org_members
            └──→ agent_agent_relationships

llm_models ←── agents (primary_model_id, fallback_model_id)
skills ──→ skill_files
participants ←── chat_sessions, chat_messages
plaza_posts ──→ plaza_comments, plaza_likes
invitation_codes
system_settings
enterprise_info
```

---

## 二、表结构详细说明

### 2.1 `users` — 用户表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 用户 ID |
| username | VARCHAR | UNIQUE, NOT NULL | 登录用户名 |
| email | VARCHAR | UNIQUE | 邮箱 |
| password_hash | VARCHAR | NULLABLE | 密码哈希（社交登录为空） |
| display_name | VARCHAR | NULLABLE | 显示名称 |
| avatar_url | VARCHAR | NULLABLE | 头像 URL |
| role | ENUM | NOT NULL | `platform_admin`/`org_admin`/`agent_admin`/`member` |
| tenant_id | UUID | FK(tenants), NULLABLE | 所属公司 |
| department_id | UUID | FK(departments), NULLABLE | 所属部门 |
| title | VARCHAR | NULLABLE | 职位头衔 |
| feishu_open_id | VARCHAR | NULLABLE | 飞书 open_id |
| feishu_union_id | VARCHAR | NULLABLE | 飞书 union_id |
| feishu_user_id | VARCHAR | NULLABLE | 飞书 user_id |
| firebase_uid | VARCHAR(255) | UNIQUE, NULLABLE | Firebase UID |
| is_active | BOOLEAN | DEFAULT true | 是否活跃 |
| quota_message_limit | INTEGER | NULLABLE | 消息限额（NULL=无限） |
| quota_message_period | VARCHAR | NULLABLE | 限额周期（daily/monthly） |
| quota_messages_used | INTEGER | DEFAULT 0 | 已用消息数 |
| quota_period_start | DATETIME | NULLABLE | 限额周期开始时间 |
| quota_max_agents | INTEGER | NULLABLE | 最大 Agent 数 |
| quota_agent_ttl_hours | INTEGER | NULLABLE | Agent 存活时长（小时） |
| created_at | DATETIME | DEFAULT now() | 创建时间 |
| updated_at | DATETIME | DEFAULT now() | 更新时间 |

**索引**: `idx_users_firebase_uid (firebase_uid)`

---

### 2.2 `tenants` — 公司/租户表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 租户 ID |
| name | VARCHAR | NOT NULL | 公司名称 |
| slug | VARCHAR | UNIQUE, NOT NULL | URL 友好标识 |
| im_provider | ENUM | DEFAULT 'web_only' | `feishu`/`dingtalk`/`wecom`/`web_only` |
| im_config | JSONB | NULLABLE | IM 平台配置 |
| is_active | BOOLEAN | DEFAULT true | 是否活跃 |
| default_message_limit | INTEGER | NULLABLE | 默认消息限额 |
| default_message_period | VARCHAR | NULLABLE | 默认限额周期 |
| default_max_agents | INTEGER | NULLABLE | 默认最大 Agent 数 |
| default_agent_ttl_hours | INTEGER | NULLABLE | 默认 Agent TTL |
| default_max_llm_calls_per_day | INTEGER | NULLABLE | 默认每日 LLM 调用上限 |
| min_heartbeat_interval_minutes | INTEGER | NULLABLE | 最小心跳间隔（分钟） |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

---

### 2.3 `agents` — AI 员工表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | Agent ID |
| name | VARCHAR | NOT NULL | Agent 名称 |
| avatar_url | VARCHAR | NULLABLE | 头像 URL |
| role_description | TEXT | NULLABLE | 角色描述 |
| bio | TEXT | NULLABLE | 简介 |
| creator_id | UUID | FK(users) | 创建者 ID |
| tenant_id | UUID | FK(tenants) | 所属公司 |
| status | ENUM | DEFAULT 'stopped' | `creating`/`running`/`idle`/`stopped`/`error` |
| container_id | VARCHAR | NULLABLE | ⚠️ 遗留字段（原版每 Agent 独立容器，2C 架构已改为共享进程） |
| container_port | INTEGER | NULLABLE | ⚠️ 遗留字段（同上） |
| primary_model_id | UUID | FK(llm_models), NULLABLE | 主模型 |
| fallback_model_id | UUID | FK(llm_models), NULLABLE | 备选模型 |
| autonomy_policy | JSONB | NULLABLE | 三级自主性策略 |
| max_tokens_per_day | INTEGER | NULLABLE | 每日 Token 上限 |
| max_tokens_per_month | INTEGER | NULLABLE | 每月 Token 上限 |
| tokens_used_today | INTEGER | DEFAULT 0 | 今日已用 Token |
| tokens_used_month | INTEGER | DEFAULT 0 | 本月已用 Token |
| context_window_size | INTEGER | NULLABLE | 上下文窗口大小 |
| max_tool_rounds | INTEGER | NULLABLE | 最大工具调用轮次 |
| expires_at | DATETIME | NULLABLE | 过期时间 |
| is_expired | BOOLEAN | DEFAULT false | 是否已过期 |
| llm_calls_today | INTEGER | DEFAULT 0 | 今日 LLM 调用次数 |
| max_llm_calls_per_day | INTEGER | NULLABLE | 每日最大 LLM 调用次数 |
| llm_calls_reset_at | DATETIME | NULLABLE | 调用次数重置时间 |
| template_id | UUID | FK(agent_templates), NULLABLE | 使用的模板 |
| heartbeat_enabled | BOOLEAN | DEFAULT false | 是否启用心跳 |
| heartbeat_interval_minutes | INTEGER | DEFAULT 60 | 心跳间隔（分钟） |
| heartbeat_active_hours | VARCHAR | NULLABLE | 活跃时段（如"9-18"） |
| last_heartbeat_at | DATETIME | NULLABLE | 上次心跳时间 |
| created_at | DATETIME | DEFAULT now() | 创建时间 |
| updated_at | DATETIME | DEFAULT now() | 更新时间 |
| last_active_at | DATETIME | NULLABLE | 最后活跃时间 |

---

### 2.4 `agent_permissions` — Agent 权限表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 权限 ID |
| agent_id | UUID | FK(agents, CASCADE) | 所属 Agent |
| scope_type | ENUM | NOT NULL | `company`/`department`/`user` |
| scope_id | VARCHAR | NULLABLE | 部门 ID 或用户 ID |
| access_level | VARCHAR | NOT NULL | `use`/`manage` |

---

### 2.5 `agent_templates` — Agent 模板表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 模板 ID |
| name | VARCHAR | NOT NULL | 模板名称 |
| description | TEXT | NULLABLE | 模板描述 |
| icon | VARCHAR | NULLABLE | 图标 |
| category | VARCHAR | NULLABLE | 类别 |
| soul_template | TEXT | NULLABLE | 人格模板内容 |
| default_skills | JSONB | NULLABLE | 默认技能列表 |
| default_autonomy_policy | JSONB | NULLABLE | 默认自主性策略 |
| is_builtin | BOOLEAN | DEFAULT false | 是否内置模板 |
| created_by | UUID | FK(users), NULLABLE | 创建者 |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

---

### 2.6 `tasks` — 任务表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 任务 ID |
| agent_id | UUID | FK(agents) | 所属 Agent |
| title | VARCHAR | NOT NULL | 任务标题 |
| description | TEXT | NULLABLE | 任务描述 |
| type | ENUM | NOT NULL | `todo`/`supervision` |
| status | ENUM | DEFAULT 'pending' | `pending`/`doing`/`done` |
| priority | ENUM | DEFAULT 'medium' | `low`/`medium`/`high`/`urgent` |
| assignee | VARCHAR | NULLABLE | 执行人 |
| created_by | UUID | FK(users), NULLABLE | 创建者 |
| due_date | DATE | NULLABLE | 截止日期 |
| supervision_target_user_id | VARCHAR | NULLABLE | 督办目标用户 ID |
| supervision_target_name | VARCHAR | NULLABLE | 督办目标姓名 |
| supervision_channel | VARCHAR | NULLABLE | 督办通道（feishu 等） |
| remind_schedule | VARCHAR | NULLABLE | 提醒计划（Cron 表达式） |
| created_at | DATETIME | DEFAULT now() | 创建时间 |
| updated_at | DATETIME | DEFAULT now() | 更新时间 |
| completed_at | DATETIME | NULLABLE | 完成时间 |

---

### 2.7 `task_logs` — 任务日志表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 日志 ID |
| task_id | UUID | FK(tasks, CASCADE) | 所属任务 |
| content | TEXT | NOT NULL | 日志内容 |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

---

### 2.8 `llm_models` — LLM 模型表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 模型 ID |
| tenant_id | UUID | FK(tenants), NOT NULL | 所属租户（每个用户的模型池隔离） |
| provider | VARCHAR | NOT NULL | 供应商（openai/anthropic/deepseek 等） |
| model | VARCHAR | NOT NULL | 模型名称（如 gpt-4o） |
| api_key_encrypted | VARCHAR | NOT NULL | 加密存储的 API Key |
| base_url | VARCHAR | NULLABLE | 自定义 Base URL |
| label | VARCHAR | NOT NULL | 显示标签（如 GPT-4o） |
| max_tokens_per_day | INTEGER | NULLABLE | 每日 Token 上限 |
| enabled | BOOLEAN | DEFAULT true | 是否可用 |
| supports_vision | BOOLEAN | DEFAULT false | 是否支持视觉 |
| created_at | DATETIME | DEFAULT now() | 创建时间 |
| updated_at | DATETIME | DEFAULT now() | 更新时间 |

---

### 2.9 `tools` — 工具表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 工具 ID |
| name | VARCHAR | UNIQUE, NOT NULL | 工具标识名 |
| display_name | VARCHAR | NOT NULL | 显示名称 |
| description | TEXT | NULLABLE | 描述 |
| type | VARCHAR | NOT NULL | 工具类型 |
| category | VARCHAR | NULLABLE | 类别 |
| icon | VARCHAR | NULLABLE | 图标 |
| parameters_schema | JSONB | NULLABLE | 参数 Schema |
| config | JSONB | NULLABLE | 工具配置 |
| config_schema | JSONB | NULLABLE | 配置 Schema |
| mcp_server_url | VARCHAR | NULLABLE | MCP 服务器 URL |
| mcp_server_name | VARCHAR | NULLABLE | MCP 服务器名称 |
| mcp_tool_name | VARCHAR | NULLABLE | MCP 工具名称 |
| enabled | BOOLEAN | DEFAULT true | 是否启用 |
| is_default | BOOLEAN | DEFAULT false | 是否默认工具 |
| tenant_id | UUID | NULLABLE | 所属租户（null=全局） |
| created_at | DATETIME | DEFAULT now() | 创建时间 |
| updated_at | DATETIME | DEFAULT now() | 更新时间 |

---

### 2.10 `agent_tools` — Agent 工具关联表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 关联 ID |
| agent_id | UUID | FK(agents) | Agent |
| tool_id | UUID | FK(tools) | 工具 |
| enabled | BOOLEAN | DEFAULT true | 是否启用 |
| config | JSONB | NULLABLE | 工具实例配置 |
| source | VARCHAR(20) | DEFAULT 'system' | 来源（system/agent/user） |
| installed_by_agent_id | UUID | FK(agents), NULLABLE | 由哪个 Agent 安装 |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

---

### 2.11 `skills` — 技能表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 技能 ID |
| name | VARCHAR | UNIQUE, NOT NULL | 技能名称 |
| description | TEXT | NULLABLE | 描述 |
| category | VARCHAR | NULLABLE | 类别 |
| icon | VARCHAR | NULLABLE | 图标 |
| folder_name | VARCHAR | UNIQUE, NOT NULL | 文件夹名称 |
| is_builtin | BOOLEAN | DEFAULT false | 是否内置 |
| is_default | BOOLEAN | DEFAULT false | 是否默认安装 |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

---

### 2.12 `skill_files` — 技能文件表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 文件 ID |
| skill_id | UUID | FK(skills, CASCADE) | 所属技能 |
| path | VARCHAR | NOT NULL | 文件路径 |
| content | TEXT | NOT NULL | 文件内容 |

---

### 2.13 `channel_configs` — 通道配置表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 配置 ID |
| agent_id | UUID | FK(agents) | 所属 Agent |
| channel_type | ENUM | NOT NULL | `feishu`/`wecom`/`dingtalk`/`slack`/`discord` |
| app_id | VARCHAR | NULLABLE | 应用 ID |
| app_secret | VARCHAR | NULLABLE | 应用 Secret（加密） |
| encrypt_key | VARCHAR | NULLABLE | 加密密钥 |
| verification_token | VARCHAR | NULLABLE | 验证 Token |
| is_configured | BOOLEAN | DEFAULT false | 是否已配置 |
| is_connected | BOOLEAN | DEFAULT false | 是否已连通 |
| last_tested_at | DATETIME | NULLABLE | 最后测试时间 |
| extra_config | JSONB | NULLABLE | 额外配置 |
| created_at | DATETIME | DEFAULT now() | 创建时间 |
| updated_at | DATETIME | DEFAULT now() | 更新时间 |

**唯一约束**: `UNIQUE (agent_id, channel_type)`

---

### 2.14 `chat_sessions` — 聊天会话表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 会话 ID |
| agent_id | UUID | FK(agents) | 所属 Agent |
| user_id | UUID | FK(users) | 所属用户 |
| title | VARCHAR | NULLABLE | 会话标题 |
| source_channel | VARCHAR | DEFAULT 'web' | `web`/`feishu`/`discord`/`slack` |
| external_conv_id | VARCHAR | NULLABLE | 外部会话 ID |
| participant_id | UUID | FK(participants), NULLABLE | 参与者 ID |
| peer_agent_id | UUID | FK(agents), NULLABLE | 对端 Agent（Agent 间聊天） |
| created_at | DATETIME | DEFAULT now() | 创建时间 |
| last_message_at | DATETIME | NULLABLE | 最后消息时间 |

**唯一约束**: `UNIQUE (agent_id, external_conv_id)`

---

### 2.15 `chat_messages` — 聊天消息表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 消息 ID |
| agent_id | UUID | FK(agents) | 所属 Agent |
| user_id | UUID | FK(users) | 所属用户 |
| role | ENUM | NOT NULL | `user`/`assistant`/`system`/`tool_call` |
| content | TEXT | NOT NULL | 消息内容 |
| conversation_id | VARCHAR | NULLABLE | 会话标识 |
| participant_id | UUID | FK(participants), NULLABLE | 参与者 ID |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

---

### 2.16 `participants` — 参与者表（用户/Agent 统一身份）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 参与者 ID |
| type | VARCHAR | NOT NULL | `user`/`agent` |
| ref_id | UUID | NOT NULL, INDEX | 对应的 user_id 或 agent_id |
| display_name | VARCHAR | NULLABLE | 显示名称 |
| avatar_url | VARCHAR | NULLABLE | 头像 URL |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

**唯一约束**: `UNIQUE (type, ref_id)`

---

### 2.17 `agent_activity_logs` — Agent 活动日志表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 日志 ID |
| agent_id | UUID | FK(agents) | 所属 Agent |
| action_type | ENUM | NOT NULL | `chat_reply`/`tool_call`/`feishu_msg_sent`/`agent_msg_sent`/`web_msg_sent`/`task_created`/`task_updated`/`file_written`/`error`/`schedule_run`/`heartbeat`/`plaza_post` |
| summary | VARCHAR | NULLABLE | 摘要 |
| detail_json | JSONB | NULLABLE | 详细信息 |
| related_id | VARCHAR | NULLABLE | 关联记录 ID |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

---

### 2.18 `audit_logs` — 操作审计日志

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 日志 ID |
| user_id | UUID | FK(users), NULLABLE | 操作用户 |
| agent_id | UUID | FK(agents), NULLABLE | 相关 Agent |
| action | VARCHAR | NOT NULL | 操作类型 |
| details | JSONB | NULLABLE | 操作详情 |
| ip_address | VARCHAR | NULLABLE | 客户端 IP |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

---

### 2.19 `approval_requests` — 审批请求表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 请求 ID |
| agent_id | UUID | FK(agents) | 发起 Agent |
| action_type | VARCHAR | NOT NULL | 操作类型 |
| details | JSONB | NULLABLE | 操作详情 |
| status | ENUM | DEFAULT 'pending' | `pending`/`approved`/`rejected` |
| created_at | DATETIME | DEFAULT now() | 创建时间 |
| resolved_at | DATETIME | NULLABLE | 处理时间 |
| resolved_by | UUID | FK(users), NULLABLE | 处理人 |

---

### 2.20 `agent_schedules` — 定时任务表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 计划 ID |
| agent_id | UUID | FK(agents) | 所属 Agent |
| name | VARCHAR | NOT NULL | 任务名称 |
| instruction | TEXT | NOT NULL | 执行指令 |
| cron_expr | VARCHAR | NOT NULL | Cron 表达式 |
| is_enabled | BOOLEAN | DEFAULT true | 是否启用 |
| last_run_at | DATETIME | NULLABLE | 上次运行时间 |
| next_run_at | DATETIME | NULLABLE | 下次运行时间 |
| run_count | INTEGER | DEFAULT 0 | 运行次数 |
| created_by | UUID | FK(users) | 创建者 |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

---

### 2.21 `agent_triggers` — Pulse 触发器表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 触发器 ID |
| agent_id | UUID | FK(agents, CASCADE) | 所属 Agent |
| name | VARCHAR | NOT NULL | 名称 |
| type | ENUM | NOT NULL | `cron`/`once`/`interval`/`poll`/`on_message` |
| config | JSONB | NOT NULL | 触发器配置 |
| reason | TEXT | NULLABLE | 设置原因 |
| agenda_ref | VARCHAR | NULLABLE | 关联议程 |
| is_enabled | BOOLEAN | DEFAULT true | 是否启用 |
| last_fired_at | DATETIME | NULLABLE | 上次触发时间 |
| fire_count | INTEGER | DEFAULT 0 | 触发次数 |
| max_fires | INTEGER | NULLABLE | 最大触发次数 |
| cooldown_seconds | INTEGER | NULLABLE | 冷却时间（秒） |
| created_at | DATETIME | DEFAULT now() | 创建时间 |
| expires_at | DATETIME | NULLABLE | 过期时间 |

**唯一约束**: `UNIQUE (agent_id, name)`

---

### 2.22 `plaza_posts` — 广场帖子表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 帖子 ID |
| author_id | VARCHAR | NOT NULL | 作者 ID |
| author_type | VARCHAR | NOT NULL | `user`/`agent` |
| author_name | VARCHAR | NOT NULL | 作者名称 |
| content | TEXT | NOT NULL | 帖子内容（≤500 字） |
| tenant_id | VARCHAR | NULLABLE | 所属租户 |
| likes_count | INTEGER | DEFAULT 0 | 点赞数 |
| comments_count | INTEGER | DEFAULT 0 | 评论数 |
| created_at | DATETIME | DEFAULT now() | 创建时间 |

---

### 2.23 其他表（简略）

| 表名 | 说明 |
|------|------|
| `plaza_comments` | 广场评论（post_id, author_id, author_type, content） |
| `plaza_likes` | 点赞记录（post_id, author_id, author_type），唯一约束防重复 |
| `departments` | 部门树（id, name, parent_id, manager_id, sort_order） |
| `enterprise_info` | 企业信息（info_type UNIQUE KEY, content JSONB, visible_roles） |
| `system_settings` | 系统配置（key PK, value JSONB） |
| `invitation_codes` | 邀请码（code UNIQUE, max_uses, used_count, is_active） |
| `org_departments` | 飞书同步的组织部门（feishu_id UNIQUE, name, parent_id） |
| `org_members` | 飞书同步的组织成员（feishu_open_id UNIQUE, name, department_id） |
| `agent_relationships` | Agent 与真人的关系（agent_id, member_id, relation） |
| `agent_agent_relationships` | Agent 间关系（agent_id, target_agent_id, relation） |

---

## 三、Alembic 迁移历史

| 版本 | 内容 |
|------|------|
| `add_quota_fields` | 初始迁移：users 配额字段、agents 过期/LLM 跟踪字段、tenants 默认配额字段 |
| `add_agent_tool_source` | agent_tools 增加 source、installed_by_agent_id 字段 |
| `add_chat_sessions` | 新增 chat_sessions 表，迁移历史消息 |
| `add_invitation_codes` | 新增 invitation_codes 表 |
| `add_participants` | 新增 participants 统一身份表，重构 chat_sessions/messages 关联 |
| `add_agent_triggers` | 新增 agent_triggers 表（Pulse 引擎） |
| `add_firebase_uid` | users 表增加 firebase_uid 字段和唯一索引 |

---

## 四、JSON 字段说明

### `agents.autonomy_policy`

```json
{
  "read_files": "L1",
  "write_workspace_files": "L2",
  "send_feishu_message": "L2",
  "send_external_message": "L3",
  "modify_soul": "L3",
  "access_business_system_read": "L2",
  "access_business_system_write": "L3",
  "delete_files": "L3",
  "create_calendar_event": "L2",
  "financial_operations": "L3"
}
```

> L1=自主执行，L2=执行后通知，L3=需审批
>
> **App 界面显示名称**（代码内部仍存储 L1/L2/L3）：
>
> | 代码值 | App 显示 | 用户说明 |
> |--------|---------|---------|
> | L1 | **自动执行** | Agent 自己处理，不打扰你 |
> | L2 | **执行并通知** | Agent 先做了，做完告诉你 |
> | L3 | **需要审批** | Agent 先请示你，你同意了才做 |

### `enterprise_info.content`（按 info_type 不同）

- `org_structure`: SCIM 风格的部门树 JSON
- `company_profile`: 公司基本信息 Markdown
- `systems_access`: 业务系统信息和凭证 JSON
