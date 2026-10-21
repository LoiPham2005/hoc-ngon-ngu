import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_model.freezed.dart';
part 'item_model.g.dart';

/// Model demo cho tinh nang phan trang, tuan thu @freezed abstract class (Rule 3)
@freezed
abstract class ItemModel with _$ItemModel {
  const factory ItemModel({
    required String id,
    required String title,
    @Default('') String description,
    @Default(0) int price,
    String? imageUrl,
  }) = _ItemModel;

  factory ItemModel.fromJson(Map<String, dynamic> json) =>
      _$ItemModelFromJson(json);
}
