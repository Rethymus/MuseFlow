import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/platform/browser_storage_status.dart';
import 'package:museflow/core/platform/export_file_writer.dart';
import 'package:museflow/core/platform/web_workspace_mode.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/manuscript_backup_service.dart';

class WebWorkspaceSettingsSection extends ConsumerWidget {
  const WebWorkspaceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(browserStorageStatusProvider);
    final settings = ref.watch(settingsRepositoryProvider).value;
    final lastBackupAt = settings?.getLastBrowserBackupAt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('浏览器工作区', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        const ListTile(
          leading: Icon(Icons.key_outlined),
          title: Text('会话级 BYOK'),
          subtitle: Text('API Key 仅保留在当前标签页会话；关闭标签页后自动失效'),
        ),
        if (isTemporaryWebWorkspace)
          ListTile(
            leading: const Icon(Icons.timer_off_outlined),
            title: const Text('临时体验模式'),
            subtitle: const Text('刷新或关闭页面后，作品、设置与 API Key 全部清除'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => switchWebWorkspaceMode(temporary: false),
          ),
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text('浏览器存储保护'),
          subtitle: Text(_storageSubtitle(status.value)),
          trailing: status.isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : status.value?.isPersistent == true
              ? const Icon(Icons.verified_outlined)
              : const Icon(Icons.chevron_right),
          onTap:
              isTemporaryWebWorkspace ||
                  status.isLoading ||
                  status.value?.isPersistent == true
              ? null
              : () => _requestPersistence(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('导出全部作品备份'),
          subtitle: Text(
            lastBackupAt == null
                ? '尚未备份；浏览器数据可能被用户或系统清除'
                : '上次备份：${_formatDateTime(lastBackupAt)}',
          ),
          onTap: () => _exportBackup(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.upload_file_outlined),
          title: const Text('导入作品备份'),
          subtitle: const Text('从 MuseFlow JSON 备份恢复文稿和章节，不覆盖现有作品'),
          onTap: () => _importBackup(context, ref),
        ),
        const Divider(),
        const SizedBox(height: 16),
      ],
    );
  }

  static String _storageSubtitle(BrowserStorageStatus? status) {
    if (status == null || !status.isSupported) {
      return '浏览器未提供存储状态，务必定期导出备份';
    }
    final usage = status.usageBytes;
    final quota = status.quotaBytes;
    final size = usage != null && quota != null
        ? '，已用 ${_formatBytes(usage)} / ${_formatBytes(quota)}'
        : '';
    return status.isPersistent ? '已获得持久化保护$size' : '当前为尽力保存，空间不足时浏览器可能清理$size';
  }

  Future<void> _requestPersistence(BuildContext context, WidgetRef ref) async {
    final status = await ref
        .read(browserStorageServiceProvider)
        .requestPersistence();
    ref.invalidate(browserStorageStatusProvider);
    if (!context.mounted) return;
    final message = status.isPersistent
        ? '浏览器已授予持久化存储保护'
        : '浏览器未授予持久化保护，请定期导出备份';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final manuscriptRepository = await ref.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepository = await ref.read(
        chapterRepositoryProvider.future,
      );
      final backupService = ManuscriptBackupService(
        manuscriptRepository: manuscriptRepository,
        chapterRepository: chapterRepository,
      );
      final now = DateTime.now();
      final date = now.toIso8601String().split('T').first;
      await writeExportFile(
        'museflow-作品备份-$date.json',
        backupService.exportJson(),
      );
      final settings = await ref.read(settingsRepositoryProvider.future);
      await settings.saveLastBrowserBackupAt(now);
      ref.invalidate(settingsRepositoryProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('作品备份已下载')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('备份失败：$error')));
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = selection?.files.single.bytes;
    if (bytes == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入作品备份？'),
        content: const Text('备份中的作品将添加到当前工作区；同 ID 作品会创建为“导入”副本。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final manuscriptRepository = await ref.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepository = await ref.read(
        chapterRepositoryProvider.future,
      );
      final result = await ManuscriptBackupService(
        manuscriptRepository: manuscriptRepository,
        chapterRepository: chapterRepository,
      ).importJson(utf8.decode(bytes));
      ref.invalidate(manuscriptNotifierProvider);
      ref.invalidate(chapterNotifierProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已导入 ${result.manuscriptCount} 部作品、${result.chapterCount} 个章节',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败：$error')));
    }
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kib = bytes / 1024;
    if (kib < 1024) return '${kib.toStringAsFixed(1)} KiB';
    return '${(kib / 1024).toStringAsFixed(1)} MiB';
  }
}
