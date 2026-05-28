import 'dart:io';
import 'lib/utils/file_security_validator.dart';

void main() async {
  print('=== 路径遍历检测测试 ===\n');

  final validator = FileSecurityValidator.instance;

  // 测试用例
  final testCases = [
    // 应该被拒绝的路径遍历攻击
    TestCase('../../../etc/passwd', true, '向上目录遍历攻击'),
    TestCase('../sensitive_file.txt', true, '相对路径向上遍历'),
    TestCase('notes/../../etc/passwd', true, '混合路径向上遍历'),
    TestCase('..\\windows\\system32', true, 'Windows风格向上遍历'),
    TestCase('/home/user/../../etc/passwd', true, '绝对路径中的向上遍历'),

    // 应该被允许的合法路径
    TestCase('/home/user/museflow/notes.md', false, '合法的绝对路径'),
    TestCase('notes.md', false, '简单的相对路径'),
    TestCase('documents/notes.txt', false, '合法的相对路径'),
    TestCase('/home/user/museflow/..', false, '当前目录上级引用（会被normalize）'),
  ];

  int passedTests = 0;
  int failedTests = 0;

  for (final testCase in testCases) {
    final result = await validator.validatePath(testCase.path);
    final isBlocked = !result.isValid;

    final testPassed = (testCase.shouldBeBlocked && isBlocked) ||
                       (!testCase.shouldBeBlocked && !isBlocked);

    if (testPassed) {
      passedTests++;
      print('✓ 通过: ${testCase.description}');
      print('  路径: ${testCase.path}');
      print('  期望: ${testCase.shouldBeBlocked ? "拒绝" : "允许"}, 实际: ${isBlocked ? "拒绝" : "允许"}\n');
    } else {
      failedTests++;
      print('✗ 失败: ${testCase.description}');
      print('  路径: ${testCase.path}');
      print('  期望: ${testCase.shouldBeBlocked ? "拒绝" : "允许"}, 实际: ${isBlocked ? "拒绝" : "允许"}');
      if (!result.isValid) {
        print('  错误信息: ${result.errorMessage}');
      }
      print('');
    }
  }

  print('=== 测试结果 ===');
  print('通过: $passedTests');
  print('失败: $failedTests');
  print('总计: ${testCases.length}');

  exit(failedTests > 0 ? 1 : 0);
}

class TestCase {
  final String path;
  final bool shouldBeBlocked;
  final String description;

  TestCase(this.path, this.shouldBeBlocked, this.description);
}