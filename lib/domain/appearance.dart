/// Stable persisted identifiers, independent of Flutter and platform colors.
class Appearance {
  const Appearance({
    this.mode = 'system',
    this.palette = 'blue',
    this.font = 'system',
    this.frame = 'soft',
  });
  final String mode, palette, font, frame;
  static const iconCount = 24;
  static const palettes = ['blue', 'teal', 'violet'];
  static const fonts = ['system', 'serif'];
  static const frames = ['soft', 'ring', 'plain'];
  static const habitColors = [
    'auto',
    'blue',
    'violet',
    'peach',
    'teal',
    'rose',
  ];
  static const habitFrames = ['auto', ...frames];
  static const preferenceValues = <String, List<String>>{
    'theme': ['system', 'light', 'dark'],
    'locale': ['system', 'en', 'zh'],
    'completion_sound': ['on', 'off'],
    'completion_haptics': ['on', 'off'],
    'palette': palettes,
    'font': fonts,
    'icon_frame': frames,
  };
  static bool validPreference(String key, Object? value) =>
      preferenceValues[key]?.contains(value) ?? false;
  factory Appearance.fromSettings(Map<String, String> settings) {
    String get(String key, String fallback) =>
        validPreference(key, settings[key]) ? settings[key]! : fallback;
    return Appearance(
      mode: get('theme', 'system'),
      palette: get('palette', 'blue'),
      font: get('font', 'system'),
      frame: get('icon_frame', 'soft'),
    );
  }
  Map<String, String> toSettings() => {
    'theme': mode,
    'palette': palette,
    'font': font,
    'icon_frame': frame,
  };
  bool get valid =>
      toSettings().entries.every((e) => validPreference(e.key, e.value));
  Appearance copyWith({
    String? mode,
    String? palette,
    String? font,
    String? frame,
  }) => Appearance(
    mode: mode ?? this.mode,
    palette: palette ?? this.palette,
    font: font ?? this.font,
    frame: frame ?? this.frame,
  );
}
