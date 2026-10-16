class AlarmInfo {
  final String id;
  final String location;
  final double latitude;
  final double longitude;
  final bool isActive;

  AlarmInfo({
    required this.id,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
  });
}
