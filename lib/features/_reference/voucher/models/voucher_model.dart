import 'package:freezed_annotation/freezed_annotation.dart';

part 'voucher_model.freezed.dart';
part 'voucher_model.g.dart';

@freezed
abstract class VoucherModel with _$VoucherModel {
  const factory VoucherModel({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'discount_percent') @Default(0) int discountPercent,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
  }) = _VoucherModel;

  factory VoucherModel.fromJson(Map<String, dynamic> json) =>
      _$VoucherModelFromJson(json);
}
