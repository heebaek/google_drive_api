import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'interface.dart';

class HttpDriveApi implements GoogleDriveApi 
{
  late final drive.DriveApi _driveApi;
  
  HttpDriveApi({required http.Client client})
  {
    _driveApi = drive.DriveApi(client);
  }
  
  String _makeQuery({String? name, String? parentId, String? q, bool onlyFolder = false, String? mimeType}) 
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
    // 특정 mimeType으로 검색하는 조건
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
    int? pageSize,
    String? driveId,
    String? fields = "files(id, name, mimeType, createdTime, modifiedTime)",
    bool onlyFolder = false,
    String? mimeType,
    includeItemsFromAllDrives = false,
    String? space = "drive",
  }) async 
  {
    List<drive.File> list = [];

    String? nextPageToken;

    var q = _makeQuery(name:name, parentId:parentId, q:query, onlyFolder: onlyFolder, mimeType: mimeType);

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
}
