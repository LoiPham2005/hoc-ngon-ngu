import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

/// Vỏ response thành công của backend: `{ "data": ... }`.
///
/// Lỗi KHÔNG đi qua đây: backend trả HTTP 4xx/5xx + `{ "error": { "code", "message", "fields" } }`
/// → Dio ném → `ErrorHandler` đổi thành `Failure`. Nên có response là có `data`.
/// Endpoint trả 204 / không có body → service khai báo `Future<void>`.
@Freezed(genericArgumentFactories: true)
abstract class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({required T data}) = _ApiResponse<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseFromJson<T>(json, fromJsonT);
}

/// `data` của danh sách phân trang: `{ "items": [...], "meta": { page, limit, total, totalPages, hasNext } }`.
/// Service: `Future<ApiResponse<PaginatedResponse<T>>>`.
@Freezed(genericArgumentFactories: true)
abstract class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    @Default([]) List<T> items,
    @Default(PageMeta()) PageMeta meta,
  }) = _PaginatedResponse<T>;

  const PaginatedResponse._();

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PaginatedResponseFromJson<T>(json, fromJsonT);

  bool get hasMore => meta.hasNext;
}

/// Thông tin phân trang.
@freezed
abstract class PageMeta with _$PageMeta {
  const factory PageMeta({
    @Default(1) int page,
    @Default(20) int limit,
    @Default(0) int total,
    @Default(1) int totalPages,
    @Default(false) bool hasNext,
  }) = _PageMeta;

  factory PageMeta.fromJson(Map<String, dynamic> json) =>
      _$PageMetaFromJson(json);
}
