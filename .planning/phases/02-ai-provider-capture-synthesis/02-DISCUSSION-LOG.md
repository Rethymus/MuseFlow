# Phase 2: AI Provider + Capture Synthesis - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 2-AI Provider + Capture Synthesis
**Areas discussed:** Provider 配置体验, 碎片合成交互流程, 反AI味策略, Token 预算与错误处理

---

## Provider 配置体验

### Provider 管理界面位置

| Option | Description | Selected |
|--------|-------------|----------|
| 设置页内子页 | 在现有设置页内加"AI 模型"子页，左侧已添加 Provider 列表，右侧配置表单 | ✓ |
| 侧边栏独立页 | 侧边栏加"AI 模型"导航项，独立页面 | |
| 卡片列表式 | 设置页内卡片列表，点击展开编辑，类似 Wi-Fi 列表 | |

**User's choice:** 设置页内子页
**Notes:** 与窗口设置等并列，统一体验。侧边栏不宜过早膨胀。

### 预设 Provider 呈现

| Option | Description | Selected |
|--------|-------------|----------|
| 预设卡片 + 自定义入口 | 显示 OpenAI/DeepSeek/Ollama 三张预设卡片，点击只填 API Key。另有"自定义"卡片。 | ✓ |
| 下拉菜单 + 手填 | 下拉选择预设（自动填 Base URL），然后填 Key。紧凑但不直观。 | |
| 纯手填表单 | 空白表单，文档里写明各家 Base URL。灵活但门槛高。 | |

**User's choice:** 预设卡片 + 自定义入口
**Notes:** 一键配置是 ROADMAP 要求。Ollama 预设不需要 API Key。

### API Key 输入体验

| Option | Description | Selected |
|--------|-------------|----------|
| 隐藏输入 + 测试连接 | 密码框（默认隐藏）+ 眼睛图标 + "测试连接"按钮 | ✓ |
| 纯密码框 | 保存后使用时才知道对不对 | |
| 密码框 + 自动验证 | 保存后自动发测试请求，显示绿勾/红叉 | |

**User's choice:** 隐藏输入 + 测试连接
**Notes:** 用户主动测试，不消耗意外 token。

### 多 Provider 选择方式

| Option | Description | Selected |
|--------|-------------|----------|
| 单选切换 | 同一时间一个 Provider 生效 | |
| 按场景分配 | 不同场景用不同 Provider | |

**User's choice:** 结合两者 — 默认简单单选切换 + 设置里"高阶模式"开关解锁按场景分配
**Notes:** 渐进式暴露复杂度。新手看简单界面，高阶用户解锁全功能。

---

## 碎片合成交互流程

### 合成结果显示位置

| Option | Description | Selected |
|--------|-------------|----------|
| 捕捉器内滑出面板 | 右侧滑出面板显示流式文本，面板内可编辑，不离开捕捉器 | ✓ |
| 独立合成页面 | 跳转到独立页面，大屏编辑空间但流程割裂 | |
| 居中对话框 | 弹出居中对话框，紧凑但编辑空间有限 | |

**User's choice:** 捕捉器内滑出面板
**Notes:** 保持创作连贯性，不跳转页面。

### 合成结果迭代方式

| Option | Description | Selected |
|--------|-------------|----------|
| 可重新生成 | "重新生成"按钮，用同样碎片重新调用 AI | |
| 一次性生成 | 只能编辑当前结果 | |
| 对话式迭代 | 追加指令在上一结果基础上迭代 | |

**User's choice:** 结合可重新生成与对话式迭代
**Notes:** 重新生成 + 可选追加指令文本框。空字段 = 纯重试，有内容 = 迭代指令。

### 重新生成 + 追加指令 UI

| Option | Description | Selected |
|--------|-------------|----------|
| 重新生成 + 可选追加指令 | 面板底部"重新生成"按钮 + 小文本框（可留空） | ✓ |
| 两个独立按钮 | "重新生成"和"追加指令"两个按钮，后者展开输入框 | |

**User's choice:** 重新生成 + 可选追加指令
**Notes:** 一个按钮两个用途，简洁。

### 合成文本送入编辑器方式

| Option | Description | Selected |
|--------|-------------|----------|
| 插入编辑器光标处 | 切换到编辑器，文本插入光标位置 | ✓ |
| 追加到文档末尾 | 文本自动追加到当前文档末尾 | |

**User's choice:** 插入编辑器光标处
**Notes:** 用户看到完整编辑器环境继续打磨。

---

## 反AI味策略

### Prompt 层与后处理层分工

| Option | Description | Selected |
|--------|-------------|----------|
| 纯 Prompt 指令 | system prompt 里指示避开 AI 风格 | |
| Prompt + 后处理双层 | Prompt 指令 + 后处理扫描器，双层防线 | ✓ |
| 纯后处理替换 | 不用 Prompt 指令，纯靠后处理 | |

**User's choice:** Prompt + 后处理双层
**Notes:** REQUIREMENTS AI-05 + AI-06 都要实现。

### 禁用词列表管理

| Option | Description | Selected |
|--------|-------------|----------|
| 内置列表 + 用户可编辑 | 硬编码初始列表，设置里可增删 | ✓ |
| 纯内置列表 | 用户不能改 | |
| 用户自建列表 | 从空白开始，灵活但新手困难 | |

**User's choice:** 内置列表 + 用户可编辑
**Notes:** 不同用户对 AI 味敏感度不同。

### 检测到 AI 痕迹后的处理方式

| Option | Description | Selected |
|--------|-------------|----------|
| 自动替换 | 同义词/近义词替换，全自动 | |
| 高亮提示用户改 | 高亮显示让用户决定 | |
| 混合模式 | 简单词自动替换，复杂结构高亮提示 | ✓ |

**User's choice:** 混合模式
**Notes:** 不过度自动化，不过度打断。简单词静默修复，复杂句式交给用户。

### Prompt 层注入策略

| Option | Description | Selected |
|--------|-------------|----------|
| 人设注入 | 给模型一个小说作者人设 | |
| 负面清单 | 直接列出禁止词汇/句式 | |
| 人设 + 清单结合 | 人设定调子，清单兜底 | ✓ |

**User's choice:** 人设 + 清单结合
**Notes:** 最全面但 Prompt 较长。反 AI 味是产品灵魂，值得多消耗 token。

---

## Token 预算与错误处理

### Token 预算管理

| Option | Description | Selected |
|--------|-------------|----------|
| 自动计算 + 透明截断 | 根据模型窗口自动计算，超出时截断并提示 | ✓ |
| 显示 token 预算让用户决定 | 显示剩余数，用户自己选碎片 | |
| 静默处理 | 后台默默截断 | |

**User's choice:** 自动计算 + 透明截断
**Notes:** 用户无需理解 token 概念。

### 碎片超出预算时的截断策略

| Option | Description | Selected |
|--------|-------------|----------|
| 移除最后选的碎片 | LIFO 移除，保留最早选的 | ✓ |
| 提示用户减少碎片 | 弹窗让用户自己取消勾选 | |
| 截断每个碎片内容 | 保留所有碎片但每个截断前 N 字 | |

**User's choice:** 移除最后选的碎片
**Notes:** 显示"已移除 N 个碎片以保证质量"。

### 错误提示方式

| Option | Description | Selected |
|--------|-------------|----------|
| 面板内友好提示 + 重试 | 合成面板内直接显示错误信息 + 重试按钮 | ✓ |
| SnackBar + 详情 | SnackBar 提示，点"查看详情"看原因 | |
| 错误对话框 | 弹出对话框显示详情 | |

**User's choice:** 面板内友好提示 + 重试
**Notes:** 不弹窗不打断，直接在面板内处理。

### 流式显示策略

| Option | Description | Selected |
|--------|-------------|----------|
| 实时流式 + 断流保护 | token 实时显示（打字机效果），断流保留已接收内容 | ✓ |
| 等待完毕后一次显示 | 完全生成后一次显示 | |

**User's choice:** 实时流式 + 断流保护
**Notes:** Phase 0 已验证 SSE 流式可行。断流时显示"生成中断，可继续编辑或重试"。

---

## Claude's Discretion

- Synthesis prompt template structure
- Banned phrase seed list content
- Auto-replacement synonym mappings
- Token counting for Chinese text
- PromptPipeline middleware interface
- Synthesis panel animation and dimensions
- Provider entity data model and Hive schema
- 高阶模式 toggle placement
- Complex pattern detection rules

## Deferred Ideas

None — all discussion stayed within Phase 2 scope.
