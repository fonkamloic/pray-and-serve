class Prayer {
  final String id;
  String title;
  String details;
  String category;
  String urgency;
  String scripture;
  String recurrence;
  String createdAt;
  bool answered;
  String? answeredAt;
  String? answerNote;
  String? personId;

  Prayer({
    required this.id,
    required this.title,
    this.details = '',
    this.category = 'Personal',
    this.urgency = 'Ongoing',
    this.scripture = '',
    this.recurrence = 'None',
    required this.createdAt,
    this.answered = false,
    this.answeredAt,
    this.answerNote,
    this.personId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'details': details,
        'category': category,
        'urgency': urgency,
        'scripture': scripture,
        'recurrence': recurrence,
        'createdAt': createdAt,
        'answered': answered,
        'answeredAt': answeredAt,
        'answerNote': answerNote,
        'personId': personId,
      };

  factory Prayer.fromJson(Map<String, dynamic> json) => Prayer(
        id: json['id'] as String,
        title: json['title'] as String,
        details: json['details'] as String? ?? '',
        category: json['category'] as String? ?? 'Personal',
        urgency: json['urgency'] as String? ?? 'Ongoing',
        scripture: json['scripture'] as String? ?? '',
        recurrence: json['recurrence'] as String? ?? 'None',
        createdAt: json['createdAt'] as String,
        answered: json['answered'] as bool? ?? false,
        answeredAt: json['answeredAt'] as String?,
        answerNote: json['answerNote'] as String?,
        personId: json['personId'] as String?,
      );
}
