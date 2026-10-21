import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:retrofit/retrofit.dart';

part 'app_version_api.freezed.dart';
part 'app_version_api.g.dart';

/// Response của public endpoint `GET /app-version/check`.
///
/// Backend KHÔNG bọc trong `ApiResponse<T>` — trả object thẳng (raw DTO).
/// JSON keys là camelCase, khớp tên field nên KHÔNG cần `@JsonKey`.
///
/// `status` là 1 trong: `"up_to_date" | "optional" | "force"`. Service map sang
/// [UpdateStatus]; bất kỳ giá trị lạ nào → `error` (fail-open, không chặn user).
@freezed
abstract class AppVersionCheckResponse with _$AppVersionCheckResponse {
  const factory AppVersionCheckResponse({
    required String status,
    @Default('') String currentVersion,
    @Default('') String latestVersion,
    @Default(false) bool forceUpdate,
    String? message,
    String? storeUrl,
  }) = _AppVersionCheckResponse;

  factory AppVersionCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$AppVersionCheckResponseFromJson(json);
}

/// Retrofit client cho public endpoint kiểm tra version.
///
/// Base URL của Dio đã bao gồm `/api/v1` nên path ở đây là `/app-version/check`.
/// Endpoint NO AUTH (backend `@Public()`) — trả [AppVersionCheckResponse] raw
/// (KHÔNG bọc `ApiResponse<T>`).
@RestApi()
abstract class AppVersionApi {
  factory AppVersionApi(Dio dio) = _AppVersionApi;

  /// `GET /app-version/check?platform=&version=&build=`
  /// - [platform]: `android` | `ios` (case-insensitive ở backend).
  /// - [version]: semver hiện tại của app.
  /// - [build]: build number (int dạng string), optional.
  @GET('/app-version/check')
  Future<AppVersionCheckResponse> checkVersion(
    @Query('platform') String platform,
    @Query('version') String version,
    @Query('build') String build,
  );
}
