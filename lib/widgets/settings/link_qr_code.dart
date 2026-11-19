import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LinkQrCode extends StatelessWidget {
  const LinkQrCode({
    super.key,
    required this.url,
    required this.label,
    this.size = 240,
  });

  final String url;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => QrImageView(
    data: url,
    size: size,
    padding: EdgeInsets.all(size * .1),
    backgroundColor: Colors.white,
    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.circle,
      color: Colors.black,
    ),
    semanticsLabel: label,
  );
}
