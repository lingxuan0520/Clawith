# OpenRouter 模型池 + Token 计费系统

## 概述

平台统一使用 OpenRouter API Key 调用 LLM，用户无需自行配置 API Key。系统预设 11 个主流模型，按实际 token 用量计费（OpenRouter 成本 + 30% 加价）。

---

## 部署配置

### 1. 获取 OpenRouter API Key

前往 [openrouter.ai/keys](https://openrouter.ai/keys) 创建 API Key。

### 2. 配置环境变量

在 `flutter_app/.env` 中添加（该文件已 gitignore，不会提交）：

```
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxxxxxx
```

### 3. 重启后端

```bash
cd flutter_app
docker compose up -d backend
```

启动日志应显示：
```
[startup] ✅ Model pool seeded: 11 created, 0 updated (11 total)
```

---

## 预设模型池

启动时自动 seed，幂等（重复启动不会重复创建）。

| 模型 | Label | Input $/1M | Output $/1M | Tier | Vision |
|------|-------|-----------|-------------|------|--------|
| openai/gpt-4o | GPT-4o | 2.50 | 10.00 | premium | ✅ |
| openai/gpt-4o-mini | GPT-4o Mini | 0.15 | 0.60 | budget | ✅ |
| anthropic/claude-sonnet-4 | Claude Sonnet 4 | 3.00 | 15.00 | premium | ✅ |
| anthropic/claude-haiku-3.5 | Claude Haiku 3.5 | 0.80 | 4.00 | standard | ✅ |
| google/gemini-2.0-flash-001 | Gemini 2.0 Flash | 0.10 | 0.40 | budget | ✅ |
| google/gemini-2.5-pro-preview | Gemini 2.5 Pro | 1.25 | 10.00 | premium | ✅ |
| deepseek/deepseek-chat-v3-0324 | DeepSeek V3 | 0.27 | 1.10 | budget | ❌ |
| deepseek/deepseek-r1 | DeepSeek R1 | 0.55 | 2.19 | standard | ❌ |
| meta-llama/llama-4-maverick | Llama 4 Maverick | 0.20 | 0.60 | budget | ❌ |
| mistralai/mistral-large-2411 | Mistral Large | 2.00 | 6.00 | standard | ❌ |
| qwen/qwen-2.5-72b-instruct | Qwen 2.5 72B | 0.30 | 0.30 | budget | ❌ |

**Tier 说明：**
- 💰 `budget` — 低成本模型，适合日常对话
- 💰💰 `standard` — 中等性能，性价比高
- 💰💰💰 `premium` — 最强模型，适合复杂任务

### 更新模型价格

编辑 `backend/app/services/model_seeder.py` 中的 `SYSTEM_MODELS` 列表，重启后端即可自动更新。

### 添加新模型

在 `SYSTEM_MODELS` 列表中追加条目，格式：

```python
{"model": "provider/model-name", "label": "显示名称", "input": 0.50, "output": 2.00, "tier": "standard", "vision": False},
```

---

## 计费逻辑

### 费用计算

```
实际扣费 = (input_tokens / 1M × input_price + output_tokens / 1M × output_price) × 1.30
```

- 30% 加价覆盖平台运营成本
- 最小扣费 1 美分（避免免费调用）
- 所有金额以 USD 美分为单位存储（整数，无浮点精度问题）

### Token 计数来源

- **WebSocket 聊天**：OpenRouter 流式响应的 `stream_options.include_usage` 字段
- **任务执行**：OpenRouter 非流式响应的 `usage.prompt_tokens` / `usage.completion_tokens`
- **兜底**：如果 API 未返回 usage，回退到 `chars / 3` 估算（仅用于 agent 级别的 token 计数器，不影响计费）

### 调用链集成点

| 调用场景 | 文件 | 逻辑 |
|----------|------|------|
| WebSocket 聊天 | `backend/app/api/websocket.py` → `call_llm()` | 调用前检查余额，调用后读取 usage 并扣费 |
| 任务执行 | `backend/app/services/task_executor.py` | 每轮 LLM 调用后读取 usage 并扣费 |

### API Key 选择逻辑

```
if model.is_system_model and model.api_key_encrypted == "":
    → 使用 settings.OPENROUTER_API_KEY（平台统一 key）
else:
    → 使用 model.api_key_encrypted（用户自建模型的 key）
```

---

## API 端点

所有端点需要 JWT 认证（`Authorization: Bearer <token>`）。

### GET /api/billing/balance

返回当前用户余额。

```json
{
  "credit_balance_cents": 2000,
  "total_purchased_cents": 2000,
  "total_used_cents": 150,
  "subscription_tier": "free",
  "subscription_expires_at": null
}
```

### GET /api/billing/models

返回可用的系统模型列表（含价格）。前端模型选择下拉用这个接口。

```json
[
  {
    "id": "uuid",
    "provider": "openrouter",
    "model": "openai/gpt-4o-mini",
    "label": "GPT-4o Mini",
    "tier": "budget",
    "supports_vision": true,
    "cost_per_input_token_million": 0.15,
    "cost_per_output_token_million": 0.6
  }
]
```

### GET /api/billing/usage?days=30&agent_id=xxx

返回用量明细（最近 N 天，可选按 agent 过滤）。

```json
[
  {
    "id": "uuid",
    "agent_id": "uuid",
    "model_name": "GPT-4o Mini",
    "input_tokens": 150,
    "output_tokens": 50,
    "cost_cents": 1,
    "created_at": "2026-03-17T10:30:00Z"
  }
]
```

### POST /api/billing/add-credits

手动充值（开发/测试用，生产环境由 RevenueCat IAP 替代）。

```json
// Request
{"amount_cents": 1000}

// Response
{"credit_balance_cents": 3000, "added_cents": 1000}
```

---

## 数据库变更

### llm_models 表新增字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| cost_per_input_token_million | FLOAT | 0 | OpenRouter 输入价格 ($/1M tokens) |
| cost_per_output_token_million | FLOAT | 0 | OpenRouter 输出价格 ($/1M tokens) |
| is_system_model | BOOLEAN | FALSE | 是否为平台预设模型 |
| tier | VARCHAR(20) | 'standard' | budget / standard / premium |

### users 表新增字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| credit_balance_cents | INTEGER | 0 | 当前余额（USD 美分） |
| total_credits_purchased_cents | INTEGER | 0 | 累计充值 |
| total_credits_used_cents | INTEGER | 0 | 累计消费 |
| subscription_tier | VARCHAR(20) | 'free' | free / basic / pro |
| subscription_expires_at | TIMESTAMPTZ | NULL | 订阅过期时间 |

### usage_records 表（新建）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| user_id | UUID | FK → users |
| agent_id | UUID | FK → agents |
| model_id | UUID | FK → llm_models |
| model_name | VARCHAR | 冗余存储，方便查询 |
| input_tokens | INTEGER | 输入 token 数 |
| output_tokens | INTEGER | 输出 token 数 |
| cost_cents | INTEGER | 扣费金额（含加价） |
| openrouter_cost_cents | INTEGER | OpenRouter 原价 |
| created_at | TIMESTAMPTZ | 记录时间 |

迁移方式：`entrypoint.sh` 中的 `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` patches，配合 `Base.metadata.create_all()` 自动建新表。

---

## 前端变更

### 模型选择 UI

Agent 创建页和设置页的模型下拉改为调用 `GET /api/billing/models`，显示格式：

```
GPT-4o Mini  💰 ~$0.6/1M
Claude Sonnet 4  💰💰💰 ~$15.0/1M
```

### 余额显示

个人页（Profile）顶部显示余额卡片，包含当前余额和累计消费。

---

## 测试验证

```bash
cd flutter_app

# 1. 生成测试 JWT
JWT=$(docker compose exec -T backend python -c "
from app.core.security import create_access_token
print(create_access_token('YOUR_USER_ID', 'platform_admin'))
")

# 2. 查看模型列表
curl -s http://localhost:8001/api/billing/models \
  -H "Authorization: Bearer $JWT" | python3 -m json.tool

# 3. 充值 $10
curl -s -X POST http://localhost:8001/api/billing/add-credits \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"amount_cents": 1000}' | python3 -m json.tool

# 4. 查余额
curl -s http://localhost:8001/api/billing/balance \
  -H "Authorization: Bearer $JWT" | python3 -m json.tool

# 5. 在 App 中选模型 → 聊天 → 再查余额和用量
curl -s "http://localhost:8001/api/billing/usage?days=7" \
  -H "Authorization: Bearer $JWT" | python3 -m json.tool

# 6. 直接验证 OpenRouter Key 是否可用
curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"openai/gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":10}' \
  | python3 -m json.tool
```

---

## 关键文件清单

| 文件 | 说明 |
|------|------|
| `flutter_app/.env` | OpenRouter API Key（gitignore） |
| `docker-compose.yml` | `OPENROUTER_API_KEY` 环境变量传递 |
| `backend/app/config.py` | `OPENROUTER_API_KEY` 配置定义 |
| `backend/app/models/llm.py` | LLMModel 定价字段 |
| `backend/app/models/user.py` | User 余额字段 |
| `backend/app/models/billing.py` | UsageRecord 模型 |
| `backend/app/services/model_seeder.py` | 模型池 seeder |
| `backend/app/services/billing.py` | 计费核心逻辑 |
| `backend/app/api/billing.py` | 计费 API 端点 |
| `backend/app/api/websocket.py` | 聊天计费集成 |
| `backend/app/services/task_executor.py` | 任务计费集成 |
| `backend/entrypoint.sh` | DB 迁移 patches |

---

## Phase 2 规划（未实现）

- RevenueCat SDK 集成（Flutter + 后端 webhook）
- 订阅套餐页面（$9.9 / $29.9 / $99.9）
- IAP 购买流程 + Apple/Google 收据验证
- 用量 Dashboard 页面
- 余额不足提醒 + 自动暂停 Agent
