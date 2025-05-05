import 'drive.dart';

class DriveListResponse {
  List<Drive>? drives;
  String? nextPageToken;

  DriveListResponse({
    this.drives,
    this.nextPageToken,
  });

  factory DriveListResponse.fromJson(Map<String, dynamic> json) {
    return DriveListResponse(
      drives: (json['drives'] as List?)
          ?.map((value) => Drive.fromJson(value as Map<String, dynamic>))
          .toList(),
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (drives != null) 'drives': drives!.map((drive) => drive.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}