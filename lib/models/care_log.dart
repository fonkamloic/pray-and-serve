class CareLog {
  final String id;
  final String personId;
  String date;
  String type;
  String note;

  CareLog({
    required this.id,
    required this.personId,
    required this.date,
    this.type = 'Call',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'date': date,
        'type': type,
        'note': note,
      };

  factory CareLog.fromJson(Map<String, dynamic> json) => CareLog(
        id: json['id'] as String,
        personId: json['personId'] as String,
        date: json['date'] as String,
        type: json['type'] as String? ?? 'Call',
        note: json['note'] as String? ?? '',
      );
}
