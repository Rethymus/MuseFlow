import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:uuid/uuid.dart';

/// Xianxia domain fixtures for journey integration tests.
///
/// Per D-08: Character cards with personality, backstory, and aliases.
/// Per D-09: Skill guardian rules covering realm constraints, sect hierarchy,
/// world taboos, and ability limits.
class XianxiaFixtures {
  static final DateTime _fixedDate = DateTime(2026, 6, 7);
  static const Uuid _uuid = Uuid();

  /// Protagonist: mortal youth turned cultivator.
  ///
  /// Name: 林风 -- resilient, determined, ordinary but unyielding.
  static CharacterCard protagonist() {
    return CharacterCard(
      id: _uuid.v4(),
      name: '林风',
      personality: '坚韧隐忍，不轻言放弃',
      backstory: '偏远山村凡人少年，因意外踏入修仙之路，天资平平但意志坚定',
      createdAt: _fixedDate,
    );
  }

  /// Master: Qingyun Sect elder.
  ///
  /// Name: 清虚真人 -- stern but caring mentor.
  static CharacterCard master() {
    return CharacterCard(
      id: _uuid.v4(),
      name: '清虚真人',
      personality: '严厉深沉，内心关爱弟子',
      backstory: '青云宗长老，练气九层巅峰，精通阵法，掌握无名功法的秘密',
      createdAt: _fixedDate,
    );
  }

  /// Senior sister: talented alchemist.
  ///
  /// Name: 苏雪晴 -- intelligent, gentle, alchemy prodigy.
  static CharacterCard senior() {
    return CharacterCard(
      id: _uuid.v4(),
      name: '苏雪晴',
      personality: '聪慧温柔，炼丹天赋极高',
      backstory: '青云宗大师姐，筑基期修为，对主角暗中关照',
      createdAt: _fixedDate,
    );
  }

  /// Rival: arrogant fellow disciple.
  ///
  /// Name: 赵天磊 -- proud, narrow-minded, competitive.
  static CharacterCard rival() {
    return CharacterCard(
      id: _uuid.v4(),
      name: '赵天磊',
      personality: '傲慢好胜，心胸狭窄',
      backstory: '外门天才弟子，出身修仙世家，视主角为竞争对手',
      createdAt: _fixedDate,
    );
  }

  /// Qingyun Sect cultivation world.
  ///
  /// Features the six-tier realm system: mortal -> Qi Refining -> Foundation
  /// Establishment -> Golden Core -> Nascent Soul -> Deity Transformation.
  static WorldSetting sectWorld() {
    return WorldSetting(
      id: _uuid.v4(),
      name: '青云宗修仙界',
      description: '青云宗坐落的修仙世界，修行体系为凡人→练气→筑基→金丹→元婴→化神。'
          '凡人通过灵根测试方可入门修仙，练气期分九层，筑基后方可御剑飞行。',
      geography: '青云山脉，主峰青云峰',
      factions: '青云宗',
      rules: '修仙者须遵守天道法则，不可滥杀凡人；门规森严，等级分明',
      techLevel: '古代仙侠',
      createdAt: _fixedDate,
    );
  }

  /// Four Skill guardian rules covering realm constraints, sect hierarchy,
  /// world taboos, and ability limits.
  ///
  /// Per D-09: All rules have isActive: true.
  static List<SkillDocument> skillRules() {
    return [
      // Rule 1: Realm hierarchy constraints
      SkillDocument(
        id: _uuid.v4(),
        name: '境界体系约束',
        description: '修仙境界体系与能力对应关系',
        content: '凡人->练气(1-9层)->筑基->金丹->元婴->化神',
        sections: SkillSections(
          powerHierarchy: '凡人 < 练气(1-9层) < 筑基 < 金丹 < 元婴 < 化神',
          taboos: '练气期不可使用筑基以上法术；丹药等级不得超过当前境界两层',
        ),
        isActive: true,
        createdAt: _fixedDate,
      ),
      // Rule 2: Sect hierarchy rules
      SkillDocument(
        id: _uuid.v4(),
        name: '门派等级森严',
        description: '青云宗内部等级制度与行为规范',
        content: '门派弟子按等级享有不同权限，低阶弟子须尊敬高阶师兄',
        sections: SkillSections(
          rules: '外门弟子不得擅入内门禁地；杂役弟子不可直接面见长老；未经允许不可学习其他峰的功法',
          taboos: '低阶弟子不可对高阶师兄无礼',
        ),
        isActive: true,
        createdAt: _fixedDate,
      ),
      // Rule 3: World taboos
      SkillDocument(
        id: _uuid.v4(),
        name: '世界观禁忌',
        description: '本世界中不存在的事物和概念',
        content: '仙侠世界观中禁止出现现代科技元素',
        sections: SkillSections(
          taboos: '不存在火器、枪械、现代电子设备；不存在科学概念；通信只能用符箓或灵兽传书',
        ),
        isActive: true,
        createdAt: _fixedDate,
      ),
      // Rule 4: Ability limits per realm
      SkillDocument(
        id: _uuid.v4(),
        name: '能力限制',
        description: '不同境界修士的能力边界',
        content: '各境界修士有明确的能力限制，不可越级使用法术',
        sections: SkillSections(
          rules: '凡人不可御剑飞行；练气期不可施展神识',
          taboos: '林风在练气期不可使用火系法术',
        ),
        isActive: true,
        createdAt: _fixedDate,
      ),
    ];
  }
}
