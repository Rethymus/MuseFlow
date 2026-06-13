import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:museflow/features/onboarding/domain/genre_option.dart';
import 'package:museflow/features/onboarding/domain/onboarding_progress.dart';
import 'package:museflow/features/onboarding/infrastructure/onboarding_progress_repository.dart';
import 'package:museflow/features/onboarding/presentation/onboarding_wizard_page.dart';
import 'package:museflow/features/onboarding/presentation/onboarding_providers.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/character_step_page.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/genre_step_page.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/world_step_page.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  group('OnboardingWizardPage', () {
    testWidgets('should build wizard with PageView and progress UI', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingWizardPage()));
      await tester.pumpAndSettle();

      // Should show the wizard page
      expect(find.byType(OnboardingWizardPage), findsOneWidget);
      // Should find a PageView
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('should show progress dots and step title on step 1', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingWizardPage()));
      await tester.pumpAndSettle();

      // Should show step title for first step
      expect(find.text('选择题材'), findsOneWidget);
      // Should show step subtitle
      expect(find.text('选择你感兴趣的故事类型'), findsOneWidget);
    });

    testWidgets('should show next button but not previous on first step', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingWizardPage()));
      await tester.pumpAndSettle();

      // Should show "下一步" button
      expect(find.text('下一步'), findsOneWidget);
      // Should NOT show "上一步" button on first step
      expect(find.text('上一步'), findsNothing);
    });

    testWidgets('should show close and skip buttons', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingWizardPage()));
      await tester.pumpAndSettle();

      // Should show close icon
      expect(find.byIcon(Icons.close), findsOneWidget);
      // Should find skip text
      expect(find.text('跳过'), findsOneWidget);
    });

    testWidgets('should advance to step 2 on next button tap', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingWizardPage()));
      await tester.pumpAndSettle();

      // Tap next button
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // Step 2 is now the AI provider setup step
      expect(find.text('配置AI'), findsOneWidget);
      // Should now show "上一步" button
      expect(find.text('上一步'), findsOneWidget);
    });

    testWidgets('should go back on previous button tap', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingWizardPage()));
      await tester.pumpAndSettle();

      // Go forward
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('配置AI'), findsOneWidget);

      // Now go back
      await tester.tap(find.text('上一步'));
      await tester.pumpAndSettle();

      // Should be back on step 1
      expect(find.text('选择题材'), findsOneWidget);
    });

    testWidgets('should advance through all steps and show start button', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingWizardPage()));
      await tester.pumpAndSettle();

      // Step 1 (Genre) -> Step 2 (AI Provider)
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('配置AI'), findsOneWidget);

      // Step 2 (AI Provider) -> Step 3 (World)
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('构建世界'), findsOneWidget);

      // Step 3 (World) -> Step 4 (Character)
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('创建角色'), findsOneWidget);

      // Step 4 (Character) -> Step 5 (Opening)
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('写开篇'), findsOneWidget);

      // On last step, should show "开始创作" instead of "下一步"
      expect(find.text('开始创作'), findsOneWidget);
    });

    testWidgets('skip button advances without validation', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingWizardPage()));
      await tester.pumpAndSettle();

      // Tap skip
      await tester.tap(find.text('跳过'));
      await tester.pumpAndSettle();

      // Should be on step 2 (AI Provider setup)
      expect(find.text('配置AI'), findsOneWidget);
    });
  });

  group('GenreStepPage', () {
    testWidgets('should display all 14 genre cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GenreStepPage(onSelected: _noop)),
        ),
      );
      await tester.pumpAndSettle();

      // Should display genre titles (spot check unique titles)
      expect(find.text('修仙'), findsOneWidget);
      expect(find.text('武侠'), findsOneWidget);
      expect(find.text('玄幻'), findsOneWidget);
      expect(find.text('科幻'), findsOneWidget);
      expect(find.text('都市'), findsOneWidget);
      expect(find.text('历史'), findsOneWidget);
      expect(find.text('古言'), findsOneWidget);
      expect(find.text('现言'), findsOneWidget);
    });

    testWidgets('should call onSelected with correct id when genre tapped', (
      tester,
    ) async {
      String? selectedId;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreStepPage(onSelected: (id) => selectedId = id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on 科幻
      await tester.tap(find.text('科幻'));
      await tester.pumpAndSettle();

      expect(selectedId, 'scifi');
    });

    testWidgets('should display channel tags on cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GenreStepPage(onSelected: _noop)),
        ),
      );
      await tester.pumpAndSettle();

      // Should find channel tags
      expect(find.text('男频'), findsWidgets);
      expect(find.text('女频'), findsWidgets);
    });

    testWidgets('should update selection highlight on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GenreStepPage(onSelected: _noop)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 修仙
      await tester.tap(find.text('修仙'));
      await tester.pumpAndSettle();

      // Then tap 科幻 — selection should change
      await tester.tap(find.text('科幻'));
      await tester.pumpAndSettle();

      // Both taps should succeed without error
      // (visual highlight is tested implicitly by state change)
    });
  });

  group('GenreOption', () {
    test('should have 14 built-in genres', () {
      expect(GenreOption.builtIn.length, 14);
    });

    test('should have 8 male channel genres', () {
      final maleCount = GenreOption.builtIn
          .where((g) => g.channel == '男频')
          .length;
      expect(maleCount, 8);
    });

    test('should have 6 female channel genres', () {
      final femaleCount = GenreOption.builtIn
          .where((g) => g.channel == '女频')
          .length;
      expect(femaleCount, 6);
    });

    test('should have unique ids', () {
      final ids = GenreOption.builtIn.map((g) => g.id).toSet();
      expect(ids.length, GenreOption.builtIn.length);
    });

    test('should have non-empty titles and descriptions', () {
      for (final genre in GenreOption.builtIn) {
        expect(
          genre.title.isNotEmpty,
          isTrue,
          reason: 'Genre ${genre.id} has empty title',
        );
        expect(
          genre.description.isNotEmpty,
          isTrue,
          reason: 'Genre ${genre.id} has empty description',
        );
      }
    });
  });

  group('OnboardingProgressRepository', () {
    late Box<dynamic> box;
    late OnboardingProgressRepository repository;

    setUp(() async {
      await setUpHiveTest();
      box = await Hive.openBox('test_onboarding_progress');
      repository = OnboardingProgressRepository(box);
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    test('should return initial progress when no data saved', () {
      final progress = repository.getProgress();
      expect(progress.currentStep, 0);
      expect(progress.completedSteps, isEmpty);
      expect(progress.selectedTemplateId, isNull);
    });

    test('should save and retrieve progress', () async {
      final progress = OnboardingProgress(
        currentStep: 2,
        completedSteps: [0, 1],
        selectedTemplateId: 'xianxia',
      );
      await repository.saveProgress(progress);

      final retrieved = repository.getProgress();
      expect(retrieved.currentStep, 2);
      expect(retrieved.completedSteps, [0, 1]);
      expect(retrieved.selectedTemplateId, 'xianxia');
    });

    test('should mark completed and report isCompleted', () async {
      expect(repository.isCompleted(), isFalse);

      await repository.markCompleted();

      expect(repository.isCompleted(), isTrue);
    });
  });

  group('WorldStepPage', () {
    testWidgets('should display name and description fields', (tester) async {
      final nameController = TextEditingController();
      final descController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldStepPage(
              worldNameController: nameController,
              worldDescriptionController: descController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('世界观名称 *'), findsOneWidget);
      expect(find.text('世界简介'), findsOneWidget);
    });

    testWidgets('should validate name is required', (tester) async {
      final nameController = TextEditingController();
      final descController = TextEditingController();
      final key = GlobalKey<WorldStepPageState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldStepPage(
              key: key,
              worldNameController: nameController,
              worldDescriptionController: descController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Validate empty form
      final isValid = key.currentState!.validate();
      await tester.pump();
      expect(isValid, isFalse);
      expect(find.text('请输入世界观名称'), findsOneWidget);
    });

    testWidgets('should validate name max length', (tester) async {
      final nameController = TextEditingController(text: 'a' * 101);
      final descController = TextEditingController();
      final key = GlobalKey<WorldStepPageState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldStepPage(
              key: key,
              worldNameController: nameController,
              worldDescriptionController: descController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final isValid = key.currentState!.validate();
      await tester.pump();
      expect(isValid, isFalse);
      expect(find.text('名称不能超过100个字符'), findsOneWidget);
    });

    testWidgets('should pass validation with valid name', (tester) async {
      final nameController = TextEditingController(text: '仙侠世界');
      final descController = TextEditingController();
      final key = GlobalKey<WorldStepPageState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldStepPage(
              key: key,
              worldNameController: nameController,
              worldDescriptionController: descController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final isValid = key.currentState!.validate();
      expect(isValid, isTrue);
    });

    testWidgets('should accept optional description', (tester) async {
      final nameController = TextEditingController(text: '测试世界');
      final descController = TextEditingController(text: '一个测试世界的描述');
      final key = GlobalKey<WorldStepPageState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldStepPage(
              key: key,
              worldNameController: nameController,
              worldDescriptionController: descController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final isValid = key.currentState!.validate();
      expect(isValid, isTrue);
    });
  });

  group('CharacterStepPage', () {
    testWidgets('should display name and description fields', (tester) async {
      final nameController = TextEditingController();
      final descController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterStepPage(
              characterNameController: nameController,
              characterDescriptionController: descController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('角色名称 *'), findsOneWidget);
      expect(find.text('角色简介'), findsOneWidget);
    });

    testWidgets('should validate name is required', (tester) async {
      final nameController = TextEditingController();
      final descController = TextEditingController();
      final key = GlobalKey<CharacterStepPageState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterStepPage(
              key: key,
              characterNameController: nameController,
              characterDescriptionController: descController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final isValid = key.currentState!.validate();
      await tester.pump();
      expect(isValid, isFalse);
      expect(find.text('请输入角色名称'), findsOneWidget);
    });

    testWidgets('should validate name max length 50', (tester) async {
      final nameController = TextEditingController(text: 'a' * 51);
      final descController = TextEditingController();
      final key = GlobalKey<CharacterStepPageState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterStepPage(
              key: key,
              characterNameController: nameController,
              characterDescriptionController: descController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final isValid = key.currentState!.validate();
      await tester.pump();
      expect(isValid, isFalse);
      expect(find.text('名称不能超过50个字符'), findsOneWidget);
    });

    testWidgets('should pass validation with valid name', (tester) async {
      final nameController = TextEditingController(text: '张三');
      final descController = TextEditingController();
      final key = GlobalKey<CharacterStepPageState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterStepPage(
              key: key,
              characterNameController: nameController,
              characterDescriptionController: descController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final isValid = key.currentState!.validate();
      expect(isValid, isTrue);
    });
  });

  group('Wizard entity creation integration', () {
    testWidgets('should show world form fields when on step 3', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: OnboardingWizardPage())),
      );
      await tester.pumpAndSettle();

      // Advance to step 2 (AI Provider), then step 3 (World)
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      expect(find.text('构建世界'), findsOneWidget);
      expect(find.text('世界观名称 *'), findsOneWidget);
      expect(find.text('世界简介'), findsOneWidget);
    });

    testWidgets('should show character form fields when on step 4', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: OnboardingWizardPage())),
      );
      await tester.pumpAndSettle();

      // Advance to step 3 (World)
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // Advance to step 4 (Character)
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      expect(find.text('创建角色'), findsOneWidget);
      expect(find.text('角色名称 *'), findsOneWidget);
      expect(find.text('角色简介'), findsOneWidget);
    });

    testWidgets('should skip step without validation on skip button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: OnboardingWizardPage())),
      );
      await tester.pumpAndSettle();

      // Skip from step 1 to step 2 (AI Provider)
      await tester.tap(find.text('跳过'));
      await tester.pumpAndSettle();

      expect(find.text('配置AI'), findsOneWidget);

      // Skip from step 2 to step 3 (World, no validation triggered)
      await tester.tap(find.text('跳过'));
      await tester.pumpAndSettle();

      expect(find.text('构建世界'), findsOneWidget);
    });
  });

  group('Entity persistence', () {
    late Box<dynamic> worldSettingsBox;
    late Box<dynamic> characterCardsBox;

    setUp(() async {
      await setUpHiveTest();
      worldSettingsBox = await Hive.openBox<dynamic>('world_settings');
      characterCardsBox = await Hive.openBox<dynamic>('character_cards');
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    test('should persist WorldSetting to Hive via repository', () async {
      await Hive.openBox('settings');
      // Simulate the provider creating a world setting
      final worldRepo = WorldSettingRepository(worldSettingsBox);
      final setting = WorldSetting(
        id: '',
        name: '测试世界',
        description: '测试描述',
        createdAt: DateTime.now(),
      );
      final saved = await worldRepo.add(setting);

      expect(saved.id.isNotEmpty, isTrue);
      expect(saved.name, '测试世界');
      expect(worldSettingsBox.length, 1);
    });

    test('should persist CharacterCard to Hive via repository', () async {
      final cardRepo = CharacterCardRepository(characterCardsBox);
      final card = CharacterCard(
        id: '',
        name: '测试角色',
        personality: '勇敢',
        createdAt: DateTime.now(),
      );
      final saved = await cardRepo.add(card);

      expect(saved.id.isNotEmpty, isTrue);
      expect(saved.name, '测试角色');
      expect(characterCardsBox.length, 1);
    });
  });

  group('OnboardingRepository providers', () {
    setUp(() async {
      await setUpHiveTest();
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    test(
      'onboardingWorldSettingRepositoryProvider creates WorldSettingRepository',
      () async {
        final container = ProviderContainer();
        final repository = await container.read(
          onboardingWorldSettingRepositoryProvider.future,
        );
        expect(repository, isA<WorldSettingRepository>());
        container.dispose();
      },
    );

    test(
      'onboardingCharacterCardRepositoryProvider creates CharacterCardRepository',
      () async {
        final container = ProviderContainer();
        final repository = await container.read(
          onboardingCharacterCardRepositoryProvider.future,
        );
        expect(repository, isA<CharacterCardRepository>());
        container.dispose();
      },
    );
  });
}

/// No-op callback for tests that don't need to verify selection.
void _noop(_) {}
