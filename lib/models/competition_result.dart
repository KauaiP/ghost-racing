
class CompetitionResult {
  final double distance;
  final int userSeconds;
  final int ghostSeconds;
  final double userPace;
  final double ghostPace;
  final bool userWon;

  CompetitionResult({
    required this.distance,
    required this.userSeconds,
    required this.ghostSeconds,
    required this.userPace,
    required this.ghostPace,
    required this.userWon,
  });

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'userSeconds': userSeconds,
      'ghostSeconds': ghostSeconds,
      'userPace': userPace,
      'ghostPace': ghostPace,
      'userWon': userWon,
    };
  }

  factory CompetitionResult.fromJson(Map<String, dynamic> json) {
    return CompetitionResult(
      distance: json['distance'],
      userSeconds: json['userSeconds'],
      ghostSeconds: json['ghostSeconds'],
      userPace: json['userPace'],
      ghostPace: json['ghostPace'],
      userWon: json['userWon'],
    );
  }
}
