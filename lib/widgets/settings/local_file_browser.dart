import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../bridge_result.dart';
import '../../l10n/app_localizations.dart';
import '../launcher_dialog.dart';
import '../remote_text_input.dart';
import '../menu_header_action.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_read_only_value.dart';

const wallpaperFolderChannel = BridgeChannel('me.efesser.flauncher/method');

Future<String?> enterWallpaperFolderPath(
  BuildContext context,
  String initial,
) async {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial);
  try {
    return await showLauncherDialog<String>(
      context: context,
      builder: (dialog) => LauncherAlertDialog(
        title: Text(l.slideshowEnterFolderPath),
        content: RemoteTextInput(
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 2048,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l.slideshowFolderPath,
              hintText: '/storage/emulated/0/Pictures',
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) Navigator.pop(dialog, value.trim());
            },
          ),
        ),
        actions: [
          LauncherDialogButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
          ),
          LauncherDialogButton(
            primary: true,
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialog, controller.text.trim());
              }
            },
            child: Text(MaterialLocalizations.of(dialog).okButtonLabel),
          ),
        ],
      ),
    );
  } finally {
    // The route finishes its transition before the editor is disposed.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }
}

enum FileBrowserKind { folder, image, media, document, text }

/// One route for local folders and documents; Back always navigates upward.
class LocalFileBrowser extends StatefulWidget {
  final String? initialPath;
  final FileBrowserKind kind;
  final String? saveName;
  final String? title;
  final String? formatHint;
  const LocalFileBrowser({
    super.key,
    this.initialPath,
    this.kind = FileBrowserKind.folder,
    this.saveName,
    this.title,
    this.formatHint,
  });
  @override
  State<LocalFileBrowser> createState() => _LocalFileBrowserState();
}

class _LocalFileBrowserState extends State<LocalFileBrowser> {
  Map<Object?, Object?>? folder;
  bool busy = true;
  String? error;
  String? _attemptedPath;
  final _upFocus = FocusNode();
  final _closeFocus = FocusNode();
  final _pathFocus = FocusNode();
  final _selectFocus = FocusNode();
  Map<String, FocusNode> _nodes = {};
  final _positions = <String, double>{};
  final _selections = <String, String>{};
  List<Map> _cachedEntries = const [];
  ScrollController? _scroll;
  int _generation = 0;
  bool _movedDuringLoad = false;

  String get _path => folder?['path'] as String? ?? widget.initialPath ?? '';
  String get _parent =>
      error != null && _attemptedPath != _path && folder != null
      ? _path
      : folder?['parent'] as String? ?? '';
  bool get _foldersOnly => widget.kind == FileBrowserKind.folder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => open(widget.initialPath),
    );
  }

  @override
  void dispose() {
    _generation++;
    _upFocus.dispose();
    _closeFocus.dispose();
    _pathFocus.dispose();
    _selectFocus.dispose();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  List<Map> _entries(Map<Object?, Object?>? data) => [
    ...(data?['folders'] as List? ?? const []).cast<Map>(),
    ...(data?['files'] as List? ?? const []).cast<Map>(),
  ];

  FocusNode _node(String path) => _nodes.putIfAbsent(path, () {
    final node = FocusNode();
    node.addListener(() {
      if (node.hasFocus) _selections[_path] = path;
    });
    return node;
  });

  FocusNode? _visibleNode(String? preferred) {
    final viewport = _scroll?.position.context.notificationContext
        ?.findRenderObject();
    bool visible(FocusNode node) =>
        node.context?.mounted == true &&
        (viewport is! RenderBox ||
            node.rect.overlaps(
              viewport.localToGlobal(Offset.zero) & viewport.size,
            ));
    final candidate = _nodes[preferred];
    if (candidate != null && visible(candidate)) return candidate;
    for (final node in _nodes.values) {
      if (visible(node)) return node;
    }
    return null;
  }

  Future<void> open(String? path, {String? restore}) async {
    if (!mounted || busy && folder != null) return;
    _attemptedPath = path;
    final generation = ++_generation;
    final previousFocus = FocusManager.instance.primaryFocus;
    if (_scroll?.hasClients == true) {
      if (_positions.length >= 100) {
        _selections.remove(_positions.keys.first);
        _positions.remove(_positions.keys.first);
      }
      _positions[_path] = _scroll!.offset;
      for (final entry in _nodes.entries) {
        if (entry.value.hasFocus) _selections[_path] = entry.key;
      }
    }
    setState(() {
      busy = true;
      _movedDuringLoad = false;
      error = null;
    });
    try {
      final data = await wallpaperFolderChannel
          .invokeMapMethod<Object?, Object?>('browseLocalFiles', {
            'path': path,
            'kind': widget.kind.name,
          });
      if (!mounted || generation != _generation) return;
      if (data == null) throw StateError('Missing folder');
      final oldNodes = _nodes;
      setState(() {
        folder = data;
        _cachedEntries = _entries(data);
        _nodes = {};
        busy = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in oldNodes.values) {
          node.dispose();
        }
        if (!mounted || generation != _generation) return;
        if (_scroll?.hasClients == true) {
          _scroll!.jumpTo(
            (_positions[_path] ?? 0).clamp(
              0,
              _scroll!.position.maxScrollExtent,
            ),
          );
        }
        // Scroll restoration materializes a previously visible lazy row first.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || generation != _generation || _movedDuringLoad) {
            return;
          }
          final target =
              _visibleNode(restore ?? _selections[_path]) ??
              (_foldersOnly
                  ? _selectFocus
                  : _parent.isNotEmpty
                  ? _upFocus
                  : _closeFocus);
          if (target.context != null) target.requestFocus();
        });
        WidgetsBinding.instance.scheduleFrame();
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        busy = false;
        error = AppLocalizations.of(context)!.fileBrowserUnavailable;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _generation || _closeFocus.hasFocus) {
          return;
        }
        if (previousFocus?.context != null) {
          previousFocus!.requestFocus();
        } else {
          _upFocus.requestFocus();
        }
      });
    }
  }

  void _up() {
    if (busy || _parent.isEmpty) return;
    open(_parent, restore: _path);
  }

  String _fileDetails(Map entry) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final bytes = entry['size'];
    var size = l.memoryUnavailable;
    if (bytes is num && bytes >= 0) {
      var value = bytes.toDouble();
      const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
      var unit = 0;
      while (value >= 1024 && unit < units.length - 1) {
        value /= 1024;
        unit++;
      }
      size = '${NumberFormat('0.##', locale).format(value)} ${units[unit]}';
    }
    final created = entry['created'];
    final modified = entry['modified'];
    final stamp = created is num && created > 0 ? created : modified;
    final date = stamp is num && stamp > 0
        ? DateFormat.yMd(locale)
              .add_Hm()
              .format(DateTime.fromMillisecondsSinceEpoch(stamp.toInt()))
        : l.memoryUnavailable;
    return '$size · ${l.date}: $date';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final directories = (folder?['folders'] as List? ?? const []).cast<Map>();
    final entries = _cachedEntries;
    return PopScope<String>(
      canPop: !busy && _parent.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _up();
      },
      child: Focus(
        skipTraversal: true,
        onKeyEvent: (_, event) {
          if (busy && event is KeyDownEvent) _movedDuringLoad = true;
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            if (_parent.isEmpty && !busy) {
              Navigator.maybePop(context);
            } else {
              _up();
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SettingsPageLayout(
          showDivider: false,
          title: IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                padding: const EdgeInsets.all(4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            child: Row(
              children: [
                MenuHeaderAction(
                  focusNode: _upFocus,
                  tooltip: l.slideshowParentFolder,
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: !busy && _parent.isNotEmpty ? _up : null,
                ),
                Expanded(
                  child: Text(
                    widget.title ??
                        (widget.saveName != null
                            ? l.save
                            : _foldersOnly
                            ? l.slideshowBrowseFolders
                            : l.fileBrowserTitle),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                MenuHeaderAction(
                  focusNode: _closeFocus,
                  tooltip: l.close,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsReadOnlyValue(
                compact: true,
                label: l.fileBrowserCurrentFolder,
                value: error == null ? _path : _attemptedPath ?? _path,
                focusNode: _pathFocus,
                textDirection: TextDirection.ltr,
                readingHeight: 64,
              ),
              if (widget.formatHint != null && widget.saveName == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    widget.formatHint!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const Divider(height: 8),
            ],
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.saveName != null)
                SettingsReadOnlyValue(
                  compact: true,
                  label: l.fileBrowserFileName,
                  value: widget.saveName!,
                  readingHeight: 48,
                  textDirection: TextDirection.ltr,
                ),
              Text(
                _foldersOnly
                    ? l.fileBrowserRemoteHint
                    : l.fileBrowserReadNameHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_foldersOnly)
                FocusableSettingsTile(
                  dense: true,
                  focusNode: _selectFocus,
                  enabled: !busy && error == null && folder != null,
                  showActionChevron: false,
                  onKeyEvent: (_, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      final node = _nodes[_selections[_path]];
                      if (node?.context != null) node!.requestFocus();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  leading: Icon(
                    widget.saveName == null
                        ? Icons.check_circle_outline
                        : Icons.save_outlined,
                  ),
                  title: Text(
                    widget.saveName == null ? l.slideshowUseFolder : l.save,
                  ),
                  onPressed: () {
                    if (!busy && error == null && folder != null) {
                      Navigator.pop(context, folder!['uri'] as String);
                    }
                  },
                ),
            ],
          ),
          child: Builder(
            builder: (context) {
              _scroll = PrimaryScrollController.of(context);
              return ListView.builder(
                itemCount: (error == null ? entries.length : 0) + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return SizedBox(
                      height: 4,
                      child: busy ? const LinearProgressIndicator() : null,
                    );
                  }
                  if (index == 1) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (error != null)
                          FocusableSettingsTile(
                            title: Text('$error\n${l.backgroundStartupRetry}'),
                            leading: const Icon(Icons.refresh),
                            onPressed: () => open(_attemptedPath),
                          )
                        else if (!busy && entries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _foldersOnly
                                  ? l.fileBrowserNoFolders
                                  : l.fileBrowserNoFiles,
                            ),
                          ),
                        if (folder?['truncated'] == true)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(l.fileBrowserPartial),
                          ),
                      ],
                    );
                  }
                  final entry = entries[index - 2];
                  final path = entry['path'] as String;
                  final directory = index - 2 < directories.length;
                  return _FileBrowserRow(
                    key: ValueKey(path),
                    focusNode: _node(path),
                    enabled: !busy,
                    showActionChevron: directory,
                    onKeyEvent: (_, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.arrowRight &&
                          _foldersOnly) {
                        _selections[_path] = path;
                        _selectFocus.requestFocus();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    name: entry['name'] as String,
                    details: directory ? null : _fileDetails(entry),
                    leading: Icon(
                      directory
                          ? Icons.folder_outlined
                          : const {
                              'mp4',
                              'm4v',
                              'mkv',
                              'webm',
                              'mov',
                              'avi',
                              '3gp',
                            }.contains(
                              (entry['name'] as String)
                                  .split('.')
                                  .last
                                  .toLowerCase(),
                            )
                          ? Icons.movie_outlined
                          : widget.kind == FileBrowserKind.image ||
                                widget.kind == FileBrowserKind.media
                          ? Icons.image_outlined
                          : Icons.description_outlined,
                    ),
                    onPressed: () {
                      if (busy) return;
                      if (directory) {
                        open(path);
                      } else {
                        Navigator.pop(
                          context,
                          Uri.file(path, windows: false).toString(),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Keep a long name readable without changing the row's activation action.
class _FileBrowserRow extends StatefulWidget {
  final FocusNode focusNode;
  final bool enabled, showActionChevron;
  final FocusOnKeyEventCallback onKeyEvent;
  final String name;
  final String? details;
  final Widget leading;
  final VoidCallback onPressed;
  const _FileBrowserRow({
    super.key,
    required this.focusNode,
    required this.enabled,
    required this.showActionChevron,
    required this.onKeyEvent,
    required this.name,
    this.details,
    required this.leading,
    required this.onPressed,
  });
  @override
  State<_FileBrowserRow> createState() => _FileBrowserRowState();
}

class _FileBrowserRowState extends State<_FileBrowserRow> {
  final _scroll = ScrollController();
  bool _expanded = false;
  bool _nameOverflows = false;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    focusNode: widget.focusNode,
    enabled: widget.enabled,
    showActionChevron: widget.showActionChevron,
    onFocusChange: (focused) {
      if (!focused && _expanded && mounted) setState(() => _expanded = false);
    },
    leading: widget.leading,
    title: LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(
            text: widget.name,
            style: DefaultTextStyle.of(context).style,
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.localeOf(context),
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: constraints.maxWidth);
        _nameOverflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_expanded && _nameOverflows)
              SizedBox(
                height: 80,
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    primary: false,
                    child: Text(widget.name),
                  ),
                ),
              )
            else
              Text(widget.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (widget.details != null)
              Text(
                widget.details!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      },
    ),
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_nameOverflows || _expanded) {
          setState(() => _expanded = !_expanded);
        }
        return KeyEventResult.handled;
      }
      if (_expanded &&
          _scroll.hasClients &&
          (event is KeyDownEvent || event is KeyRepeatEvent) &&
          (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.arrowUp)) {
        final next =
            (_scroll.offset +
                    (event.logicalKey == LogicalKeyboardKey.arrowDown
                        ? 50
                        : -50))
                .clamp(0.0, _scroll.position.maxScrollExtent);
        if (next != _scroll.offset) {
          _scroll.jumpTo(next);
          return KeyEventResult.handled;
        }
      }
      return widget.onKeyEvent(node, event);
    },
    onPressed: widget.onPressed,
  );
}
