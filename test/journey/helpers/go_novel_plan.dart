/// Long-form novel generation plan for the Go (围棋) real-GLM journey.
///
/// Theme: 2022 全国新高考Ⅰ卷作文题——本手、妙手、俗手。以小说体裁（非应试
/// 议论文）诠释三者辩证，落点为欧·亨利式反转：俗手亦是妙手，妙手亦可能是
/// 俗手，看似本手既可能是妙手也可能是俗手；假作真时真亦假，无为有处有还无。
///
/// 题材刻意避开修仙，取现代奇诡喜剧：江南老巷深处的"半目棋社"，少年陆衡拜
/// 怪师傅纪百川为师。师傅满口似非而是的双关怪话，偶尔打破第四面墙——而每一
/// 句怪话都是埋好的伏笔或主题回响。三单元剧（本手／妙手／俗手）环环相扣。
///
/// Pure data + helpers — no Flutter/test imports, no side effects.
library;

/// 围棋小说《俗手》的世界观与人物卡农，注入每一次生成调用。
const String kGoWorldContext = '''
【世界观】现代，江南某城（暗合"江南的学姐"之梗）。老城区一条叫"槐荫巷"的窄
巷深处，藏着一家叫"半目棋社"的旧棋馆：门面寒酸，招牌掉漆，常年只有一两位
老人下棋，老板是个谁也说不清来路的怪老头。本世界是写实底色＋一丝奇诡：没
有修仙、没有法术、没有系统面板，但人世如棋，每一步落子都有盘外之意。
【围棋三手·主旨】本手＝合乎棋理的正规下法，基础；妙手＝出人意料的精妙之
手，创造；俗手＝貌似合理而全局受损的劣着。三者并非定论：俗手在更高处亦妙，
妙手埋祸时亦俗，看似平庸的本手或藏妙机、或含俗患——真假互为表里。
【主角】陆衡：二十二岁，刚毕业的迷茫青年。童年曾学棋，十二岁那年在一场关
键对局中下出一步被他自认毁棋的"俗手"，从此弃棋，也从此认定自己平庸怯懦。
他因一次偶然躲雨闯入半目棋社，被怪老头一句"你这步棋，二十年前我替你下过"
钉在原地。整部书是他重新识棋、识人、识己，最终看破"那步俗手"真相的过程。
【师傅】纪百川：半目棋社老板，七十岁上下，瘦，左小指少一节。人称"老纪"或
"纪师傅"，街坊当他是个混日子的落魄棋客。他说话似非而是，惯用双关与冷幽默，
偶尔说出惊悚的字面真话或打破第四面墙（譬如道出章节号、称能"关掉你的系统"）。
这些怪话绝非随机——每一句都是埋好的伏笔、主题回响，或对叙事框架的暗示。
他的整个人生在旁人眼里是一步大俗手（有天赋却自甘埋没），真相待 finale 揭晓。
【单元剧·三案环扣】
- 第一案「本手」（约1-33章）：陆衡入社学棋。故人之女苏小满事业攀升，正欲走
  一步"漂亮捷径"（看似妙手、实为俗手）。陆衡以最笨的本手（坦白与坚守）救她。
- 第二案「妙手」（约34-66章）：陆衡童年宿敌、如今名满天下的国手江潮重现。
  江潮的成名"神之一手"实为十年前窃自半目棋社墙上那盘无名残局；妙手即俗手，
  偷来的妙手反噬其心。陆衡面临揭不揭发的抉择。
- 第三案「俗手」（约67-100章）：师傅纪百川的来路与那盘残局的真相浮出。众人
  眼中他自甘堕落的一生，竟是一步为护人、护道而甘受的"大俗手"——而正是这步
  俗手，成全了真正的妙手与全局的善。欧·亨利式收束，回填全部伏笔。
【写作禁忌·反AI腔】禁空洞排比、套话转场、公式化结尾悬念、堆砌叠词与程度副
词；以具体动作、感官、白描、留白代替抽象抒情；对话贴合身份心境。师傅的怪
话必须有逻辑或伏笔支撑，不得为怪而怪、不得随机抖机灵。严守现代写实底色，
绝不出现修仙、法术、系统面板等设定。''';

/// 《俗手》的执笔人人格——现代奇诡喜剧＋冷幽默＋打破第四面墙＋反AI腔。
///
/// 这是全书的"反AI味"灵魂：AI默认产出工整、煽情、四平八稳的散文；本人格
/// 反其道——短句控节奏、白描留白、对话带冷幽默与双关、师傅的怪话似非而是。
const String kGoWriterPersona =
    '你是一位技艺精湛、风格凌厉的中文小说家，擅现代奇诡喜剧与冷幽默。'
    '你的文字凝练、画面感强、善用留白与节奏：落笔即是画面，以动作、感官、'
    '白描推进，多用短句控节奏，穿插长句铺陈。你绝不写空洞抒情、不堆砌副词'
    '叠词、不用套话转场与公式化结尾悬念。'
    '本书主角的师傅纪百川，说话似非而是：惯用双关、字面之外的真意，偶尔抛出'
    '惊悚的字面真话或打破第四面墙（如道出章节号、称能"关掉你的系统"、提到'
    '"下载原神""免疫系统""江南的学姐"等市井与网络梗）。但请牢记：师傅的每一'
    '句怪话都不是随机抖机灵，而是埋好的伏笔、主题回响，或对棋局/叙事框架的'
    '隐喻——它们最终都会在后面得到回扣。幽默要冷、要克制、要有人味。'
    '严守现代写实底色，不出现修仙法术与系统面板。'
    '只输出正文，不要标题、不要分点、不要解释、不要寒暄。';

/// 续写段形态提示（1=开篇，2..6展开不收尾，7收束）。与修仙版通用，复用。
const Map<int, String> kSegmentHints = {
  1: '请撰写本章开篇约2200字。直接进入场景，不要复述前情；写出人物此刻的处境、感官与情绪，为后续留出接续空间。',
  2: '续写约2200字。展开本场景的细节、对话与人物心理，让画面与人物立体起来。本章为长篇章节，请持续展开，不要收尾、不要总结。紧接上文，不要复述。',
  3: '续写约2200字。推进本章的核心冲突或转折，加深张力，让情节往前走。本章为长篇章节，请持续展开，不要收尾。不要复述已有内容。',
  4: '续写约2200字。深化人物关系、铺陈环境与心理，或引入一个小转折。本章为长篇章节，请持续展开，不要收尾。',
  5: '续写约2200字。继续推进情节，保持节奏与画面感。本章为长篇章节，请持续展开，不要收尾。',
  6: '续写约2200字。把本章推向一个情绪或情节的落点，但不必闭合所有线索。本章为长篇章节，请持续展开，不要急于收尾。',
  7: '续写约1500字。完成本章最后的收束，干净利落，留白，或留一丝余韵，但不要用公式化悬念句。',
};

/// 用高性能模型开篇的章节（弧线边界与情绪高点，文笔最紧要处）。其余开篇与
/// 所有续写用 glm-4-flash。
const Set<int> kGoKeyChapters = {
  1, // 入社·第一面
  3, // 师傅第一句"盘外招"怪话
  12, // 第一案高潮·苏小满的捷径
  20, // 师傅与已故国手的关系初露
  33, // 第一案收束·本手立
  34, // 第二案起·江潮重现
  50, // 中点·成名妙手的裂缝
  60, // 苏小曼捷径的延迟反噬兑现
  66, // 第二案收束·妙手即俗手
  67, // 第三案起·师傅来路
  78, // 偷来的妙手真相坐实
  84, // 陌生人身份揭破
  88, // 陆衡童年那盘棋真相
  92, // 师傅断指之由
  95, // "半目"之名由来
  96, // 墙上残局作者揭晓
  97, // 反复出现的"俗手"棋形落定
  98, // "盘外招"真意
  99, // "系统"梗的总回扣＋第四面墙
  100, // 欧·亨利 finale
};

const String kModelHigh = 'glm-4-plus';
const String kModelLow = 'glm-4-flash';

/// 每段硬性字数下限，保证 4-5 段即可命中 7000 字章节目标。
const String kLengthFloor =
    '\n（硬性要求：本段正文不少于1800中文字，若不足请继续写到1800字以上方可停止；不要提前收尾。）';

String openingModelFor(int chapterNo) =>
    kGoKeyChapters.contains(chapterNo) ? kModelHigh : kModelLow;

/// 一条伏笔线。plantedChapter 埋设，resolveChapter 回收。
class GoForeshadowingPlan {
  final String id;
  final String title;
  final int plantedChapter;
  final int resolveChapter;
  final String sourceExcerpt;

  const GoForeshadowingPlan({
    required this.id,
    required this.title,
    required this.plantedChapter,
    required this.resolveChapter,
    required this.sourceExcerpt,
  });
}

/// 十二条环扣伏笔，全部于第100章前回收。每一条都指向"俗手/妙手/本手"互为
/// 表里的核心反转——假作真时真亦假，无为有处有还无。
const List<GoForeshadowingPlan> kGoForeshadowingThreads = [
  GoForeshadowingPlan(
    id: 'fs-loss',
    title: '陆衡童年那盘"输掉"的棋的真相',
    plantedChapter: 1,
    resolveChapter: 88,
    sourceExcerpt: '十二岁那年，他落下一子，随即认定自己毁了整盘棋。可那盘棋，他其实从没真正看完过。',
  ),
  GoForeshadowingPlan(
    id: 'fs-panwai',
    title: '师傅反复念叨的"盘外招"一词的真意',
    plantedChapter: 3,
    resolveChapter: 98,
    sourceExcerpt: '"真正的妙手，往往不在棋盘上。"师傅落子如常，话却像隔空递来。',
  ),
  GoForeshadowingPlan(
    id: 'fs-nowin',
    title: '师傅"从不为赢而下"的规矩背后',
    plantedChapter: 4,
    resolveChapter: 93,
    sourceExcerpt: '"我这儿的规矩——"老纪敲了敲棋罐，"不为赢，才下。"陆衡只当他是输不起的托词。',
  ),
  GoForeshadowingPlan(
    id: 'fs-qipu',
    title: '半目棋社墙上那盘无名残局的真正作者',
    plantedChapter: 2,
    resolveChapter: 96,
    sourceExcerpt: '墙上裱着一盘没下完的残局，没有署名。陆衡问是谁下的，师傅只说："一个下了步俗手的人。"',
  ),
  GoForeshadowingPlan(
    id: 'fs-name',
    title: '棋社名"半目"二字的由来',
    plantedChapter: 2,
    resolveChapter: 95,
    sourceExcerpt: '招牌掉了漆，"半目"两个字却新得扎眼，像是被人反复描过。',
  ),
  GoForeshadowingPlan(
    id: 'fs-finger',
    title: '师傅左手少一节小指的缘由',
    plantedChapter: 5,
    resolveChapter: 92,
    sourceExcerpt: '他拈棋的左手，小指只有半截。陆衡想问，话到嘴边又咽了回去。',
  ),
  GoForeshadowingPlan(
    id: 'fs-system',
    title: '师傅口中的"系统"到底指什么',
    plantedChapter: 7,
    resolveChapter: 99,
    sourceExcerpt: '"我能关掉你的系统。"师傅忽然说。陆衡愣住——他手机明明没装什么系统。',
  ),
  GoForeshadowingPlan(
    id: 'fs-stranger',
    title: '反复出现、观棋不发一言的陌生人',
    plantedChapter: 9,
    resolveChapter: 84,
    sourceExcerpt: '角落里那个戴旧呢帽的男人又来了，从不落子，只看。看完就走。',
  ),
  GoForeshadowingPlan(
    id: 'fs-xiaoman',
    title: '苏小满那步"妙手"捷径埋下的祸根',
    plantedChapter: 12,
    resolveChapter: 60,
    sourceExcerpt: '苏小满笑着说自己找到了一步"神来之笔"。陆衡却想起师傅的话：太漂亮的棋，要先想想它亏了什么。',
  ),
  GoForeshadowingPlan(
    id: 'fs-shape',
    title: '反复浮现的那个特定"俗手"棋形',
    plantedChapter: 15,
    resolveChapter: 97,
    sourceExcerpt: '盘角那个笨拙的愚形，陆衡越看越像自己十二岁下的那步——可师傅盯着它，眼神却亮。',
  ),
  GoForeshadowingPlan(
    id: 'fs-jiangchao',
    title: '江潮成名"神之一手"实为窃自残局',
    plantedChapter: 34,
    resolveChapter: 78,
    sourceExcerpt: '江潮复盘中那步惊艳天下的妙手，与棋社墙上残局的下一手，分毫不差。',
  ),
  GoForeshadowingPlan(
    id: 'fs-champion',
    title: '师傅与一位已故国手的隐秘渊源',
    plantedChapter: 20,
    resolveChapter: 100,
    sourceExcerpt: '茶垢斑驳的相框里，年轻的老纪与那位名满天下的故人并肩而立，中间隔着一盘棋。',
  ),
];

/// 统计 CJK 汉字数（不计标点、ASCII、数字）——即用户指定的"中文字数（不计
/// 标点）"指标，只 Han 码位计入 7000–9000 目标。
int cjkCharCount(String text) {
  var n = 0;
  for (final r in text.runes) {
    if ((r >= 0x4E00 && r <= 0x9FFF) || (r >= 0x3400 && r <= 0x4DBF)) {
      n++;
    }
  }
  return n;
}

/// 将 text 裁到 [minCjk]–[maxCjk] 区间，于句末边界切。已在内则原样返回。
String trimToCjkRange(String text, {int minCjk = 7000, int maxCjk = 9000}) {
  final count = cjkCharCount(text);
  if (count <= maxCjk) return text;

  const boundaries = ['。', '！', '？', '!', '?', '\n'];
  var running = 0;
  var lastBoundaryEnd = -1;
  var bestEnd = -1;
  final runes = text.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    final r = runes[i];
    final isCjk = (r >= 0x4E00 && r <= 0x9FFF) || (r >= 0x3400 && r <= 0x4DBF);
    if (isCjk) running++;
    if (boundaries.contains(String.fromCharCode(r))) {
      lastBoundaryEnd = i + 1;
      if (running >= minCjk && running <= maxCjk) {
        bestEnd = lastBoundaryEnd;
      }
    }
    if (running > maxCjk) break;
  }
  final end = bestEnd > 0 ? bestEnd : lastBoundaryEnd;
  return end > 0 ? text.substring(0, end) : text;
}

/// 从 beat "第1章 入社：陆衡是…" 抽出干净标题 "第1章 入社"。
String chapterTitleFromBeat(String beat) {
  final cut = beat.indexOf('：');
  if (cut <= 0) return beat.substring(0, beat.length.clamp(0, 20));
  final head = beat.substring(0, cut);
  return head.length > 24 ? head.substring(0, 24) : head;
}
