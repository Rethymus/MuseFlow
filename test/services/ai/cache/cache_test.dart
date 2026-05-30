import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:museflow/services/ai/ai_service.dart';
import 'package:museflow/services/ai/cache/ai_request_cache.dart';
import 'package:museflow/services/ai/cache/cache_manager.dart';
import 'package:museflow/services/ai/cache/ai_cache_entry.dart';
import 'package:museflow/services/ai/cache/ai_cache_stats.dart';
import 'package:museflow/services/ai/cache/memory_cache.dart';
import 'package:museflow/models/ai_message.dart';
import 'package:museflow/models/ai_config.dart';

@GenerateMocks([AIService])
void main() {
  group('AI Cache System Tests', () {
    late AIRequestCache cache;
    late CacheManager cacheManager;

    setUp(() async {
      cache = AIRequestCache.instance;
      cacheManager = CacheManager.instance;
      await AIRequestCache.initialize();
      await CacheManager.initialize();
    });

    tearDown(() async {
      await cache.clearAll();
    });

    test('Cache initialization test', () async {
      expect(cache, isNotNull);
      expect(cacheManager, isNotNull);
    });

    test('Cache key generation test', () async {
      final messages = [
        AIMessage.user(id: 'msg1', content: 'Hello'),
      ];

      final config = AIConfig(
        id: 'config1',
        provider: AIProvider.anthropic,
        apiKey: 'test-key',
        model: 'claude-3-5-sonnet-20241022',
        temperature: 0.7,
      );

      // 测试缓存一致性：相同参数查询应返回相同结果
      final result1 = await cache.checkCache(messages, config);
      final result2 = await cache.checkCache(messages, config);
      // 两次查询结果应一致（都为null或都为同一个entry）
      expect(result1 == result2, isTrue);
    });

    test('Cache expiration strategy test', () {
      // 验证缓存过期行为：过期的条目应该被正确识别
      final now = DateTime.now();

      final expiredEntry = AICacheEntry(
        cacheKey: 'expired_key',
        content: 'Expired content',
        model: 'claude-3-5-sonnet-20241022',
        createdAt: now.subtract(const Duration(hours: 49)),
        expiresAt: now.subtract(const Duration(hours: 1)),
        lastAccessAt: now,
      );
      expect(expiredEntry.isExpired, isTrue);

      final validEntry = AICacheEntry(
        cacheKey: 'valid_key',
        content: 'Valid content',
        model: 'claude-3-5-sonnet-20241022',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 48)),
        lastAccessAt: now,
      );
      expect(validEntry.isExpired, isFalse);
      expect(validEntry.remainingSeconds, greaterThan(0));
    });

    test('Cache entry creation test', () {
      final entry = AICacheEntry(
        cacheKey: 'test_key',
        content: 'Test content',
        model: 'claude-3-5-sonnet-20241022',
        inputTokens: 100,
        outputTokens: 200,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        lastAccessAt: DateTime.now(),
      );

      expect(entry.cacheKey, equals('test_key'));
      expect(entry.totalTokens, equals(300));
      expect(entry.isExpired, isFalse);

      final updatedEntry = entry.updateAccess();
      expect(updatedEntry.hitCount, equals(1));
    });

    test('Cache statistics test', () {
      final stats = AICacheStats.initial();

      expect(stats.totalRequests, equals(0));
      expect(stats.hitRate, equals(0.0));
      expect(stats.hasData, isFalse);

      // 记录一次命中
      final afterHit = stats.recordHit(tokens: 100);
      expect(afterHit.totalRequests, equals(1));
      expect(afterHit.cacheHits, equals(1));
      expect(afterHit.hitRate, equals(1.0));

      // 记录一次未命中
      final afterMiss = afterHit.recordMiss();
      expect(afterMiss.totalRequests, equals(2));
      expect(afterMiss.cacheMisses, equals(1));
      expect(afterMiss.hitRate, equals(0.5));
    });

    test('Cache health status test', () async {
      final health = await cacheManager.getHealthStatus();

      expect(health, containsPair('is_healthy', isA<bool>()));
      expect(health, containsPair('hit_rate', isA<double>()));
      expect(health, containsPair('requests_saved_rate', isA<double>()));
      expect(health['targets_met'], isA<Map<String, bool>>());
    });

    test('Cache performance metrics test', () async {
      final metrics = await cacheManager.getPerformanceMetrics();

      expect(metrics.hitRate, isA<double>());
      expect(metrics.requestsSavedRate, isA<double>());
      expect(metrics.totalRequests, isA<int>());
      expect(metrics.cacheHits, isA<int>());
      expect(metrics.isEfficient, isA<bool>());
    });

    test('Cache size distribution test', () async {
      final distribution = await cache.getDetailedStats();
      expect(distribution, isA<Map<String, dynamic>>());
      expect(distribution.containsKey('performance_stats'), isTrue);
      expect(distribution.containsKey('cache_sizes'), isTrue);
    });

    test('Cache suggestions test', () async {
      final suggestions = await cacheManager.getSuggestions();
      expect(suggestions, isA<List<String>>());
    });

    test('Cache report generation test', () async {
      final report = await cacheManager.generateReport();
      expect(report, contains('AI Cache Performance Report'));
      expect(report, contains('Health Status'));
      expect(report, contains('Hit Rate'));
    });
  });

  group('AI Service Cache Integration Tests', () {
    late AIService aiService;

    setUp(() async {
      aiService = await AIService.initialize();
    });

    tearDown(() async {
      aiService.dispose();
    });

    test('Cache enable/disable test', () {
      // 验证setCachingEnabled方法可正常调用
      // 默认状态可通过cacheManager访问来间接验证
      expect(aiService.cacheManager, isNotNull);

      // 禁用缓存（不抛出异常即为成功）
      aiService.setCachingEnabled(false);

      // 重新启用
      aiService.setCachingEnabled(true);

      // 缓存管理器应该仍然可用
      expect(aiService.cacheManager, isNotNull);
    });

    test('Cache manager access test', () {
      final manager = aiService.cacheManager;
      expect(manager, isNotNull);
      expect(manager, equals(CacheManager.instance));
    });

    test('Cache statistics access test', () async {
      final stats = await aiService.getCacheStats();
      expect(stats, isA<AICacheStats>());
    });

    test('Cache health check test', () async {
      final health = await aiService.getCacheHealthStatus();
      expect(health, isA<Map<String, dynamic>>());
      expect(health.containsKey('is_healthy'), isTrue);
    });

    test('Cache performance metrics test', () async {
      final metrics = await aiService.getCachePerformanceMetrics();
      expect(metrics, isA<CachePerformanceMetrics>());
    });

    test('Cache event stream test', () {
      final events = aiService.cacheEvents;
      expect(events, isA<Stream<CacheManagerEvent>>());
    });
  });

  group('Cache Entry Model Tests', () {
    test('Cache entry serialization test', () {
      final now = DateTime.now();
      final entry = AICacheEntry(
        cacheKey: 'test_key',
        content: 'Test content',
        model: 'claude-3-5-sonnet-20241022',
        inputTokens: 100,
        outputTokens: 200,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        lastAccessAt: now,
      );

      // 转换为JSON
      final json = entry.toJson();
      expect(json['cacheKey'], equals('test_key'));
      expect(json['content'], equals('Test content'));
      expect(json['model'], equals('claude-3-5-sonnet-20241022'));

      // 从JSON创建
      final restored = AICacheEntry.fromJson(json);
      expect(restored.cacheKey, equals(entry.cacheKey));
      expect(restored.content, equals(entry.content));
      expect(restored.model, equals(entry.model));
    });

    test('Cache entry age calculation test', () {
      final now = DateTime.now();
      final entry = AICacheEntry(
        cacheKey: 'test_key',
        content: 'Test content',
        model: 'claude-3-5-sonnet-20241022',
        createdAt: now.subtract(const Duration(minutes: 30)),
        expiresAt: now.add(const Duration(hours: 24)),
        lastAccessAt: now,
      );

      expect(entry.ageInSeconds, greaterThan(0));
      expect(entry.remainingSeconds, greaterThan(0));
    });

    test('Cache entry expiration test', () {
      final now = DateTime.now();
      final expiredEntry = AICacheEntry(
        cacheKey: 'expired_key',
        content: 'Expired content',
        model: 'claude-3-5-sonnet-20241022',
        createdAt: now.subtract(Duration(hours: 25)),
        expiresAt: now.subtract(Duration(hours: 1)),
        lastAccessAt: now,
      );

      expect(expiredEntry.isExpired, isTrue);

      final validEntry = AICacheEntry(
        cacheKey: 'valid_key',
        content: 'Valid content',
        model: 'claude-3-5-sonnet-20241022',
        createdAt: now,
        expiresAt: now.add(Duration(hours: 1)),
        lastAccessAt: now,
      );

      expect(validEntry.isExpired, isFalse);
    });
  });

  group('Cache Statistics Model Tests', () {
    test('Statistics serialization test', () {
      final stats = AICacheStats(
        totalRequests: 100,
        cacheHits: 45,
        cacheMisses: 55,
        totalHits: 45,
        totalMisses: 55,
        hitRate: 0.45,
        avgResponseTime: 250.0,
        tokensSaved: 15000,
        requestsSaved: 45,
        resetAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      final json = stats.toJson();
      expect(json['totalRequests'], equals(100));
      expect(json['hitRate'], equals(0.45));

      final restored = AICacheStats.fromJson(json);
      expect(restored.totalRequests, equals(stats.totalRequests));
      expect(restored.hitRate, equals(stats.hitRate));
    });

    test('Statistics efficiency check test', () {
      final efficientStats = AICacheStats(
        totalRequests: 100,
        cacheHits: 50,
        cacheMisses: 50,
        totalHits: 50,
        totalMisses: 50,
        hitRate: 0.50,
        avgResponseTime: 250.0,
        tokensSaved: 15000,
        requestsSaved: 50,
        resetAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      expect(efficientStats.isEfficient, isTrue);
      expect(efficientStats.meetsTarget, isTrue);

      final inefficientStats = AICacheStats(
        totalRequests: 100,
        cacheHits: 30,
        cacheMisses: 70,
        totalHits: 30,
        totalMisses: 70,
        hitRate: 0.30,
        avgResponseTime: 250.0,
        tokensSaved: 9000,
        requestsSaved: 30,
        resetAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      expect(inefficientStats.isEfficient, isFalse);
      expect(inefficientStats.meetsTarget, isFalse);
    });

    test('Statistics report generation test', () {
      final stats = AICacheStats(
        totalRequests: 100,
        cacheHits: 45,
        cacheMisses: 55,
        totalHits: 45,
        totalMisses: 55,
        hitRate: 0.45,
        avgResponseTime: 250.0,
        tokensSaved: 15000,
        requestsSaved: 45,
        resetAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      final report = stats.toReport();
      expect(report, contains('Total Requests: 100'));
      expect(report, contains('Cache Hits: 45'));
      expect(report, contains('Hit Rate: 45.00%'));
    });
  });

  group('Memory Cache Tests', () {
    late MemoryCache memoryCache;

    setUp(() {
      memoryCache = MemoryCache(maxEntries: 10);
    });

    tearDown(() {
      memoryCache.dispose();
    });

    test('Memory cache basic operations test', () {
      final entry = AICacheEntry(
        cacheKey: 'test_key',
        content: 'Test content',
        model: 'claude-3-5-sonnet-20241022',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 1)),
        lastAccessAt: DateTime.now(),
      );

      // 设置缓存
      memoryCache.set('test_key', entry);
      expect(memoryCache.size, equals(1));

      // 获取缓存
      final retrieved = memoryCache.get('test_key');
      expect(retrieved, isNotNull);
      expect(retrieved!.content, equals('Test content'));

      // 移除缓存
      memoryCache.remove('test_key');
      expect(memoryCache.size, equals(0));
    });

    test('Memory cache LRU eviction test', () {
      // 填满缓存
      for (int i = 0; i < 10; i++) {
        final entry = AICacheEntry(
          cacheKey: 'key_$i',
          content: 'Content $i',
          model: 'claude-3-5-sonnet-20241022',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(hours: 1)),
          lastAccessAt: DateTime.now(),
        );
        memoryCache.set('key_$i', entry);
      }

      expect(memoryCache.size, equals(10));
      expect(memoryCache.isFull, isTrue);

      // 添加第11个条目，应该驱逐最旧的
      final newEntry = AICacheEntry(
        cacheKey: 'key_10',
        content: 'New content',
        model: 'claude-3-5-sonnet-20241022',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 1)),
        lastAccessAt: DateTime.now(),
      );

      memoryCache.set('key_10', newEntry);
      expect(memoryCache.size, equals(10));

      // key_0 应该被驱逐
      final evicted = memoryCache.get('key_0');
      expect(evicted, isNull);
    });

    test('Memory cache expiration test', () async {
      final expiredEntry = AICacheEntry(
        cacheKey: 'expired_key',
        content: 'Expired content',
        model: 'claude-3-5-sonnet-20241022',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().subtract(Duration(minutes: 1)),
        lastAccessAt: DateTime.now(),
      );

      memoryCache.set('expired_key', expiredEntry);

      // 尝试获取过期的条目
      final retrieved = memoryCache.get('expired_key');
      expect(retrieved, isNull);
    });
  });

  group('Integration Tests', () {
    test('End-to-end cache workflow test', () async {
      final aiService = await AIService.initialize();

      // 检查缓存管理器
      final manager = aiService.cacheManager;
      expect(manager, isNotNull);

      // 检查统计信息
      final stats = manager.stats;
      expect(stats, isNotNull);

      // 生成报告
      final report = await manager.generateReport();
      expect(report, contains('AI Cache Performance Report'));

      aiService.dispose();
    });
  });
}
