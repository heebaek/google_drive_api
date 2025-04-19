import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'google_drive_drive.dart';
import 'google_drive_drive_list.dart';
import 'google_drive_file.dart';
import 'google_drive_file_list.dart';
import 'interface.dart';

class HttpDriveApi implements GoogleDriveApi {
  static const String fields = 'id,name,mimeType,createdTime,modifiedTime,size,parents,hasThumbnail,driveId';

  late final drive.DriveApi _driveApi;
  
  HttpDriveApi(http.Client client) {
    _driveApi = drive.DriveApi(client);
  }

  GoogleDriveFile convertFile(drive.File file)
  {
    return GoogleDriveFile(
      createdTime: file.createdTime,
      driveId: file.driveId,
      hasThumbnail: file.hasThumbnail,
      id: file.id,
      mimeType: file.mimeType,
      modifiedTime: file.modifiedTime,
      name: file.name,
      parents: file.parents,
      size: file.size,
    );
  }

  GoogleDriveDrive convertDrive(drive.Drive drive)
  {
    return GoogleDriveDrive(
      createdTime: drive.createdTime,
      hidden: drive.hidden,
      id: drive.id,
      name: drive.name,
    );
  }

  String _makeQuery({
    String? name,
    String? parentId,
    String? q,
    bool onlyFolder = false,
    bool onlyFile = false,
    String? mimeType,
  }) {
    List<String> conditions = [];

    if (name?.isNotEmpty ?? false) {
      conditions.add("name = '$name'");
    }

    if (parentId?.isNotEmpty ?? false) {
      conditions.add("'$parentId' in parents");
    }

    if (q?.isNotEmpty ?? false) {
      conditions.add(q!);
    }

    // 폴더만 검색하는 조건
    if (onlyFolder) {
      conditions.add("mimeType='application/vnd.google-apps.folder'");
    } else if (onlyFile) {
      conditions.add("mimeType!='application/vnd.google-apps.folder'");
    } else if (mimeType?.isNotEmpty ?? false) {
      conditions.add("mimeType='$mimeType'");
    }

    // 삭제된 파일 제외
    conditions.add("trashed=false");

    // 모든 조건을 AND로 결합
    return conditions.join(" and ");
  }

  @override
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
    String? nextPageToken,
  }) async {
    var q = _makeQuery(
      name: name,
      parentId: parentId,
      q: query,
      onlyFolder: onlyFolder,
      onlyFile: onlyFile,
      mimeType: mimeType,
    );

    if (fields?.isNotEmpty ?? false) {
      fields = "files($fields)";
    }

    final response = await _driveApi.files.list(
      q: q,
      orderBy: orderBy,
      pageSize: pageSize,
      spaces: space,
      $fields: fields,
      supportsAllDrives: true,
      includeItemsFromAllDrives: driveId != null,
      driveId: driveId,
      pageToken: nextPageToken,
      supportsTeamDrives: driveId != null,
      corpora: driveId != null ? "drive" : null,
    );

    var files = response.files?.map((e) => convertFile(e)).toList();

    return GoogleDriveFileList(
      files: files,
      incompleteSearch: response.incompleteSearch,
      nextPageToken: response.nextPageToken,
    );
  }

  @override
  Future<GoogleDriveDriveList> listDrives({String? nextPageToken}) async {
    var response = await _driveApi.drives.list(
      pageToken: nextPageToken,
      pageSize: 100, // 한 페이지당 최대 항목 수 (API 기본값보다 큰 값 사용)
    );

    var drives = response.drives?.map((e) => convertDrive(e)).toList();
        
    return GoogleDriveDriveList(
      drives: drives,
      nextPageToken: response.nextPageToken,
    );
  }

  @override
  Future<GoogleDriveFile> createFile(
    String parentId,
    String fileName,
    Stream<List<int>> dataStream, {
    String? driveId,
    DateTime? originalDate,
    int? fileSize,
    String contentType = 'application/octet-stream',
  }) async {
    final file =
        drive.File()
          ..name = fileName
          ..parents = [parentId]
          ..driveId = driveId
          ..modifiedTime = originalDate;

    final media = drive.Media(dataStream, fileSize, contentType: contentType);
    final result = await _driveApi.files.create(
      file,
      uploadMedia: media,
      supportsAllDrives: true,
    );

    return convertFile(result);
  }

  @override
  Future<GoogleDriveFile> createFolder(
    String parentId,
    String folderName, {
    String? driveId,
  }) async {
    final folder =
        drive.File()
          ..driveId = driveId
          ..name = folderName
          ..mimeType = 'application/vnd.google-apps.folder'
          ..parents = [parentId];

    final result = await _driveApi.files.create(
      folder,
      supportsAllDrives: true,
    );

    return convertFile(result);
  }

  @override
  Future<GoogleDriveFile> getFile(String fileId) async {
    final file =
        await _driveApi.files.get(
              fileId,
              $fields: fields,
              supportsAllDrives: true,
            )
            as drive.File;

    return convertFile(file);
  }

  @override
  Future<GoogleDriveFile> updateFile(
    String fileId, {
    String? fileName,
    String? addParents,
    String? removeParents,
  }) async {
    var request = drive.File();
    if (fileName != null) request.name = fileName;

    var file = await _driveApi.files.update(
      request,
      fileId,
      addParents: addParents,
      removeParents: removeParents,
      supportsAllDrives: true,
      $fields:fields
    );

    return convertFile(file);
  }

  @override
  Future<Stream<List<int>>> getFileStream(String fileId) async {
    final mediaStream =
        await _driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
              supportsAllDrives: true,
            )
            as drive.Media;
    return mediaStream.stream;
  }
  
  @override
  Future<void> delete(String fileId) async
  {
    await _driveApi.files.delete(fileId, supportsAllDrives: true);
  }
  
  @override
  Future<GoogleDriveFile> copyFile(String fromId, String toId) async 
  {
    final copied = drive.File()..parents = [toId];  
    var file = await _driveApi.files.copy(copied, fromId, supportsAllDrives: true, $fields: fields);
    return convertFile(file);
  }
  /*

    var sourceFile = await getFile(fromId);
    final file = drive.File()
      ..name = sourceFile.name
      ..parents = [toId]
      ..mimeType = 'application/vnd.google-apps.file';

    var newFile = await _driveApi.files.copy(
      file,
      fromId,
      supportsAllDrives: true,
      $fields: fields
    );

    return convertFile(newFile);
  }
  */
}
