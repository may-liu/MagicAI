import 'dart:io';

class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  List<FileNode> children;
  bool isExpanded;
  bool isLoaded;

  FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const [],
    this.isExpanded = false,
    this.isLoaded = false,
  });

  FileNode copyWith(FileNode? newNode) {
    return FileNode(
      name: newNode?.name ?? name,
      path: newNode?.path ?? path,
      isDirectory: newNode?.isDirectory ?? isDirectory,
      children: newNode?.children ?? children,
      isLoaded: newNode?.isLoaded ?? isLoaded,
    );
  }

  static Future<FileNode> fromDirectory(Directory dir) async {
    return FileNode(
      name: dir.path.split(Platform.pathSeparator).last,
      path: dir.path,
      isDirectory: true,
      isLoaded: false,
    );
  }

  Future<FileNode> loadRootDirectory() async {
    children = await _getChildren(Directory(path));
    isLoaded = true;

    return FileNode(
      name: name,
      path: path,
      isDirectory: true,
      children: children,
      isLoaded: true,
    );
  }

  Future<FileNode?> loadChildren() async {
    if (!isDirectory || isLoaded) return null;
    return loadRootDirectory();
  }

  static Future<List<FileNode>> _getChildren(Directory dir) async {
    try {
      final entities = await dir.list().toList();
      final validExtensions = {'.md'};

      final nodes = await Future.wait(
        entities.map((entity) async {
          final isDir = await FileSystemEntity.isDirectory(entity.path);
          final name = entity.path.split(Platform.pathSeparator).last;

          if (isDir) {
            return FileNode.fromDirectory(Directory(entity.path));
          } else if (validExtensions.any((ext) => entity.path.endsWith(ext))) {
            return FileNode(name: name, path: entity.path, isDirectory: false);
          }
          return null; // 标记为可能返回null
        }),
      );

      return nodes.whereType<FileNode>().toList(); // 这里过滤null值
    } catch (e) {
      return [];
    }
  }
}
