class Dam {
  final String name;
  final double level;
  final String lastUpdated;
  final String capacity;

  const Dam({
    required this.name,
    required this.level,
    required this.lastUpdated,
    required this.capacity,
  });

  factory Dam.fromFirestore(String id, Map<String, dynamic> data) {
    return Dam(
      name: data['name'] as String,
      level: (data['level'] as num).toDouble(),
      lastUpdated: data['lastUpdated'] as String,
      capacity: data['capacity'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'lastUpdated': lastUpdated,
      'capacity': capacity,
    };
  }
}
