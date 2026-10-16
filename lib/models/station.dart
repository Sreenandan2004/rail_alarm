class Station {
  final String code;
  final String name;
  final double latitude;
  final double longitude;

  const Station({
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      code: json['code'] as String,
      name: json['name'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'lat': latitude,
    'lng': longitude,
  };

  String get displayName => '$name ($code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Station &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
