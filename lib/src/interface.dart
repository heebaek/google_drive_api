
import 'drive_list_response.dart';
import 'file.dart';
import 'file_list_response.dart';

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
    String? nextPageToken
  });

  Future<DriveListResponse> listDrives({String? nextPageToken});

  Future<File> createFile(
    String parentId,
    String fileName,
    Stream<List<int>> dataStream, {
    String? driveId,
    DateTime? originalDate,
    int? fileSize,
    String contentType
  });

  Future<File> createFolder(
    String parentId,
    String folderName,
    {
      String? driveId
    }
  );

  Future<File> getFile(String fileId);

  Future<File> updateFile(String fileId, {String? fileName, List<String>? addParents, List<String>? removeParents});

  Future<Stream<List<int>>> getFileStream(String fileId);

  Future<void> delete(String fileId);
  
  Future<File> copyFile(String fromId, String toId);
}
