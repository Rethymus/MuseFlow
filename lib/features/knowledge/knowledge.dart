/// MuseFlow 知识库功能
///
/// 提供角色卡和世界观设定的管理功能，包括：
/// - 角色卡管理：姓名、年龄、外貌、性格、背景、说话风格、人际关系、标签
/// - 世界观设定：世界类型、时代、魔法体系、科技水平、地点、势力组织
/// - 智能搜索：支持模糊搜索角色、世界观、地点和组织
/// - 导入导出：支持JSON格式的批量导入导出
/// - AI集成：自动生成AI写作提示词
///
/// 使用方法：
/// 1. 在main.dart中初始化：`await KnowledgeFeature.initialize()`
/// 2. 添加Provider：`...KnowledgeFeature.getProviders()`
/// 3. 导航到知识库：`KnowledgeFeature.getScreen()`
/// 4. 添加搜索功能：`KnowledgeFeature.getQuickSearch()`

library museflow_knowledge;

// 核心功能
export 'knowledge_screen.dart';
export 'knowledge_init.dart';
export 'knowledge_search.dart';

// 数据模型
export 'character_model.dart';
export 'world_model.dart';

// 服务层
export 'character_service.dart';
export 'world_service.dart';
