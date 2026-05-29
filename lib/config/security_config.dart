import 'app_constants.dart';

/// 文件安全配置
///
/// 集中管理所有文件操作相关的安全配置参数
/// 部分通用配置值已迁移到 AppConstants，这里保留安全特有的配置
class SecurityConfig {
  // 文件大小限制 (使用 AppConstants 中的值)
  static const int maxSingleFileSize = AppConstants.maxSingleFileSizeBytes;
  static const int maxTotalSize = AppConstants.maxTotalSizeBytes;
  static const int maxFileNameLength = AppConstants.maxFileNameLength;

  // 缓存配置 (使用 AppConstants 中的值)
  static const int maxCacheSize = AppConstants.maxCacheSizeBytes;
  static const int maxCacheEntries = AppConstants.maxCacheEntries;
  static const Duration cacheExpiration = AppConstants.cacheExpiration;

  // 文件类型安全配置
  static const Set<String> textFileExtensions = {
    '.txt',
    '.md',
    '.json',
    '.csv',
    '.xml',
    '.yaml',
    '.yml',
    '.html',
    '.css',
    '.js',
    '.ts',
    '.dart',
    '.py',
    '.java',
  };

  static const Set<String> imageFileExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.svg',
    '.webp',
    '.bmp',
    '.ico',
  };

  static const Set<String> audioFileExtensions = {
    '.mp3',
    '.wav',
    '.m4a',
    '.aac',
    '.ogg',
    '.flac',
    '.wma',
  };

  static const Set<String> videoFileExtensions = {
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
    '.webm',
    '.flv',
    '.wmv',
  };

  static const Set<String> documentFileExtensions = {
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.odt',
    '.ods',
    '.odp',
    '.rtf',
    '.tex',
  };

  static const Set<String> archiveFileExtensions = {
    '.zip',
    '.tar',
    '.gz',
    '.7z',
    '.rar',
    '.bz2',
    '.xz',
  };

  // 危险文件类型
  static const Set<String> executableExtensions = {
    '.exe',
    '.bat',
    '.cmd',
    '.sh',
    '.ps1',
    '.vbs',
    '.js',
    '.jar',
    '.app',
    '.deb',
    '.rpm',
    '.dmg',
    '.pkg',
    '.msi',
    '.com',
    '.scr',
    '.pif',
    '.vb',
    '.vbe',
    '.jse',
    '.wsf',
    '.wsh',
    '.ws',
    '.scf',
    '.lnk',
  };

  // 系统文件模式
  static const List<String> systemFilePatterns = [
    r'\.\.', // 路径遍历
    r'~\$', // Windows临时文件
    r'thumbs\.db', // Windows缩略图缓存
    r'\.ds_store', // macOS系统文件
    r'\._', // macOS资源分叉
    r'\.spotlight-', // macOS索引文件
    r'\.trash', // 回收站
    r'\.recycle', // 回收站
    r'desktop\.ini', // Windows配置文件
    r'\.git', // Git目录
    r'\.svn', // SVN目录
    r'\.hg', // Mercurial目录
  ];

  // 路径安全配置 (使用 AppConstants 中的值)
  static const int maxPathDepth = AppConstants.maxPathDepth;
  static const int maxPathLength = AppConstants.maxPathLength;

  // 安全目录配置
  static const String appDirName = 'museflow';
  static const String cacheDirName = 'cache';
  static const String exportsDirName = 'exports';
  static const String importsDirName = 'imports';
  static const String tempDirName = 'temp';

  // 审计配置 (使用 AppConstants 中的值)
  static const int maxAuditLogEntries = AppConstants.maxAuditLogEntries;
  static const Duration auditLogRetention = AppConstants.auditLogRetention;

  // 性能配置 (使用 AppConstants 中的值)
  static const int maxConcurrentFileOperations =
      AppConstants.maxConcurrentFileOperations;
  static const Duration fileOperationTimeout =
      AppConstants.fileOperationTimeout;

  // 权限配置
  static const bool requireWritePermission = true;
  static const bool requireReadPermission = true;
  static const bool strictPathValidation = true;

  /// 获取所有允许的文件扩展名
  static Set<String> getAllAllowedExtensions() {
    return {
      ...textFileExtensions,
      ...imageFileExtensions,
      ...audioFileExtensions,
      ...videoFileExtensions,
      ...documentFileExtensions,
      ...archiveFileExtensions,
    };
  }

  /// 获取所有危险文件扩展名
  static Set<String> getAllDangerousExtensions() {
    return executableExtensions;
  }

  /// 检查文件扩展名是否安全
  static bool isSafeExtension(String extension) {
    final normalizedExt = extension.toLowerCase();
    return getAllAllowedExtensions().contains(normalizedExt);
  }

  /// 检查文件扩展名是否危险
  static bool isDangerousExtension(String extension) {
    final normalizedExt = extension.toLowerCase();
    return getAllDangerousExtensions().contains(normalizedExt);
  }

  /// 获取文件类型分类
  static String getFileTypeCategory(String extension) {
    final normalizedExt = extension.toLowerCase();

    if (textFileExtensions.contains(normalizedExt)) {
      return 'text';
    } else if (imageFileExtensions.contains(normalizedExt)) {
      return 'image';
    } else if (audioFileExtensions.contains(normalizedExt)) {
      return 'audio';
    } else if (videoFileExtensions.contains(normalizedExt)) {
      return 'video';
    } else if (documentFileExtensions.contains(normalizedExt)) {
      return 'document';
    } else if (archiveFileExtensions.contains(normalizedExt)) {
      return 'archive';
    } else {
      return 'unknown';
    }
  }

  /// 获取安全的文件大小限制
  static int getSafeSizeLimit(String fileType) {
    switch (fileType) {
      case 'text':
        return 1 * 1024 * 1024; // 1MB
      case 'image':
        return 5 * 1024 * 1024; // 5MB
      case 'audio':
        return 10 * 1024 * 1024; // 10MB
      case 'video':
        return 50 * 1024 * 1024; // 50MB
      case 'document':
        return 10 * 1024 * 1024; // 10MB
      case 'archive':
        return 20 * 1024 * 1024; // 20MB
      default:
        return maxSingleFileSize;
    }
  }
}

/// 文件操作权限
enum FileOperationPermission {
  read,
  write,
  delete,
  execute,
}

/// 文件操作结果
class FileOperationResult {
  final bool success;
  final String? errorMessage;
  final dynamic data;

  const FileOperationResult({
    required this.success,
    this.errorMessage,
    this.data,
  });

  factory FileOperationResult.success([dynamic data]) {
    return FileOperationResult(
      success: true,
      data: data,
    );
  }

  factory FileOperationResult.failure(String errorMessage) {
    return FileOperationResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}
