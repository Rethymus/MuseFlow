import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/onboarding/domain/genre_option.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';
import 'package:museflow/features/onboarding/presentation/onboarding_providers.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/character_step_page.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/genre_step_page.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/opening_step_page.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/provider_step_page.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/world_step_page.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/shared/widgets/app_toast.dart';

/// Full-screen onboarding wizard with 4-step PageView navigation.
///
/// Steps: Genre -> World -> Character -> Opening
/// Steps: genre selection, world creation, character creation, AI opening.
class OnboardingWizardPage extends ConsumerStatefulWidget {
  const OnboardingWizardPage({super.key});

  @override
  ConsumerState<OnboardingWizardPage> createState() =>
      _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends ConsumerState<OnboardingWizardPage> {
  late PageController _pageController;
  int _currentStep = 0;

  /// Total number of wizard steps.
  static const int _totalSteps = 5;

  /// Step titles displayed in the progress area.
  static const List<String> _stepTitles = [
    '选择题材',
    '配置AI',
    '构建世界',
    '创建角色',
    '写开篇',
  ];

  static const List<String> _stepSubtitles = [
    '选择你感兴趣的故事类型',
    '设置AI模型，开启智能辅助',
    '为你的世界命名，让故事有根基',
    '创造你的主角，给故事一个灵魂',
    '选择一种开篇风格，开始你的故事',
  ];

  // Controllers for WorldStepPage fields.
  final _worldNameController = TextEditingController();
  final _worldDescriptionController = TextEditingController();

  // Controllers for CharacterStepPage fields.
  final _characterNameController = TextEditingController();
  final _characterDescriptionController = TextEditingController();
  OpeningVariant? _selectedOpeningVariant;
  String _selectedGenreName = '通用';

  // GlobalKey accessors for step form validation.
  final _worldStepKey = GlobalKey<WorldStepPageState>();
  final _characterStepKey = GlobalKey<CharacterStepPageState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _worldNameController.dispose();
    _worldDescriptionController.dispose();
    _characterNameController.dispose();
    _characterDescriptionController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentStep = page;
    });
  }

  Future<void> _nextStep() async {
    if (_currentStep >= _totalSteps - 1) {
      await _completeOnboarding();
      return;
    }

    // Step-specific logic when advancing FROM a step
    switch (_currentStep) {
      case 2: // Advancing from World step -> create WorldSetting entity
        final isValid = _worldStepKey.currentState?.validate() ?? false;
        if (isValid && _worldNameController.text.trim().isNotEmpty) {
          await _createWorldSetting();
        }
        break;
      case 3: // Advancing from Character step -> create CharacterCard entity
        final isValid = _characterStepKey.currentState?.validate() ?? false;
        if (isValid && _characterNameController.text.trim().isNotEmpty) {
          await _createCharacterCard();
        }
        break;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _previousStep() async {
    if (_currentStep <= 0) return;
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _skipStep() async {
    if (_currentStep >= _totalSteps - 1) {
      await _completeOnboarding();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _createWorldSetting() async {
    try {
      final repository = await ref.read(
        onboardingWorldSettingRepositoryProvider.future,
      );
      final setting = WorldSetting(
        id: '',
        name: _worldNameController.text.trim(),
        description: _worldDescriptionController.text.trim(),
        createdAt: DateTime.now(),
      );
      await repository.add(setting);
    } catch (e) {
      if (mounted) {
        showAppToast(context, message: '世界观创建失败: $e');
      }
    }
  }

  Future<void> _createCharacterCard() async {
    try {
      final repository = await ref.read(
        onboardingCharacterCardRepositoryProvider.future,
      );
      final card = CharacterCard(
        id: '',
        name: _characterNameController.text.trim(),
        personality: _characterDescriptionController.text.trim(),
        createdAt: DateTime.now(),
      );
      await repository.add(card);
    } catch (e) {
      if (mounted) {
        showAppToast(context, message: '角色创建失败: $e');
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final selectedOpening = _selectedOpeningVariant;

    // Create the user's first manuscript so the wizard's choices land in a
    // concrete place: previously the wizard only created orphaned knowledge
    // entities and inserted the opening into an editor that did not exist
    // (SE-5). The opening becomes the first chapter's content.
    String? manuscriptId;
    try {
      final repository = await ref.read(manuscriptRepositoryProvider.future);
      final chapters = await ref.read(chapterRepositoryProvider.future);
      final now = DateTime.now();
      final worldName = _worldNameController.text.trim();
      final title = worldName.isNotEmpty ? worldName : '我的第一部作品';

      final manuscript = await repository.add(
        Manuscript(
          id: '',
          title: title,
          genre: _selectedGenreName,
          coverLetter: title.substring(0, title.length.clamp(0, 2)),
          status: '构思中',
          targetWordCount: 50000,
          createdAt: now,
          updatedAt: now,
        ),
      );
      manuscriptId = manuscript.id;

      await chapters.add(
        Chapter(
          id: '',
          manuscriptId: manuscript.id,
          title: '第一章',
          sortOrder: 1,
          status: '草稿',
          documentContent: selectedOpening?.text ?? '',
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (selectedOpening != null) {
        ref.read(writingStatsCollectorProvider.future).then((collector) {
          collector.recordAiInsertion(
            selectedOpening.text,
            projectId: manuscript.id,
          );
        });
      }
      // Make the library list pick up the new manuscript.
      ref.invalidate(manuscriptNotifierProvider);
    } catch (_) {
      // Finishing onboarding must never be blocked by persistence issues;
      // fall through and land on the library instead of the new editor.
    }

    try {
      final repository = await ref.read(onboardingRepositoryProvider.future);
      await repository.markCompleted();
    } catch (_) {
      // Even if persistence fails, navigate away so user is not stuck.
    }
    if (!mounted) return;
    context.go(
      manuscriptId != null
          ? '/manuscript/$manuscriptId/editor'
          : AppConstants.editor,
    );
  }

  /// Progress indicator showing 4 dots for step tracking.
  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastStep = _currentStep == _totalSteps - 1;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Back/skip live in the bottom action bar only; keeping a single
        // navigation cluster avoids the previous five-affordance header
        // (上一步/跳过/关闭 on top of 上一步/下一步) that blurred which
        // action actually exits the wizard.
        actions: [
          TextButton(
            onPressed: _skipStep,
            child: Text(
              '跳过此步',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, size: 20),
            tooltip: '退出引导',
            onPressed: _completeOnboarding,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress dots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _buildProgressDots(),
          ),
          // Step title and subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                Text(
                  _stepTitles[_currentStep],
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  _stepSubtitles[_currentStep],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // PageView with step content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: [
                // Step 1: Genre selection. Tapping a card only records the
                // selection; advancing happens through the single 下一步
                // button. The previous tap-to-auto-advance let a follow-up
                // 下一步 tap silently skip the AI provider step.
                GenreStepPage(
                  onSelected: (genreId) {
                    _selectedGenreName = '通用';
                    for (final genre in GenreOption.builtIn) {
                      if (genre.id == genreId) {
                        _selectedGenreName = genre.title;
                        break;
                      }
                    }
                  },
                ),
                // Step 2: AI provider setup
                ProviderStepPage(onSetupComplete: (_) => _nextStep()),
                // Step 3: World setting creation
                WorldStepPage(
                  key: _worldStepKey,
                  worldNameController: _worldNameController,
                  worldDescriptionController: _worldDescriptionController,
                ),
                // Step 4: Character card creation
                CharacterStepPage(
                  key: _characterStepKey,
                  characterNameController: _characterNameController,
                  characterDescriptionController:
                      _characterDescriptionController,
                ),
                OpeningStepPage(
                  genreName: _selectedGenreName,
                  worldDescription: _worldDescriptionController.text,
                  characterDescription: _characterDescriptionController.text,
                  onSelected: (variant) {
                    _selectedOpeningVariant = variant;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('上一步'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _nextStep,
                child: Text(isLastStep ? '开始创作' : '下一步'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
