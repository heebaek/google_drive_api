import 'google_drive_file.dart';

class GoogleDriveFileList {
  List<GoogleDriveFile>? files;
  bool? incompleteSearch;
  String? nextPageToken;

  GoogleDriveFileList({
    this.files,
    this.incompleteSearch,
    this.nextPageToken,
  });

  factory GoogleDriveFileList.fromJson(Map<String, dynamic> json) {
    return GoogleDriveFileList(
      files: (json['files'] as List?)
          ?.map((value) => GoogleDriveFile.fromJson(value as Map<String, dynamic>))
          .toList(),
      incompleteSearch: json['incompleteSearch'] as bool?,
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (files != null) 'files': files!.map((file) => file.toJson()).toList(),
        if (incompleteSearch != null) 'incompleteSearch': incompleteSearch!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}