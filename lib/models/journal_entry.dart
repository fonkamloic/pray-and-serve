class JournalEntry {
  final String id;
  String date;
  String title;
  String body;
  String scripture;
  String reflection;

  JournalEntry({
    required this.id,
    required this.date,
    this.title = '',
    this.body = '',
    this.scripture = '',
    this.reflection = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'title': title,
        'body': body,
        'scripture': scripture,
        'reflection': reflection,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        date: json['date'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        scripture: json['scripture'] as String? ?? '',
        reflection: json['reflection'] as String? ?? '',
      );
}
