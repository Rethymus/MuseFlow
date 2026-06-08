/// Three-stage prompt constants for the xianxia journey test.
///
/// Per D-03: Stage prompts set scene/theme for each cultivation block.
/// Individual chapter plot points in StoryOutline.chapters provide per-chapter
/// specifics; these prompts provide the broader thematic direction.
///
/// Stage mapping:
/// - Ch 1-30 (indices 0-29): no stage prompt (Phase 14 arc, existing)
/// - Ch 31-60 (indices 30-59): Golden Core stage
/// - Ch 61-90 (indices 60-89): Nascent Soul stage
/// - Ch 91-100 (indices 90-99): Ascension stage
class StagePrompts {
  /// Golden Core stage prompt for chapters 31-60.
  ///
  /// Sets the scene for Core Formation challenges, sect politics intensifying,
  /// and the risk of failure and retry that defines this cultivation stage.
  static const String goldenCore =
      '金丹期：林风踏入金丹修炼之路，面临结丹的严峻考验。'
      '门派内部暗流涌动，王磊的阴谋如同毒蛇般伺机而动。'
      '结丹失败的痛苦、重头再来的决心、同门之间的信任与背叛交织成一幅复杂的画卷。'
      '这一阶段考验的是不屈的意志和面对失败的勇气。';

  /// Nascent Soul stage prompt for chapters 61-90.
  ///
  /// Sets the scene for tribulation dangers, inner demons, and the weight of
  /// accumulated power and responsibility at this cultivation stage.
  static const String nascentSoul =
      '元婴期：新境界带来前所未有的力量，也带来前所未有的劫难。'
      '心魔如影随形，考验着修士的道心是否坚不可摧。'
      '门派大战的血与火、禁地封印的崩裂、师门的秘密一一揭开。'
      '力量的积累伴随着责任的加重，每一步都走在刀锋之上。';

  /// Ascension stage prompt for chapters 91-100.
  ///
  /// Sets the scene for the final breakthrough, resolving all story threads,
  /// and ascending to a higher realm.
  static const String ascension =
      '飞升篇：所有伏笔线索汇聚终局，身世之谜最终揭开。'
      '天劫降临，九道天雷淬炼肉身与道心，化神与飞升只在一线之间。'
      '玉简碎片的真正使命、天衡盘的重铸、凡间与仙界的平衡全系于此。'
      '以凡人之心踏上仙途，这是最后的考验，也是新的开始。';

  /// Returns the stage-specific prompt for the given chapter [index].
  ///
  /// - Indices 0-29: returns empty string (Phase 14 chapters have no stage prompt)
  /// - Indices 30-59: returns [goldenCore]
  /// - Indices 60-89: returns [nascentSoul]
  /// - Indices 90-99: returns [ascension]
  static String forChapterIndex(int index) {
    if (index < 30) return '';
    if (index < 60) return goldenCore;
    if (index < 90) return nascentSoul;
    return ascension;
  }
}
