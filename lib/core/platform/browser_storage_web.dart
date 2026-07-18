import 'dart:js_interop';

import 'package:museflow/core/platform/browser_storage_status.dart';
import 'package:web/web.dart' as web;

class BrowserStorageService {
  const BrowserStorageService();

  Future<BrowserStorageStatus> getStatus() async {
    try {
      final storage = web.window.navigator.storage;
      final persisted = (await storage.persisted().toDart).toDart;
      final estimate = await storage.estimate().toDart;
      return BrowserStorageStatus(
        isSupported: true,
        isPersistent: persisted,
        usageBytes: estimate.usage,
        quotaBytes: estimate.quota,
      );
    } catch (_) {
      return const BrowserStorageStatus.unsupported();
    }
  }

  Future<BrowserStorageStatus> requestPersistence() async {
    try {
      await web.window.navigator.storage.persist().toDart;
    } catch (_) {
      return const BrowserStorageStatus.unsupported();
    }
    return getStatus();
  }
}
