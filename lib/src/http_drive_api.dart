import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'interface.dart';

class HttpDriveApi implements GoogleDriveApi 
{
  late final drive.DriveApi _driveApi;
  
  HttpDriveApi(http.Client client)
  {
    _driveApi = drive.DriveApi(client);
  }
  
  String _makeQuery({String? name, String? parentId, String? q, bool onlyFolder = false, bool onlyFile = false, String? mimeType}) 
  {
    List<String> conditions = [];

    if (name?.isNotEmpty ?? false)
    {
      conditions.add("name = '$name'");
    }

    if (parentId?.isNotEmpty ?? false)
    {
      conditions.add("'$parentId' in parents");
    }

    if (q?.isNotEmpty ?? false)
    {
      conditions.add(q!);
    }
    
    // 폴더만 검색하는 조건
    if (onlyFolder) 
    {
      conditions.add("mimeType='application/vnd.google-apps.folder'");
    }
    else if (onlyFile)
    {
      conditions.add("mimeType!='application/vnd.google-apps.folder'");
    } 
    else if (mimeType?.isNotEmpty ?? false)
    {
      conditions.add("mimeType='$mimeType'");
    } 
   
    // 삭제된 파일 제외
    conditions.add("trashed=false");

    // 모든 조건을 AND로 결합
    return conditions.join(" and ");
  }

  @override
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
  }) async 
  {
    List<drive.File> list = [];

    String? nextPageToken;

    var q = _makeQuery(name:name, parentId:parentId, q:query, onlyFolder: onlyFolder, onlyFile: onlyFile, mimeType: mimeType);

    if (fields?.isNotEmpty ?? false)
    {
      fields = "files($fields)";
    }

    do 
    {
      final response = await _driveApi.files.list(
        q: q,
        orderBy: orderBy,
        pageSize: pageSize,
        spaces: space,
        $fields: fields,
        supportsAllDrives: true,
        includeItemsFromAllDrives: includeItemsFromAllDrives,
        driveId: driveId,
        pageToken: nextPageToken,
      );

      if (response.files?.isNotEmpty ?? false) 
      {
        list.addAll(response.files!);
      }

      nextPageToken = response.nextPageToken;
    } while (nextPageToken != null);
    return list;
  }
  
  @override
  Future<drive.File> createFile(String parentId, String fileName, Stream<List<int>> dataStream, {DateTime? originalDate, int? fileSize, String contentType = 'application/octet-stream'}) async
  {  
    final file = drive.File()
      ..name = fileName
      ..parents = [parentId]
      ..modifiedTime = originalDate;

    final media = drive.Media(dataStream, fileSize, contentType: contentType);
    final result = await _driveApi.files.create(file, uploadMedia: media, supportsAllDrives: true);
    return result;
  }
  
  @override
  Future<drive.File> createFolder(String parentId, String folderName) async
  {
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [parentId];

    final result = await _driveApi.files.create(
      folder, 
      supportsAllDrives: true,
    );

    return result;
  }
  
  @override
  Future<void> delete(String fileId) async
  {
    await _driveApi.files.delete(fileId, supportsAllDrives: true);
  }
  
  @override
  Future<String?> getParents(String fileId) async
  {
    final file = await _driveApi.files.get(
      fileId,
      $fields: 'parents',
      supportsAllDrives: true,
    ) as drive.File;

    return file.parents?.join(',');
  }
  
  @override
  Future<void> rename(String fileId, String newName) async
  {
    await _driveApi.files.update(
      drive.File()..name = newName,
      fileId,
      supportsAllDrives: true,
    );    
  }
  
  @override
  Future<Stream<List<int>>> getFileStream(String fileId) async
  {
    final mediaStream = await _driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia, supportsAllDrives: true) as drive.Media;
    return mediaStream.stream;
  }
  
  @override
  Future<void> copyFile(String fromId, String toId) async 
  {
    final copied = drive.File()..parents = [toId];  
    await _driveApi.files.copy(copied, fromId, supportsAllDrives: true);
  }

  @override
  Future<void> copyFolder(String fromId, String toId, {required String? driveId}) async
  {
    final originalFolder = await _driveApi.files.get(fromId, supportsAllDrives: true) as drive.File;

    final createdFolder = await createFolder(toId, originalFolder.name!);

    var children = await listFiles(
      parentId:fromId,
      driveId: driveId,
      pageSize: 1000,
      fields: "id, mimeType",
      includeItemsFromAllDrives: driveId == null
    );

    for (var item in children) 
    {
      if (item.mimeType == "application/vnd.google-apps.folder") 
      {
        await copyFolder(item.id!, createdFolder.id!, driveId: driveId);
      } 
      else 
      {
        await copyFile(item.id!, createdFolder.id!);
      }
    }
  }

  @override
  Future<void> moveFile(String fromId, String toId) async
  {
    final previousParents = await getParents(fromId);

    await _driveApi.files.update(
      drive.File(), // ✅ 불필요한 `parents` 설정 제거
      fromId,
      addParents: toId,
      removeParents: previousParents,
      supportsAllDrives: true,
    );
  }
  
  @override
  Future<void> moveFolder(String fromId, String toId) async 
  {
    final previousParents = await getParents(fromId);

    await _driveApi.files.update(
      drive.File(), // ✅ 불필요한 `parents` 설정 제거
      fromId,
      addParents: toId,
      removeParents: previousParents,
      supportsAllDrives: true,
    );
  }
}
