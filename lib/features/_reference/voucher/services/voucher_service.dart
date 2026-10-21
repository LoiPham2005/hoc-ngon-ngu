import 'package:dio/dio.dart';
import 'package:lingua/core/network/api_response.dart';
import 'package:lingua/features/_reference/voucher/models/voucher_model.dart';
import 'package:retrofit/retrofit.dart';

part 'voucher_service.g.dart';

@RestApi()
abstract class VoucherService {
  factory VoucherService(Dio dio) = _VoucherService;

  @GET('/vouchers')
  Future<ApiResponse<List<VoucherModel>>> getVouchers();

  @GET('/vouchers/{id}')
  Future<ApiResponse<VoucherModel>> getVoucherDetail(@Path('id') String id);

  @GET('/vouchers/search')
  Future<ApiResponse<List<VoucherModel>>> searchVouchers(
    @Query('q') String query,
  );

  @DELETE('/vouchers/{id}')
  Future<ApiResponse<VoucherModel>> deleteVoucher(@Path('id') String id);
}
