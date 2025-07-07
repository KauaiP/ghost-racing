class GhostData {
  final double distance; // em metros
  final int elapsedSeconds; // tempo total em segundos
  final double pace; // min/km

  GhostData({
    required this.distance,
    required this.elapsedSeconds,
    required this.pace,
  });

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'elapsedSeconds': elapsedSeconds,
      'pace': pace,
    };
  }

  factory GhostData.fromJson(Map<String, dynamic> json) {
    return GhostData(
      distance: json['distance'],
      elapsedSeconds: json['elapsedSeconds'],
      pace: json['pace'],
    );
  }
}
