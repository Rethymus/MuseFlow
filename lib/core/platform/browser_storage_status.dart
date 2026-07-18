class BrowserStorageStatus {
  const BrowserStorageStatus({
    required this.isSupported,
    required this.isPersistent,
    this.usageBytes,
    this.quotaBytes,
  });

  const BrowserStorageStatus.unsupported()
    : isSupported = false,
      isPersistent = false,
      usageBytes = null,
      quotaBytes = null;

  final bool isSupported;
  final bool isPersistent;
  final int? usageBytes;
  final int? quotaBytes;
}
