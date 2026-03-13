# Soloship 成本计算文档

> **版本**: v2.0
> **更新日期**: 2026-03-13
> **货币**: USD
> **LLM 接入**: OpenRouter（统一 API，按 token 计费，无月费，5.5% 平台费）
> **部署架构**: Docker Compose 单机（backend + postgres + redis）

---

## 一、成本构成总览

| 类别 | 月成本（USD） | 备注 |
|------|-------------|------|
| LLM API（OpenRouter） | 变量成本 | 取决于用户数量和模型选择 |
| 云服务器（VPS） | $10 ~ $80 | 一台机器跑 Docker Compose |
| Firebase Auth | $0 | 10,000 MAU 免费 |
| Apple 开发者账号 | $8.25/月 | $99/年 |
| Google Play | $25 一次性 | 未来 Android |
| **固定成本** | **~$18 ~ $88/月** | |

> 数据库（PostgreSQL）和缓存（Redis）都跑在同一台 VPS 的 Docker Compose 里，不额外花钱。

---

## 二、LLM 模型定价（OpenRouter 实际价格，2026-03）

### 2.1 全部可选模型

以下为 OpenRouter 上的实际价格（含 5.5% 平台费），按 **输出价格** 从高到低排列。
`openrouter_id` 是代码里调用 OpenRouter API 时用的模型标识。

**旗舰级**

| 模型 | openrouter_id | 输入 / 1M | 输出 / 1M | 上下文 |
|------|--------------|----------|----------|--------|
| Claude Opus 4.6 | `anthropic/claude-opus-4-6` | $5.00 | $25.00 | 1M |
| GPT-5.4 | `openai/gpt-5.4` | $2.50 | $15.00 | 1M |
| Claude Sonnet 4.6 | `anthropic/claude-sonnet-4-6` | $3.00 | $15.00 | 1M |
| GPT-5.3 Chat | `openai/gpt-5.3-chatgpt` | $1.75 | $14.00 | 128K |

**中端**

| 模型 | openrouter_id | 输入 / 1M | 输出 / 1M | 上下文 |
|------|--------------|----------|----------|--------|
| Claude Haiku 4.5 | `anthropic/claude-haiku-4-5` | $1.00 | $5.00 | 200K |
| Kimi K2.5 | `moonshotai/kimi-k2.5` | $0.45 | $2.20 | 262K |
| DeepSeek R1 | `deepseek/deepseek-r1` | $0.55 | $2.19 | 164K |
| Gemini 3.1 Flash Lite | `google/gemini-3.1-flash-lite-preview` | $0.25 | $1.50 | 1M |
| MiniMax M2.5 | `minimax/minimax-m2.5` | $0.295 | $1.20 | 196K |

**低价**

| 模型 | openrouter_id | 输入 / 1M | 输出 / 1M | 上下文 |
|------|--------------|----------|----------|--------|
| Mercury 2 | `inception/mercury-2` | $0.25 | $0.75 | 128K |
| GPT-5.4 Mini | `openai/gpt-5.4-mini` | $0.15 | $0.60 | 128K |
| ByteDance Seed 2.0 Mini | `bytedance-seed/seed-2.0-mini` | $0.10 | $0.40 | 262K |
| DeepSeek V3.2 | `deepseek/deepseek-chat` | $0.25 | $0.38 | 164K |

**免费**

| 模型 | openrouter_id | 限制 |
|------|--------------|------|
| StepFun Step 3.5 Flash | `stepfun/step-3.5-flash:free` | 20 req/min, 200 req/day |
| Qwen3 Coder 480B | `qwen/qwen3-coder:free` | 20 req/min, 200 req/day |
| GLM 4.5 Air | `zhipu/glm-4.5-air:free` | 20 req/min, 200 req/day |
| Kimi K2 | `moonshotai/kimi-k2:free` | 20 req/min, 200 req/day |
| DeepSeek R1 | `deepseek/deepseek-r1:free` | 20 req/min, 200 req/day |

### 2.2 单次对话成本

假设单次对话：**2,000 输入 tokens + 500 输出 tokens**

| 模型 | 单次成本 | 每天 10 次 | 每月 300 次 |
|------|---------|----------|-----------|
| Claude Opus 4.6 | $0.0225 | $0.225 | $6.75 |
| Claude Sonnet 4.6 | $0.0135 | $0.135 | $4.05 |
| GPT-5.4 | $0.0125 | $0.125 | $3.75 |
| Claude Haiku 4.5 | $0.0045 | $0.045 | $1.35 |
| Kimi K2.5 | $0.0020 | $0.020 | $0.60 |
| MiniMax M2.5 | $0.0012 | $0.012 | $0.36 |
| DeepSeek V3.2 | $0.0007 | $0.007 | $0.21 |
| Free 模型 | $0 | $0 | $0 |

### 2.3 Heartbeat 成本

每次心跳约 5,000 tokens（输入 4,000 + 输出 1,000）：

| 场景 | 模型 | 单次成本 | 月成本 |
|------|------|---------|--------|
| 3 Agent × 8 次/天 | DeepSeek V3.2 | $0.0014 | $1.01 |
| 3 Agent × 8 次/天 | Haiku 4.5 | $0.009 | $6.48 |
| 5 Agent × 8 次/天 | Haiku 4.5 | $0.009 | $10.80 |

---

## 三、服务器成本

### 3.1 部署方式

一台海外 VPS，上面跑 Docker Compose（backend + postgres + redis 三个容器）。
与本地开发环境完全一致，无需额外托管数据库或 Redis。

### 3.2 海外 VPS 选型

| 供应商 | 规格 | 月成本 | 特点 |
|--------|------|-------|------|
| **AWS Lightsail** | 1 vCPU, 1GB, 40G SSD | $5/月 | 最便宜，够跑测试 |
| **AWS Lightsail** | 2 vCPU, 2GB, 60G SSD | $10/月 | 小规模生产 |
| **DigitalOcean** | 2 vCPU, 2GB, 50G SSD | $12/月 | 简单好用 |
| **Fly.io** | shared-cpu-1x, 2GB | $10.70/月 | 全球 35+ 节点 |
| **AWS Lightsail** | 2 vCPU, 4GB, 80G SSD | $20/月 | 稳定生产 |
| **DigitalOcean** | 4 vCPU, 8GB | $48/月 | 规模化 |

### 3.3 分阶段方案

| 阶段 | 用户规模 | 推荐配置 | 月成本 |
|------|---------|---------|-------|
| 内测 | ≤50 人 | Lightsail 2vCPU/2GB | **$10** |
| 上线 | 50~500 人 | Lightsail 2vCPU/4GB | **$20** |
| 增长 | 500~2000 人 | DigitalOcean 4vCPU/8GB | **$48** |
| 规模化 | 2000+ 人 | 2× 实例 + 负载均衡 | **~$120** |

---

## 四、支付渠道成本

| 渠道 | 费率 | 适用场景 |
|------|------|---------|
| Apple IAP（年收入 < $1M） | **15%** | iOS 内购（必须走 IAP） |
| Apple IAP（年收入 ≥ $1M） | **30%** | 同上 |
| Google Play（年收入前 $1M） | **15%** | Android 内购 |
| Stripe | **2.9% + $0.30** | Web 端充值（如果有的话） |

> Apple 抽成是最大的渠道成本。用户付 $9.99，Apple 拿走 $1.50，你到手 $8.49。

---

## 五、订阅制设计

### 5.1 核心逻辑：按模型价格动态分配 Token

**不可能亏钱的订阅模型**：用户每月固定付费，平台先扣掉所有成本，剩下的钱按用户选择的模型价格换算成 Token 额度。

```
用户月费 $X
  → 扣 Apple 抽成 15%          = $X × 0.85
  → 扣 OpenRouter 平台费 5.5%  = × 0.945
  → 扣平台毛利 30%             = × 0.70
  → 剩余 = 可用于购买 Token 的预算
  → 按用户选的模型单价 → 换算成 Token 额度
```

**公式**：`Token 预算 = 月费 × 0.85 × 0.945 × 0.70 = 月费 × 0.5624`

> 关键点：
> - 用户自由选择任何模型，**不同模型对应不同的 Token 数量**
> - 选便宜模型 → Token 多；选贵模型 → Token 少
> - **平台永远不亏钱**，因为 Token 额度是从收入倒推出来的
> - 未用完的 Token 结转到下月（不清零）

### 5.2 套餐定价

| 套餐 | 月费 | Token 预算 | 最大 Agent 数 | Heartbeat |
|------|------|-----------|-------------|-----------|
| **Free** | $0 | $0（仅限免费模型） | 2 | 不支持 |
| **Starter** | $4.99 | $2.81 | 5 | 不支持 |
| **Pro** | $12.99 | $7.31 | 10 | 支持 |
| **Premium** | $29.99 | $16.87 | 20 | 支持 |

> Token 预算 = 月费 × 0.5624（扣除 Apple 15% + OpenRouter 5.5% + 平台毛利 30%）

### 5.3 各套餐能聊多少次？

按「单次对话 2,000 输入 + 500 输出」估算，Token 预算按模型单价换算：

**Starter $4.99/月（Token 预算 $2.81）**

| 模型 | 单次成本 | 可聊次数 | Token 额度 |
|------|---------|---------|-----------|
| DeepSeek V3.2 | $0.0007 | ~4,014 次 | ~10M tokens |
| ByteDance Seed 2.0 Mini | $0.0004 | ~7,025 次 | ~17.6M tokens |
| GPT-5.4 Mini | $0.0006 | ~4,683 次 | ~11.7M tokens |
| Mercury 2 | $0.0009 | ~3,122 次 | ~7.8M tokens |
| Free 模型 | $0 | 不限（受速率限制） | 不限 |

**Pro $12.99/月（Token 预算 $7.31）**

| 模型 | 单次成本 | 可聊次数 | Token 额度 |
|------|---------|---------|-----------|
| DeepSeek V3.2 | $0.0007 | ~10,443 次 | ~26.1M tokens |
| Kimi K2.5 | $0.0020 | ~3,655 次 | ~9.1M tokens |
| MiniMax M2.5 | $0.0012 | ~6,092 次 | ~15.2M tokens |
| Claude Haiku 4.5 | $0.0045 | ~1,624 次 | ~4.1M tokens |
| Gemini 3.1 Flash Lite | $0.0013 | ~5,623 次 | ~14.1M tokens |

**Premium $29.99/月（Token 预算 $16.87）**

| 模型 | 单次成本 | 可聊次数 | Token 额度 |
|------|---------|---------|-----------|
| Claude Opus 4.6 | $0.0225 | ~750 次 | ~1.9M tokens |
| Claude Sonnet 4.6 | $0.0135 | ~1,250 次 | ~3.1M tokens |
| GPT-5.4 | $0.0125 | ~1,350 次 | ~3.4M tokens |
| Claude Haiku 4.5 | $0.0045 | ~3,749 次 | ~9.4M tokens |
| DeepSeek V3.2 | $0.0007 | ~24,100 次 | ~60.3M tokens |

> 用户在 App 中看到的提示：「您的 Token 预算还剩 $X.XX，使用 [当前模型] 约可对话 XX 次」

### 5.4 平台收入分析

**每笔订阅的收入拆解（以 Pro $12.99 为例）**

| 去向 | 金额 | 占比 |
|------|------|------|
| Apple 抽成 | $1.95 | 15.0% |
| OpenRouter 平台费 | $0.61 | 4.7% |
| **平台毛利** | **$3.12** | **24.0%** |
| 用户 Token 预算 | $7.31 | 56.3% |
| **合计** | **$12.99** | 100% |

**各套餐平台毛利**

| 套餐 | 月费 | 平台毛利 | 说明 |
|------|------|---------|------|
| Free | $0 | $0 | 免费模型无成本，用于获客 |
| Starter | $4.99 | $1.49 | 30% × ($4.99 × 0.85 × 0.945) |
| Pro | $12.99 | $3.12 | 同上 |
| Premium | $29.99 | $7.20 | 同上 |

> **平台毛利 30% 是固定的，不受用户模型选择影响。** 无论用户选什么模型，平台都拿 30% 毛利。

### 5.5 Free 套餐说明

Free 用户只能使用 OpenRouter 上的免费模型（$0 成本）：

| 模型 | openrouter_id | 限制 |
|------|--------------|------|
| StepFun Step 3.5 Flash | `stepfun/step-3.5-flash:free` | 20 req/min, 200 req/day |
| Qwen3 Coder 480B | `qwen/qwen3-coder:free` | 20 req/min, 200 req/day |
| GLM 4.5 Air | `zhipu/glm-4.5-air:free` | 20 req/min, 200 req/day |
| Kimi K2 | `moonshotai/kimi-k2:free` | 20 req/min, 200 req/day |
| DeepSeek R1 | `deepseek/deepseek-r1:free` | 20 req/min, 200 req/day |

> Free 用户对平台零成本（OpenRouter 免费模型 + 无 Apple 抽成）。平台只需承担服务器成本。

### 5.6 App 端展示逻辑

```
┌──────────────────────────────────────────┐
│  Pro 套餐                    $12.99/月    │
│                                          │
│  Token 预算余额：$5.42                    │
│  当前模型：Claude Haiku 4.5              │
│  预计还可对话：~1,204 次                  │
│                                          │
│  [切换模型]  → 切换后重新计算可对话次数    │
│                                          │
│  下次续费：2026-04-13                     │
│  结转余额：上月 $1.23 + 本月 $7.31       │
└──────────────────────────────────────────┘
```

- 余额以**美元金额**展示（而非 Token 数），更直观
- 切换模型后，实时重新计算「预计可对话次数」
- 每月续费时：新预算 $7.31 + 上月未用余额 → 累加

---

## 六、盈亏平衡分析

### 6.1 固定成本

| 项目 | 月成本 |
|------|-------|
| VPS（Lightsail 2vCPU/4GB） | $20 |
| Apple 开发者账号 | $8.25 |
| **合计** | **$28.25/月** |

### 6.2 盈亏表

假设用户分布：60% Starter，30% Pro，10% Premium。
平台毛利率固定 30%（已扣 Apple + OpenRouter 后的 30%），不受模型选择影响：

| 付费用户数 | 月订阅收入 | 平台毛利 (30%×净收入) | 服务器 | **净利润** |
|-----------|----------|---------------------|--------|----------|
| 5 | $42 | $10.08 | $20 | **-$10.17** |
| 10 | $84 | $20.16 | $20 | **-$0.09** |
| 15 | $126 | $30.24 | $20 | **+$1.99** |
| 50 | $420 | $100.80 | $20 | **+$72.55** |
| 100 | $840 | $201.60 | $48 | **+$145.35** |
| 500 | $4,200 | $1,008 | $120 | **+$859.75** |

> 加权平均月费 = $4.99×0.6 + $12.99×0.3 + $29.99×0.1 = $8.89/用户
> 平台毛利/用户 = $8.89 × 0.85 × 0.945 × 0.30 = $2.14/用户
> **盈亏平衡点：约 14 名付费用户**（月固定成本 $28.25 ÷ $2.14 ≈ 13.2）

### 6.3 最坏情况

- 1000 个免费用户，0 个付费用户
- Free 模型 OpenRouter 成本 = $0
- 服务器 $20 + Apple $8.25 = **月亏 $28.25**（可承受）

### 6.4 为什么不可能亏钱（变动成本部分）

```
每笔订阅收入 → Apple 拿 15% → OpenRouter 拿 5.5% → 平台拿 30% → 剩下给用户买 Token
                 ↑                ↑                    ↑
               固定比例          固定比例             固定比例

用户无论选什么模型，平台的变动成本毛利率恒为 30%。
唯一的亏损风险来自固定成本（服务器+Apple 开发者账号），
只要付费用户 ≥ 14 人，固定成本即可覆盖。
```

---

## 七、需要的代码改动

| 改动项 | 说明 |
|--------|------|
| `users` 表加 `subscription_tier` | `free` / `starter` / `pro` / `premium` |
| `users` 表加 `token_budget_balance` | 当前剩余 Token 预算（美元，精确到分） |
| `users` 表加 `subscription_renew_date` | 下次续费日期 |
| 新建 `budget_transactions` 表 | 预算消耗/充值/结转流水（每次对话扣除记录） |
| 新建 `subscription_plans` 表 | 套餐定义（价格、Token 预算、最大 Agent 数等） |
| `llm_models` 表加 `openrouter_id` | OpenRouter 模型标识（如 `anthropic/claude-sonnet-4-6`） |
| `llm_models` 表加 `input_price_per_million` | 输入价格 / 1M tokens |
| `llm_models` 表加 `output_price_per_million` | 输出价格 / 1M tokens |
| 平台预置模型种子数据 | 所有 OpenRouter 模型 + 价格，用户无需自己配置 API Key |
| WebSocket 聊天流程 | 对话前检查预算余额 → 对话后按实际 token × 模型单价扣除预算 |
| 新增订阅 API | Apple IAP receipt 验证 + 套餐激活 + 预算发放 |
| 新增余额 API | `GET /subscription/balance`（余额 + 预计可聊次数） |
| 新增流水 API | `GET /subscription/transactions`（消耗明细） |
| 月度定时任务 | 每月发放新预算 + 旧预算结转 |
