import 'package:flutter/foundation.dart';

@immutable
class Province {
  final String name;
  final String code;
  final double total;
  final List<Map<String, dynamic>> dams;

  const Province({
    required this.name,
    required this.code,
    required this.total,
    this.dams = const [],
  });

  factory Province.fromFirestore(Map<String, dynamic> data) {
    return Province(
      name: data['name'] as String,
      code: data['code'] as String,
      total: (data['total'] as num).toDouble(),
      dams: List<Map<String, dynamic>>.from(data['dams'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'total': total,
      'dams': dams,
    };
  }

  Province copyWith({
    String? name,
    String? code,
    double? total,
    List<Map<String, dynamic>>? dams,
  }) {
    return Province(
      name: name ?? this.name,
      code: code ?? this.code,
      total: total ?? this.total,
      dams: dams ?? this.dams,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Province &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          code == other.code &&
          total == other.total;

  @override
  int get hashCode => name.hashCode ^ code.hashCode ^ total.hashCode;

  @override
  String toString() => 'Province(name: $name, code: $code, total: $total)';
}
