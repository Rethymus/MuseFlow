import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/core/platform/web_workspace_mode.dart';

class WebWorkspaceGate extends ConsumerStatefulWidget {
  const WebWorkspaceGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WebWorkspaceGate> createState() => _WebWorkspaceGateState();
}

class _WebWorkspaceGateState extends ConsumerState<WebWorkspaceGate> {
  bool _isVisible = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider.future);
      if (!mounted || settings.hasSeenWebWorkspaceNotice()) return;
      setState(() => _isVisible = true);
    } catch (_) {
      // The application remains usable if browser storage is unavailable.
    }
  }

  Future<void> _continue({required bool requestPersistence}) async {
    setState(() => _isSaving = true);
    try {
      if (requestPersistence) {
        await ref.read(browserStorageServiceProvider).requestPersistence();
        ref.invalidate(browserStorageStatusProvider);
      }
      final settings = await ref.read(settingsRepositoryProvider.future);
      await settings.markWebWorkspaceNoticeSeen();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isVisible = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ExcludeFocus(
          excluding: _isVisible,
          child: ExcludeSemantics(excluding: _isVisible, child: widget.child),
        ),
        if (_isVisible)
          Positioned.fill(
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              label: '浏览器工作区设置',
              explicitChildNodes: true,
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: FocusTraversalGroup(
                      child: CallbackShortcuts(
                        bindings: {
                          const SingleActivator(LogicalKeyboardKey.escape): () {
                            if (!_isSaving) {
                              _continue(requestPersistence: false);
                            }
                          },
                        },
                        child: AlertDialog(
                          title: const Text('浏览器工作区'),
                          content: Text(
                            isTemporaryWebWorkspace
                                ? '当前为临时体验：作品、设置和 API Key 只存在于内存中，刷新或关闭页面后全部清除。离开前请导出作品备份。'
                                : '作品会自动保存在当前浏览器中，但清理站点数据或浏览器回收空间仍可能导致丢失。\n\n'
                                      'AI Provider API Key 只保留在当前标签页会话中，关闭标签页后需要重新填写。Key 会发送给你选择的 AI 服务商，不会发送给 MuseFlow 或 GitHub。\n\n'
                                      '请定期从设置页导出作品备份。',
                          ),
                          actions: [
                            if (!isTemporaryWebWorkspace)
                              TextButton(
                                onPressed: _isSaving
                                    ? null
                                    : () => switchWebWorkspaceMode(
                                        temporary: true,
                                      ),
                                child: const Text('临时体验'),
                              ),
                            TextButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _continue(requestPersistence: false),
                              child: const Text('稍后'),
                            ),
                            FilledButton(
                              autofocus: true,
                              onPressed: _isSaving
                                  ? null
                                  : () => _continue(
                                      requestPersistence:
                                          !isTemporaryWebWorkspace,
                                    ),
                              child: Text(
                                isTemporaryWebWorkspace ? '开始临时体验' : '继续并保护存储',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
