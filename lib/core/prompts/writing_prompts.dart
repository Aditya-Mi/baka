/// Daily writing prompts and motivational nudges.
/// Rotates by day-of-year so the same prompt shows all day.
class WritingPrompts {
  static const _prompts = <String>[
    'What surprised you today?',
    'Describe where you are right now.',
    'What are you looking forward to?',
    'What did today smell, sound, or feel like?',
    'Who made you smile today?',
    'What is something you learned today?',
    'What would you tell your past self about today?',
    'What conversation is still on your mind?',
    'What did you almost do but didn\'t?',
    'Describe today in three words — then explain them.',
    'What made you laugh today?',
    'What was the best moment of the last 24 hours?',
    'What are you grateful for right now?',
    'What is weighing on your mind?',
    'If today were a color, what would it be?',
    'What do you wish had gone differently?',
    'What are you proud of today?',
    'Who do you want to check in on?',
    'What did your body need today?',
    'What is one thing you want to remember about today?',
    'What fear showed up today?',
    'Even one sentence is enough.',
    'A quiet moment for today\'s thoughts.',
    'What is still unfinished from today?',
    'Write about someone you thought of today.',
    'What was the hardest part of the day?',
    'What are you looking forward to tomorrow?',
    'What brought you peace today?',
    'Describe a small moment that mattered.',
    'What would today look like from someone else\'s perspective?',
    'What question do you keep asking yourself?',
    'What does today mean, a year from now?',
    'Five minutes. Just for you.',
    'Your story is still being written.',
    'What do you want to let go of today?',
  ];

  /// Returns today's prompt — same all day, changes at midnight.
  static String todayPrompt() {
    final day = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _prompts[day % _prompts.length];
  }
}
