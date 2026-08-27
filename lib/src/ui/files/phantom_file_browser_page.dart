import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../theme/phantom_theme.dart';
import '../../utils/json_formatter.dart';

/// Sandbox file browser.
///
/// With no [directory] it lists the app's storage roots (documents, support,
/// cache, temp); from there it recurses into subdirectories.
class PhantomFileBrowserPage extends StatefulWidget {
  final Directory? directory;
  final String? title;

  const PhantomFileBrowserPage({super.key, this.directory, this.title});

  @override
  State<PhantomFileBrowserPage> createState() => _PhantomFileBrowserPageState();
}

class _PhantomFileBrowserPageState extends State<PhantomFileBrowserPage> {
  List<_FileItem> _items = [];
  bool _loading = true;
  String? _errorMessage;

  bool get _isRoot => widget.directory == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = _isRoot ? await _loadRoots() : await _loadDirectory();
      if (!mounted) return;
      setState(() {
        _items = items;
        _errorMessage = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<_FileItem>> _loadRoots() async {
    final roots = <_FileItem>[];

    Future<void> add(String label, Future<Directory?> Function() resolve) async {
      try {
        final dir = await resolve();
        if (dir == null || !dir.existsSync()) return;
        if (roots.any((r) => r.entity.path == dir.path)) return;
        roots.add(_FileItem(
          name: label,
          entity: dir,
          isDirectory: true,
          size: 0,
          modifiedDate: dir.statSync().modified,
          subtitleOverride: dir.path,
        ));
      } catch (_) {
        // Root not available on this platform — skip it.
      }
    }

    await add('Documents', getApplicationDocumentsDirectory);
    await add('Application Support', getApplicationSupportDirectory);
    await add('Cache', getApplicationCacheDirectory);
    await add('Temporary', getTemporaryDirectory);
    if (Platform.isIOS || Platform.isMacOS) {
      await add('Library', getLibraryDirectory);
    }
    if (Platform.isAndroid) {
      await add('External Storage', getExternalStorageDirectory);
    }
    return roots;
  }

  Future<List<_FileItem>> _loadDirectory() async {
    final entities = widget.directory!.listSync(followLinks: false);
    final items = <_FileItem>[];

    for (final entity in entities) {
      final name = entity.path.split(Platform.pathSeparator).last;
      if (name.startsWith('.')) continue;
      FileStat stat;
      try {
        stat = entity.statSync();
      } catch (_) {
        continue;
      }
      items.add(_FileItem(
        name: name,
        entity: entity,
        isDirectory: stat.type == FileSystemEntityType.directory,
        size: stat.size,
        modifiedDate: stat.modified,
      ));
    }

    items.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text(
          widget.title ?? 'File Browser',
          style:
              TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.onBackground, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(PhantomTheme theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.error, fontSize: 13),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, color: theme.onBackgroundVariant, size: 40),
            const SizedBox(height: 12),
            Text(
              'Empty directory',
              style:
                  TextStyle(color: theme.onBackgroundVariant, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _fileRow(_items[index], theme),
    );
  }

  Widget _fileRow(_FileItem item, PhantomTheme theme) {
    final canPreview = !item.isDirectory && item.canPreview;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (item.isDirectory) {
          _openDirectory(item, theme);
        } else if (canPreview) {
          _previewFile(item, theme);
        }
      },
      onLongPress: () => _showActions(item, theme, canPreview),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.outlineVariant),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Icon(
                item.icon,
                size: 18,
                color: item.isDirectory
                    ? theme.primary
                    : theme.onBackgroundVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: theme.onBackground,
                      fontSize: 14,
                      fontWeight:
                          item.isDirectory ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: theme.onBackgroundVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (item.isDirectory)
              Icon(Icons.chevron_right,
                  color: theme.onBackgroundVariant, size: 16),
          ],
        ),
      ),
    );
  }

  void _openDirectory(_FileItem item, PhantomTheme theme) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhantomThemeProvider(
          theme: theme,
          child: PhantomFileBrowserPage(
            directory: Directory(item.entity.path),
            title: item.name,
          ),
        ),
      ),
    );
  }

  Future<void> _previewFile(_FileItem item, PhantomTheme theme) async {
    String contents;
    try {
      contents = await File(item.entity.path).readAsString();
      contents = prettyPrintJson(contents) ?? contents;
    } catch (e) {
      contents = 'Error reading file: $e';
    }
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhantomThemeProvider(
          theme: theme,
          child: _FilePreviewPage(title: item.name, contents: contents),
        ),
      ),
    );
  }

  void _showActions(_FileItem item, PhantomTheme theme, bool canPreview) {
    if (_isRoot) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                item.name,
                style: TextStyle(
                  color: theme.onBackground,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (canPreview)
              ListTile(
                leading: Icon(Icons.visibility, color: theme.info, size: 20),
                title: Text('Preview',
                    style: TextStyle(color: theme.onBackground, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _previewFile(item, theme);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.error, size: 20),
              title: Text('Delete',
                  style: TextStyle(color: theme.error, fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(item, theme);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(_FileItem item, PhantomTheme theme) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Delete ${item.name}?',
            style: TextStyle(color: theme.onBackground, fontSize: 16)),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: theme.onBackgroundVariant, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: theme.onBackgroundVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await item.entity.delete(recursive: item.isDirectory);
              } catch (_) {}
              await _load();
            },
            child: Text('Delete',
                style: TextStyle(
                    color: theme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _FilePreviewPage extends StatelessWidget {
  final String title;
  final String contents;

  const _FilePreviewPage({required this.title, required this.contents});

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text(
          title,
          style:
              TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          contents,
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _FileItem {
  final String name;
  final FileSystemEntity entity;
  final bool isDirectory;
  final int size;
  final DateTime? modifiedDate;
  final String? subtitleOverride;

  const _FileItem({
    required this.name,
    required this.entity,
    required this.isDirectory,
    required this.size,
    this.modifiedDate,
    this.subtitleOverride,
  });

  static const _previewableExtensions = {
    'json', 'txt', 'log', 'plist', 'xml', 'csv', 'yaml', 'yml', 'md', //
  };

  String get extension {
    final index = name.lastIndexOf('.');
    if (index == -1 || index == name.length - 1) return '';
    return name.substring(index + 1).toLowerCase();
  }

  bool get canPreview => _previewableExtensions.contains(extension);

  String get subtitle {
    if (subtitleOverride != null) return subtitleOverride!;
    final parts = <String>[];
    if (!isDirectory) parts.add(_formattedSize);
    if (modifiedDate != null) parts.add(_formattedDate);
    return parts.join('  ·  ');
  }

  String get _formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get _formattedDate {
    final d = modifiedDate!;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, $hh:$mm';
  }

  IconData get icon {
    if (isDirectory) return Icons.folder;
    switch (extension) {
      case 'json':
        return Icons.data_object;
      case 'plist':
      case 'xml':
      case 'yaml':
      case 'yml':
        return Icons.list_alt;
      case 'sqlite':
      case 'db':
      case 'sqlite3':
        return Icons.storage;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return Icons.image_outlined;
      case 'log':
      case 'txt':
      case 'md':
      case 'csv':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
