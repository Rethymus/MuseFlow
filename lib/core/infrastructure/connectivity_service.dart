import 'package:connectivity_plus/connectivity_plus.dart';

/// Probe signature: returns the device's current connectivity transports.
///
/// Indirection over [Connectivity] itself so tests can inject a deterministic
/// result without standing up a platform channel mock.
typedef ConnectivityProbe = Future<List<ConnectivityResult>> Function();

/// Best-effort network reachability probe used to fast-fail AI calls when the
/// device is definitively offline.
///
/// Wraps `connectivity_plus` (a declared-but-previously-unused MuseFlow dep —
/// wiring it here closes Phase 30.3 "网络状态感知 → 离线时禁用 AI 操作").
///
/// "Probably offline" is **true only** when the device reports no transport at
/// all — the result list is exclusively [ConnectivityResult.none]. Any positive
/// transport (wifi/mobile/ethernet/vpn/bluetooth/satellite/other), an empty
/// result, or a throwing probe is treated as **online**.
///
/// This best-effort design never false-blocks a user who is actually reachable:
/// the cost of a false "offline" (blocking a working AI call) far exceeds the
/// cost of a false "online" (one failed call that surfaces the normal network
/// error UX after the bounded timeout). See [AIAdapter.onlineCheck].
class ConnectivityService {
  final ConnectivityProbe _probe;

  /// [probe] defaults to [Connectivity.checkConnectivity]; inject a fake in tests.
  ConnectivityService([ConnectivityProbe? probe])
    : _probe = probe ?? Connectivity().checkConnectivity;

  /// Whether the device reports no network transport at all.
  ///
  /// True only for an exclusively-`none` result list. Never throws — a failing
  /// connectivity backend is treated as "online" (do not block).
  Future<bool> isProbablyOffline() async {
    try {
      final results = await _probe();
      return results.isNotEmpty &&
          results.every((r) => r == ConnectivityResult.none);
    } catch (_) {
      // Backend unavailable → assume online (never false-block).
      return false;
    }
  }
}
