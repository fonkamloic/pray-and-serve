class ServeGroup {
  final String id;
  String name;
  List<String> personIds;

  ServeGroup({
    required this.id,
    required this.name,
    this.personIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'personIds': personIds,
      };

  factory ServeGroup.fromJson(Map<String, dynamic> json) => ServeGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        personIds:
            (json['personIds'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}
