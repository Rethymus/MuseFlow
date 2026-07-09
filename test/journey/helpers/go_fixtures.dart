import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:uuid/uuid.dart';

/// 围棋题材《俗手》的领域 fixtures。
///
/// 四张人物卡（主角／师傅／故人之女／宿敌国手）＋四条 Skill 守护规则
/// （围棋术语规范／现代写实底色／师傅怪话须有伏笔依据／人物一致性）。
/// 守护规则使偏差检测对围棋题材有真实意义，而非沿用修仙的境界约束。
class GoFixtures {
  static final DateTime _fixedDate = DateTime(2026, 7, 8);
  static const Uuid _uuid = Uuid();

  static List<CharacterCard> characters() {
    return [protagonist(), master(), xiaoman(), jiangchao()];
  }

  /// 主角：刚毕业的迷茫青年，童年弃棋，重新识棋识己。
  static CharacterCard protagonist() {
    return CharacterCard(
      id: _uuid.v4(),
      name: '陆衡',
      personality: '内敛自省，外柔内韧，习惯性自我否定却暗藏执拗',
      backstory:
          '二十二岁刚毕业的迷茫青年。童年曾学棋，十二岁一场关键对局自认下出"毁棋的俗手"后弃棋，从此认定自己平庸怯懦。仲夏躲雨误入半目棋社，被怪老头一句话钉住，重新识棋、识人、识己',
      createdAt: _fixedDate,
    );
  }

  /// 师傅：半目棋社老板，似非而是的怪老头，全书伏笔与反转的枢纽。
  static CharacterCard master() {
    return CharacterCard(
      id: _uuid.v4(),
      name: '纪百川',
      personality: '似非而是，冷幽默，藏锋守拙，看透妙手之害而甘居俗手',
      backstory:
          '七十岁上下，瘦，左小指少一节，半目棋社老板。街坊当他落魄棋客，实为三十年前诸多妙手真正的源头。他藏起会反噬好友的妙手、甘当一辈子被讥为"俗手"的陪练，是全书反转所在',
      createdAt: _fixedDate,
    );
  }

  /// 故人之女：事业攀升的青年，险走捷径（第一案）。
  static CharacterCard xiaoman() {
    return CharacterCard(
      id: _uuid.v4(),
      name: '苏小满',
      personality: '聪明进取，要强好胜，一度为求快而动了捷径的念头',
      backstory:
          '陆衡童年邻居、故人之女，在某大公司扶摇直上。险走一步"漂亮捷径"（看似妙手、实为俗手），被陆衡以笨拙的本手拦下，后凭扎实补漏站稳脚跟。其捷径的延迟反噬在第60章兑现',
      createdAt: _fixedDate,
    );
  }

  /// 宿敌：名满天下的年轻国手，成名妙手实为窃来（第二案）。
  static CharacterCard jiangchao() {
    return CharacterCard(
      id: _uuid.v4(),
      name: '江潮',
      personality: '天赋惊人，好胜要强，被"妙手"光环反噬后虚怯而内疚',
      backstory:
          '陆衡童年宿敌，十二岁击败陆衡致其弃棋。后成名满天下的国手，但其惊艳天下的"神之一手"实为十二岁时从半目棋社偷看的残局思路。偷来的妙手没有本手的根，终被反噬',
      createdAt: _fixedDate,
    );
  }

  static List<SkillDocument> skills() => skillRules();

  /// 四条 Skill 守护规则，覆盖围棋术语、世界观底色、怪话逻辑、人物一致。
  static List<SkillDocument> skillRules() {
    return [
      // 规则1：围棋术语与本手/妙手/俗手主旨
      SkillDocument(
        id: _uuid.v4(),
        name: '围棋术语与三手主旨',
        description: '围棋术语使用规范与本书核心辩证',
        content:
            '本手=合乎棋理的正规下法(基础)；妙手=出人意料的精妙之手(创造)；俗手=貌似合理而全局受损的劣着。辩证：俗手亦妙、妙手亦俗、本手或妙或俗，真假互为表里',
        sections: SkillSections(
          rules:
              '围棋术语(定式/急所/棋筋/厚势/先手/弃子/复盘/愚形/半目/盘外招等)须用得准确；不可把俗手写成妙手或反之而无辩证铺垫',
          taboos: '不可滥用术语堆砌；不可让人物张口就是术语词典式解释',
        ),
        isActive: true,
        createdAt: _fixedDate,
      ),
      // 规则2：现代写实底色（世界观禁忌）
      SkillDocument(
        id: _uuid.v4(),
        name: '现代写实底色',
        description: '本书世界观的写实约束',
        content: '现代江南城市背景，写实底色＋一丝奇诡，无人飞天遁地',
        sections: SkillSections(
          rules: '场景为现代都市(棋社/公司/街巷/赛场)，人物行为合乎现代常识',
          taboos:
              '禁止修仙、法术、灵气、境界、飞升等设定；禁止真正的"系统面板/穿越/异能"——师傅口中的"系统"是隐喻与梗，非真实游戏系统',
        ),
        isActive: true,
        createdAt: _fixedDate,
      ),
      // 规则3：师傅怪话须有伏笔依据
      SkillDocument(
        id: _uuid.v4(),
        name: '怪话有据',
        description: '师傅纪百川的怪话与第四面墙须有逻辑或伏笔支撑',
        content: '师傅的似非而是、双关、打破第四面墙的怪话，是全书伏笔载体与喜剧引擎',
        sections: SkillSections(
          rules: '师傅每一句怪话都应是双关、字面真话、伏笔回响或对棋局/叙事框架的隐喻，最终都能在后面得到回扣',
          taboos: '不得为怪而怪、随机抖机灵、无逻辑的荒诞；怪话必须有据可循',
        ),
        isActive: true,
        createdAt: _fixedDate,
      ),
      // 规则4：人物性格一致性
      SkillDocument(
        id: _uuid.v4(),
        name: '人物一致性',
        description: '主要人物的性格与言行须前后一致',
        content: '人物有成长弧但性格底色稳定，不可OOC',
        sections: SkillSections(
          rules: '陆衡内敛自省、纪百川藏锋冷幽默、苏小满要强、江潮天赋高而内敛；成长须有铺垫，不可突变',
          taboos: '人物不可突然性格断裂、不可说出与身份心境严重违和的台词',
        ),
        isActive: true,
        createdAt: _fixedDate,
      ),
    ];
  }
}
