# Soloship 技术方案

> **版本**: v1.0
> **更新日期**: 2026-03-11

---

## 一、技术选型总览

| 层级 | 技术栈 | 版本 | 选型理由 |
|------|--------|------|----------|
| **移动端** | Flutter | 3.x | 跨平台（iOS/macOS/Android），单代码库 |
| **状态管理** | Riverpod 2 | 2.x | 类型安全、支持 AsyncValue、自动销毁 |
| **路由** | GoRouter | - | 声明式路由、支持 redirect 守卫 |
| **HTTP 客户端** | Dio | - | 拦截器机制、超时控制、multipart 上传 |
| **WebSocket** | web_socket_channel | - | 流式聊天实时通信 |
| **认证（客户端）** | Firebase Auth | - | Google/Apple 社交登录，零后端依赖 |
| **本地存储** | SharedPreferences | - | JWT token 持久化 |
| **后端框架** | FastAPI | Python 3.12 | 异步、自动 OpenAPI 文档、类型校验 |
| **ORM** | SQLAlchemy 2 | async | asyncpg 驱动，池化连接 |
| **数据库** | PostgreSQL | 15 | 成熟可靠，JSON 支持，全文搜索 |
| **缓存** | Redis | 7 | 状态缓存、会话管理 |
| **容器化** | Docker Compose | - | 本地开发一键启动 |
| **数据库迁移** | Alembic | - | 版本化 schema 变更 |
| **认证（服务端）** | Firebase ID Token + JWT | RS256/HS256 | Firebase 验证 + 平台 JWT 签发 |

---

## 二、开发环境

### 2.1 端口分配

| 服务 | 端口 | 说明 |
|------|------|------|
| Flutter 后端 API | 8001 | FastAPI（容器内 8000 映射到宿主 8001） |
| PostgreSQL | 5434 | 映射到容器内 5432 |
| Redis | 6380 | 映射到容器内 6379 |
| 原版后端（参考） | 8000 | 不启动，仅代码参考 |
| 原版前端（参考） | 3000/5173 | 不启动，仅代码参考 |

### 2.2 启动方式

```bash
# 启动全部后端服务
cd flutter_app && docker compose up -d

# 查看后端日志
docker compose logs backend -f

# 重启后端
docker compose restart backend

# Flutter App 启动
# VS Code 按 F5（已配置 launch.json）
# 或 flutter run
```

### 2.3 目录结构

```
opc_ref/
├── frontend/                 # 原版 React 前端（不动，仅参考）
├── backend/                  # 原版后端（不动，仅参考）
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart         # 入口：Firebase 初始化 + ProviderScope
│   │   ├── core/
│   │   │   ├── router/       # GoRouter 路由配置
│   │   │   ├── theme/        # AppColors + AppTheme（暗色/亮色）
│   │   │   └── network/      # Dio ApiClient + WebSocketClient
│   │   ├── stores/           # Riverpod StateNotifier（auth_store, app_store）
│   │   ├── services/         # ApiService 单例（所有 API 调用封装）
│   │   ├── components/       # 复用组件（Markdown、Modal、FileBrowser）
│   │   └── pages/            # 所有页面（9 个）
│   ├── backend/
│   │   ├── app/
│   │   │   ├── main.py       # FastAPI 入口 + lifespan（建表 + seed）
│   │   │   ├── config.py     # 环境变量配置
│   │   │   ├── database.py   # 异步 SQLAlchemy 引擎
│   │   │   ├── api/          # 23 个 API 路由模块
│   │   │   ├── models/       # 18 个 SQLAlchemy 模型文件
│   │   │   └── schemas/      # Pydantic 请求/响应 schema
│   │   └── alembic/          # 数据库迁移脚本（7 个版本）
│   └── docker-compose.yml    # Docker 编排（backend + postgres + redis）
└── docs/                     # 项目文档
```

---

## 三、认证方案

### 3.1 认证流程

```
┌─────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Flutter  │────→│ Firebase │────→│ 后端 API │────→│ PostgreSQL│
│   App    │     │  Auth    │     │ /auth/   │     │          │
│          │     │          │     │ firebase │     │          │
└─────────┘     └──────────┘     └──────────┘     └──────────┘
     │               │                │                 │
     │  1. 社交登录   │                │                 │
     │──────────────→│                │                 │
     │  2. Firebase  │                │                 │
     │     ID Token  │                │                 │
     │←──────────────│                │                 │
     │  3. 发送 ID Token              │                 │
     │───────────────────────────────→│                 │
     │               │    4. RS256 验证 Firebase Token   │
     │               │                │  5. 查找/创建用户│
     │               │                │────────────────→│
     │  6. 返回平台 JWT（HS256, 1 年） │                │
     │←───────────────────────────────│                 │
     │  7. 存入 SharedPreferences     │                 │
```

### 3.2 JWT 策略

- **签名算法**: HS256（平台 JWT）
- **有效期**: 525,600 分钟（≈ 1 年）
- **载荷**: `{ sub: user_id, username, role, tenant_id, exp }`
- **刷新策略**: 不刷新，过期后重新社交登录
- **新用户默认角色**: `platform_admin`

---

## 四、Agent 运行时方案

### 4.1 容器隔离

每个 Agent 实例运行在独立的 Docker 容器中（OpenClaw Gateway 进程）：

- **镜像**: `openclaw:local`（可配置）
- **网络**: `soloship_network` bridge 网络
- **文件挂载**: `/data/agents/<agent_id>/` 独立目录
- **生命周期**: 后端通过 Docker SDK 管理容器的创建、启动、停止、删除

### 4.2 Agent 文件结构

```
/data/agents/<agent_id>/
├── soul.md                   # 人格定义
├── memory.md                 # 长期记忆
├── todo.json                 # 待办任务
├── state.json                # 运行状态
├── skills/                   # 技能文件
│   └── <skill_name>/SKILL.md
├── workspace/                # 工作空间
└── enterprise_info/          # 企业信息（从平台同步）
```

### 4.3 LLM 模型管理

- 平台管理员在企业设置中配置**模型池**（多个 LLM 供应商）
- 每个 Agent 从池中选择**主模型**和**备选模型**
- 支持供应商: OpenAI、Anthropic、DeepSeek、Azure 等
- API Key 加密存储在数据库中

---

## 五、实时通信方案

### 5.1 WebSocket 聊天

- **协议**: `ws(s)://<host>/ws/chat/<agent_id>?token=<jwt>`
- **事件类型**:
  - `chunk`: 流式文本片段
  - `thinking`: Agent 推理过程
  - `tool_call`: 工具调用（名称、参数、结果）
  - `done`: 完成响应
- **自动重连**: 断开后 2 秒自动重试

### 5.2 轮询更新

- Agent 列表: 30 秒轮询
- Dashboard/Plaza: 15 秒轮询
- Agent 详情: 15 秒轮询

---

## 六、部署方案

### 6.1 开发环境（当前）

Docker Compose 本地部署：
- backend: FastAPI + Uvicorn
- postgres: PostgreSQL 15 Alpine
- redis: Redis 7 Alpine

### 6.2 生产环境（规划）

| 组件 | 方案 |
|------|------|
| 后端 | 云服务器 + Docker Compose / K8s |
| 数据库 | 云 RDS（PostgreSQL） |
| 缓存 | 云 Redis |
| 对象存储 | Agent 文件迁移到 S3/OSS |
| CDN | 静态资源加速 |
| SSL | Let's Encrypt / 云证书 |
| App 分发 | TestFlight（iOS）/ APK 直装（Android） |

---

## 七、安全策略

| 策略 | 实现 |
|------|------|
| 认证 | Firebase Social Auth + 平台 JWT |
| API 鉴权 | Bearer Token 验证（2C 模式下无角色校验，所有用户默认 `platform_admin`） |
| 数据隔离 | Tenant ID 作为查询过滤条件 |
| Agent 隔离 | 独立 Docker 容器 + 独立文件目录 |
| 密钥存储 | LLM API Key 加密存储（`api_key_encrypted`） |
| CORS | 白名单域名限制 |
| SQL 注入防护 | SQLAlchemy ORM 参数化查询 |
