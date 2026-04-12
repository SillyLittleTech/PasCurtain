import 'dart:math';

/// Generates cryptographically strong password suggestions.
///
/// Uses [Random.secure] so suggestions are suitable for use as real credentials.
class PasswordGenerator {
  PasswordGenerator({int length = 20}) : _length = length {
    assert(length >= 4, 'PasswordGenerator length must be at least 4.');
  }

  final int _length;

  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _digits = '0123456789';
  static const String _symbols = r'!@#$%^&*()-_=+[]{}|;:,.<>?';
  static const String _all = _upper + _lower + _digits + _symbols;

  /// Returns a list of [count] secure random password suggestions.
  List<String> generate({int count = 3}) {
    final suggestions = <String>[];
    for (var i = 0; i < count; i++) {
      suggestions.add(_generateOne());
    }
    return suggestions;
  }

  String _generateOne() {
    final rng = Random.secure();
    // Guarantee at least one character from each character class
    final chars = <String>[
      _upper[rng.nextInt(_upper.length)],
      _lower[rng.nextInt(_lower.length)],
      _digits[rng.nextInt(_digits.length)],
      _symbols[rng.nextInt(_symbols.length)],
    ];

    // Fill remaining positions randomly from the full set
    for (var i = chars.length; i < _length; i++) {
      chars.add(_all[rng.nextInt(_all.length)]);
    }

    // Fisher-Yates shuffle to avoid predictable positions
    for (var i = chars.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }

    return chars.join();
  }

  /// Returns a memorable passphrase from a small built-in wordlist.
  ///
  /// The words are joined by a separator and padded with digits and symbols
  /// to meet common complexity requirements.
  static String generatePassphrase({int wordCount = 4}) {
    final rng = Random.secure();
    final words = _wordlist;
    final selected = List.generate(
      wordCount,
      (_) => words[rng.nextInt(words.length)],
    );
    const symbols = r'!@#$%^&*()-_=+[]{}|;:,.<>?';
    final number = rng.nextInt(900) + 100; // 3-digit number
    final symbol = symbols[rng.nextInt(symbols.length)];
    return '${selected.join('-')}-$number$symbol';
  }

  // A short word list for passphrase generation.
  // Extended with security-neutral common words.
  static const List<String> _wordlist = [
    'apple', 'beach', 'brave', 'cedar', 'chess', 'climb', 'cloud', 'coral',
    'dance', 'delta', 'depth', 'drift', 'eagle', 'ember', 'flame', 'flair',
    'flint', 'forge', 'frost', 'glass', 'globe', 'gloom', 'grace', 'grant',
    'grove', 'haven', 'heart', 'hedge', 'ivory', 'jewel', 'karma', 'lance',
    'lemon', 'lodge', 'lunar', 'maple', 'marsh', 'merit', 'metal', 'might',
    'minds', 'minor', 'mirth', 'moist', 'monks', 'mount', 'noble', 'north',
    'oaken', 'ocean', 'olive', 'onyx', 'orbit', 'otter', 'oxide', 'ozone',
    'pearl', 'penny', 'petal', 'pilot', 'pixel', 'pizza', 'place', 'plain',
    'plant', 'plaza', 'plumb', 'plume', 'plush', 'poet', 'polar', 'poppy',
    'prism', 'prize', 'quest', 'quill', 'quota', 'quoth', 'radar', 'radix',
    'rally', 'range', 'rapid', 'ratio', 'raven', 'razor', 'realm', 'rebel',
    'relay', 'remix', 'renew', 'rivet', 'robin', 'rocky', 'rouge', 'rover',
    'rustic', 'saint', 'salvo', 'sandy', 'satin', 'seeker', 'serif', 'shade',
    'shaft', 'shore', 'siege', 'sigma', 'silky', 'since', 'skate', 'slate',
    'sleek', 'slide', 'slime', 'slope', 'smart', 'smolt', 'snake', 'solar',
    'solid', 'sonic', 'spark', 'spell', 'spice', 'spine', 'spiral', 'spoke',
    'spoon', 'sprig', 'squad', 'stack', 'stage', 'stair', 'stake', 'stale',
    'stand', 'steel', 'steep', 'stern', 'still', 'stilt', 'sting', 'stock',
    'stone', 'stork', 'storm', 'story', 'stout', 'stove', 'strap', 'straw',
    'style', 'sugar', 'suite', 'sunny', 'super', 'swift', 'sword', 'table',
    'tempo', 'tenor', 'thorn', 'tiger', 'tonic', 'torch', 'track', 'trade',
    'trail', 'train', 'trait', 'tramp', 'tread', 'treat', 'trend', 'trial',
    'tribe', 'trick', 'troop', 'trout', 'trove', 'truce', 'truly', 'trust',
    'tulip', 'tuner', 'twist', 'ultra', 'umbra', 'unify', 'unity', 'until',
    'upper', 'urban', 'usual', 'usher', 'utter', 'vague', 'valid', 'valor',
    'valve', 'vapor', 'vault', 'venom', 'venue', 'verse', 'video', 'vigor',
    'viola', 'viper', 'viral', 'visor', 'vista', 'vital', 'vivid', 'vocal',
    'vodka', 'vogue', 'voice', 'voter', 'wagon', 'watch', 'water', 'weave',
    'wedge', 'wheel', 'while', 'white', 'whole', 'wider', 'wield', 'wight',
    'winds', 'wired', 'wispy', 'witch', 'worth', 'wrath', 'xenon', 'yacht',
    'yield', 'young', 'zeal', 'zebra', 'zero', 'zingy', 'zonal', 'zodiac',
  ];
}
