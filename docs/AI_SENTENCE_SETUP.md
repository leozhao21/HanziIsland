# AI 自动生成例句（V2）接入说明

要实现 PRD 中的「输入汉字 → 生成儿童友好例句」，你需要提供以下信息：

## 1. 必选：大模型 API

| 项目 | 说明 |
|------|------|
| **API Key** | OpenAI、Anthropic、或国内模型（通义、文心、智谱、DeepSeek 等） |
| **Base URL** | 官方或代理地址，例如 `https://api.openai.com/v1` |
| **Model 名称** | 例如 `gpt-4o-mini`、`claude-3-5-haiku`、`qwen-turbo` |

建议放在 **Xcode 环境变量** 或 **Keychain**，不要提交到 Git：

- `HANZI_AI_API_KEY`
- `HANZI_AI_BASE_URL`（可选）
- `HANZI_AI_MODEL`（可选）

## 2. 必选：生成规则（已在 PRD，实现时写入 Prompt）

- 例句必须包含目标汉字
- 口语化、儿童生活场景
- 不超过 20 字
- 禁止书面语（如「请你饮用一杯热茶」）

## 3. 可选但推荐

| 项目 | 用途 |
|------|------|
| **家长审核开关** | 生成后先存草稿，家长确认再写入字库 |
| **批量任务列表** | 上传 Level 3/4 缺例句的字 id，离线批量生成 |
| **缓存策略** | 同一字只生成一次，结果写入 JSON 或 SwiftData |
| **费用上限** | 每日/每用户调用次数限制 |

## 4. 你不需要提供的（可由 App 实现）

- Prompt 模板与校验（字数、是否含目标字）
- 失败重试与回退到本地模板句
- 与 `HanziCharacter.sentence` 字段的读写

## 5. 接入后的代码位置（建议）

```
Domain/Services/AISentenceGenerationService.swift   # 调用 API
Domain/Protocols/SentenceGenerating.swift         # 协议，便于 mock
Presentation/.../ParentSentenceReviewView.swift   # 家长审核（可选）
```

## 6. 最小 Prompt 示例

```
你是儿童识字助手。为汉字「{char}」（{pinyin}，{meaning}）写一句例句。
要求：包含该字；6-10岁口语；≤20字；只输出一句，不要解释。
```

---

**总结：你只要提供 API Key + 选用的模型/端点；若需要国内合规，说明使用哪家云厂商即可，我可以按该 SDK 写好 `AISentenceGenerationService`。**
