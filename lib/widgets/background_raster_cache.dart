import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/memory_resources.dart';
import '../providers/foreground_work.dart';

/// One bounded texture for a decorative background, rebuilt on layer changes.
/// Unlike an extra repaint boundary, this flattens static GPU passes as well.
/// Nested animations still invalidate the layer; no timer freezes the scene.
class BackgroundRasterCache extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const BackgroundRasterCache({
    super.key,
    required this.child,
    this.enabled = true,
  });
  @override
  State<BackgroundRasterCache> createState() => _BackgroundRasterCacheState();
}

class _BackgroundRasterCacheState extends State<BackgroundRasterCache>
    with WidgetsBindingObserver {
  _BackgroundCacheRender? _render;
  MemoryResources? _resources;
  ForegroundWork? _work;
  bool _activationScheduled = false;
  bool _ready = false;
  bool _pressure = false;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_activationScheduled) {
      _activationScheduled = true;
      _work = context.read<ForegroundWork?>();
      if (_work != null) {
        unawaited(
          _work!.schedule(this, () async {
            if (mounted) setState(() => _ready = true);
          }, delay: const Duration(milliseconds: 500)),
        );
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _ready = true);
        });
      }
    }
    final resources = context.read<MemoryResources?>();
    if (identical(resources, _resources)) return;
    _resources?.unregister(this);
    _resources = resources;
    resources?.register(
      this,
      clear: () => _render?.evict(),
      // Texture memory belongs to Graphics/PSS, not the encoded-image total.
      stats: () => const MemoryCacheStats(0, 0),
      activity: () => {'background_raster_bytes': _render?.cacheBytes ?? 0},
    );
  }

  @override
  void didHaveMemoryPressure() {
    _render?.evict(disable: true);
    if (mounted) setState(() => _pressure = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (!foreground) _render?.evict(disable: true);
    if (mounted) {
      setState(() {
        _foreground = foreground;
        if (foreground) _pressure = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _BackgroundCacheWidget(
    enabled: widget.enabled && _ready && _foreground && !_pressure,
    onCreated: (render) => _render = render,
    child: widget.child,
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resources?.unregister(this);
    _work?.cancel(this);
    _render?.evict(disable: true);
    _render = null;
    super.dispose();
  }
}

class _BackgroundCacheWidget extends SingleChildRenderObjectWidget {
  final bool enabled;
  final void Function(_BackgroundCacheRender) onCreated;
  const _BackgroundCacheWidget({
    required super.child,
    required this.enabled,
    required this.onCreated,
  });
  @override
  RenderObject createRenderObject(BuildContext context) {
    final render = _BackgroundCacheRender(
      enabled,
      MediaQuery.devicePixelRatioOf(context),
    );
    onCreated(render);
    return render;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _BackgroundCacheRender renderObject,
  ) => renderObject.configure(enabled, MediaQuery.devicePixelRatioOf(context));
}

class _BackgroundCacheRender extends RenderRepaintBoundary {
  bool _enabled;
  double _pixelRatio;
  _BackgroundCacheRender(this._enabled, this._pixelRatio);
  int get cacheBytes => layer is _BackgroundCacheLayer
      ? (layer! as _BackgroundCacheLayer).cacheBytes
      : 0;
  void evict({bool disable = false}) {
    if (disable) _enabled = false;
    final current = layer;
    if (current is _BackgroundCacheLayer) {
      if (disable) {
        current.configure(size, _pixelRatio, false);
      } else {
        current.evict();
      }
    }
  }

  void configure(bool enabled, double pixelRatio) {
    if (_enabled == enabled && _pixelRatio == pixelRatio) return;
    _enabled = enabled;
    _pixelRatio = pixelRatio;
    markNeedsCompositedLayerUpdate();
  }

  @override
  _BackgroundCacheLayer updateCompositedLayer({
    covariant _BackgroundCacheLayer? oldLayer,
  }) {
    final result = oldLayer ?? _BackgroundCacheLayer();
    result.configure(size, _pixelRatio, _enabled);
    return result;
  }
}

class _BackgroundCacheLayer extends OffsetLayer {
  Size _size = Size.zero;
  double _pixelRatio = 1;
  bool _enabled = true;
  bool _failed = false;
  ui.Image? _image;
  ui.Picture? _picture;
  int get cacheBytes => _image == null ? 0 : _image!.width * _image!.height * 4;
  void evict() {
    _dropImage();
    markNeedsAddToScene();
  }

  void configure(Size size, double ratio, bool enabled) {
    if (_size == size && _pixelRatio == ratio && _enabled == enabled) return;
    _size = size;
    _pixelRatio = ratio;
    _enabled = enabled;
    _failed = false;
    _dropImage();
    markNeedsAddToScene();
  }

  void _dropImage() {
    _picture?.dispose();
    _picture = null;
    _image?.dispose();
    _image = null;
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    _dropImage();
    // Retained rendering skips this method until this layer or a descendant
    // changes. Even changes inside nested repaint/opacity layers invalidate it.
    if (!_size.isFinite || !_pixelRatio.isFinite || _pixelRatio <= 0) {
      super.addToScene(builder);
      return;
    }
    final width = (_size.width * _pixelRatio).ceil();
    final height = (_size.height * _pixelRatio).ceil();
    if (!_enabled ||
        _failed ||
        width <= 0 ||
        height <= 0 ||
        width * height * 4 > 16 * 1024 * 1024 ||
        !supportsRasterization()) {
      super.addToScene(builder);
      return;
    }
    final offscreen = ui.SceneBuilder();
    offscreen.pushTransform(
      Matrix4.diagonal3Values(_pixelRatio, _pixelRatio, 1).storage,
    );
    addChildrenToScene(offscreen);
    offscreen.pop();
    final scene = offscreen.build();
    try {
      _image = scene.toImageSync(width, height);
    } catch (_) {
      _failed = true;
      super.addToScene(builder);
      return;
    } finally {
      scene.dispose();
    }
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      _image!,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Offset.zero & _size,
      Paint()..filterQuality = FilterQuality.none,
    );
    _picture = recorder.endRecording();
    engineLayer = builder.pushOffset(
      offset.dx,
      offset.dy,
      oldLayer: engineLayer as ui.OffsetEngineLayer?,
    );
    builder.addPicture(Offset.zero, _picture!);
    builder.pop();
  }

  @override
  void dispose() {
    _dropImage();
    super.dispose();
  }
}
