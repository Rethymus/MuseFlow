import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/infrastructure/connectivity_service.dart';

void main() {
  group('ConnectivityService.isProbablyOffline', () {
    test('offline when result list is exclusively [none]', () async {
      final service = ConnectivityService(
        () async => [ConnectivityResult.none],
      );
      expect(await service.isProbablyOffline(), isTrue);
    });

    test('online when wifi present', () async {
      final service = ConnectivityService(
        () async => [ConnectivityResult.wifi],
      );
      expect(await service.isProbablyOffline(), isFalse);
    });

    test('online when any positive transport present alongside none', () async {
      // Best-effort: a positive transport (vpn) overrides a `none` entry.
      final service = ConnectivityService(
        () async => [ConnectivityResult.none, ConnectivityResult.vpn],
      );
      expect(await service.isProbablyOffline(), isFalse);
    });

    test('online for every positive transport type', () async {
      const positive = [
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
        ConnectivityResult.bluetooth,
        ConnectivityResult.vpn,
        ConnectivityResult.satellite,
        ConnectivityResult.other,
        ConnectivityResult.wifi,
      ];
      for (final r in positive) {
        final service = ConnectivityService(() async => [r]);
        expect(await service.isProbablyOffline(), isFalse, reason: '$r');
      }
    });

    test(
      'online (best-effort, never false-block) when result list is empty',
      () async {
        final service = ConnectivityService(() async => []);
        expect(await service.isProbablyOffline(), isFalse);
      },
    );

    test('online (best-effort) when connectivity backend throws', () async {
      final service = ConnectivityService(
        () async => throw StateError('backend unavailable'),
      );
      expect(await service.isProbablyOffline(), isFalse);
    });
  });
}
