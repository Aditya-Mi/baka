enum Mood {
  happy('😊', 'Happy'),
  sad('😔', 'Sad'),
  angry('😤', 'Angry'),
  tired('😴', 'Tired'),
  anxious('😰', 'Anxious'),
  excited('🥳', 'Excited'),
  calm('😌', 'Calm'),
  crying('😢', 'Tearful'),
  thoughtful('🤔', 'Reflective'),
  loved('❤️', 'Loved');

  const Mood(this.emoji, this.label);
  final String emoji;
  final String label;

  static Mood fromName(String name) =>
      Mood.values.firstWhere((m) => m.name == name, orElse: () => Mood.calm);
}
