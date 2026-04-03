import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../services/sync_service.dart';
import '../models/paired_device.dart';
import '../services/storage_service.dart';

enum _Step {
  home,
  newDeviceQr,
  existingDeviceScan,
  pairing,
  done,
  error,
}

class SyncScreen extends StatefulWidget {
  final SyncService syncService;
  final StorageService storage;

  const SyncScreen({
    super.key,
    required this.syncService,
    required this.storage,
  });

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  _Step _step = _Step.home;
  String _statusMessage = '';
  Map<String, dynamic>? _qrData;
  final _localAuth = LocalAuthentication();
  StreamSubscription<SyncEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = widget.syncService.events.listen(_onSyncEvent);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    if (_step == _Step.newDeviceQr) {
      widget.syncService.cancelPairingSession();
    }
    super.dispose();
  }

  void _onSyncEvent(SyncEvent event) {
    if (!mounted) return;
    switch (event) {
      case SyncEventPaired(:final deviceName):
        if (_step == _Step.newDeviceQr || _step == _Step.pairing) {
          setState(() {
            _step = _Step.done;
            _statusMessage = 'Paired with $deviceName! Your data is syncing…';
          });
        }
      case SyncEventSynced(:final deviceName, :final added):
        if (_step == _Step.done) {
          setState(() {
            _statusMessage = added > 0
                ? 'Synced with $deviceName — $added item(s) added.'
                : 'Up to date with $deviceName.';
          });
        }
      case SyncEventFailed(:final error):
        if (_step == _Step.pairing) {
          setState(() {
            _step = _Step.error;
            _statusMessage = error;
          });
        }
    }
  }

  // -------------------------------------------------------------------------
  // "New device" flow: show QR for the existing device to scan.
  // -------------------------------------------------------------------------

  Future<void> _startNewDeviceMode() async {
    final data = await widget.syncService.startPairingSession();
    setState(() {
      _qrData = data;
      _step = _Step.newDeviceQr;
    });
  }

  // -------------------------------------------------------------------------
  // "Existing device" flow: scan QR from the new device.
  // -------------------------------------------------------------------------

  void _startExistingDeviceMode() {
    setState(() => _step = _Step.existingDeviceScan);
  }

  Future<void> _onQrScanned(String rawValue) async {
    Map<String, dynamic> qrData;
    try {
      qrData = jsonDecode(rawValue) as Map<String, dynamic>;
      if (qrData['mode'] != 'pair') throw const FormatException();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid pairing QR code.')),
        );
      }
      return;
    }

    setState(() {
      _step = _Step.pairing;
      _statusMessage = 'Waiting for biometric approval…';
    });

    // Biometric auth to approve pairing.
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Approve pairing with ${qrData['deviceName']}',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!authenticated) {
        setState(() {
          _step = _Step.error;
          _statusMessage = 'Authentication cancelled.';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _step = _Step.error;
        _statusMessage = 'Biometric unavailable: $e';
      });
      return;
    }

    setState(() => _statusMessage = 'Pairing…');

    try {
      await widget.syncService.completePairing(qrData);
      // Success event will be handled by _onSyncEvent.
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _Step.error;
          _statusMessage = 'Pairing failed: $e';
        });
      }
    }
  }

  // -------------------------------------------------------------------------
  // Paired devices management
  // -------------------------------------------------------------------------

  Future<void> _manualSync(PairedDevice device) async {
    // We don't have the IP here — mDNS will find it when devices are nearby.
    // Show a message guiding the user.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Auto-sync with ${device.deviceName} will happen when both devices are on the same WiFi.'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _unpair(PairedDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Remove ${device.deviceName}?',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 20, color: AppColors.textPrimary)),
        content: Text(
          'This device will no longer be able to sync with this one.',
          style: GoogleFonts.sourceSans3(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove',
                  style: TextStyle(color: AppColors.coral))),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.syncService.unpairDevice(device.deviceId);
      if (mounted) setState(() {});
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgHeader,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Device Sync',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: switch (_step) {
          _Step.home => _buildHome(),
          _Step.newDeviceQr => _buildNewDeviceQr(),
          _Step.existingDeviceScan => _buildScanner(),
          _Step.pairing => _buildProgress(_statusMessage),
          _Step.done => _buildDone(),
          _Step.error => _buildError(),
        },
      ),
    );
  }

  // --- Home ---

  Widget _buildHome() {
    final paired = widget.storage.getPairedDevices();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('PAIR A DEVICE'),
          const SizedBox(height: 12),
          _PairingCard(
            icon: Icons.qr_code_2,
            title: 'New device',
            subtitle: 'Show a QR code for your other device to scan',
            onTap: _startNewDeviceMode,
          ),
          const SizedBox(height: 12),
          _PairingCard(
            icon: Icons.qr_code_scanner,
            title: 'I have an existing device',
            subtitle: 'Scan the QR code shown on the new device',
            onTap: _startExistingDeviceMode,
          ),
          if (paired.isNotEmpty) ...[
            const SizedBox(height: 28),
            _sectionLabel('PAIRED DEVICES'),
            const SizedBox(height: 12),
            ...paired.map((d) => _PairedDeviceTile(
                  device: d,
                  onSync: () => _manualSync(d),
                  onRemove: () => _unpair(d),
                )),
          ],
          const SizedBox(height: 24),
          _buildSecurityNote(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.sourceSans3(
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600),
      );

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 16, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sync is end-to-end encrypted with AES-256-GCM. Your data never leaves your WiFi network. Pairing requires biometric approval on the authorising device.',
              style: GoogleFonts.sourceSans3(
                  fontSize: 12, color: AppColors.textMuted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // --- QR display (new device waiting to be scanned) ---

  Widget _buildNewDeviceQr() {
    final qrJson = jsonEncode(_qrData);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan from your other device',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Open Pray & Serve on the device you want to connect, tap "Sync with Device" → "I have an existing device", then scan this code.',
              style: GoogleFonts.sourceSans3(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: qrJson,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Expires in 5 minutes',
              style: GoogleFonts.sourceSans3(
                  fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: () {
                widget.syncService.cancelPairingSession();
                setState(() => _step = _Step.home);
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.border)),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Camera scanner ---

  Widget _buildScanner() {
    bool scanned = false;
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            if (scanned) return;
            final barcode = capture.barcodes.firstOrNull;
            final raw = barcode?.rawValue;
            if (raw != null && raw.isNotEmpty) {
              scanned = true;
              controller.stop();
              _onQrScanned(raw);
            }
          },
        ),
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: Container(color: Colors.black54),
              ),
              SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(color: Colors.transparent),
                    ),
                    Center(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.gold, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    'Point at the QR on the new device',
                    style: GoogleFonts.sourceSans3(
                        fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _step = _Step.home),
          ),
        ),
      ],
    );
  }

  // --- Progress spinner ---

  Widget _buildProgress(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                color: AppColors.gold, strokeWidth: 2),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceSans3(
                  fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // --- Success ---

  Widget _buildDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.green, size: 64),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceSans3(
                  fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() => _step = _Step.home),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Error ---

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.coral, size: 64),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceSans3(
                  fontSize: 14, color: AppColors.coral, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() => _step = _Step.home),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _PairingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PairingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.sourceSans3(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.sourceSans3(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PairedDeviceTile extends StatelessWidget {
  final PairedDevice device;
  final VoidCallback onSync;
  final VoidCallback onRemove;

  const _PairedDeviceTile({
    required this.device,
    required this.onSync,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final pairedDate = device.pairedAt.split('T')[0];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.devices, color: AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.deviceName,
                    style: GoogleFonts.sourceSans3(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text('Paired $pairedDate',
                    style: GoogleFonts.sourceSans3(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.gold, size: 20),
            onPressed: onSync,
            tooltip: 'Sync info',
          ),
          IconButton(
            icon: const Icon(Icons.link_off, color: AppColors.coral, size: 20),
            onPressed: onRemove,
            tooltip: 'Remove device',
          ),
        ],
      ),
    );
  }
}
