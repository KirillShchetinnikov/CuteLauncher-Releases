import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standalone Flutter-only reproduction. The build script supplies fixture.png;
/// no CuteLauncher services, preferences, database or platform bridge are used.
/// Start with route /original or /resize in a fresh process for each case.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(color: Colors.black, child: ImageProbe()),
    ),
  );
}

class ImageProbe extends StatefulWidget {
  const ImageProbe({super.key});

  @override
  State<ImageProbe> createState() => _ImageProbeState();
}

class _ImageProbeState extends State<ImageProbe> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
      if (mounted) await _decode();
    });
  }

  Future<void> _decode() async {
    final resize =
        ui.PlatformDispatcher.instance.defaultRouteName != '/original';
    final data = await rootBundle.load('assets/fixture.png');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    debugPrint(
      'IMPELLER_IMAGE_PROBE source=${descriptor.width}x${descriptor.height}'
      ' target=${resize ? "160x90" : "original"}',
    );
    descriptor.dispose();
    buffer.dispose();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: resize ? 160 : null,
      targetHeight: resize ? 90 : null,
      allowUpscaling: false,
    );
    try {
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint(
            'IMPELLER_IMAGE_PROBE frame_ready='
            '${frame.image.width}x${frame.image.height}',
          );
        }
      });
    } finally {
      codec.dispose();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Center(child: RawImage(image: _image, width: 640, height: 360));
}
