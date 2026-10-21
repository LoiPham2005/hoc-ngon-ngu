// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/attached.dart';
import '../models/create_upload_request.dart';
import '../models/direct_upload_response.dart';
import '../models/enum0.dart';
import '../models/file_response.dart';
import '../models/files_list_response.dart';
import '../models/id_response.dart';
import '../models/kind.dart';
import '../models/rename_file_request.dart';

part 'files_client.g.dart';

@RestApi()
abstract class FilesClient {
  factory FilesClient(Dio dio, {String? baseUrl}) = _FilesClient;

  /// Danh sách tệp — người thường (file:upload) chỉ thấy tệp CỦA MÌNH, file:manage thấy tất cả.
  ///
  /// [q] - Tìm theo tên tệp.
  ///
  /// [attached] - false = mồ côi, sắp bị dọn.
  ///
  /// [uploadedById] - Chỉ có tác dụng với file:manage.
  ///
  /// Name not received - field will be skipped.
  @GET('/files')
  Future<FilesListResponse> getFiles({
    @Query('kind') Kind? kind,
    @Query('q') String? q,
    @Query('attached') Attached? attached,
    @Query('uploadedById') String? uploadedById,
    @Query('page') int? page = 1,
    @Query('limit') int? limit = 20,
  });

  /// Tải tệp lên QUA MÁY CHỦ (multipart) — ảnh 5MB, tài liệu 20MB, âm thanh 50MB. Video đi POST /files/uploads. Kiểm MAGIC BYTES chứ không tin Content-Type do client khai. Trả `file.id` — gửi kèm form nghiệp vụ (vd. `avatarFileId`) để gắn; không gắn trong 24 giờ sẽ bị dọn.
  ///
  /// [file] - Name not received - field will be skipped.
  ///
  /// [folder] - Name not received - field will be skipped.
  ///
  /// [retain] - Giữ trong thư viện, không dọn — chỉ file:manage.
  /// Name not received and was auto-generated.
  ///
  /// Name not received - field will be skipped.
  @MultiPart()
  @POST('/files')
  Future<FileResponse> postFiles({
    @Part(name: 'file') required MultipartFile file,
    @Part(name: 'folder') String? folder,
    @Part(name: 'retain') Enum0? retain,
  });

  /// Tải TRỰC TIẾP lên kho (video, tệp lớn): nhận URL ký sẵn -> client PUT nội dung kèm đúng `upload.headers` -> gọi POST /files/{id}/complete. Chỉ có khi kho là S3 (409 nếu không).
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @POST('/files/uploads')
  Future<DirectUploadResponse> postFilesUploads({
    @Body() required CreateUploadRequest body,
  });

  /// Chi tiết tệp — tệp của người khác (không có file:manage) trả 404.
  ///
  /// Name not received - field will be skipped.
  @GET('/files/{id}')
  Future<FileResponse> getFilesId({
    @Path('id') required String id,
  });

  /// Đổi TÊN hiển thị. Nội dung không sửa được — tải tệp mới rồi gắn lại.
  ///
  /// [body] - Name not received - field will be skipped.
  ///
  /// Name not received - field will be skipped.
  @PATCH('/files/{id}')
  Future<FileResponse> patchFilesId({
    @Path('id') required String id,
    @Body() required RenameFileRequest body,
  });

  /// Xoá tệp khỏi kho. Tệp đang được dùng (vd. làm avatar) trả 409 — gỡ ra trước.
  ///
  /// Name not received - field will be skipped.
  @DELETE('/files/{id}')
  Future<IdResponse> deleteFilesId({
    @Path('id') required String id,
  });

  /// Xác nhận đã PUT xong (tải trực tiếp). Máy chủ kiểm tệp THẬT trên kho: tồn tại, dung lượng, chữ ký đầu tệp. Không đạt thì xoá luôn và trả 422.
  ///
  /// Name not received - field will be skipped.
  @POST('/files/{id}/complete')
  Future<FileResponse> postFilesIdComplete({
    @Path('id') required String id,
  });
}
