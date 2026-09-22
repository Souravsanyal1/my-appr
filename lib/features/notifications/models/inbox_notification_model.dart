/// Model for an in-app notification inbox item.
/// Stored locally in StorageService and works fully offline.
class InboxNotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? route; // Deep-link route, e.g. '/unlock', '/notifications'
  final DateTime receivedAt;
  final bool isRead;

  const InboxNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.route,
    required this.receivedAt,
    this.isRead = false,
  });

  InboxNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? route,
    DateTime? receivedAt,
    bool? isRead,
  }) {
    return InboxNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      route: route ?? this.route,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'route': route,
        'receivedAt': receivedAt.millisecondsSinceEpoch,
        'isRead': isRead,
      };

  factory InboxNotificationModel.fromMap(Map<String, dynamic> map) =>
      InboxNotificationModel(
        id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        route: map['route'] as String?,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(
          map['receivedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
        isRead: map['isRead'] as bool? ?? false,
      );
}
