import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:toastification/toastification.dart';

/// `toast.success('...')`, `toast.error('...')`, `toast.loading()` / `toast.stopLoading()`.
const toast = ToastService._();

class ToastService {
  const ToastService._();

  void success(String message, {String? title}) =>
      _show(ToastificationType.success, message, title);
  void error(String message, {String? title}) =>
      _show(ToastificationType.error, message, title);
  void warning(String message, {String? title}) =>
      _show(ToastificationType.warning, message, title);
  void info(String message, {String? title}) =>
      _show(ToastificationType.info, message, title);

  static String? _lastMessage;
  static DateTime? _lastAt;

  void _show(ToastificationType type, String message, String? title) {
    // Cùng nội dung trong 2s chỉ hiện 1 lần (nhiều nơi cùng báo 1 sự kiện).
    final now = DateTime.now();
    final last = _lastAt;
    if (message == _lastMessage &&
        last != null &&
        now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastMessage = message;
    _lastAt = now;
    toastification.show(
      type: type,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 3),
      title: title == null ? null : Text(title),
      description: Text(message),
      showProgressBar: true,
      dragToClose: true,
    );
  }

  void loading([String message = 'Đang tải...']) =>
      SmartDialog.showLoading<void>(msg: message);

  void stopLoading() => SmartDialog.dismiss<void>(status: SmartStatus.loading);
}
