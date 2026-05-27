# 识字岛 HanziIsland

面向 4–10 岁儿童的汉字学习 iOS App，基于 PRD v1.0 实现 MVP。

## 技术栈

- Swift 6
- SwiftUI
- SwiftData
- MVVM + Clean Architecture（Presentation / Domain / Data）

## 已实现功能（v1.0 MVP）

| PRD 模块 | 状态 |
|---------|------|
| 汉字基础信息 + 生活化例句 | ✅ JSON 字库 |
| 熟练度 6 级 + 答对+1/答错-2 | ✅ `MasteryLevel` |
| 间隔复习 1/3/7/15/30 天 | ✅ `SpacedRepetitionService` |
| 每日任务（新字/复习/随机检查） | ✅ 三种家长模式 |
| 四类检测题 | ✅ 认字/拼音/例句/看图 |
| 题库回流（重点复习库） | ✅ `inIntensiveReview` + 遗忘率排序 |
| 掌握字数徽章 | ✅ |
| 成长岛星星解锁 | ✅ |
| 家长中心统计 | ✅ |
| Level 1–4 字库 | ✅ 100 / 300 / 500 / 1000 字 |
| 每日学习趋势持久化 | ✅ SwiftData 14 日图表 |
| AI 自动生成例句 | 🔜 V2（见 `docs/AI_SENTENCE_SETUP.md`） |

## 打开项目

```bash
open /Users/zhaolei/Projects/HanziIsland/HanziIsland.xcodeproj
```

在 Xcode 中选择你的 **Development Team**（Signing & Capabilities），然后运行到模拟器或真机。

## 项目结构

```
HanziIsland/
├── Domain/           # 业务模型、服务、用例
├── Data/             # SwiftData 实体与仓库
├── Presentation/     # SwiftUI Views + ViewModels
└── Resources/        # characters_level1.json … level4.json
```

字库重新生成：

```bash
pip3 install pypinyin
python3 Scripts/generate_character_catalog.py
```

## 后续扩展

1. 人工润色 Level 2–4 例句（可在 `Scripts/generate_character_catalog.py` 的 `CUSTOM_SENTENCES` 中补充）
2. 接入真实笔画动画、配音、插图资源
3. V2：AI 例句生成服务（见 `docs/AI_SENTENCE_SETUP.md`）
4. Widget / 家长端推送周报
# HanziIsland
