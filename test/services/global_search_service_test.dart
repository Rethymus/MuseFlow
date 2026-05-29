import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/services/global_search_service.dart';
import 'package:museflow/services/secure_storage_service.dart';
import 'package:museflow/features/knowledge/character_service.dart';
import 'package:museflow/features/knowledge/world_service.dart';

/// GlobalSearchService测试
/// 验证全局搜索服务的核心功能
void main() {
  group('GlobalSearchService基础测试', () {
    late GlobalSearchService searchService;

    setUp(() {
      // 创建服务实例，不依赖Hive初始化
      final storageService = SecureStorageService();
      final characterService = CharacterService();
      final worldService = WorldService();

      searchService = GlobalSearchService(
        storageService: storageService,
        characterService: characterService,
        worldService: worldService,
      );
    });

    test('搜索服务初始化', () {
      expect(searchService, isNotNull);
      expect(searchService, isA<GlobalSearchService>());
    });

    test('搜索方法存在验证', () {
      const query = '测试搜索';

      expect(
        () => searchService.search(query),
        returnsNormally,
      );
    });

    test('空查询处理', () {
      expect(() => searchService.search(''), returnsNormally);
    });

    test('长查询处理', () {
      const longQuery = 'A' * 1000;

      expect(() => searchService.search(longQuery), returnsNormally);
    });
  });

  group('GlobalSearchService功能测试', () {
    late GlobalSearchService searchService;

    setUp(() {
      final storageService = SecureStorageService();
      final characterService = CharacterService();
      final worldService = WorldService();

      searchService = GlobalSearchService(
        storageService: storageService,
        characterService: characterService,
        worldService: worldService,
      );
    });

    test('搜索笔记功能', () async {
      const query = '笔记';

      final results = await searchService.search(query);

      expect(results, isList);
      expect(results, isA<List>());
    });

    test('搜索角色功能', () async {
      const query = '角色';

      final results = await searchService.search(query);

      expect(results, isList);
    });

    test('搜索世界观功能', () async {
      const query = '世界';

      final results = await searchService.search(query);

      expect(results, isList);
    });

    test('多关键词搜索', () async {
      const query = '笔记 角色';

      final results = await searchService.search(query);

      expect(results, isList);
    });

    test('特殊字符搜索', () async {
      const query = '测试:emoji🎉';

      final results = await searchService.search(query);

      expect(results, isList);
    });
  });

  group('GlobalSearchService性能测试', () {
    late GlobalSearchService searchService;

    setUp(() {
      final storageService = SecureStorageService();
      final characterService = CharacterService();
      final worldService = WorldService();

      searchService = GlobalSearchService(
        storageService: storageService,
        characterService: characterService,
        worldService: worldService,
      );
    });

    test('搜索响应时间测试', () async {
      const query = '性能测试';

      final stopwatch = Stopwatch()..start();
      await searchService.search(query);
      stopwatch.stop();

      // 搜索应在合理时间内完成（<5秒）
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('并发搜索测试', () async {
      const queries = ['查询1', '查询2', '查询3'];

      final stopwatch = Stopwatch()..start();
      final results = await Future.wait(
        queries.map((q) => searchService.search(q)),
      );
      stopwatch.stop();

      expect(results.length, 3);
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });
  });

  group('GlobalSearchService缓存测试', () {
    late GlobalSearchService searchService;

    setUp(() {
      final storageService = SecureStorageService();
      final characterService = CharacterService();
      final worldService = WorldService();

      searchService = GlobalSearchService(
        storageService: storageService,
        characterService: characterService,
        worldService: worldService,
      );
    });

    test('缓存功能验证', () async {
      const query = '缓存测试';

      // 第一次搜索
      await searchService.search(query);

      // 第二次搜索应该更快（使用缓存）
      final stopwatch1 = Stopwatch()..start();
      await searchService.search(query);
      stopwatch1.stop();

      final time1 = stopwatch1.elapsedMilliseconds;

      // 第三次搜索
      final stopwatch2 = Stopwatch()..start();
      await searchService.search(query);
      stopwatch2.stop();

      final time2 = stopwatch2.elapsedMilliseconds;

      // 缓存命中后应该更快或相似
      expect(time2, lessThanOrEqualTo(time1 + 100));
    });

    test('清除缓存功能', () {
      expect(() => searchService.clearCache(), returnsNormally);
    });
  });
}
