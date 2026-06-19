---
quick_id: 260619-pgf
slug: skill-generation-real-glm
date: 2026-06-19
status: complete
---

# skill_generation 真实 GLM 覆盖（闭合最后一条结构化输出路径）

## 触发：nwc 侦察第5条 LLM 路径，Phase 25 覆盖扫尾

nwc（260619-nwc）侦察发现 4 个零真实覆盖路径，p7t 闭合 template_completion 后，剩
`skill_generation_service`（世界观设定生成）是最后一条零真实覆盖的结构化输出路径。

curl 探测（pgf，2/2）：GLM-4-flash 完全遵守 prompt 的 5 个 `##` 二级标题请求
（力量等级体系/门派·势力关系/世界规则/禁忌·限制/专用术语），`_parseMarkdown.pick()` 全部 5 section
正确切片（powerHierarchy 254-342 字等）。**无隐藏 bug**——prompt 对标题显式、模型遵从、contains 匹配命中。

故本任务=**纯覆盖补全**（无生产代码改动），价值：锁定当前良好行为（回归守卫）+ 完成 Phase 25
「全部结构化输出路径有 real-GLM 覆盖」里程碑（对齐 ea1/ea2/ea3 模式）。canned
`skill_generation_service_test` 喂完美 Markdown via fake adapter 证明不了 `_parseMarkdown` 对真实
输出（标题措辞可能漂移）鲁棒性——real-GLM 锁定之。

## 方案（构造注入 + 流式 accumulate + parseSkillDocument，镜像 ea3）

`SkillGenerationService` 构造注入（openAIAdapter/apiKey/baseUrl/model 直接传）→ 真实测试最简洁：
`generateSkillStream(concept).toList()` accumulate → `parseSkillDocument(name, description, rawContent)`
→ 断言 5 SkillSections（powerHierarchy/factionRelations/rules/taboos/terminology）全非空。
零生产代码改动。无 key 优雅 skip。

## 验证（证据）

- analyze 0
- 真实 GLM-4-flash GREEN：5 section 全非空（端到端：流式 adapter + _parseMarkdown 在真实输出上）
- canned skill_generation_service_test 零回归（无生产改动）
- 无 key 优雅 skip

## 教训

- Phase 25 结构化输出路径覆盖扫尾——5 条全闭合（synthesis/manuscript/opening/反AI味/editor×3/
  template×2/skill_generation）。逐条 real-GLM 验证容错最有价值（canned fake-adapter 结构性盲区）。
- 干净路径也值得覆盖锁定——回归守卫防未来 prompt/解析器改动悄悄破坏（如标题措辞漂移）。
