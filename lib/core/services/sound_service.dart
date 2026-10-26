import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:lingua/core/di/global_providers.dart';
import 'package:lingua/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sound_service.g.dart';

/// Âm thanh hiệu ứng khi luyện tập (file trong `assets/sounds/`).
enum Sfx {
  /// Trả lời đúng: 2 nốt chuông đi lên.
  correct,

  /// Trả lời sai: 2 nốt trầm đi xuống, nhẹ.
  wrong,

  /// Hoàn thành 1 bài: hợp âm rải.
  complete,
}

/// Phát âm thanh + rung nhẹ khi trả lời. Tắt trong Hồ sơ → [soundEnabledProvider].
/// Mỗi âm 1 player nạp sẵn (độ trễ thấp), trộn cùng nhạc đang mở, không chặn giọng đọc.
class SoundService {
  SoundService({required bool Function() enabled}) : _enabled = enabled;

  final bool Function() _enabled;
  final _players = <Sfx, AudioPlayer>{};

  /// Môi trường test không có plugin âm thanh → không phát.
  static final _disabled = Platform.environment.containsKey('FLUTTER_TEST');

  static final _context = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  /// Đúng / sai sau 1 câu trả lời.
  Future<void> answer({required bool correct}) =>
      play(correct ? Sfx.correct : Sfx.wrong);

  Future<void> play(Sfx sfx) async {
    if (_disabled || !_enabled()) return;
    await switch (sfx) {
      Sfx.correct => HapticFeedback.lightImpact(),
      Sfx.wrong => HapticFeedback.mediumImpact(),
      Sfx.complete => HapticFeedback.heavyImpact(),
    };
    try {
      final player = _players[sfx] ??= await _load(sfx);
      await player.stop();
      await player.resume();
    } on Object catch (e, s) {
      talker.error('[SFX] play $sfx failed', e, s);
    }
  }

  Future<AudioPlayer> _load(Sfx sfx) async {
    final player = AudioPlayer();
    await player.setAudioContext(_context);
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource('sounds/${sfx.name}.wav'));
    return player;
  }
}

@Riverpod(keepAlive: true)
SoundService soundService(Ref ref) =>
    SoundService(enabled: () => ref.read(soundEnabledProvider));

/// Bật/tắt âm thanh & rung khi trả lời (mặc định bật) — lưu trên máy.
@Riverpod(keepAlive: true)
class SoundEnabled extends _$SoundEnabled {
  static const _key = 'sound_effects_v1';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? true;

  Future<void> set({required bool enabled}) async {
    state = enabled;
    await ref.read(sharedPrefsProvider).setBool(_key, enabled);
  }
}
