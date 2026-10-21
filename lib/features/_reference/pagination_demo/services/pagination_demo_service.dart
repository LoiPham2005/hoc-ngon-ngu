import 'package:dio/dio.dart';
import 'package:lingua/core/network/api_response.dart';
import 'package:lingua/features/_reference/pagination_demo/models/item_model.dart';
import 'package:retrofit/retrofit.dart';

part 'pagination_demo_service.g.dart';

@RestApi()
abstract class PaginationDemoService {
  factory PaginationDemoService(Dio dio) = _PaginationDemoService;

  @GET('/items')
  Future<ApiResponse<PaginatedResponse<ItemModel>>> getItems({
    @Query('page') required int page,
    @Query('limit') int limit = 20,
    @Query('q') String? query,
  });
}
