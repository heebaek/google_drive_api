import 'package:oauth2restclient/oauth2restclient.dart';

import 'google_drive_drive_list.dart';
import 'google_drive_file.dart';
import 'google_drive_file_list.dart';
import 'interface.dart';

class HttpDriveApi implements GoogleDriveApi {
  static const String theFields = 'id,name,mimeType,createdTime,modifiedTime,size,parents,hasThumbnail,driveId';

  final OAuth2RestClient client;
  
  HttpDriveApi(this.client);
  
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

  Map<String, String> _makeQueryParams({String? q, String? orderBy, int? pageSize, String? driveId, String? fields, String? space, String? nextPageToken}) 
  {
    final Map<String, String> queryParams = {};

    if (q?.isNotEmpty ?? false) {    
      queryParams['q'] = q!;
    }
   
    if (orderBy?.isNotEmpty ?? false) {
      queryParams['orderBy'] = orderBy!;
    }

    if (pageSize != null) {
      queryParams['pageSize'] = pageSize.toString();
    }

    if (driveId?.isNotEmpty ?? false) {
      queryParams['driveId'] = driveId!;
      queryParams['includeItemsFromAllDrives'] = 'true';
      queryParams['supportsTeamDrives'] = 'true';      
      queryParams['corpora'] = "drive";      
    }

    if (fields?.isNotEmpty ?? false) {
      queryParams['fields'] = "files($fields)";
    }

    if (space?.isNotEmpty ?? false) 
    {
      queryParams['space'] = space!;
    }
    
    if (nextPageToken?.isNotEmpty ?? false) 
    {
      queryParams['pageToken'] = nextPageToken!;
    }

    return queryParams;
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

    var queryParams = _makeQueryParams(q:q, orderBy:orderBy, pageSize:pageSize, driveId:driveId, fields:fields, space:space, nextPageToken:nextPageToken);
    
    var url = 'https://www.googleapis.com/drive/v3/files';
    var json = await client.getJson(url, queryParams: queryParams);
    return GoogleDriveFileList.fromJson(json);
  }

  @override
  Future<GoogleDriveDriveList> listDrives({String? nextPageToken}) async {

    Map<String, String> queryParams = {"pageSize" : "100"};
    if (nextPageToken?.isNotEmpty ?? false) {
      queryParams["pageToken"] = nextPageToken!;
    }

    var url = 'www.googleapis.com/drive/v3/drives';
    final json = await client.getJson(url);
    return GoogleDriveDriveList.fromJson(json);
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

    var url = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=true";

    final fileMeta = GoogleDriveFile(
      createdTime: originalDate,
      driveId: driveId,
      mimeType: contentType,
      name: fileName,
      parents: [parentId],
      size: fileSize?.toString()
    ).toJson();

    OAuth2JsonBody meta = OAuth2JsonBody(fileMeta);
    OAuth2FileBody file = OAuth2FileBody(dataStream, contentLength: fileSize!, contentType: contentType);
    var body = OAuth2MultiBody.related(meta, file);

    var json = await client.postJson(url, body:body);
    return GoogleDriveFile.fromJson(json);
  }

  @override
  Future<GoogleDriveFile> createFolder(
    String parentId,
    String folderName, {
    String? driveId,
  }) async {

    final fileMeta = GoogleDriveFile(
      driveId: driveId,
      mimeType: 'application/vnd.google-apps.folder',
      name: folderName,
      parents: [parentId],
    ).toJson();

    var url = "https://www.googleapis.com/drive/v3/files?supportsAllDrives=true";

    OAuth2JsonBody body = OAuth2JsonBody(fileMeta);
    
    var json = await client.postJson(url, body:body);
    return GoogleDriveFile.fromJson(json);
  }

  @override
  Future<GoogleDriveFile> getFile(String fileId) async 
  {
    var url = "https://www.googleapis.com/drive/v3/files/$fileId?supportsAllDrives=true";
    var queryParams = _makeQueryParams(fields:theFields);
    var json = await client.getJson(url, queryParams: queryParams);
    return GoogleDriveFile.fromJson(json);
  }

  @override
  Future<GoogleDriveFile> updateFile(
    String fileId, {
    String? fileName,
    String? addParents,
    String? removeParents,
  }) async 
  {
    var url = "https://www.googleapis.com/drive/v3/files/$fileId";
    var queryParams = _makeQueryParams(fields:theFields);
    if (addParents != null)
    {
      queryParams["addParents"] = addParents;
    }

    if (removeParents != null)
    {
      queryParams["removeParents"] = removeParents;
    }

    var file = GoogleDriveFile(name:fileName);
    var body = OAuth2JsonBody(file.toJson());

    var response = await client.patchJson(url, body:body, queryParams: queryParams);
    return GoogleDriveFile.fromJson(response);
  }

  @override
  Future<Stream<List<int>>> getFileStream(String fileId) async 
  {
    var url = "https://www.googleapis.com/drive/v3/files/$fileId?alt=media";
    var stream = await client.getStream(url);
    return stream;
  }
  
  @override
  Future<void> delete(String fileId) async
  {
    var url = "https://www.googleapis.com/drive/v3/files/$fileId&supportsAllDrives=true";
    await client.delete(url);
  }
  
  @override
  Future<GoogleDriveFile> copyFile(String fromId, String toId) async 
  {
    var url = "https://www.googleapis.com/drive/v3/files/$fromId/copy&supportsAllDrives=true";
    var queryParams = _makeQueryParams(fields:theFields);
    final copied = GoogleDriveFile(parents: [toId]);
    var body = OAuth2JsonBody(copied.toJson());
    var response = await client.postJson(url, body:body, queryParams: queryParams);
    return GoogleDriveFile.fromJson(response);
  }
}
