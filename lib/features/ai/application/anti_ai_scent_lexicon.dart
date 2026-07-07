part of 'anti_ai_scent_processor.dart';

/// Synonym maps, cliche lists, and structural regex patterns for
/// [AntiAIScentProcessor].
///
/// Extracted from the main processor file to satisfy the
/// 03-flutter-standards.md file-size cap. All symbols are library-private
/// top-level constants; the processor class accesses them via bare names.

/// Fixed synonym map for auto-replacement per D-09.
/// Empty string values mean "delete the phrase".
/// Organized by category for maintainability.
/// Target: 200+ entries across 20 categories.
const Map<String, String> _synonymMap = {
  // ═══════════════════════════════════════════════════════════════
  // 一、过渡连接词 (Essay-style transitions — rare in fiction)
  // ═══════════════════════════════════════════════════════════════
  '然而': '但是',
  '与此同时': '',
  '事实上': '',
  '实际上': '',
  '具体来说': '',
  '换句话说': '',
  '进一步来说': '',
  '更重要的是': '',
  '话虽如此': '',
  '尽管如此': '',
  '不仅如此': '',
  '此外': '',
  '换言之': '',
  '更为重要的是': '',
  '在此期间': '',
  '在此之前': '',
  '从此以后': '',
  '自那以后': '',

  // ═══════════════════════════════════════════════════════════════
  // 二、总结归纳词 (Conclusion phrases — essay-style, not fiction)
  // ═══════════════════════════════════════════════════════════════
  '综上所述': '',
  '总而言之': '',
  '总的来说': '',
  '总之': '',
  '简而言之': '',
  '概而言之': '',
  '由此可见': '',
  '一言以蔽之': '',
  '由此看来': '',
  '事实证明': '',
  '由此可知': '',
  '足以证明': '',
  '由此表明': '',

  // ═══════════════════════════════════════════════════════════════
  // 三、强调判断词 (Emphasis/judgment — AI loves these in fiction)
  // ═══════════════════════════════════════════════════════════════
  '值得注意的是': '',
  '需要指出的是': '',
  '毫无疑问': '',
  '不可否认': '',
  '不言而喻': '',
  '显而易见': '',
  '众所周知': '',
  '毋庸置疑': '',
  '不容忽视': '',
  '至关重要': '',
  '从某种意义上说': '',
  '值得一提': '',
  '尤为突出': '',
  '尤为重要': '',
  '的确如此': '',
  '无可厚非': '',
  '不言自明': '',
  '不可小觑': '',
  '不得不说': '',
  '尤其': '',

  // ═══════════════════════════════════════════════════════════════
  // 四、序数枚举词 (Enumerative — AI enumerates where fiction flows)
  // Note: 第一/第二/第三 removed — they're too aggressive as standalone
  // replacements (e.g., "第二次" → "次"). First/其次/Last catch enumeration.
  '首先': '',
  '其次': '',
  '最后': '',
  '一方面': '',
  '另一方面': '',

  // ═══════════════════════════════════════════════════════════════
  // 五、因果解释词 (Causal explanation — AI over-explains cause)
  // ═══════════════════════════════════════════════════════════════
  '正因如此': '',
  '之所以如此': '',
  '究其原因': '',
  '归根结底': '',
  '追根溯源': '',
  '溯其根源': '',
  '正因为如此': '',
  '正因这般': '',
  '原因很简单': '',
  '其根本原因': '',
  '这其中的原因': '',

  // ═══════════════════════════════════════════════════════════════
  // 六、叙述框架词 (Narrative framework — AI starts with meta)
  // ═══════════════════════════════════════════════════════════════
  '人们常说': '',
  '俗话说': '',
  '古人云': '',
  '常言道': '',
  '有句话说的好': '',
  '正所谓': '',
  '故事要从': '',
  '事情要追溯到': '',
  '事情是这样的': '',
  '情况是这样的': '',
  '原来如此': '',
  '经过一番': '',
  '在一番': '',

  // ═══════════════════════════════════════════════════════════════
  // 七、情感表达套话 (Emotional cliches — AI tells instead of shows)
  // ═══════════════════════════════════════════════════════════════
  '心中涌起一股暖流': '',
  '眼眶微微湿润': '',
  '鼻子一酸': '',
  '暖流涌遍全身': '',
  '百感交集': '',
  '五味杂陈': '',
  '心如刀绞': '',
  '泪流满面': '',
  '一股暖意涌上心头': '',
  '不禁潸然泪下': '',
  '心中五味杂陈': '',
  '一阵酸楚涌上心头': '',
  '眼眶微红': '',
  '心如刀割': '',
  '肝肠寸断': '',
  '心潮澎湃': '',
  '怒火中烧': '',
  '心中一紧': '',
  '心中一颤': '',
  '不由得心头一紧': '',

  // ═══════════════════════════════════════════════════════════════
  // 八、人物描写套话 (Character description — formulaic portraits)
  // ═══════════════════════════════════════════════════════════════
  '眼中闪过一丝': '',
  '嘴角微微上扬': '',
  '眉头微皱': '',
  '眼神中透着': '',
  '目光中带着': '',
  '脸上露出': '',
  '神情自若': '',
  '面色如常': '',
  '面不改色': '',
  '不紧不慢': '',
  '从容不迫': '',
  '波澜不惊': '',
  '气宇轩昂': '',
  '英姿飒爽': '',
  '目光如炬': '',
  '目光深邃': '',
  '嘴角勾起一抹': '',
  '眼中闪过一抹': '',
  '面色微变': '',

  // ═══════════════════════════════════════════════════════════════
  // 九、动作描写套话 (Action cliches — repetitive physical actions)
  // ═══════════════════════════════════════════════════════════════
  '缓缓说道': '',
  '淡淡地说': '',
  '微微一笑': '',
  '紧紧握住': '',
  '默默注视': '',
  '悄然离开': '',
  '倒吸一口凉气': '',
  '不由自主地': '',
  '下意识地': '',
  '情不自禁地': '',
  '鬼使神差地': '',
  '毫不犹豫地': '',
  '缓缓点头': '',
  '轻轻摇头': '',
  '长叹一声': '',
  '深吸一口气': '',

  // ═══════════════════════════════════════════════════════════════
  // 十、心理活动套话 (Inner thought cliches — formulaic narration)
  // ═══════════════════════════════════════════════════════════════
  '心中暗想': '',
  '心中想着': '',
  '心里清楚': '',
  '顿时明白了': '',
  '恍然大悟': '',
  '心下暗忖': '',
  '暗自思忖': '',
  '心中了然': '',
  '心知肚明': '',
  '若有所思': '',
  '陷入沉思': '',
  '百思不得其解': '',
  '心念一动': '',
  '灵光一闪': '',
  '心中暗自': '',

  // ═══════════════════════════════════════════════════════════════
  // 十一、结尾悬念套话 (Ending hook cliches — formulaic chapter ends)
  // ═══════════════════════════════════════════════════════════════
  '一场更大的风暴': '',
  '真正的考验': '',
  '才刚刚开始': '',
  '等待着他': '',
  '命运的齿轮': '',
  '更大的挑战': '',
  '一切才刚刚开始': '',
  '真正的战斗': '',
  '命运的转折': '',
  '故事才刚刚开始': '',
  '一场暴风雨即将来临': '',
  '暗流涌动': '',

  // ═══════════════════════════════════════════════════════════════
  // 十二、比喻/修辞套话 (Metaphor/rhetoric — AI defaults to these)
  // ═══════════════════════════════════════════════════════════════
  '宛如仙境': '',
  '美不胜收': '',
  '如诗如画': '',
  '美轮美奂': '',
  '心旷神怡': '',
  '沁人心脾': '',
  '引人入胜': '',
  '叹为观止': '',
  '仿佛置身于': '',
  '宛若天成': '',
  '犹如一把利剑': '',
  '如同黑夜中的明灯': '',
  '宛如烈火': '',
  '好似潮水': '',

  // ═══════════════════════════════════════════════════════════════
  // 十三、修仙/玄幻类型套话 (Xianxia/fantasy genre cliches)
  // ═══════════════════════════════════════════════════════════════
  '灵气涌动': '',
  '磅礴的力量': '',
  '周身气息': '',
  '体内灵力': '',
  '剑气纵横': '',
  '灵力波动': '',
  '灵光闪烁': '',
  '道韵流转': '',
  '法力涌动': '',
  '灵气四溢': '',
  '威压逼人': '',
  '气势如虹': '',

  // ═══════════════════════════════════════════════════════════════
  // 十四、对话标签套话 (Dialogue tag cliches — repetitive attribution)
  // ═══════════════════════════════════════════════════════════════
  '沉声说道': '',
  '冷冷地说': '',
  '厉声喝道': '',
  '温柔地说道': '',
  '低声说道': '',
  '高声说道': '',
  '轻声说道': '',
  '沉声道': '',
  '冷冷道': '',
  '淡淡道': '',

  // ═══════════════════════════════════════════════════════════════
  // 十五、环境氛围套话 (Atmospheric cliches — formulaic scenery)
  // ═══════════════════════════════════════════════════════════════
  '夜色如水': '',
  '月华如练': '',
  '繁星点点': '',
  '万籁俱寂': '',
  '一片寂静': '',
  '鸦雀无声': '',
  '空气凝固': '',
  '气氛凝重': '',
  '气氛紧张': '',
  '寂静无声': '',

  // ═══════════════════════════════════════════════════════════════
  // 十六、时间转场套话 (Temporal transition — AI paragraph starters)
  // ═══════════════════════════════════════════════════════════════
  '就在这时': '',
  '就在此时': '',
  '就在那一刻': '',
  '刹那间': '',
  '顷刻间': '',
  '转瞬之间': '',
  '弹指之间': '',
  '须臾之间': '',
  '瞬息之间': '',
  '片刻之后': '',
  '过了片刻': '',
  '良久之后': '',

  // ═══════════════════════════════════════════════════════════════
  // 十七、评价性套话 (Evaluative cliches — AI judges for the reader)
  // ═══════════════════════════════════════════════════════════════
  '令人惊叹': '',
  '让人感动': '',
  '不禁感慨': '',
  '令人欣慰': '',
  '引人深思': '',
  '令人震撼': '',
  '让人心酸': '',
  '让人窒息': '',
  '令人叹服': '',
  '让人肃然起敬': '',
  '令人窒息': '',
  '令人心悸': '',

  // ═══════════════════════════════════════════════════════════════
  // 十八、节奏填充词 (Pacing fillers — AI pads rhythm uniformly)
  // ═══════════════════════════════════════════════════════════════
  '不知不觉间': '',
  '在不知不觉中': '',
  '不知不觉地': '',
  '悄无声息地': '',
  '毫无征兆地': '',
  '毫无预兆地': '',
  '缓缓地': '',
  '徐徐地': '',

  // ═══════════════════════════════════════════════════════════════
  // 十九、叙事总结套话 (Narrative summary — AI summarizes instead of shows)
  // ═══════════════════════════════════════════════════════════════
  '事情的发展': '',
  '这一切的一切': '',
  '这才是真正的': '',
  '这便是': '',
  '一切都发生了变化': '',

  // ═══════════════════════════════════════════════════════════════
  // 二十、强度修饰词 (Intensity modifiers — AI amplifies everything)
  // ═══════════════════════════════════════════════════════════════
  '极其': '',
  '异常': '',
  '万分': '',
  '无比': '',
  '极为': '',
  '尤为': '',
  '十分': '',
  '格外': '',
  '甚为': '',
  '着实': '',
};

/// Phrases that appear in the AI prompt's banned list but are NOT
/// auto-replaced in post-processing. Instead, they are wrapped with
/// 【】 markers for the author to review and decide.
///
/// These are common Chinese literary words that have high false-positive
/// risk — perfectly legitimate in classic fiction but overused by AI.
/// By highlighting instead of replacing, we preserve the author's ability
/// to accept or reject each usage in context.
///
/// Categories moved to highlight-only:
/// - Common transitions: 然而, 事实上, 实际上, 此外
/// - Emphasis/judgment words: 毫无疑问, 不可否认, 不言而喻, etc.
/// - Enumeration markers: 首先, 其次, 最后 (break prose if deleted)
/// - Literary time expressions: 刹那间, 顷刻间, etc. (valid in fiction)
/// - Common intensifiers: 极其, 异常, 十分, etc. (too common to delete)
/// - Pacing fillers: 不知不觉间, etc. (natural in fiction)
const Set<String> _highlightOnlyPhrases = {
  // Common literary transitions
  '然而', '事实上', '实际上', '此外',
  // Emphasis/judgment words used in narrator voice
  '毫无疑问', '不可否认', '不言而喻', '众所周知', '毋庸置疑',
  '不容忽视', '无可厚非', '不言自明', '不可小觑', '尤其',
  // Enumeration markers (deleting breaks prose structure)
  '首先', '其次', '最后', '一方面', '另一方面',
  // Literary time expressions (valid in wuxia/xianxia)
  '刹那间', '顷刻间', '转瞬之间', '弹指之间', '须臾之间',
  '瞬息之间', '片刻之后', '过了片刻', '良久之后',
  // Pacing fillers (natural in fiction)
  '不知不觉间', '在不知不觉中', '不知不觉地',
  // Common intensifiers (too ubiquitous to auto-delete)
  '极其', '异常', '万分', '无比', '极为', '尤为',
  '十分', '格外', '甚为', '着实',
};

/// Structural pattern regexes per D-10.
/// These are highlighted with 【】 markers, not auto-replaced.
/// Organized by pattern type for maintainability.
final List<RegExp> _structuralPatterns = [
  // --- 并列/递进结构 (Parallel/progressive) ---
  RegExp(r'不仅[^，。！？\n]{1,20}而且'),
  RegExp(r'不仅[^，。！？\n]{1,20}还'),
  RegExp(r'既[^，。！？\n]{1,12}又[^，。！？\n]{1,12}'),

  // --- 条件/让步结构 (Conditional/concessive) ---
  RegExp(r'无论[^，。！？\n]{1,20}，?[^。！？\n]{1,20}都'),
  RegExp(r'与其说[^，。！？\n]{2,15}，?不如说'),

  // --- 因果/推理结构 (Causal/reasoning) ---
  RegExp(r'随着[^，。！？\n]{1,20}的发展'),
  RegExp(r'在[^，。！？\n]{1,20}中，[^，。！？\n]{1,20}发挥了重要作用'),
  RegExp(r'因为[^，。！？\n]{2,25}，所以[^，。！？\n]{2,25}'),

  // --- 描写/比喻结构 (Description/metaphor) ---
  RegExp(r'仿佛[^，。！？\n]{2,20}一般'),
  RegExp(r'在[^，。！？\n]{2,12}的映衬下'),

  // --- 叙述/评价结构 (Narrative/evaluative) ---
  RegExp(r'让人不禁[^，。！？\n]{2,15}'),
  RegExp(r'正是[^，。！？\n]{2,20}使得[^，。！？\n]{2,20}'),
];

const List<String> _transitionCliches = [
  '与此同时',
  '就在这时',
  '不料',
  '忽然',
  '突然',
  '下一刻',
  '片刻之后',
];

const List<String> _xianxiaCliches = [
  '灵气涌动',
  '磅礴的力量',
  '眼中闪过一丝',
  '不由得',
  '倒吸一口凉气',
  '周身气息',
  '体内灵力',
  '剑气纵横',
];

/// Wuxia (武侠) genre cliches — martial-arts / jianghu vocabulary that AI
/// overuses in wuxia fiction (AA-05). Sibling to [_xianxiaCliches]; the
/// product supports 修仙/武侠/都市/科幻/玄幻 preset packs
/// (`.planning/PROJECT.md`), so
/// genre-cliche feedback should not be xianxia-only.
///
/// Phrases pick the martial/jianghu register (内力/轻功/剑光/刀光/真气/身法/
/// 招式/武学) to stay distinct from the xianxi灵力 register above.
const List<String> _wuxiaCliches = [
  '内力运转',
  '施展轻功',
  '剑光一闪',
  '刀光剑影',
  '真气鼓荡',
  '身法如电',
  '招式凌厉',
  '武学修为',
];

/// Urban (都市) genre cliches — modern business / CEO / high-society
/// register AI overuses in urban fiction (AA-05b). Distinct from the
/// xianxia/wuxia registers above.
const List<String> _urbanCliches = [
  '薄唇微抿',
  '眉眼冷峻',
  '气场全开',
  '叱咤商界',
  '高定西装',
  '顶级会所',
  '名门望族',
  '雷厉风行',
];

/// Sci-fi (科幻) genre cliches — hard-concept register AI overuses in
/// science fiction (AA-05b).
const List<String> _scifiCliches = [
  '量子纠缠',
  '意识上传',
  '星际航行',
  '虚拟现实',
  '光年之外',
  '维度坍缩',
  '文明等级',
  '基因改造',
];

/// Xuanhuan (玄幻) genre cliches — western-magic / otherworld / bloodline-
/// pact register AI overuses in xuanhuan fiction (AA-05c). Closes the 5/5
/// preset coverage (修仙/武侠/都市/科幻/玄幻, `.planning/PROJECT.md`).
/// Distinct from the xianxia 灵力 register: xuanhuan's magic/otherworld/contract vocabulary
/// (魔法/异界/血脉/契约) is a xianxia blind spot — refuting the AA-05b
/// "high overlap with xianxia" deferral.
const List<String> _xuanhuanCliches = [
  '魔法元素',
  '吟唱咒语',
  '血脉觉醒',
  '签订契约',
  '召唤魔兽',
  '魔法学院',
  '圣域',
  '异界大陆',
];

/// Manner-adverb stems (AA-06) — bare 2-char reduplicated softeners AI prose
/// over-relies on (缓缓/微微/淡淡…). Distinct from the synonym map, which
/// catches fixed phrases ('缓缓说道'): these bare stems fire across ANY verb
/// (缓缓起身/推门/抬手), exposing distributional register over-reliance the
/// phrase lists miss. Threshold ≥5 (progressText is paragraph-scale).
const List<String> _mannerAdverbStems = [
  '缓缓',
  '微微',
  '淡淡',
  '轻轻',
  '深深',
  '默默',
  '静静',
  '渐渐',
  '隐隐',
  '悄悄',
];

const List<String> _formulaicEndings = [
  '一场更大的风暴',
  '真正的考验',
  '才刚刚开始',
  '等待着他',
  '命运的齿轮',
];

/// Emotional cliches — phrases AI overuses to describe feelings.
const List<String> _emotionalCliches = [
  '心中涌起一股暖流',
  '眼眶微微湿润',
  '鼻子一酸',
  '暖流涌遍全身',
  '百感交集',
  '五味杂陈',
  '心如刀绞',
  '泪流满面',
  '一股暖意涌上心头',
  '不禁潸然泪下',
];

/// Description formulas — generic scenic descriptions AI defaults to.
const List<String> _descriptionFormulas = [
  '宛如仙境',
  '美不胜收',
  '如诗如画',
  '美轮美奂',
  '心旷神怡',
  '沁人心脾',
  '引人入胜',
  '叹为观止',
];
