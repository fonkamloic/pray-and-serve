import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bonsoir/bonsoir.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'backup_service.dart';
import 'sync_crypto.dart';
import '../models/paired_device.dart';

// ---------------------------------------------------------------------------
// Events emitted by SyncService for the UI layer to react to.
// ---------------------------------------------------------------------------

sealed class SyncEvent {}

final class SyncEventPaired extends SyncEvent {
  final String deviceName;
  SyncEventPaired(this.deviceName);
}

final class SyncEventSynced extends SyncEvent {
  final String deviceName;
  final int added;
  SyncEventSynced(this.deviceName, this.added);
}

final class SyncEventFailed extends SyncEvent {
  final String error;
  SyncEventFailed(this.error);
}

// ---------------------------------------------------------------------------

class SyncService {
  static const _serviceType = '_prayserve._tcp';
  static const _httpPort = 8765;
  static const _minSyncInterval = Duration(minutes: 5);
  static const _syncTimeout = Duration(seconds: 15);

  final StorageService _storage;
  final BackupService _backup;

  late final String _deviceId;
  String _deviceName = 'Unknown Device';

  HttpServer? _httpServer;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  /// Active pairing session token and its expiry.
  String? _pendingSessionToken;
  DateTime? _sessionTokenExpiry;

  bool _syncInProgress = false;
  final Map<String, DateTime> _lastSyncAt = {};

  final _eventsController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get events => _eventsController.stream;

  SyncService(this._storage, this._backup);

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  Future<void> init() async {
    _deviceId = _storage.getDeviceId();
    _deviceName = await _getDeviceName();
    await _startHttpServer();
    _startMdns(); // fire-and-forget, mDNS errors are non-fatal
  }

  void dispose() {
    _httpServer?.close(force: true);
    _broadcast?.stop();
    _discovery?.stop();
    _eventsController.close();
  }

  // -------------------------------------------------------------------------
  // HTTP Server
  // -------------------------------------------------------------------------

  Future<void> _startHttpServer() async {
    final router = Router()
      ..get('/status', _handleStatus)
      ..post('/pair', _handlePair)
      ..post('/sync', _handleSync);

    try {
      _httpServer = await shelf_io.serve(
        const Pipeline().addMiddleware(_corsMiddleware()).addHandler(router.call),
        InternetAddress.anyIPv4,
        _httpPort,
      );
    } catch (_) {
      // Port might already be in use — not fatal; sync requires active server.
    }
  }

  Middleware _corsMiddleware() {
    return (innerHandler) {
      return (request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          'content-type': 'application/json',
          ...response.headers,
        });
      };
    };
  }

  Response _handleStatus(Request request) {
    return Response.ok(jsonEncode({
      'deviceId': _deviceId,
      'deviceName': _deviceName,
      'version': 1,
    }));
  }

  Future<Response> _handlePair(Request request) async {
    if (_pendingSessionToken == null ||
        (_sessionTokenExpiry != null &&
            DateTime.now().isAfter(_sessionTokenExpiry!))) {
      return Response.forbidden(
          jsonEncode({'error': 'No active pairing session'}));
    }

    final body = await request.readAsString();
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON'}));
    }

    final sessionToken = json['sessionToken'] as String?;
    final fromDeviceId = json['fromDeviceId'] as String?;
    final fromDeviceName = json['fromDeviceName'] as String?;
    final sharedSecret = json['sharedSecret'] as String?;

    if (sessionToken == null ||
        sessionToken != _pendingSessionToken ||
        fromDeviceId == null ||
        fromDeviceName == null ||
        sharedSecret == null) {
      return Response(400,
          body: jsonEncode({'error': 'Invalid pairing data'}));
    }

    // One-use: invalidate immediately.
    _pendingSessionToken = null;
    _sessionTokenExpiry = null;

    // Persist the paired device, replacing any stale entry with the same ID.
    final devices = _storage.getPairedDevices()
        .where((d) => d.deviceId != fromDeviceId)
        .toList()
      ..add(PairedDevice(
        deviceId: fromDeviceId,
        deviceName: fromDeviceName,
        sharedSecretBase64: sharedSecret,
        pairedAt: DateTime.now().toIso8601String(),
      ));
    await _storage.savePairedDevices(devices);

    _eventsController.add(SyncEventPaired(fromDeviceName));

    return Response.ok(jsonEncode({'success': true}));
  }

  Future<Response> _handleSync(Request request) async {
    final body = await request.readAsString();
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON'}));
    }

    final fromDeviceId = json['deviceId'] as String?;
    final payloadB64 = json['payload'] as String?;
    if (fromDeviceId == null || payloadB64 == null) {
      return Response(400, body: jsonEncode({'error': 'Missing fields'}));
    }

    final paired = _storage
        .getPairedDevices()
        .cast<PairedDevice?>()
        .firstWhere((d) => d?.deviceId == fromDeviceId, orElse: () => null);

    if (paired == null) {
      return Response.forbidden(jsonEncode({'error': 'Unknown device'}));
    }

    try {
      final secret = base64Decode(paired.sharedSecretBase64);
      final decrypted =
          await SyncCrypto.decrypt(secret, base64Decode(payloadB64));
      final remoteData =
          jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;

      final added = await _backup.mergeFromData(remoteData);

      // Respond with our local data.
      final localData = _backup.buildBackupData();
      final encrypted = await SyncCrypto.encrypt(
          secret, Uint8List.fromList(utf8.encode(jsonEncode(localData))));

      if (added > 0) {
        _eventsController
            .add(SyncEventSynced(paired.deviceName, added));
      }

      return Response.ok(jsonEncode({
        'deviceId': _deviceId,
        'payload': base64Encode(encrypted),
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Sync error: $e'}));
    }
  }

  // -------------------------------------------------------------------------
  // Pairing (called by the scanner / "existing device")
  // -------------------------------------------------------------------------

  /// Starts a new pairing session and returns the QR payload.
  Future<Map<String, dynamic>> startPairingSession() async {
    final token = SyncCrypto.generateSessionToken();
    _pendingSessionToken = token;
    _sessionTokenExpiry = DateTime.now().add(const Duration(minutes: 5));
    final ip = await _getLocalIp();
    return {
      'mode': 'pair',
      'deviceId': _deviceId,
      'deviceName': _deviceName,
      'ip': ip,
      'port': _httpPort,
      'sessionToken': token,
    };
  }

  /// Cancels an in-progress pairing session (e.g. user navigated away).
  void cancelPairingSession() {
    _pendingSessionToken = null;
    _sessionTokenExpiry = null;
  }

  /// Called after the user has scanned a QR and passed biometric auth.
  /// Connects to the new device, sends shared secret, triggers first sync.
  Future<void> completePairing(Map<String, dynamic> qrData) async {
    final ip = qrData['ip'] as String;
    final port = qrData['port'] as int;
    final newDeviceId = qrData['deviceId'] as String;
    final newDeviceName = qrData['deviceName'] as String;
    final sessionToken = qrData['sessionToken'] as String;

    // Check if already paired — reuse same secret to allow re-pairing gracefully.
    final existing = _storage
        .getPairedDevices()
        .cast<PairedDevice?>()
        .firstWhere((d) => d?.deviceId == newDeviceId, orElse: () => null);

    final secretBytes = existing != null
        ? base64Decode(existing.sharedSecretBase64)
        : SyncCrypto.generateSecret();
    final secretB64 = base64Encode(secretBytes);

    final response = await http
        .post(
          Uri.parse('http://$ip:$port/pair'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sessionToken': sessionToken,
            'fromDeviceId': _deviceId,
            'fromDeviceName': _deviceName,
            'sharedSecret': secretB64,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Pairing rejected (${response.statusCode})');
    }

    // Persist.
    final devices = _storage
        .getPairedDevices()
        .where((d) => d.deviceId != newDeviceId)
        .toList()
      ..add(PairedDevice(
        deviceId: newDeviceId,
        deviceName: newDeviceName,
        sharedSecretBase64: secretB64,
        pairedAt: DateTime.now().toIso8601String(),
      ));
    await _storage.savePairedDevices(devices);

    _eventsController.add(SyncEventPaired(newDeviceName));

    // Trigger first sync immediately.
    await syncWithIp(newDeviceId, ip, port);
  }

  // -------------------------------------------------------------------------
  // Sync
  // -------------------------------------------------------------------------

  Future<void> syncWithIp(String deviceId, String ip, int port) async {
    if (_syncInProgress) return;

    final paired = _storage
        .getPairedDevices()
        .cast<PairedDevice?>()
        .firstWhere((d) => d?.deviceId == deviceId, orElse: () => null);

    if (paired == null) return;
    _syncInProgress = true;

    try {
      final secret = base64Decode(paired.sharedSecretBase64);
      final localData = _backup.buildBackupData();
      final encrypted = await SyncCrypto.encrypt(
          secret, Uint8List.fromList(utf8.encode(jsonEncode(localData))));

      final response = await http
          .post(
            Uri.parse('http://$ip:$port/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': _deviceId,
              'payload': base64Encode(encrypted),
            }),
          )
          .timeout(_syncTimeout);

      if (response.statusCode == 200) {
        final resp = jsonDecode(response.body) as Map<String, dynamic>;
        final decrypted = await SyncCrypto.decrypt(
            secret, base64Decode(resp['payload'] as String));
        final remoteData =
            jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
        final added = await _backup.mergeFromData(remoteData);
        _lastSyncAt[deviceId] = DateTime.now();
        _eventsController.add(SyncEventSynced(paired.deviceName, added));
      }
    } catch (e) {
      _eventsController.add(SyncEventFailed('Sync with ${paired.deviceName} failed: $e'));
    } finally {
      _syncInProgress = false;
    }
  }

  /// Remove a paired device.
  Future<void> unpairDevice(String deviceId) async {
    final devices =
        _storage.getPairedDevices().where((d) => d.deviceId != deviceId).toList();
    await _storage.savePairedDevices(devices);
  }

  // -------------------------------------------------------------------------
  // mDNS auto-discovery
  // -------------------------------------------------------------------------

  Future<void> _startMdns() async {
    try {
      await _registerBonsoirService();
    } catch (_) {}
    try {
      await _startBonsoirDiscovery();
    } catch (_) {}
  }

  Future<void> _registerBonsoirService() async {
    final service = BonsoirService(
      name: 'PrayServe-${_deviceId.substring(0, 8)}',
      type: _serviceType,
      port: _httpPort,
      attributes: {'did': _deviceId},
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  Future<void> _startBonsoirDiscovery() async {
    _discovery = BonsoirDiscovery(type: _serviceType);
    await _discovery!.ready;
    _discovery!.eventStream?.listen(_onDiscoveryEvent);
    await _discovery!.start();
  }

  void _onDiscoveryEvent(BonsoirDiscoveryEvent event) async {
    if (event.type != BonsoirDiscoveryEventType.discoveryServiceResolved) return;

    final service = event.service;
    if (service == null) return;

    final remoteDeviceId = service.attributes['did'];
    if (remoteDeviceId == null || remoteDeviceId == _deviceId) return;

    // Check if paired.
    final paired = _storage
        .getPairedDevices()
        .cast<PairedDevice?>()
        .firstWhere((d) => d?.deviceId == remoteDeviceId, orElse: () => null);

    if (paired == null) return;

    // Respect minimum sync interval.
    final last = _lastSyncAt[remoteDeviceId];
    if (last != null && DateTime.now().difference(last) < _minSyncInterval) return;

    final resolved = service as ResolvedBonsoirService;
    final host = resolved.host;
    if (host == null || host.isEmpty) return;

    await syncWithIp(remoteDeviceId, host, _httpPort);
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Future<String> _getLocalIp() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiIP() ?? '127.0.0.1';
    } catch (_) {
      return '127.0.0.1';
    }
  }

  Future<String> _getDeviceName() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return android.model;
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return ios.name;
      }
    } catch (_) {}
    return 'Unknown Device';
  }
}
