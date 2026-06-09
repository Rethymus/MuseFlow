#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const root = path.resolve(new URL('..', import.meta.url).pathname);
const outDir = path.join(root, 'docs/readme/screenshots');
const genDir = path.join(root, 'scripts/generated-readme-screenshots');
const width = 1440;
const height = 1000;

const nav = ['捕捉器', '编辑器', '知识库', '故事结构', '统计', '设置'];
const navIcons = ['✦', '✎', '▤', '◇', '↗', '⚙'];

const shots = [
  ['01-manuscript-library.png', 1, '文稿库', '管理多部作品、状态、目标字数和最近编辑进度。', ['作品|3', '目标字数|500,000', '本周更新|12,480'], [['剑道苍穹', '写作中 · 修仙 · 500,000 字目标'], ['雾海灯塔', '构思中 · 奇幻 · 世界观草稿完成'], ['雪线旧约', '精修中 · 悬疑 · 角色线待校验']]],
  ['02-capture-inbox.png', 0, '灵感捕捉', '零点击记录碎片，按故事、章节、场景标签整理。', ['碎片|18', '已选择|4', '标签|3'], [['林风在山门前听见古剑低鸣', '故事 · 2026-06-09 10:20'], ['苏雪晴用药香留下禁地线索', '角色 · 2026-06-09 10:14'], ['第八十章前揭开弃剑峰旧约', '章节 · 2026-06-09 10:08'], ['问心石阶只回应断裂剑印', '场景 · 2026-06-09 09:52']]],
  ['03-ai-organization.png', 0, 'AI 整理', '从选中的灵感碎片生成结构化草稿，作者保留最终判断。', ['输入碎片|4', '生成段落|3', '保留术语|9'], [['已选择碎片', '断裂剑印、药香线索、禁地旧约、问心石阶'], ['角色约束', '林风克制，苏雪晴不能直接说破真相'], ['世界规则', '禁地开启需要宗主令或旧剑印共鸣']]],
  ['04-chapter-editor.png', 1, '章节编辑器', '章节侧栏、正文编辑、自动保存状态和写作统计在同一工作台。', ['章节|24', '当前字数|738', '保存状态|已保存'], [['第1章 山门问心', '林风站在青冥剑宗山门前，袖中的断裂剑印忽然发烫。'], ['第2章 断印微光', '问心石上浮起一缕青光，像有人在雾里慢慢拔剑。']]],
  ['05-editor-ai-toolbar.png', 1, '编辑器 AI 工具栏', '对选中文段执行语气改写、段落润色和自由指令。', ['操作|3', '待确认|2', '上下文锚点|5'], [['语气改写', '把选中文段改成克制、悬疑的修仙叙事。'], ['段落润色', '压低 AI 味，保留作者原意和伏笔。'], ['自由指令', '让这段更悬疑，并暗示禁地旧约。']]],
  ['06-knowledge-characters.png', 2, '角色卡', '记录角色性格、外貌、别名和背景，注入写作上下文。', ['角色|12', '别名|18', '命中|6'], [['林风', '克制、敏锐，袖中藏有断裂剑印。'], ['苏雪晴', '白衣药师，知道禁地旧约却不能明说。'], ['清虚真人', '弃剑峰长老，问心石阶的守门人。']]],
  ['07-knowledge-world.png', 2, '世界观', '维护宗门、地理、规则、禁忌和技术层级。', ['设定|8', '势力|4', '规则|16'], [['青冥剑宗', '三峰一谷，禁地位于雾海裂隙下方。'], ['戒律堂', '掌管门规与禁地通行令。'], ['弃剑峰', '旧案发生地，清虚真人闭关之处。']]],
  ['08-template-gallery.png', 2, '模板库', '从类型模板生成世界观、角色和章节草稿。', ['模板|9', '草稿|2', '类型|修仙'], [['男频修仙宗门', '境界体系、宗门势力、禁地旧约。'], ['都市异能', '组织冲突、能力代价、调查线。'], ['古风权谋', '朝堂关系、家族盟约、暗线伏笔。']]],
  ['09-skill-rules.png', 2, 'Skill 规则', '启用力量等级、世界禁忌和术语规则，约束 AI 输出。', ['规则|4', '启用|3', '违规提醒|1'], [['境界体系约束', '炼气、筑基、金丹、元婴必须逐级推进。'], ['世界观禁忌', '禁地开启需要宗主令或旧剑印共鸣。'], ['术语统一', '青冥剑宗、问心石、弃剑峰固定写法。']]],
  ['10-foreshadowing.png', 3, '伏笔管理', '埋设、发展、解决每条线索，避免长篇遗忘。', ['伏笔|11', '进行中|7', '已解决|4'], [['断裂剑印', '第1章埋设 · 计划第80章解决 · 关联弃剑峰旧案'], ['苏雪晴的药香', '第5章埋设 · 第42章解决 · 指向禁地入口'], ['问心石阶', '第1章埋设 · 正在发展 · 与主角血脉相关']]],
  ['11-plot-timeline.png', 3, '剧情线', '按章节排列情节点，跟踪草稿、初稿、精修和定稿状态。', ['情节点|18', '草稿|6', '完成|8'], [['第1章 山门问心', '设定 · 林风通过问心石阶'], ['第42章 禁地旧约', '转折 · 苏雪晴暗示入口'], ['第80章 弃剑峰真相', '高潮 · 断裂剑印完整共鸣']]],
  ['12-story-arc.png', 3, '故事弧图', '用结构角色查看铺垫、发展、转折、高潮和解决。', ['铺垫|5', '转折|4', '高潮|2'], [['铺垫', '山门问心、断印微光、药圃旧图'], ['发展', '外门试剑、戒律堂追问、雾海裂隙'], ['高潮', '弃剑峰真相、禁地旧约兑现']]],
  ['13-logic-guardian.png', 3, '逻辑守护', '检查角色、设定、伏笔和剧情因果的一致性。', ['检查项|24', '风险|3', '已确认|21'], [['境界跳跃风险', '第42章输出提到金丹，但林风仍在筑基。'], ['伏笔遗漏', '断裂剑印超过默认阈值，需要推进或提醒。'], ['角色一致', '苏雪晴仍遵守不能直说禁地真相的约束。']]],
  ['14-export-cleanup.png', 3, '整理与导出', '清理 Markdown 残留，导出 Markdown、TXT 和 JSON。', ['章节|100', '清理项|8', '格式|3'], [['Markdown', '保留章节标题，适合继续排版。'], ['TXT', '移除格式符号，适合平台粘贴。'], ['JSON', '包含章节结构，适合备份和迁移。']]],
  ['15-writing-stats.png', 4, '写作统计', '查看每日字数、速度趋势、AI 辅助比例和成就。', ['总字数|126,480', '写作天数|18', 'AI 辅助|22.4%'], [['每日字数', '最近七日稳定在 4,000 - 8,000 字。'], ['速度趋势', '夜间写作速度提升，精修阶段下降。'], ['AI 使用比例', '主要用于整理碎片和段落润色。']]],
  ['16-token-audit.png', 4, 'Token 审计', '按操作、章节和时间追踪 AI 调用成本。', ['输入 Token|62,400', '输出 Token|31,200', 'API 调用|128'], [['碎片整理', '36 次 · 42,000 Token · fake-model'], ['段落润色', '58 次 · 31,600 Token · fake-model'], ['逻辑守护', '34 次 · 20,000 Token · fake-model']]],
  ['17-reports-hub.png', 4, '分析报告', '百章创作验证的四维分析入口。', ['报告|4', '问题|12', '建议|9'], [['Token 成本分析', '万字短篇成本与 50 万字长篇推算。'], ['用户痛点报告', '功能缺陷、体验摩擦、缺失需求。'], ['一致性分析', '角色卡和设定集与正文对比。']]],
  ['18-report-details.png', 4, '报告详情', '查看 Token 成本、盲读结果、痛点和一致性明细。', ['预估 Token|4.68M', '预估调用|450', '优化建议|2'], [['50万字长篇推算', '按当前万字样本推算，区间为 40x - 60x。'], ['优化建议', '批量操作减少调用；缩短知识库注入上下文。'], ['导出动作', '报告可导出为 Markdown 供版本归档。']]],
  ['19-settings.png', 5, '设置', '管理 AI、存储、本地数据和应用信息。', ['版本|0.1.1', '存储|本地', '统计清理|安全'], [['AI 模型', '配置和管理 AI 模型提供商。'], ['AI 用语过滤', '自定义需要过滤的 AI 味词组。'], ['清除写作统计', '不影响正文、文稿和知识库。']]],
  ['20-ai-providers.png', 5, 'AI 模型管理', '管理 OpenAI 兼容、Claude、Ollama 等模型配置。', ['预设模型|6', '当前模型|fake-model', '密钥状态|安全存储'], [['OpenAI', 'https://api.openai.com/v1'], ['DeepSeek', 'OpenAI 兼容接口'], ['Ollama', '本地模型服务']]],
  ['21-banned-phrases.png', 5, 'AI 用语过滤', '维护禁用词组，降低低质 AI 文风痕迹。', ['默认词组|12', '自定义|4', '命中高亮|8'], [['值得注意的是', '常见说明文套话，建议删除或重写。'], ['总而言之', '总结痕迹明显，需改为剧情动作。'], ['需要指出的是', '弱化叙事现场感，默认过滤。']]],
];

function escapeXml(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;' }[char]));
}

function text(x, y, value, size = 20, weight = 400, fill = '#e6e1eb') {
  return `<text x="${x}" y="${y}" font-size="${size}" font-weight="${weight}" fill="${fill}">${escapeXml(value)}</text>`;
}

function rect(x, y, w, h, fill, stroke = '#353541', rx = 8) {
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}" fill="${fill}" stroke="${stroke}"/>`;
}

function svg([file, navIndex, title, subtitle, metrics, rows]) {
  const parts = [
    `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`,
    `<style>text{font-family:'Noto Sans CJK SC','Noto Sans CJK','DejaVu Sans',sans-serif}.muted{fill:#c9c3d0}</style>`,
    rect(0, 0, width, height, '#111218', 'none', 0),
    rect(0, 0, 236, height, '#181922', 'none', 0),
    text(22, 42, '灵韵 MuseFlow', 23, 800),
  ];

  for (let i = 0; i < nav.length; i++) {
    const y = 78 + i * 58;
    if (i === navIndex) parts.push(rect(18, y - 28, 200, 44, '#334073', '#334073', 8));
    parts.push(text(30, y, navIcons[i], 22, 700, i === navIndex ? '#ffffff' : '#c9c3d0'));
    parts.push(text(66, y, nav[i], 18, i === navIndex ? 700 : 400, i === navIndex ? '#ffffff' : '#c9c3d0'));
  }
  parts.push(rect(18, 906, 200, 70, '#181922', '#4b4858', 8), text(34, 936, '本地优先', 16, 700), text(34, 962, '未连接云同步', 14, 400, '#c9c3d0'));

  parts.push(text(268, 58, title, 34, 850), text(268, 92, subtitle, 18, 400, '#c9c3d0'));
  parts.push(rect(1130, 34, 128, 42, '#c0c4ff', '#c0c4ff', 21), text(1155, 61, '执行', 16, 700, '#24284b'));
  parts.push(rect(1274, 34, 112, 42, '#111218', '#8f8ba0', 21), text(1304, 61, '筛选', 16, 700));

  metrics.forEach((metric, index) => {
    const [label, value] = metric.split('|');
    const x = 268 + index * 370;
    parts.push(rect(x, 122, 350, 94, '#1d1e27', '#353541', 8));
    parts.push(text(x + 24, 157, label, 17, 400, '#c9c3d0'));
    parts.push(text(x + 24, 194, value, 28, 850));
  });

  const startY = 254;
  if (file === '04-chapter-editor.png') {
    parts.push(rect(268, startY, 300, 692, '#1d1e27'), rect(588, startY, 798, 692, '#1d1e27'));
    rows.forEach((row, i) => {
      parts.push(rect(288, startY + 24 + i * 82, 260, 62, i === 0 ? '#313246' : '#242530', '#3b3b48', 8));
      parts.push(text(308, startY + 62 + i * 82, row[0], 18, 700));
    });
    parts.push(text(642, 330, '林风站在青冥剑宗山门前，袖中的断裂剑印忽然发烫。', 24, 500));
    parts.push(text(642, 388, '问心石上浮起一缕青光，像有人在雾里慢慢拔剑。', 24, 500));
    parts.push(text(642, 446, '清虚真人没有让他跪下，只问：你想要力量，还是想要答案？', 24, 500));
    parts.push(text(624, 918, '总字数：738 / 500,000 字', 16, 400, '#c9c3d0'));
  } else {
    rows.forEach((row, i) => {
      const y = startY + i * 122;
      parts.push(rect(268, y, 1118, 96, '#1d1e27'));
      parts.push(text(296, y + 38, row[0], 22, 800));
      parts.push(text(296, y + 70, row[1], 17, 400, '#c9c3d0'));
      parts.push(text(1350, y + 58, '›', 30, 700, '#9a94a5'));
    });
    parts.push(rect(268, 680, 350, 180, '#1d1e27'), rect(650, 680, 350, 180, '#1d1e27'), rect(1032, 680, 354, 180, '#1d1e27'));
    parts.push(text(298, 742, '离线演示', 24, 800), text(680, 742, 'FakeAdapter', 24, 800), text(1062, 742, '安全存储未展示', 24, 800));
    parts.push(text(298, 786, '截图由可复现脚本生成', 17, 400, '#c9c3d0'), text(680, 786, '不访问真实 API 密钥', 17, 400, '#c9c3d0'), text(1062, 786, '生产安全策略不变', 17, 400, '#c9c3d0'));
  }
  parts.push('</svg>');
  return parts.join('\n');
}

await fs.mkdir(outDir, { recursive: true });
await fs.mkdir(genDir, { recursive: true });
for (const entry of await fs.readdir(outDir)) {
  if (entry.endsWith('.png')) await fs.unlink(path.join(outDir, entry));
}

for (const shot of shots) {
  const svgPath = path.join(genDir, shot[0].replace('.png', '.svg'));
  const pngPath = path.join(outDir, shot[0]);
  await fs.writeFile(svgPath, svg(shot));
  execFileSync('magick', [svgPath, pngPath], { stdio: 'inherit' });
  const stat = await fs.stat(pngPath);
  if (stat.size < 20000) throw new Error(`${shot[0]} is unexpectedly small (${stat.size} bytes)`);
}

console.log(`Generated ${shots.length} README screenshots in ${outDir}`);
