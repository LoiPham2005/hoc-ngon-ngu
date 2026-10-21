// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/error_logger.dart';

import '../models/auth_oauth_provider_callback_request.dart';
import '../models/empty_response.dart';
import '../models/o_auth_linked_response.dart';
import '../models/o_auth_providers_response.dart';

part 'o_auth_client.g.dart';

@RestApi()
abstract class OAuthClient {
  factory OAuthClient(Dio dio, {String? baseUrl}) = _OAuthClient;

  /// Nhà cung cấp ĐÃ cấu hình — màn đăng nhập dùng để biết vẽ nút nào.
  ///
  /// Name not received - field will be skipped.
  @GET('/auth/oauth/providers')
  Future<OAuthProvidersResponse> getAuthOauthProviders();

  /// Tài khoản mạng xã hội đã liên kết.
  ///
  /// Name not received - field will be skipped.
  @GET('/auth/oauth/linked')
  Future<OAuthLinkedResponse> getAuthOauthLinked();

  /// Bắt đầu luồng OAuth — trả 302 tới nhà cung cấp. Mở bằng TRÌNH DUYỆT (hoặc Custom Tab / ASWebAuthenticationSession trên mobile), không phải bằng fetch: nhà cung cấp cần một phiên trình duyệt thật.
  ///
  /// Name not received - field will be skipped.
  @GET('/auth/oauth/{provider}/start')
  Future<void> getAuthOauthProviderStart({
    @Path('provider') required String provider,
  });

  /// Nhà cung cấp gọi lại sau khi người dùng đồng ý. Trả 302 về ứng dụng — KHÔNG trả JSON, vì đích đến là thanh địa chỉ của trình duyệt.
  ///
  /// Name not received - field will be skipped.
  @GET('/auth/oauth/{provider}/callback')
  Future<void> getAuthOauthProviderCallback({
    @Path('provider') required String provider,
    @Query('code') String? code,
    @Query('state') String? state,
    @Query('error') String? error,
  });

  /// Cùng luồng nhưng nhận form POST — Apple bắt buộc response_mode=form_post khi xin scope name/email.
  ///
  /// Name not received - field will be skipped.
  @FormUrlEncoded()
  @POST('/auth/oauth/{provider}/callback')
  Future<void> postAuthOauthProviderCallback({
    @Path('provider') required String provider,
    @Body() required AuthOauthProviderCallbackRequest body,
  });

  /// Gỡ liên kết — từ chối nếu đây là cách đăng nhập cuối cùng.
  ///
  /// Name not received - field will be skipped.
  @DELETE('/auth/oauth/{provider}')
  Future<EmptyResponse> deleteAuthOauthProvider({
    @Path('provider') required String provider,
  });
}
