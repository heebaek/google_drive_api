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
    String? space = "drive",
  });

  Future<List<drive.Drive>> listDrives();

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

  Future<void> moveFolder(String fromId, String toId);

  Future<void> copyFile(String fromId, String toId);

  Future<void> copyFolder(String fromId, String toId, {required String? driveId});

  Future<void> rename(String fileId, String newName);

  Future<Stream<List<int>>> getFileStream(String fileId);
}
