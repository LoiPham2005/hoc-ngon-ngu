// GENERATED CODE - DO NOT MODIFY BY HAND
// Sinh bởi gen_api.dart — chạy lại `make gen-api` là bị ghi đè.
// ignore_for_file: type=lint

import 'dart:async';

import 'package:dio/dio.dart' show MultipartFile;
import 'package:api_client/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'files_providers.g.dart';

/// Danh sách tệp — người thường (file:upload) chỉ thấy tệp CỦA MÌNH, file:manage thấy tất cả.
@riverpod
Future<FilesListResponse> getFiles(
  Ref ref, {
  Kind? kind,
  String? q,
  Attached? attached,
  String? uploadedById,
  int? page = 1,
  int? limit = 20,
}) => ref
    .watch(restClientProvider)
    .files
    .getFiles(
      kind: kind,
      q: q,
      attached: attached,
      uploadedById: uploadedById,
      page: page,
      limit: limit,
    );

/// Chi tiết tệp — tệp của người khác (không có file:manage) trả 404.
@riverpod
Future<FileResponse> getFilesId(Ref ref, {required String id}) =>
    ref.watch(restClientProvider).files.getFilesId(id: id);

/// Thao tác GHI nhóm `files`. State = đang chạy / lỗi của lần gọi gần nhất; lỗi được NÉM LẠI cho
/// nơi gọi. Thành công thì làm mới mọi provider GET của nhóm.
///
/// `await ref.read(filesActionsProvider.notifier).<method>(...)`
@Riverpod(keepAlive: true)
class FilesActions extends _$FilesActions {
  @override
  FutureOr<void> build() {}

  FilesClient get _api => ref.read(restClientProvider).files;

  Future<R> _run<R>(Future<R> Function() call) async {
    state = const AsyncLoading();
    try {
      final result = await call();
      if (ref.mounted) {
        state = const AsyncData(null);
        ref.invalidate(getFilesProvider);
        ref.invalidate(getFilesIdProvider);
      }
      return result;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }

  /// POST — `files.postFiles`.
  Future<FileResponse> postFiles({
    required MultipartFile file,
    String? folder,
    Enum0? retain,
  }) => _run(() => _api.postFiles(file: file, folder: folder, retain: retain));

  /// Tải TRỰC TIẾP lên kho (video, tệp lớn): nhận URL ký sẵn -> client PUT nội dung kèm đúng `upload.headers` -> gọi POST /files/{id}/complete. Chỉ có khi kho là S3 (409 nếu không).
  Future<DirectUploadResponse> postFilesUploads({
    required CreateUploadRequest body,
  }) => _run(() => _api.postFilesUploads(body: body));

  /// Đổi TÊN hiển thị. Nội dung không sửa được — tải tệp mới rồi gắn lại.
  Future<FileResponse> patchFilesId({
    required String id,
    required RenameFileRequest body,
  }) => _run(() => _api.patchFilesId(id: id, body: body));

  /// Xoá tệp khỏi kho. Tệp đang được dùng (vd. làm avatar) trả 409 — gỡ ra trước.
  Future<IdResponse> deleteFilesId({required String id}) =>
      _run(() => _api.deleteFilesId(id: id));

  /// Xác nhận đã PUT xong (tải trực tiếp). Máy chủ kiểm tệp THẬT trên kho: tồn tại, dung lượng, chữ ký đầu tệp. Không đạt thì xoá luôn và trả 422.
  Future<FileResponse> postFilesIdComplete({required String id}) =>
      _run(() => _api.postFilesIdComplete(id: id));
}
