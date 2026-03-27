import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = LocalAuthentication();
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    setState(() {
      _authenticating = true;
      _error = null;
    });
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Unlock Pray & Serve',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (authenticated) {
        widget.onUnlock();
      } else {
        setState(() {
          _authenticating = false;
          _error = 'Authentication failed.';
        });
      }
    } catch (_) {
      setState(() {
        _authenticating = false;
        _error = 'Biometrics unavailable on this device.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\u271D',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 72,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pray & Serve',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'YOUR PRIVATE WALK WITH GOD',
                  style: GoogleFonts.sourceSans3(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 48),
                if (_authenticating)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Authenticating...',
                        style: GoogleFonts.sourceSans3(
                            fontSize: 14, color: AppColors.textMuted),
                      ),
                    ],
                  )
                else ...[
                  if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sourceSans3(
                          fontSize: 14, color: AppColors.coral),
                    ),
                    const SizedBox(height: 24),
                  ],
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint, size: 20),
                    label: const Text('Unlock'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
