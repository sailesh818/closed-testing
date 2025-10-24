class AppModel {
  final String id;
  final String userId;
  final String appName;
  final String description;
  //final String logoUrl;
  final String googleGroup;
  final String webAppLink;
  final String appLink;
  final int installs;

  AppModel({
    required this.id,
    required this.userId,
    required this.appName,
    required this.description,
    //required this.logoUrl,
    required this.googleGroup,
    required this.webAppLink,
    required this.appLink,
    required this.installs,
  });

  factory AppModel.fromMap(Map<String, dynamic> map, String id) {
    return AppModel(
      id: id,
      userId: map['userId'] ?? '',
      appName: map['appName'] ?? '',
      description: map['description'] ?? '',
      //logoUrl: map['logoUrl'] ?? '',
      googleGroup: map['googleGroup'] ?? '',
      webAppLink: map['webAppLink'] ?? '',
      appLink: map['appLink'] ?? '',
      installs: map['installs'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'appName': appName,
      'description': description,
      // 'logoUrl': logoUrl,
      'googleGroup': googleGroup,
      'webAppLink': webAppLink,
      'appLink': appLink,
      'installs': installs,
    };
  }
}
