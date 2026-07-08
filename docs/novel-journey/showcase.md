### 规模与字数
- **章节数**：100 章（全量真实 GLM 生成，未完结于百章内、于第 100 章飞升收束）
- **总字数（去标点 CJK）**：821,036 字 · 平均 8,210 字/章 · 区间 [6,972, 8,980]
- **规格合规**：每章 7000–9000 中文字（不计标点，允许 ±500）；补丁续写后 100/100 章落在 [6500, 9500]，其中 99/100 章达 7000+

### 耗时与成本
- **总耗时**：10h3m54s（平均 362.3 秒/章）
- **Token 消耗**：输入 2,983,607 · 输出 1,235,392 · 合计 4,218,999 （513 次 API 调用）
- **模型搭配**（高性能＋低开销混用）：  glm-4-plus 用于 18 个关键章（开篇/高潮/收束）的开篇；glm-4-flash 承担其余开篇与全部续写、守护、摘要

| 模型 | 调用次数 | 输入 token | 输出 token | 单价(输入/输出,¥/百万) | 估算成本 |
|---|---:|---:|---:|---|---:|
| glm-4-flash | 495 | 2,962,728 | 1,190,712 | ¥0.10 / ¥0.10 | ¥0.42 |
| glm-4-plus | 18 | 20,879 | 44,680 | ¥50.00 / ¥50.00 | ¥3.28 |
| **合计** | **513** | **2,983,607** | **1,235,392** | — | **¥3.69** |

> 成本为按公开定价假设的估算（见脚本 `PRICING`），以智谱官方为准；权威指标为实测 Token 数。

### 反 AI 味 · 一致性守护 · 伏笔填坑
- **反 AI 味**：全册标记 8,368 处 AI 腔征兆，其中 8,032 处由同义词表自动净化，其余进入作者复核信号
  - 高频信号：转场套话偏多（94）、叠词/程度副词堆砌（91）、类型文套句偏多（83）、结尾悬念公式化（45）、结构化句式重复（36）
- **Skill 守护（设定一致性）**：全册触发 372 条偏离告警，由偏差检测在生成侧即时拦截
- **伏笔填坑**：埋设 12 条长线伏笔，回收 12 条，填坑率 100%，平均 50.1 章回收

### 精选章节摘录（文笔/高潮）
完整正文托管于 Notion（见下方目录与跳转链接）。以下是机器挑选的若干段落预览：

> **第1章 · 凡人少年**（[Notion 全文](https://app.notion.com/p/1-397600df78ee8168aeafeb38654b1883)）
>
> 山风呼啸，卷起枯叶打着旋儿掠过林风的脚踝。他抡起斧头，青筋在黝黑的手背上凸起，每一次落下都带着山野间特有的沉闷声响。木屑纷飞中，他的眼神却专注，仿佛那棵老槐树不是阻碍，而是值得尊重的对手。
> "吱呀——"槐树应声而倒，轰然倒地的声音惊起了几只林鸟。林风抹去额头的汗水，抬头望向青云山的方向。云雾缭绕间，若隐若现的飞檐斗角如同传说中仙人居住的地方。他从小就听村里的老人讲过青云宗的故事，那些御剑飞行、呼风唤雨的修仙者，在这片山巅之上俯瞰凡尘。
> "小风，歇会儿吧。"老槐树下，村口的老张头递过一葫芦水。林风接过，仰头灌了几口，冰凉的液体顺着喉咙滑下，稍稍缓解了口干舌燥。

> **第30章 · 筑基**（[Notion 全文](https://app.notion.com/p/30-397600df78ee81939447c7f6e77e0ffd)）
>
> 月光如水，洒在青云峰顶。林风盘膝而坐，手中托着一枚丹药，丹身流转着淡金色光芒，散发出若有若无的草木清香。这是他历经千辛万苦采集灵草，炼制而成的筑基丹。丹药入手温润，仿佛蕴藏着无尽的生命力。
> 夜风拂过，带着山顶特有的寒意，吹动林风的青衫。他，将丹药放入口中。丹药入口即化，化作一股温热的气流顺着喉咙滑入丹田。起初只是微微发热，随即那热量开始迅速蔓延，如同点燃了体内的火种。
> 林风闭上眼睛，感受着体内发生的变化。丹田处，一股暖流开始涌现，逐渐扩散至全身经脉。他按照无名功法中的心法引导，开始吸纳这股能量。经脉中的灵气仿佛被唤醒，开始按照特定的路线运转。

> **第50章 · 二次结丹**（[Notion 全文](https://app.notion.com/p/50-397600df78ee815b99c6cc7dae75be88)）
>
> 丹田内，灵力如江河奔涌。林风盘膝而坐，闭目凝神，感受着体内经脉重塑后的全新状态。每一条经脉都宽阔了数倍，内壁光滑如镜，灵力在其中流淌，再无阻滞。金丹碎片悬浮在丹田中央，散发出柔和的金光，那是他第一次尝试结丹失败后留下的痕迹。
> "准备好了吗？"清虚真人的声音在洞府中响起，平静中带着一丝不易察觉的紧张。
> 林风睁开眼，眸中闪烁着坚定："师尊，弟子已准备就绪。"
> 苏雪晴站在一旁，手中托着一枚丹药："这是师尊炼制的固元丹，能辅助你稳定心神。"
> 林风接过丹药，服下。丹药入口即化，一股清凉的气息顺着喉咙滑入腹中，丹田内的灵力似乎变得更加活跃。
> "这次结丹，无需阵法辅助。"清虚真人道，"凭借你体内重塑的经脉，以及无名功法与凝丹功法的融合，你有足够的实力完成二次结丹。

> **第75章 · 血战南门**（[Notion 全文](https://app.notion.com/p/75-397600df78ee8179874bf6361992a5e6)）
>
> 血腥味在空气中弥漫，混合着硫磺与焦土的气息。林风的长剑泛着青光，剑尖滴落的鲜血在他脚边汇成细流。南大门的石阶上，躺着三具暗影门弟子的尸体，他们的眼睛圆睁，凝固着的惊骇。
> "林师弟，左翼不稳！"赵天磊的声音从远处传来，带着一丝喘息。他的长剑已经布满缺口，衣袍撕裂处露出几道血痕。
> 林风没有回头，元婴期的感知让他早已察觉战局变化。他身形一晃，剑如游龙，三名偷袭的暗影门弟子咽喉同时出现细线般的血痕。倒下前，他们甚至没能发出一声惊呼。
> 白灵的身影在林风肩头若隐若现，雪白的毛发沾染了血点，双眼却闪烁着智慧的光芒。她轻轻一甩头，一道幻术如雾般散开，几名正要包抄的敌人突然停下脚步，茫然四顾。

> **第85章 · 破心魔**（[Notion 全文](https://app.notion.com/p/85-397600df78ee811f8d57fecdaf692ffc)）
>
> 林风站在幻境中心，四周是无穷无尽的黑暗。他能听见自己的心跳声，沉重而有力，像一面战鼓敲打在胸膛上。汗水从额头滑落，滴在石板上，发出微弱的声响。幻境中的空气黏稠得如同胶水，每一次呼吸都像是吞下了千斤重的铅块。
> "放弃吧。"一个声音在他身后响起，熟悉得让他心头发紧。那是父母的声音，温暖而带着叹息，"你永远无法超越自己的极限，何必执着于此？"
> 林风没有回头。他知道，这是心魔的把戏。他闭上眼睛，感受着指尖的触感——粗糙，真实，带着常年劳作留下的薄茧。这是他作为凡人的印记，也是他力量的源泉。
> "你以为你是谁？"另一个声音响起，是赵天磊，带着嘲讽的笑意，"一个山野村夫，也妄想修仙？

> **第100章 · 飞升**（[Notion 全文](https://app.notion.com/p/100-397600df78ee81528227db55cb64b64f)）
>
> 青云峰顶，云海翻涌。
> 林风站在崖边，衣袂被山风吹得猎猎作响。脚下是万丈深渊，远处是连绵的山峦，被一层薄薄的晨雾笼罩。他，空气中弥漫着灵气与尘埃混合的味道，清冽而厚重。
> "准备好了吗？"苏雪晴的声音从身后传来，温柔如初。
> 林风点点头，目光落在身旁的天衡盘上。那枚古朴的玉盘在晨光中流转着淡蓝色的光晕，表面篆刻的符文仿佛活了过来，缓缓游动。清虚真人已经化作点点灵光，融入了这枚上古神器之中，完成了他千年的宿命。
> "师尊……"林风轻声呼唤，声音被风吹散。
> 赵天磊拍了拍他的肩膀，手掌宽厚而有力："这一路走来，你从未让任何人失望。现在，轮到你为我们，为青云宗，为整个修仙界开辟道路了。

### 章节目录与正文
每章正文以仓库 Markdown 呈现（GitHub 可直接阅读）；提供 Notion 凭据后，另以 Notion 页面托管。

| 章 | 标题 | 字数 | 正文 |
|---:|---|---:|---|
| 1 | 凡人少年 | 8,635 | [Markdown](docs/novel-journey/chapters/第001章-凡人少年.md) · [Notion](https://app.notion.com/p/1-397600df78ee8168aeafeb38654b1883) |
| 2 | 山门试炼 | 7,122 | [Markdown](docs/novel-journey/chapters/第002章-山门试炼.md) · [Notion](https://app.notion.com/p/2-397600df78ee81b99c79e03a5e53ae23) |
| 3 | 入门 | 8,704 | [Markdown](docs/novel-journey/chapters/第003章-入门.md) · [Notion](https://app.notion.com/p/3-397600df78ee817e8598f6b4c60f0c59) |
| 4 | 灵气初感 | 8,803 | [Markdown](docs/novel-journey/chapters/第004章-灵气初感.md) · [Notion](https://app.notion.com/p/4-397600df78ee81aaa20bf9da21b7dac9) |
| 5 | 藏经阁 | 8,170 | [Markdown](docs/novel-journey/chapters/第005章-藏经阁.md) · [Notion](https://app.notion.com/p/5-397600df78ee8113aa35d3b6edb8ae6a) |
| 6 | 无名功法 | 8,741 | [Markdown](docs/novel-journey/chapters/第006章-无名功法.md) · [Notion](https://app.notion.com/p/6-397600df78ee815b9808ec0b259aafd9) |
| 7 | 练气一层 | 8,737 | [Markdown](docs/novel-journey/chapters/第007章-练气一层.md) · [Notion](https://app.notion.com/p/7-397600df78ee810c8ceecaba6f1b4b98) |
| 8 | 同门 | 8,407 | [Markdown](docs/novel-journey/chapters/第008章-同门.md) · [Notion](https://app.notion.com/p/8-397600df78ee81bf8d0dc93aaa5980f3) |
| 9 | 丹房意外 | 8,591 | [Markdown](docs/novel-journey/chapters/第009章-丹房意外.md) · [Notion](https://app.notion.com/p/9-397600df78ee81339476d652ecaffc74) |
| 10 | 练气三层 | 8,169 | [Markdown](docs/novel-journey/chapters/第010章-练气三层.md) · [Notion](https://app.notion.com/p/10-397600df78ee811ba181edf471ac793e) |
| 11 | 外门比武 | 8,032 | [Markdown](docs/novel-journey/chapters/第011章-外门比武.md) · [Notion](https://app.notion.com/p/11-397600df78ee8172b01cc040c80e3480) |
| 12 | 首胜 | 8,200 | [Markdown](docs/novel-journey/chapters/第012章-首胜.md) · [Notion](https://app.notion.com/p/12-397600df78ee81c9a143f578f1db52a4) |
| 13 | 引起注意 | 7,969 | [Markdown](docs/novel-journey/chapters/第013章-引起注意.md) · [Notion](https://app.notion.com/p/13-397600df78ee8178b5f8e9c1cace4360) |
| 14 | 秘传 | 8,610 | [Markdown](docs/novel-journey/chapters/第014章-秘传.md) · [Notion](https://app.notion.com/p/14-397600df78ee8127b71be955c709404a) |
| 15 | 练气六层 | 8,190 | [Markdown](docs/novel-journey/chapters/第015章-练气六层.md) · [Notion](https://app.notion.com/p/15-397600df78ee8118b675f93fc10da90f) |
| 16 | 灵兽谷 | 8,301 | [Markdown](docs/novel-journey/chapters/第016章-灵兽谷.md) · [Notion](https://app.notion.com/p/16-397600df78ee815aad19fba8e41753bc) |
| 17 | 灵兽契约 | 8,758 | [Markdown](docs/novel-journey/chapters/第017章-灵兽契约.md) · [Notion](https://app.notion.com/p/17-397600df78ee81dfb467fb3237883d09) |
| 18 | 内门考核 | 7,217 | [Markdown](docs/novel-journey/chapters/第018章-内门考核.md) · [Notion](https://app.notion.com/p/18-397600df78ee81aab901d4b71572b2a5) |
| 19 | 第一关 | 8,714 | [Markdown](docs/novel-journey/chapters/第019章-第一关.md) · [Notion](https://app.notion.com/p/19-397600df78ee816697f6dbe5ff88b884) |
| 20 | 第二关 | 8,506 | [Markdown](docs/novel-journey/chapters/第020章-第二关.md) · [Notion](https://app.notion.com/p/20-397600df78ee81ae935cf98911e739f3) |
| 21 | 第三关 | 8,942 | [Markdown](docs/novel-journey/chapters/第021章-第三关.md) · [Notion](https://app.notion.com/p/21-397600df78ee81808e73c1023166ef1d) |
| 22 | 晋升内门 | 8,287 | [Markdown](docs/novel-journey/chapters/第022章-晋升内门.md) · [Notion](https://app.notion.com/p/22-397600df78ee817388e7c31aa696fa5c) |
| 23 | 内门风波 | 8,509 | [Markdown](docs/novel-journey/chapters/第023章-内门风波.md) · [Notion](https://app.notion.com/p/23-397600df78ee817d9da6fed3ef37f3f0) |
| 24 | 斗法台 | 8,595 | [Markdown](docs/novel-journey/chapters/第024章-斗法台.md) · [Notion](https://app.notion.com/p/24-397600df78ee81ff8928f29a94bba22b) |
| 25 | 练气九层 | 8,144 | [Markdown](docs/novel-journey/chapters/第025章-练气九层.md) · [Notion](https://app.notion.com/p/25-397600df78ee8166868ef96690f22482) |
| 26 | 筑基灵材 | 8,790 | [Markdown](docs/novel-journey/chapters/第026章-筑基灵材.md) · [Notion](https://app.notion.com/p/26-397600df78ee81209a7be704bb646eae) |
| 27 | 险境 | 8,553 | [Markdown](docs/novel-journey/chapters/第027章-险境.md) · [Notion](https://app.notion.com/p/27-397600df78ee8143b4dae23d121a208a) |
| 28 | 脱困 | 8,225 | [Markdown](docs/novel-journey/chapters/第028章-脱困.md) · [Notion](https://app.notion.com/p/28-397600df78ee81e68e3edd8d67d6d19b) |
| 29 | 筑基丹 | 8,468 | [Markdown](docs/novel-journey/chapters/第029章-筑基丹.md) · [Notion](https://app.notion.com/p/29-397600df78ee819c8eced9d8e3bc2085) |
| 30 | 筑基 | 8,274 | [Markdown](docs/novel-journey/chapters/第030章-筑基.md) · [Notion](https://app.notion.com/p/30-397600df78ee81939447c7f6e77e0ffd) |
| 31 | 筑基稳固 | 8,836 | [Markdown](docs/novel-journey/chapters/第031章-筑基稳固.md) · [Notion](https://app.notion.com/p/31-397600df78ee81abb44bc6790f691aac) |
| 32 | 金丹功法 | 8,371 | [Markdown](docs/novel-journey/chapters/第032章-金丹功法.md) · [Notion](https://app.notion.com/p/32-397600df78ee8179b467d147c176447a) |
| 33 | 王磊阴谋 | 8,514 | [Markdown](docs/novel-journey/chapters/第033章-王磊阴谋.md) · [Notion](https://app.notion.com/p/33-397600df78ee812eb73eff5e31444169) |
| 34 | 灵矿历练 | 8,613 | [Markdown](docs/novel-journey/chapters/第034章-灵矿历练.md) · [Notion](https://app.notion.com/p/34-397600df78ee8148a260cf7ebc7b7992) |
| 35 | 矿脉危机 | 7,412 | [Markdown](docs/novel-journey/chapters/第035章-矿脉危机.md) · [Notion](https://app.notion.com/p/35-397600df78ee81e48a2be3ee8f229ab3) |
| 36 | 灵力凝聚 | 8,681 | [Markdown](docs/novel-journey/chapters/第036章-灵力凝聚.md) · [Notion](https://app.notion.com/p/36-397600df78ee810b9133c7efa9dc082b) |
| 37 | 天才聚集 | 8,669 | [Markdown](docs/novel-journey/chapters/第037章-天才聚集.md) · [Notion](https://app.notion.com/p/37-397600df78ee81e59baed3407910f4cf) |
| 38 | 论道争锋 | 8,685 | [Markdown](docs/novel-journey/chapters/第038章-论道争锋.md) · [Notion](https://app.notion.com/p/38-397600df78ee816b8871c088da4a124d) |
| 39 | 长老质疑 | 8,349 | [Markdown](docs/novel-journey/chapters/第039章-长老质疑.md) · [Notion](https://app.notion.com/p/39-397600df78ee8157b91af90d4c47cb2d) |
| 40 | 苏雪晴的秘密 | 8,439 | [Markdown](docs/novel-journey/chapters/第040章-苏雪晴的秘密.md) · [Notion](https://app.notion.com/p/40-397600df78ee8141a53bcca961fe2051) |
| 41 | 结丹前夕 | 8,435 | [Markdown](docs/novel-journey/chapters/第041章-结丹前夕.md) · [Notion](https://app.notion.com/p/41-397600df78ee811a91f0c0cf8c62de3b) |
| 42 | 凝丹初试 | 8,785 | [Markdown](docs/novel-journey/chapters/第042章-凝丹初试.md) · [Notion](https://app.notion.com/p/42-397600df78ee81b59e21ebe8ab1d9af1) |
| 43 | 结丹失败 | 7,436 | [Markdown](docs/novel-journey/chapters/第043章-结丹失败.md) · [Notion](https://app.notion.com/p/43-397600df78ee8138a7dad36e7d6ad41b) |
| 44 | 重伤昏迷 | 8,905 | [Markdown](docs/novel-journey/chapters/第044章-重伤昏迷.md) · [Notion](https://app.notion.com/p/44-397600df78ee819ba7bfedc4c6748fdb) |
| 45 | 艰难恢复 | 7,023 | [Markdown](docs/novel-journey/chapters/第045章-艰难恢复.md) · [Notion](https://app.notion.com/p/45-397600df78ee81a28b33e5427b6b7333) |
| 46 | 重塑经脉 | 8,850 | [Markdown](docs/novel-journey/chapters/第046章-重塑经脉.md) · [Notion](https://app.notion.com/p/46-397600df78ee81aa91f4d4d75b1f6339) |
| 47 | 修为重聚 | 8,684 | [Markdown](docs/novel-journey/chapters/第047章-修为重聚.md) · [Notion](https://app.notion.com/p/47-397600df78ee8128a936dc9c0afb7e3a) |
| 48 | 真相浮现 | 7,634 | [Markdown](docs/novel-journey/chapters/第048章-真相浮现.md) · [Notion](https://app.notion.com/p/48-397600df78ee8191be36e472ad101a14) |
| 49 | 神秘共鸣 | 8,323 | [Markdown](docs/novel-journey/chapters/第049章-神秘共鸣.md) · [Notion](https://app.notion.com/p/49-397600df78ee811b85d8d5c7e470fe8d) |
| 50 | 二次结丹 | 8,640 | [Markdown](docs/novel-journey/chapters/第050章-二次结丹.md) · [Notion](https://app.notion.com/p/50-397600df78ee815b99c6cc7dae75be88) |
| 51 | 金丹初成 | 7,205 | [Markdown](docs/novel-journey/chapters/第051章-金丹初成.md) · [Notion](https://app.notion.com/p/51-397600df78ee81ec892ad1842458f708) |
| 52 | 金丹威力 | 7,904 | [Markdown](docs/novel-journey/chapters/第052章-金丹威力.md) · [Notion](https://app.notion.com/p/52-397600df78ee817da900dee6312d5f11) |
| 53 | 门派暗流 | 8,560 | [Markdown](docs/novel-journey/chapters/第053章-门派暗流.md) · [Notion](https://app.notion.com/p/53-397600df78ee8191b255e6358a5c508c) |
| 54 | 禁地异动 | 8,694 | [Markdown](docs/novel-journey/chapters/第054章-禁地异动.md) · [Notion](https://app.notion.com/p/54-397600df78ee814780a7ef91c8b01ec4) |
| 55 | 再结金丹 | 7,337 | [Markdown](docs/novel-journey/chapters/第055章-再结金丹.md) · [Notion](https://app.notion.com/p/55-397600df78ee811dbc84e0263cbc1147) |
| 56 | 外敌入侵 | 8,591 | [Markdown](docs/novel-journey/chapters/第056章-外敌入侵.md) · [Notion](https://app.notion.com/p/56-397600df78ee81ef83e8dbde4c3558a0) |
| 57 | 混乱之夜 | 7,634 | [Markdown](docs/novel-journey/chapters/第057章-混乱之夜.md) · [Notion](https://app.notion.com/p/57-397600df78ee819299cde63fba90a6e2) |
| 58 | 追踪线索 | 7,586 | [Markdown](docs/novel-journey/chapters/第058章-追踪线索.md) · [Notion](https://app.notion.com/p/58-397600df78ee81c3b3a1e5282a6a1a08) |
| 59 | 深入虎穴 | 7,428 | [Markdown](docs/novel-journey/chapters/第059章-深入虎穴.md) · [Notion](https://app.notion.com/p/59-397600df78ee8178b50ce5d7019b989c) |
| 60 | 营救 | 8,655 | [Markdown](docs/novel-journey/chapters/第060章-营救.md) · [Notion](https://app.notion.com/p/60-397600df78ee810f8cbed8d14fe8a2c3) |
| 61 | 劫后余生 | 8,238 | [Markdown](docs/novel-journey/chapters/第061章-劫后余生.md) · [Notion](https://app.notion.com/p/61-397600df78ee81089713c3b637ed6c96) |
| 62 | 新境感悟 | 8,022 | [Markdown](docs/novel-journey/chapters/第062章-新境感悟.md) · [Notion](https://app.notion.com/p/62-397600df78ee818d8039c43cf6a76b25) |
| 63 | 暗影门的图谋 | 7,512 | [Markdown](docs/novel-journey/chapters/第063章-暗影门的图谋.md) · [Notion](https://app.notion.com/p/63-397600df78ee818b9935c0697c12f3fc) |
| 64 | 苏雪晴的秘密 | 7,399 | [Markdown](docs/novel-journey/chapters/第064章-苏雪晴的秘密.md) · [Notion](https://app.notion.com/p/64-397600df78ee8135a54bd553353c69f3) |
| 65 | 王磊的下场 | 8,332 | [Markdown](docs/novel-journey/chapters/第065章-王磊的下场.md) · [Notion](https://app.notion.com/p/65-397600df78ee81df98accbc4f6711535) |
| 66 | 禁地探秘 | 8,523 | [Markdown](docs/novel-journey/chapters/第066章-禁地探秘.md) · [Notion](https://app.notion.com/p/66-397600df78ee8118bf3ee1fac7f8b75a) |
| 67 | 上古传承 | 7,786 | [Markdown](docs/novel-journey/chapters/第067章-上古传承.md) · [Notion](https://app.notion.com/p/67-397600df78ee81e3b548c5fe8644ba2f) |
| 68 | 身世之谜 | 7,302 | [Markdown](docs/novel-journey/chapters/第068章-身世之谜.md) · [Notion](https://app.notion.com/p/68-397600df78ee81e48b61e890d9b1ec02) |
| 69 | 元婴感悟 | 8,400 | [Markdown](docs/novel-journey/chapters/第069章-元婴感悟.md) · [Notion](https://app.notion.com/p/69-397600df78ee8140b828cf74027afa02) |
| 70 | 禁地异变 | 8,734 | [Markdown](docs/novel-journey/chapters/第070章-禁地异变.md) · [Notion](https://app.notion.com/p/70-397600df78ee813eb0c9c5220437c24a) |
| 71 | 风暴前夜 | 7,168 | [Markdown](docs/novel-journey/chapters/第071章-风暴前夜.md) · [Notion](https://app.notion.com/p/71-397600df78ee81fc95fefd1f305ba20b) |
| 72 | 凝结元婴 | 8,903 | [Markdown](docs/novel-journey/chapters/第072章-凝结元婴.md) · [Notion](https://app.notion.com/p/72-397600df78ee813f943df6dac7c9c954) |
| 73 | 元婴战力 | 8,570 | [Markdown](docs/novel-journey/chapters/第073章-元婴战力.md) · [Notion](https://app.notion.com/p/73-397600df78ee81ac91b1de831152a763) |
| 74 | 战争爆发 | 8,980 | [Markdown](docs/novel-journey/chapters/第074章-战争爆发.md) · [Notion](https://app.notion.com/p/74-397600df78ee81d0b360f7fa58e4c02a) |
| 75 | 血战南门 | 8,815 | [Markdown](docs/novel-journey/chapters/第075章-血战南门.md) · [Notion](https://app.notion.com/p/75-397600df78ee8179874bf6361992a5e6) |
| 76 | 赵天磊的选择 | 8,620 | [Markdown](docs/novel-journey/chapters/第076章-赵天磊的选择.md) · [Notion](https://app.notion.com/p/76-397600df78ee81f7b6a5fb045b0d5b90) |
| 77 | 友宗驰援 | 7,056 | [Markdown](docs/novel-journey/chapters/第077章-友宗驰援.md) · [Notion](https://app.notion.com/p/77-397600df78ee81188641dd9345aaff7e) |
| 78 | 苏雪晴觉醒 | 8,592 | [Markdown](docs/novel-journey/chapters/第078章-苏雪晴觉醒.md) · [Notion](https://app.notion.com/p/78-397600df78ee817eac63fe52c96886a7) |
| 79 | 古剑之威 | 8,324 | [Markdown](docs/novel-journey/chapters/第079章-古剑之威.md) · [Notion](https://app.notion.com/p/79-397600df78ee811a8152c42b90d88b70) |
| 80 | 暗影撤退 | 8,506 | [Markdown](docs/novel-journey/chapters/第080章-暗影撤退.md) · [Notion](https://app.notion.com/p/80-397600df78ee81ceb442c707c7375ce6) |
| 81 | 心魔初现 | 8,817 | [Markdown](docs/novel-journey/chapters/第081章-心魔初现.md) · [Notion](https://app.notion.com/p/81-397600df78ee816eb5eec2fae9ea447e) |
| 82 | 心魔加深 | 7,212 | [Markdown](docs/novel-journey/chapters/第082章-心魔加深.md) · [Notion](https://app.notion.com/p/82-397600df78ee810fb25be3c549652b74) |
| 83 | 心魔困境 | 7,148 | [Markdown](docs/novel-journey/chapters/第083章-心魔困境.md) · [Notion](https://app.notion.com/p/83-397600df78ee811e8acae8fc48fd70c1) |
| 84 | 本心抉择 | 7,864 | [Markdown](docs/novel-journey/chapters/第084章-本心抉择.md) · [Notion](https://app.notion.com/p/84-397600df78ee81c5a58dd8d24efb9a58) |
| 85 | 破心魔 | 7,119 | [Markdown](docs/novel-journey/chapters/第085章-破心魔.md) · [Notion](https://app.notion.com/p/85-397600df78ee811f8d57fecdaf692ffc) |
| 86 | 心魔劫后 | 7,919 | [Markdown](docs/novel-journey/chapters/第086章-心魔劫后.md) · [Notion](https://app.notion.com/p/86-397600df78ee810090c2eeaf0130e9b0) |
| 87 | 赵天磊和解 | 8,590 | [Markdown](docs/novel-journey/chapters/第087章-赵天磊和解.md) · [Notion](https://app.notion.com/p/87-397600df78ee81ffa98ec7ecb71e89ba) |
| 88 | 禁地封印崩裂 | 8,755 | [Markdown](docs/novel-journey/chapters/第088章-禁地封印崩裂.md) · [Notion](https://app.notion.com/p/88-397600df78ee81219540c533e46cdf02) |
| 89 | 清虚真人的使命 | 8,462 | [Markdown](docs/novel-journey/chapters/第089章-清虚真人的使命.md) · [Notion](https://app.notion.com/p/89-397600df78ee81149f2bf3d761fc4bd6) |
| 90 | 神器现世 | 8,720 | [Markdown](docs/novel-journey/chapters/第090章-神器现世.md) · [Notion](https://app.notion.com/p/90-397600df78ee81508f8ae294bdabe474) |
| 91 | 天衡碎片 | 8,743 | [Markdown](docs/novel-journey/chapters/第091章-天衡碎片.md) · [Notion](https://app.notion.com/p/91-397600df78ee81fca7ebe33c0cc22fba) |
| 92 | 宿命之约 | 7,769 | [Markdown](docs/novel-journey/chapters/第092章-宿命之约.md) · [Notion](https://app.notion.com/p/92-397600df78ee8195a73bf4a012d78180) |
| 93 | 最后的准备 | 7,525 | [Markdown](docs/novel-journey/chapters/第093章-最后的准备.md) · [Notion](https://app.notion.com/p/93-397600df78ee81c6ab4dd22be77d289b) |
| 94 | 元婴巅峰 | 6,972 | [Markdown](docs/novel-journey/chapters/第094章-元婴巅峰.md) · [Notion](https://app.notion.com/p/94-397600df78ee81f4b8c1c3238373dfed) |
| 95 | 身世最终揭秘 | 7,296 | [Markdown](docs/novel-journey/chapters/第095章-身世最终揭秘.md) · [Notion](https://app.notion.com/p/95-397600df78ee81cf9986f45b2ce3314f) |
| 96 | 天劫降临 | 8,122 | [Markdown](docs/novel-journey/chapters/第096章-天劫降临.md) · [Notion](https://app.notion.com/p/96-397600df78ee818e858dc66600955127) |
| 97 | 第九道天雷 | 8,690 | [Markdown](docs/novel-journey/chapters/第097章-第九道天雷.md) · [Notion](https://app.notion.com/p/97-397600df78ee81e3bd73e91697de6e45) |
| 98 | 上界之战 | 8,787 | [Markdown](docs/novel-journey/chapters/第098章-上界之战.md) · [Notion](https://app.notion.com/p/98-397600df78ee813a886df6a0ca8871d7) |
| 99 | 天衡重铸 | 7,104 | [Markdown](docs/novel-journey/chapters/第099章-天衡重铸.md) · [Notion](https://app.notion.com/p/99-397600df78ee81008142f0e8dfd17141) |
| 100 | 飞升 | 7,399 | [Markdown](docs/novel-journey/chapters/第100章-飞升.md) · [Notion](https://app.notion.com/p/100-397600df78ee81528227db55cb64b64f) |
