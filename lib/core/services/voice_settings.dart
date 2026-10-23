import 'dart:convert';

import 'package:lingua/core/di/global_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_settings.g.dart';

/// 1 giọng đọc có trên máy (Text-to-Speech).
class TtsVoice {
  const TtsVoice({
    required this.name,
    required this.locale,
    this.identifier,
    this.quality,
    this.gender,
    this.network = false,
  });

  /// Từ dữ liệu `flutter_tts.getVoices` (Android / iOS trả khác trường).
  factory TtsVoice.fromPlatform(Map<dynamic, dynamic> map) => TtsVoice(
    name: '${map['name']}',
    locale: '${map['locale']}',
    identifier: map['identifier'] as String?,
    quality: map['quality'] as String?,
    gender: map['gender'] as String?,
    network: map['network_required'] == '1',
  );

  factory TtsVoice.fromJson(Map<String, dynamic> json) => TtsVoice(
    name: json['name'] as String,
    locale: json['locale'] as String,
    identifier: json['identifier'] as String?,
    quality: json['quality'] as String?,
    gender: json['gender'] as String?,
    network: json['network'] as bool? ?? false,
  );

  final String name;

  /// Dạng `en-US`, `ja-JP`.
  final String locale;

  /// iOS: mã giọng (chọn đúng giọng nhanh nhất).
  final String? identifier;

  /// Android: very high / high / normal…; iOS: default / enhanced / premium.
  final String? quality;

  /// iOS: male / female (Android không có).
  final String? gender;

  /// Android: cần mạng mới đọc được.
  final bool network;

  String get id => identifier ?? '$locale/$name';

  bool get isHighQuality =>
      const {'very high', 'high', 'enhanced', 'premium'}.contains(quality);

  Map<String, String> toPlatform() => {
    'name': name,
    'locale': locale,
    'identifier': ?identifier,
  };

  Map<String, dynamic> toJson() => {
    'name': name,
    'locale': locale,
    'identifier': identifier,
    'quality': quality,
    'gender': gender,
    'network': network,
  };

  @override
  bool operator ==(Object other) => other is TtsVoice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Cài đặt đọc của 1 ngôn ngữ: giọng chính, giọng người thứ 2 (hội thoại), tốc độ.
/// Giọng `null` = mặc định của máy / tự chọn.
class VoicePrefs {
  const VoicePrefs({this.voice, this.partner, this.rate = defaultRate});

  factory VoicePrefs.fromJson(Map<String, dynamic> json) => VoicePrefs(
    voice: _voice(json['voice']),
    partner: _voice(json['partner']),
    rate: (json['rate'] as num?)?.toDouble() ?? defaultRate,
  );

  /// Tốc độ flutter_tts (0.5 ≈ bình thường): mặc định hơi chậm cho người học.
  static const defaultRate = 0.42;
  static const minRate = 0.25;
  static const maxRate = 0.7;

  final TtsVoice? voice;
  final TtsVoice? partner;
  final double rate;

  Map<String, dynamic> toJson() => {
    'voice': voice?.toJson(),
    'partner': partner?.toJson(),
    'rate': rate,
  };

  static TtsVoice? _voice(Object? json) =>
      json is Map<String, dynamic> ? TtsVoice.fromJson(json) : null;
}

/// Giọng đọc người dùng chọn, theo ngôn ngữ đọc (`en-US`, `ja-JP`) — lưu trên máy.
@Riverpod(keepAlive: true)
class VoiceSettingsNotifier extends _$VoiceSettingsNotifier {
  static const _key = 'voice_v1';

  @override
  Map<String, VoicePrefs> build() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return const {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, VoicePrefs.fromJson(v as Map<String, dynamic>)),
      );
    } on Object {
      return const {};
    }
  }

  VoicePrefs of(String language) => state[language] ?? const VoicePrefs();

  Future<void> setVoice(String language, TtsVoice? voice) {
    final p = of(language);
    return _save(
      language,
      VoicePrefs(voice: voice, partner: p.partner, rate: p.rate),
    );
  }

  Future<void> setPartner(String language, TtsVoice? voice) {
    final p = of(language);
    return _save(
      language,
      VoicePrefs(voice: p.voice, partner: voice, rate: p.rate),
    );
  }

  Future<void> setRate(String language, double rate) {
    final p = of(language);
    return _save(
      language,
      VoicePrefs(voice: p.voice, partner: p.partner, rate: rate),
    );
  }

  Future<void> _save(String language, VoicePrefs prefs) async {
    state = {...state, language: prefs};
    await ref
        .read(sharedPrefsProvider)
        .setString(
          _key,
          jsonEncode(state.map((k, v) => MapEntry(k, v.toJson()))),
        );
  }
}
