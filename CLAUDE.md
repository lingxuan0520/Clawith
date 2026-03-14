# CLAUDE.md — Soloship 项目工作指南

## 项目概览

**Soloship** 是一个 2C 移动应用，让每个用户都能拥有自己的 AI 数字员工团队。
用户登录后即是自己公司的最高管理者，可以创建公司、雇佣 AI 员工（Agent）、分配任务。

这个仓库包含两套独立的技术栈：

| 目录 | 用途 | 状态 |
|------|------|------|
| `frontend/` | 原版 React Web 前端 | 保持不动，参考用 |
| `backend/` | 原版后端（JWT 登录）| 保持不动 |
| `flutter_app/` | 新 Flutter 移动端 App | 主要开发目标 |
| `flutter_app/backend/` | Flutter 专用后端（Firebase Auth）| 主要开发目标 |

---

## 核心原则

1. **原版不动**：`frontend/` 和 `backend/` 目录不做任何修改，仅作参考。
2. **先原版、再优化**：移植功能时先 1:1 还原 React 原版逻辑，再在此基础上改进。
3. **2C 逻辑**：每个登录用户默认拥有 `platform_admin` 权限，每个人都是自己公司的老板。
4. **中文优先**：App UI 当前阶段全部使用中文。
5. **出问题看日志**：遇到 bug 先查后端日志（`docker compose logs backend -f`）和数据库，不要只看代码猜。代码是自己写的，自己看自己看不出问题。

---

## 目录结构

```
opc_ref/
├── frontend/               # 原版 React 前端（不动）
├── backend/                # 原版后端（不动）
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── router/app_router.dart    # GoRouter，含 splash 启动页
│   │   │   ├── theme/app_theme.dart      # AppColors 暗色主题
│   │   │   └── network/api_client.dart   # Dio，指向 localhost:8001
│   │   ├── stores/
│   │   │   ├── auth_store.dart           # AuthState，含 initialized 标志
│   │   │   └── app_store.dart            # AppState（currentTenantId, themeMode）
│   │   ├── services/api.dart             # 所有 API 调用封装
│   │   └── pages/                        # 对应 React pages/ 的所有页面
│   └── backend/                          # Flutter 专用后端
│       └── app/api/auth.py               # Firebase 登录端点 POST /api/auth/firebase
├── .vscode/launch.json     # VS Code 调试配置（F5 启动模拟器）
└── CLAUDE.md               # 本文件
```

---

## Flutter 后端

- **端口**：8001（区别于原版 8000）
- **数据库**：PostgreSQL 端口 5434，数据库名 `clawith`，用户 `clawith`
- **Redis**：端口 6380
- **认证方式**：Firebase ID Token → 后端 RS256 验证 → 返回平台 JWT
- **JWT 有效期**：1 年
- **新用户默认角色**：`platform_admin`（每个用户都是自己公司的老板）

启动命令（在 `flutter_app/` 目录下）：
```bash
docker compose up -d
```

---

## 常用命令

```bash
# 查看后端日志
cd flutter_app && docker compose logs backend -f

# 查询数据库
docker compose exec -T postgres psql -U clawith -d clawith -c "SELECT * FROM users;"

# 重启后端
docker compose restart backend

# Flutter 热重载（模拟器内）
Cmd+Shift+R

# Flutter 热重启（改了状态类时用）
Cmd+Shift+F5（VS Code）或模拟器内 Shift+R
```

---

## 关键设计决策

### 认证流程
1. App 启动 → 显示 `/splash`（加载圆圈）
2. 从 SharedPreferences 读 token → 调用 `/api/auth/me` 验证
3. 验证成功 → 跳 `/plaza`；失败或无 token → 跳 `/login`
4. 登录页：Google Sign-In 或 Apple Sign-In → Firebase → 后端 `/api/auth/firebase` → 返回 JWT

### 权限模型
- 所有登录用户默认 `platform_admin`
- 没有邀请码限制（2C 应用，开放注册）
- 每个用户可以创建任意数量的公司（tenant）

### 侧边栏
- 顶部显示当前公司名，多公司时点击弹出 `showMenu` 切换（宽度与触发区域一致）
- 底部显示用户头像（Google 有头像，Apple 没有）、姓名、角色
- 企业设置：`platform_admin` 或 `org_admin` 可见（与原版逻辑一致）

---

## 待办事项（按优先级）

- [ ] 完整测试所有现有页面功能（Agent 创建/详情/聊天/消息/企业设置）
- [ ] 头像：Apple 登录无头像时显示首字母彩色头像
- [ ] 多语言支持（当前硬编码中文）
- [ ] 虚拟办公室 RPG 场景（Flame 引擎）
- [ ] 移动端 UI 优化（手势、摇杆等）
