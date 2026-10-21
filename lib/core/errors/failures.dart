/// Lỗi đã chuẩn hoá để hiển thị cho user. Tạo qua `ErrorHandler.handle(e)`.
sealed class Failure implements Exception {
  const Failure(this.message, {this.code});

  final String message;
  final int? code;

  @override
  bool operator ==(Object other) =>
      other is Failure &&
      other.runtimeType == runtimeType &&
      other.message == message &&
      other.code == code;

  @override
  int get hashCode => Object.hash(runtimeType, message, code);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Không có kết nối mạng']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Phiên đăng nhập đã hết hạn'])
    : super(code: 401);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.errors = const {}});

  final Map<String, List<String>> errors;
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Đã xảy ra lỗi không xác định']);
}
