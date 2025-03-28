import 'package:googleapis/drive/v3.dart' as drive;

abstract interface class GoogleDriveApi {
  Future<List<drive.File>> listFiles({
    String? name,
    String? parentId,
    String? query,
    String? orderBy,
    int? pageSize,
    String? driveId,
    String? fields = "files(id, name, mimeType, createdTime, modifiedTime)",
    bool onlyFolder = false,
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
}
