/// AI服务统一导出文件
///
/// 使用这个文件可以一次性导入所有AI相关的类和工具

// 基础模型
export '../../models/ai_config.dart';
export '../../models/ai_message.dart';
export '../../models/ai_response.dart';

// 核心服务
export 'ai_service.dart';
export 'ai_adapter.dart';

// 适配器实现
export 'adapters/openai_adapter.dart';
export 'adapters/claude_adapter.dart';
export 'adapters/deepseek_adapter.dart';
export 'adapters/ollama_adapter.dart';

// 工具类
export 'ai_config_manager.dart';

// 使用示例（开发时参考）
export 'ai_usage_example.dart';
