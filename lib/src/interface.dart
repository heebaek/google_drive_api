import 'drive_list_response.dart';
import 'file_list_response.dart';
import 'gd_file.dart';

abstract interface class GoogleDriveApi {
  Future<FileListResponse> listFiles({
    String? name,
    String? parentId,
    String? query,
    String? orderBy,
    int? pageSize = 1,
    String? driveId,
    String? fields,
    bool onlyFolder,
    bool onlyFile,
    String? mimeType,
    String? space,
    String? nextPageToken,
  });

  Future<DriveListResponse> listDrives({String? nextPageToken});

  Future<GDFile> createFile(
    String parentId,
    String fileName,
    Stream<List<int>> dataStream, {
    String? driveId,
    DateTime? originalDate,
    int? fileSize,
    String contentType,
  });

  Future<GDFile> createFolder(
    String parentId,
    String folderName, {
    String? driveId,
  });

  Future<GDFile> getFile(String fileId);

  Future<GDFile> updateFile(
    String fileId, {
    String? fileName,
    List<String>? addParents,
    List<String>? removeParents,
  });

  Future<Stream<List<int>>> getFileStream(String fileId);

  Future<void> delete(String fileId);

  Future<GDFile> copyFile(String fromId, String toId);
}
