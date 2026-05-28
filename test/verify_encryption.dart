#!/usr/bin/env dart

import 'dart:io';
import 'package:museflow/services/secure_data_service.dart';

/// 简单的加密验证脚本
void main() async {
  print('MuseFlow 加密功能验证');
  print('=' * 50);

  try {
    // 初始化加密服务
    print('初始化加密服务...');
    final secureService = SecureDataService.instance;
    await secureService.initialize();

    print('✓ 加密服务初始化成功');

    // 验证服务状态
    final status = secureService.getStatus();
    print('\n加密服务状态:');
    print('  算法: ${status['algorithm']}');
    print('  密钥长度: ${status['key_size']} bits');
    print('  密钥派生: ${status['key_derivation']}');
    print('  迭代次数: ${status['iterations']}');
    print('  IV长度: ${status['iv_length']} bytes');

    // 测试基本加密功能
    print('\n测试基本加密功能...');
    const testData = 'Hello, MuseFlow! 你好世界 🎵';

    final encrypted = secureService.encrypt(testData);
    print('✓ 数据加密成功');
    print('  原始数据长度: ${testData.length} bytes');
    print('  加密数据长度: ${encrypted.length} bytes');

    final decrypted = secureService.decrypt(encrypted);
    print('✓ 数据解密成功');
    print('  解密数据: $decrypted');

    if (decrypted == testData) {
      print('✓ 加密解密验证通过');
    } else {
      print('✗ 加密解密验证失败');
      exit(1);
    }

    // 测试笔记加密
    print('\n测试笔记数据加密...');
    final noteData = secureService.encryptNoteData(
      noteId: 'test-note-123',
      title: '测试笔记标题',
      content: '这是测试笔记的内容，包含敏感信息需要加密保护。',
    );

    print('✓ 笔记加密成功');
    print('  标题加密长度: ${noteData['title']!.length}');
    print('  内容加密长度: ${noteData['content']!.length}');
    print('  加密算法: ${noteData['algorithm']}');
    print('  加密时间: ${noteData['created_at']}');

    final decryptedNote = secureService.decryptNoteData(
      noteId: 'test-note-123',
      encryptedTitle: noteData['title']!,
      encryptedContent: noteData['content']!,
    );

    print('✓ 笔记解密成功');
    print('  解密标题: ${decryptedNote['title']}');
    print('  解密内容: ${decryptedNote['content']}');

    // 测试批量加密
    print('\n测试批量加密功能...');
    final notes = List.generate(10, (i) => {
      'id': 'batch-note-$i',
      'title': '批量笔记 $i',
      'content': '内容 $i' * 10,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'tags': ['test', 'batch'],
    });

    final stopwatch = Stopwatch()..start();
    final encryptedNotes = secureService.batchEncryptNotes(notes);
    stopwatch.stop();

    print('✓ 批量加密成功');
    print('  处理笔记数: ${encryptedNotes.length}');
    print('  总耗时: ${stopwatch.elapsedMilliseconds}ms');
    print('  平均每条: ${(stopwatch.elapsedMilliseconds / encryptedNotes.length).toStringAsFixed(2)}ms');

    final decryptStopwatch = Stopwatch()..start();
    final decryptedNotes = secureService.batchDecryptNotes(encryptedNotes);
    decryptStopwatch.stop();

    print('✓ 批量解密成功');
    print('  解密耗时: ${decryptStopwatch.elapsedMilliseconds}ms');
    print('  平均每条: ${(decryptStopwatch.elapsedMilliseconds / decryptedNotes.length).toStringAsFixed(2)}ms');

    // 验证数据完整性
    bool allMatch = true;
    for (int i = 0; i < notes.length; i++) {
      if (decryptedNotes[i]['title'] != notes[i]['title'] ||
          decryptedNotes[i]['content'] != notes[i]['content']) {
        allMatch = false;
        break;
      }
    }

    if (allMatch) {
      print('✓ 数据完整性验证通过');
    } else {
      print('✗ 数据完整性验证失败');
      exit(1);
    }

    // 测试特殊字符处理
    print('\n测试特殊字符处理...');
    const specialCases = [
      '', // 空字符串
      'A' * 10000, // 长文本
      '!@#\$%^&*()_+-=[]{}|;:\'",.<>?/~`', // 特殊字符
      '你好世界 🎵🎶🎼🎹', // Emoji和多语言
      'Line1\nLine2\rLine3\tTabbed', // 控制字符
    ];

    for (final testCase in specialCases) {
      final enc = secureService.encrypt(testCase, dataId: 'special-${testCase.hashCode}');
      final dec = secureService.decrypt(enc, dataId: 'special-${testCase.hashCode}');

      if (dec == testCase) {
        print('✓ 特殊字符测试通过: ${testCase.length > 20 ? "长文本" : testCase}');
      } else {
        print('✗ 特殊字符测试失败');
        exit(1);
      }
    }

    // 测试唯一性
    print('\n测试加密唯一性...');
    const sameData = 'Same data for uniqueness test';
    final enc1 = secureService.encrypt(sameData, dataId: 'unique-1');
    final enc2 = secureService.encrypt(sameData, dataId: 'unique-2');

    if (enc1 != enc2) {
      print('✓ 加密唯一性验证通过（相同数据产生不同密文）');
    } else {
      print('✗ 加密唯一性验证失败');
      exit(1);
    }

    // 性能测试
    print('\n性能测试...');
    const perfIterations = 100;
    final perfData = 'Performance test data ' * 10; // ~220 bytes

    final encStopwatch = Stopwatch()..start();
    for (int i = 0; i < perfIterations; i++) {
      secureService.encrypt(perfData, dataId: 'perf-$i');
    }
    encStopwatch.stop();

    final avgEncTime = encStopwatch.elapsedMilliseconds / perfIterations;
    print('  加密性能: ${avgEncTime.toStringAsFixed(2)}ms/op (220 bytes)');

    if (avgEncTime < 100) {
      print('✓ 加密性能良好');
    } else {
      print('⚠ 加密性能可能需要优化');
    }

    // 清理
    print('\n清理资源...');
    await secureService.dispose();
    print('✓ 资源清理完成');

    print('\n' + '=' * 50);
    print('所有测试通过！✓');
    print('加密功能工作正常，准备用于生产环境。');

  } catch (e, stackTrace) {
    print('\n✗ 测试失败: $e');
    print('堆栈跟踪:\n$stackTrace');
    exit(1);
  }
}