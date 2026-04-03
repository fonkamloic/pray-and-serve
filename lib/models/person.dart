class Person {
  final String id;
  String name;
  String notes;
  List<String> tags;
  List<String> needs;
  String email;
  String contactFreq;
  String? lastContact;

  Person({
    required this.id,
    required this.name,
    this.notes = '',
    this.tags = const [],
    this.needs = const [],
    this.email = '',
    this.contactFreq = 'Monthly',
    this.lastContact,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'notes': notes,
        'tags': tags,
        'needs': needs,
        'email': email,
        'contactFreq': contactFreq,
        'lastContact': lastContact,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        name: json['name'] as String,
        notes: json['notes'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        needs: (json['needs'] as List<dynamic>?)?.cast<String>() ?? [],
        email: json['email'] as String? ?? '',
        contactFreq: json['contactFreq'] as String? ?? 'Monthly',
        lastContact: json['lastContact'] as String?,
      );
}
