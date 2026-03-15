import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MenuSyncPage extends StatefulWidget {
  const MenuSyncPage({
    super.key,
    required this.hotelName,
    required this.hotelHours,
    required this.menuId,
    required this.menuUrl,
  });

  final String hotelName;
  final String hotelHours;
  final String menuId;
  final String menuUrl;

  @override
  State<MenuSyncPage> createState() => _MenuSyncPageState();
}

class _MenuSyncPageState extends State<MenuSyncPage> {
  final GlobalKey _captureKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _saveQrCard() async {
    if (_isSaving) {
      return;
    }
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving images is not supported on web.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Capture area is not ready');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode image');
      }
      final pngBytes = byteData.buffer.asUint8List();
      final outputFile = await _createOutputFile();
      await outputFile.writeAsBytes(pngBytes);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved QR image to ${outputFile.path}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save QR image: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<File> _createOutputFile() async {
    final home = Platform.environment['HOME'];
    final baseDir = home == null
        ? Directory.current
        : Directory('$home/Downloads');
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    return File('${baseDir.path}/menu-sync-${widget.menuId}-$timestamp.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Sync')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sync complete',
                    style: GoogleFonts.fraunces(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C1A18),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Share this QR code to open the live hotel menu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  RepaintBoundary(
                    key: _captureKey,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F5EF),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: QrImageView(
                              data: widget.menuUrl,
                              size: 240,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF0F2B3A),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF0F2B3A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _InfoRow(label: 'Hotel', value: widget.hotelName),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Hours', value: widget.hotelHours),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Menu ID', value: widget.menuId),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'URL', value: widget.menuUrl),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _saveQrCard,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_rounded),
                          label: Text(
                            _isSaving
                                ? 'Saving...'
                                : 'Save QR Code Image',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F2B3A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1A18),
            ),
          ),
        ],
      ),
    );
  }
}
