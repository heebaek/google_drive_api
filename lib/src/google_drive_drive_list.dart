import 'google_drive_drive.dart';

class GoogleDriveDriveList {
  List<GoogleDriveDrive>? drives;
  String? nextPageToken;

  GoogleDriveDriveList({
    this.drives,
    this.nextPageToken,
  });

  factory GoogleDriveDriveList.fromJson(Map<String, dynamic> json) {
    return GoogleDriveDriveList(
      drives: (json['drives'] as List?)
          ?.map((value) => GoogleDriveDrive.fromJson(value as Map<String, dynamic>))
          .toList(),
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (drives != null) 'drives': drives!.map((drive) => drive.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}