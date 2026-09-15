class ModelInboxNotification {
  int? id;
  String? notificationType;
  String? title;
  String? body;
  int? eventId;
  Map<String, dynamic>? data;
  bool isRead;
  String? createdAt;

  ModelInboxNotification({
    this.id,
    this.notificationType,
    this.title,
    this.body,
    this.eventId,
    this.data,
    this.isRead = false,
    this.createdAt,
  });

  factory ModelInboxNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map
            ? Map<String, dynamic>.from(
                (json['data'] as Map).map((k, v) => MapEntry(k.toString(), v)),
              )
            : null);

    String? body = json['body']?.toString();
    if (body == null || body.trim().isEmpty) {
      body = data?['body']?.toString() ??
          data?['content']?.toString() ??
          data?['minutes_content']?.toString();
    }

    return ModelInboxNotification(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      notificationType: json['notification_type']?.toString(),
      title: json['title']?.toString(),
      body: body,
      eventId: json['event_id'] is int
          ? json['event_id']
          : int.tryParse(json['event_id']?.toString() ?? ''),
      data: data,
      isRead: (json['is_read'] ?? 0) == 1,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'notification_type': notificationType,
        'title': title,
        'body': body,
        'event_id': eventId,
        'data': data,
        'is_read': isRead ? 1 : 0,
        'created_at': createdAt,
      };
}
