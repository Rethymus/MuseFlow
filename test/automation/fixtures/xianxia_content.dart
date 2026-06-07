/// Deterministic xianxia genre test content.
///
/// Fixed strings are used by FakeAdapter so automation tests can assert
/// business flow behavior without real AI calls.
class XianxiaContent {
  static const List<String> synthesis = [
    '林风立于青云峰巅，剑气纵横三千里。今日筑基大成，他日必证金丹大道。',
    '破晓时分，灵气如潮涌入丹田。她缓缓睁眼，眸中闪过一道金光——练气九层，终于突破！',
    '古洞深处，一枚玉简静静悬浮。其上篆刻着"九霄剑诀"四字，散发出令人心悸的威压。',
  ];

  static const List<String> rewrite = [
    '剑光一闪，血溅三尺。他面无表情地收剑入鞘，转身踏入风雪之中。',
    '灵力汇聚掌心，化作一道青色光柱直冲云霄。天地为之变色，雷云滚滚而来。',
  ];

  static const List<String> polish = [
    '他深吸一口气，缓缓运转《玄天功》。丹田内灵力如江河奔涌，沿着经脉游走周天，最终汇聚于气海。',
    '月华如水，洒在剑身之上。她持剑而立，衣袂飘飘，宛若谪仙临尘。',
  ];

  static const List<String> freeInput = [
    '此剑名为"斩仙"，乃上古仙人遗留之物。持之者可破万法，斩因果，逆天改命。',
  ];

  static const Map<String, List<String>> assertableSubstrings = {
    'synthesis': ['林风', '筑基'],
    'rewrite': ['剑光'],
    'polish': ['灵力', '月华'],
    'freeInput': ['斩仙'],
  };

  static const Map<String, List<String>> responses = {
    'synthesis': synthesis,
    'rewrite': rewrite,
    'polish': polish,
    'freeInput': freeInput,
  };
}
