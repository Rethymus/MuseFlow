import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/features/onboarding/presentation/onboarding_providers.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/genre_step_page.dart';
import 'package:museflow/shared/constants/app_constants.dart';

/// Full-screen onboarding wizard with 4-step PageView navigation.
///
/// Steps: Genre → World → Character → Opening
/// Step 1 (Genre) is implemented here. Steps 2-4 are stubs for Plans 08-03/08-05.
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
  static const List<String> _stepTitles = [
    '选择题材',
    '构建世界',
    '创建角色',
    '写开篇',
  ];

  static const List<String> _stepSubtitles = [
    '选择你感兴趣的故事类型',
    '为你的世界命名，让故事有根基',
    '创造你的主角，给故事一个灵魂',
    '选择一种开篇风格，开始你的故事',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  Future<void> _completeOnboarding() async {
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
              isLastStep ? '跳过' : '跳过',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
                  onSelected: (_) => _nextStep(),
                ),
                // Step 2: World (stub for Plan 08-03)
                const _StubStepPage(
                  icon: Icons.public,
                  title: '构建你的世界',
                  description: '这一步将在下一版本中实现',
                ),
                // Step 3: Character (stub for Plan 08-03)
                const _StubStepPage(
                  icon: Icons.person,
                  title: '创建你的角色',
                  description: '这一步将在下一版本中实现',
                ),
                // Step 4: Opening (stub for Plan 08-05)
                const _StubStepPage(
                  icon: Icons.edit_note,
                  title: '撰写开篇',
                  description: '这一步将在下一版本中实现',
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

/// Placeholder widget for unimplemented wizard steps.
///
/// Used by Plans 08-03 and 08-05. Each step will be replaced with a full
/// implementation when its plan is executed.
class _StubStepPage extends StatelessWidget {
  const _StubStepPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
