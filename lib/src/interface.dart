
import 'google_drive_drive_list.dart';
import 'google_drive_file.dart';
import 'google_drive_file_list.dart';

abstract interface class GoogleDriveApi {
  Future<GoogleDriveFileList> listFiles({
    String? name,
    String? parentId,
    String? query,
    String? orderBy,
    int? pageSize = 1,
    String? driveId,
    String? fields = "id,name,mimeType,createdTime,modifiedTime,size,parents,hasThumbnail,driveId",
    bool onlyFolder = false,
    bool onlyFile = false,
    String? mimeType,
    String? space = "drive",
    String? nextPageToken
  });

  Future<GoogleDriveDriveList> listDrives({String? nextPageToken});

  Future<GoogleDriveFile> createFile(
    String parentId,
    String fileName,
    Stream<List<int>> dataStream, {
    String? driveId,
    DateTime? originalDate,
    int? fileSize,
    String contentType = 'application/octet-stream',
  });

  Future<GoogleDriveFile> createFolder(
    String parentId,
    String folderName,
    {
      String? driveId
    }
  );

  Future<GoogleDriveFile> getFile(String fileId);

  Future<GoogleDriveFile> updateFile(String fileId, {String? fileName, String? addParents, String? removeParents});

  Future<Stream<List<int>>> getFileStream(String fileId);

  Future<void> delete(String fileId);

  //Future<String?> getParents(String fileId);

  //Future<void> moveFile(String fromId, String toId);

  //Future<void> moveFolder(String fromId, String toId);

  Future<GoogleDriveFile> copyFile(String fromId, String toId);

  //Future<void> rename(String fileId, String newName);
}
