/// Long-form novel generation plan for the real-GLM 100-chapter journey.
///
/// Pure data + helpers — no Flutter/test imports, no side effects. Keeps the
/// generator test file thin and lets the README cite a single source of truth
/// for the foreshadowing map, key-chapter model routing, and prompt shape.
library;

/// World + character context injected into every generation call.
///
/// Mirrors the xianxia fixtures wired by `_setupWorldBuilding` in
/// `serial_generation_test.dart` so the long-form run shares the same canon
/// as the deterministic journey — only the per-chapter depth changes.
const String kWorldContext = '''
【世界观】青云宗（青冥宗）修仙界。境界次第：练气 → 筑基 → 金丹 → 元婴 → 化神 → 飞升。宗门有藏经阁、丹房、灵兽谷、后山禁地；与天剑门比邻，与暗影门及幕后上界势力对立。
【主角】林风：青云山脚凡人少年，父母早逝，天资平平却意志如铁。于藏经阁偶得上古玉简，修习无名功法，契约灵兽白灵（雪白灵狐，能共享视野、施幻术）。从外门杂役一路走到化神飞升。
【主要人物】
- 苏雪晴：大师姐，温柔聪慧，精通炼丹；身藏上古剑修血脉，与后山禁地古剑共鸣。
- 赵天磊：同门世家子弟，天赋过人；初对林风轻蔑嫉妒，历经生死后结为挚友。
- 清虚真人：长老，林风师尊，严厉中藏慈悲；实为上古大能灵虚真人转世，守护封印于禁地之下的天衡盘。
- 王磊：内门弟子，傲慢阴狠，暗中勾结暗影门，多次设计陷害林风。
- 白灵：林风的灵狐，通体雪白，随主人境界进化，可幻化人形。
- 柳寒烟：天剑门首席弟子，与林风惺惺相惜。
【写作禁忌】禁AI腔：勿用空洞排比、套话转场、公式化结尾悬念、堆砌叠词副词；以具体动作、感官、白描、留白代替抽象抒情；对话贴合身份心境；严守设定不得OOC。''';

/// Anti-AI-scent writer persona used as the system message for every call.
const String kWriterPersona =
    '你是一位技艺精湛的中文修仙小说家，文笔凝练、画面感强、善用留白与节奏。'
    '你与人协作而非代笔：每一行都要留下"人"的呼吸与温度，让读者看不出AI的痕迹。'
    '落笔即是画面，以动作、感官、白描推进；多用短句控节奏，穿插长句铺陈。'
    '不写空洞抒情、不堆砌副词叠词、不用套话转场与公式化结尾。严守世界观与人物设定。'
    '只输出正文，不要标题、不要分点、不要解释、不要寒暄。';

/// Narrative shape hint per continuation segment (1-indexed segment number).
/// Segment 1 is the opening; 2..6 expand without concluding (long-form chapters
/// must not wrap up early or the chapter falls short of the word target);
/// segment 7 closes.
const Map<int, String> kSegmentHints = {
  1: '请撰写本章开篇约2200字。直接进入场景，不要复述前情；写出人物此刻的处境、感官与情绪，为后续留出接续空间。',
  2: '续写约2200字。展开本场景的细节、对话与人物心理，让画面与人物立体起来。本章为长篇章节，请持续展开，不要收尾、不要总结。紧接上文，不要复述。',
  3: '续写约2200字。推进本章的核心冲突或转折，加深张力，让情节往前走。本章为长篇章节，请持续展开，不要收尾。不要复述已有内容。',
  4: '续写约2200字。深化人物关系、铺陈环境与心理，或引入一个小转折。本章为长篇章节，请持续展开，不要收尾。',
  5: '续写约2200字。继续推进情节，保持节奏与画面感。本章为长篇章节，请持续展开，不要收尾。',
  6: '续写约2200字。把本章推向一个情绪或情节的落点，但不必闭合所有线索。本章为长篇章节，请持续展开，不要急于收尾。',
  7: '续写约1500字。完成本章最后的收束，干净利落，留白，或留一丝余韵，但不要用公式化悬念句。',
};

/// Chapters whose opening segment is generated with the higher-quality model
/// (glm-4-plus) — arc boundaries and emotional peaks where prose quality
/// matters most for the showcase. All other openings and every continuation
/// use the low-cost model (glm-4-flash).
const Set<int> kKeyChapters = {
  1,
  5,
  13,
  25,
  30,
  41,
  50,
  57,
  60,
  72,
  75,
  85,
  90,
  96,
  97,
  98,
  99,
  100,
};

/// High-performance model for key-chapter openings; low-cost model elsewhere.
const String kModelHigh = 'glm-4-plus';
const String kModelLow = 'glm-4-flash';

/// Hard per-segment length floor appended to every generation prompt so each
/// streamed segment is dense enough to reach the 7000-char chapter target in
/// 4–5 segments (not 6–7), keeping the 100-chapter run inside its time budget.
const String kLengthFloor =
    '\n（硬性要求：本段正文不少于1800中文字，若不足请继续写到1800字以上方可停止；不要提前收尾。）';

/// Opening-segment model for chapter [chapterNo] (1-indexed).
String openingModelFor(int chapterNo) =>
    kKeyChapters.contains(chapterNo) ? kModelHigh : kModelLow;

/// A foreshadowing thread in the 100-chapter plan.
///
/// [plantedChapter]/[resolveChapter] are 1-indexed chapter numbers. The
/// generator plants the entry at its planted chapter and marks it resolved at
/// its resolve chapter, yielding a real lifecycle + fill-rate metric.
class ForeshadowingPlan {
  final String id;
  final String title;
  final int plantedChapter;
  final int resolveChapter;
  final String sourceExcerpt;

  const ForeshadowingPlan({
    required this.id,
    required this.title,
    required this.plantedChapter,
    required this.resolveChapter,
    required this.sourceExcerpt,
  });
}

/// Twelve cross-book foreshadowing threads derived from `StoryOutline`.
/// Every thread is resolved by chapter 100 — the novel is a complete arc.
const List<ForeshadowingPlan> kForeshadowingThreads = [
  ForeshadowingPlan(
    id: 'fs-jade',
    title: '藏经阁神秘玉简的来历',
    plantedChapter: 5,
    resolveChapter: 90,
    sourceExcerpt: '玉简表面布满裂纹，隐约散发奇异的灵光。',
  ),
  ForeshadowingPlan(
    id: 'fs-nameless',
    title: '无名功法的真正渊源',
    plantedChapter: 6,
    resolveChapter: 91,
    sourceExcerpt: '与宗门正统功法截然不同的上古修炼之法。',
  ),
  ForeshadowingPlan(
    id: 'fs-zhao',
    title: '赵天磊对林风的敌意',
    plantedChapter: 8,
    resolveChapter: 76,
    sourceExcerpt: '赵天磊出身修仙世家，对外门弟子上位的林风心存轻蔑。',
  ),
  ForeshadowingPlan(
    id: 'fs-master',
    title: '清虚真人的复杂神情与身份',
    plantedChapter: 13,
    resolveChapter: 67,
    sourceExcerpt: '长老严厉告诫的同时，流露出一丝复杂的神情。',
  ),
  ForeshadowingPlan(
    id: 'fs-bailing',
    title: '灵兽白灵契约的最终归宿',
    plantedChapter: 17,
    resolveChapter: 86,
    sourceExcerpt: '林风与白灵心意相通，结成灵兽契约。',
  ),
  ForeshadowingPlan(
    id: 'fs-liu',
    title: '天剑门柳寒烟的缘分',
    plantedChapter: 37,
    resolveChapter: 77,
    sourceExcerpt: '柳寒烟对林风的功法表现出浓厚兴趣。',
  ),
  ForeshadowingPlan(
    id: 'fs-wang',
    title: '王磊的阴谋与背后势力',
    plantedChapter: 33,
    resolveChapter: 65,
    sourceExcerpt: '王磊暗中联合心腹，密谋设局陷害林风。',
  ),
  ForeshadowingPlan(
    id: 'fs-su',
    title: '苏雪晴隐藏的血脉秘密',
    plantedChapter: 40,
    resolveChapter: 64,
    sourceExcerpt: '苏雪晴感应到来自后山禁地的微弱呼唤。',
  ),
  ForeshadowingPlan(
    id: 'fs-forbidden',
    title: '后山禁地的封印异动',
    plantedChapter: 40,
    resolveChapter: 88,
    sourceExcerpt: '封印阵法出现裂痕，一股古老力量试图冲破束缚。',
  ),
  ForeshadowingPlan(
    id: 'fs-origin',
    title: '林风的真正身世',
    plantedChapter: 49,
    resolveChapter: 91,
    sourceExcerpt: '恍惚间看到一位古老修士传授失传功法，对身世产生疑问。',
  ),
  ForeshadowingPlan(
    id: 'fs-upper',
    title: '暗影门背后的上界势力',
    plantedChapter: 57,
    resolveChapter: 98,
    sourceExcerpt: '暗影门将苏雪晴掳走，似对其特殊体质有所图谋。',
  ),
  ForeshadowingPlan(
    id: 'fs-demon',
    title: '元婴期心魔劫的伏笔',
    plantedChapter: 72,
    resolveChapter: 85,
    sourceExcerpt: '修为飞速提升却根基未稳，心魔悄然入侵。',
  ),
];

/// Counts CJK ideographs in [text], excluding punctuation, ASCII, and digits.
///
/// This is the "中文字数（不计标点）" metric the user specified: only Han
/// code points count toward the 7000–9000 target.
int cjkCharCount(String text) {
  var n = 0;
  for (final r in text.runes) {
    if ((r >= 0x4E00 && r <= 0x9FFF) || (r >= 0x3400 && r <= 0x4DBF)) {
      n++;
    }
  }
  return n;
}

/// Trims [text] to the [minCjk]–[maxCjk] CJK-char range at a sentence
/// boundary. If already within range, returns as-is. If above, cuts at the
/// last sentence end at or before [maxCjk] (but not below [minCjk]).
String trimToCjkRange(String text, {int minCjk = 7000, int maxCjk = 9000}) {
  final count = cjkCharCount(text);
  if (count <= maxCjk) return text;

  const boundaries = ['。', '！', '？', '!', '?', '\n'];
  // Walk code points, track the last boundary position whose running CJK
  // count is still >= minCjk (so we never trim below the floor).
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

/// Extracts a clean chapter title from a StoryOutline beat such as
/// "第1章 凡人少年：林风是…" → "第1章 凡人少年".
String chapterTitleFromBeat(String beat) {
  final cut = beat.indexOf('：');
  if (cut <= 0) return beat.substring(0, beat.length.clamp(0, 20));
  final head = beat.substring(0, cut); // "第1章 凡人少年"
  return head.length > 24 ? head.substring(0, 24) : head;
}
