import 'package:museflow/core/platform/browser_storage_status.dart';

class BrowserStorageService {
  const BrowserStorageService();

  Future<BrowserStorageStatus> getStatus() async {
    return const BrowserStorageStatus.unsupported();
  }

  Future<BrowserStorageStatus> requestPersistence() => getStatus();
}
