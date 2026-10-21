import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingua/core/riverpod/base_notifier.dart';
import 'package:lingua/core/utils/toast.dart';

/// Toast thông báo từ `notifier.run(successMessage:, errorMessage:)`.
///
/// Chỉ màn đang ở TRÊN CÙNG mới toast — notifier dùng chung (keepAlive) được nhiều màn
/// trong stack cùng nghe (vd Login nằm dưới Register) thì vẫn chỉ hiện 1 toast.
void useRunMessages(BaseNotifier<Object?>? notifier) {
  final context = useContext();
  useEffect(() {
    final n = notifier;
    if (n == null) return null;
    final sub = n.messages.listen((m) {
      if (!context.mounted) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
        return; // màn bị che → bỏ
      }
      m.isError ? toast.error(m.text) : toast.success(m.text);
    });
    return sub.cancel;
  }, [notifier]);
}
