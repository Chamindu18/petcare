import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/qr_health_passport.dart';
import '../../domain/repositories/qr_health_passport_repository.dart';
import 'verified_health_passport_page.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({
    super.key,
    required this.repository,
    this.verificationOnly = false,
  });

  final QrHealthPassportRepository repository;
  final bool verificationOnly;

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    final token = raw == null ? null : QrHealthPassportPayload.decode(raw);
    if (token == null) {
      setState(() => _error = 'This is not a valid PetCare+ QR code.');
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });
    await _controller.stop();
    try {
      final passport = await widget.repository.verifyQrReference(token);
      if (!mounted) return;
      if (passport == null) {
        setState(() {
          _error = 'QR verification failed. It may be expired, revoked, or unauthorized.';
          _processing = false;
        });
        await _controller.start();
        return;
      }

      if (widget.verificationOnly) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('QR verified'),
            content: Text(
              'This is an active passport for appointment ${_shortId(passport.appointmentId)}. Medical information remains restricted to the assigned veterinarian.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VerifiedHealthPassportPage(
              token: token,
              repository: widget.repository,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'QR verification failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.verificationOnly ? 'Verify QR' : 'Scan Health Passport'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(
              message: error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? 'Camera permission is required to scan the QR code.'
                  : 'The camera is unavailable.',
              onRetry: _controller.start,
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.secondary, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _processing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Verifying...', style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : Text(
                        _error ?? 'Place the PetCare+ QR code inside the frame.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _error == null ? Colors.white : Colors.orangeAccent,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String value) => value.length <= 10
      ? value.toUpperCase()
      : value.substring(0, 10).toUpperCase();
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white, size: 56),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry camera')),
            ],
          ),
        ),
      ),
    );
  }
}
