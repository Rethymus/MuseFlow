import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/temporary_hive_workspace.dart';

void main() {
  tearDown(() => Hive.close());

  test('opens the temporary workspace with in-memory boxes only', () async {
    await openTemporaryHiveWorkspace();

    final manuscripts = Hive.box<dynamic>('manuscripts');
    await manuscripts.put('draft', {'title': '临时作品'});

    expect(manuscripts.get('draft'), {'title': '临时作品'});
    expect(manuscripts.path, isNull);
    expect(Hive.box<dynamic>('settings').path, isNull);
    expect(Hive.box<dynamic>('chapters').path, isNull);
  });
}
