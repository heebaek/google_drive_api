import 'package:googleapis/drive/v3.dart' as drive;

abstract interface class GoogleDriveApi {
  Future<List<drive.File>> listFiles({
    String? name,
    String? parentId,
    String? query,
    String? orderBy,
    int? pageSize = 1,
    String? driveId,
    String? fields = "id, name, mimeType, createdTime, modifiedTime, size",
    bool onlyFolder = false,
    bool onlyFile = false,
    String? mimeType,
    includeItemsFromAllDrives = false,
    String? space = "drive",
  });

  Future<drive.File> createFile(
    String parentId,
    String fileName,
    Stream<List<int>> dataStream, {
    DateTime? originalDate,
    int? fileSize,
    String contentType = 'application/octet-stream',
  });

  Future<drive.File> createFolder(
    String parentId,
    String folderName    
  );

  Future<void> delete(String fileId);

  Future<String?> getParents(String fileId);

  Future<void> moveFile(String fromId, String toId);

  Future<void> rename(String fileId, String newName);

  Future<Stream<List<int>>> getFileStream(String fileId);
}
