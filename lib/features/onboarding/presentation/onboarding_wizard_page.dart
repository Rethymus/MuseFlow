import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/onboarding/domain/genre_option.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';
import 'package:museflow/features/onboarding/presentation/onboarding_providers.dart';
import 'package:museflow/features/onboarding/presentation/opening_text_insertion.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/character_step_page.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/genre_step_page.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/opening_step_page.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/world_step_page.dart';
import 'package:museflow/shared/constants/app_constants.dart';

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
  static const int _totalSteps = 4;

  /// Step titles displayed in the progress area.
  static const List<String> _stepTitles = ['选择题材', '构建世界', '创建角色', '写开篇'];

  static const List<String> _stepSubtitles = [
    '选择你感兴趣的故事类型',
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
      case 1: // Advancing from World step -> create WorldSetting entity
        final isValid = _worldStepKey.currentState?.validate() ?? false;
        if (isValid && _worldNameController.text.trim().isNotEmpty) {
          await _createWorldSetting();
        }
        break;
      case 2: // Advancing from Character step -> create CharacterCard entity
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('世界观创建失败: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('角色创建失败: $e')));
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final selectedOpening = _selectedOpeningVariant;
    if (selectedOpening != null) {
      insertOpeningText(
        ref.read(editorProvider),
        selectedOpening.text,
        onAiInserted: (text) {
          ref.read(writingStatsCollectorProvider.future).then((collector) {
            collector.recordAiInsertion(text);
          });
        },
      );
    }

    try {
      final repository = await ref.read(onboardingRepositoryProvider.future);
      await repository.markCompleted();
    } catch (_) {
      // Even if persistence fails, navigate away so user is not stuck.
    }
    if (mounted) {
      context.go(AppConstants.editor);
    }
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
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: '上一步',
                onPressed: _previousStep,
              )
            : null,
        actions: [
          TextButton(
            onPressed: _skipStep,
            child: Text(
              '跳过',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: '关闭',
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stepSubtitles[_currentStep],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
                // Step 1: Genre selection
                GenreStepPage(
                  onSelected: (genreId) {
                    _selectedGenreName = '通用';
                    for (final genre in GenreOption.builtIn) {
                      if (genre.id == genreId) {
                        _selectedGenreName = genre.title;
                        break;
                      }
                    }
                    _nextStep();
                  },
                ),
                // Step 2: World setting creation
                WorldStepPage(
                  key: _worldStepKey,
                  worldNameController: _worldNameController,
                  worldDescriptionController: _worldDescriptionController,
                ),
                // Step 3: Character card creation
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
