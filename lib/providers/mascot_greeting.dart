import 'dart:math';
import '../models/user_model.dart';

/// Picks a context-aware greeting line for the mascot to say.
///
/// Keep lines short — they render in a 260px-wide speech bubble and animate
/// character-by-character, so anything over ~60 characters feels sluggish.
///
/// Occasions:
///   - [forAppOpen]: first frame / tab switch to HOME
///   - [forCoinAdded]: immediately after a successful coin grant
///   - [forLevelUp]: when pig levels up
class MascotGreeting {
  MascotGreeting._();

  static String forAppOpen(UserModel user) {
    final pigName = user.pigName;
    final name = user.name.trim().isEmpty ? 'buddy' : user.name;
    final streak = user.currentStreak;
    final hour = DateTime.now().hour;

    final pool = <String>[
      if (hour < 11) 'Good morning, $name!',
      if (hour < 11) 'Rise and save, $name!',
      if (hour >= 11 && hour < 17) 'Hi $name! Ready to save?',
      if (hour >= 11 && hour < 17) 'Hey $name, $pigName missed you!',
      if (hour >= 17 && hour < 21) 'Welcome back, $name!',
      if (hour >= 21 || hour < 4) "Late saver! One more coin before bed?",
      if (streak >= 7) "$streak-day streak! You're on fire! 🔥",
      if (streak >= 3) "$streak days in a row — keep it up!",
      "Hi $name! I'm $pigName 👋",
      "You got this, $name!",
      "Every coin counts!",
    ];
    return _pick(pool);
  }

  static String forCoinAdded(UserModel user, int amount) {
    final pigName = user.pigName;
    final pool = <String>[
      "Om nom! +$amount coin${amount == 1 ? '' : 's'}!",
      "Yum! Thank you!",
      "I love saving!",
      "Clink clink! 🪙",
      "$amount more, yay!",
      "$pigName is happy!",
    ];
    return _pick(pool);
  }

  static String forLevelUp(UserModel user) {
    final pool = <String>[
      "Woohoo! I leveled up!",
      "Look at me grow!",
      "You made me bigger!",
      "Amazing work!",
    ];
    return _pick(pool);
  }

  static String _pick(List<String> lines) {
    if (lines.isEmpty) return 'Hi there!';
    return lines[Random().nextInt(lines.length)];
  }
}
