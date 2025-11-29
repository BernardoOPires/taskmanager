class Task {
  final int? id;
  final String title;
  final String description;
  final String priority;
  final bool completed;
  final DateTime? completedAt;
  final String? completedBy;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime lastModifiedAt;
  final bool isSynced;

  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.completed,
    this.completedAt,
    this.completedBy,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.lastModifiedAt,
    this.isSynced = true,
  });

  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;
  bool get wasCompletedByShake => completedBy == 'shake';

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? priority,
    bool? completed,
    DateTime? completedAt,
    String? completedBy,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? lastModifiedAt,
    bool? isSynced,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'completed': completed ? 1 : 0,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'completed_by': completedBy,
      'photo_path': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'last_modified_at': lastModifiedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'medium',
      completed: (map['completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
      completedBy: map['completed_by'] as String?,
      photoPath: map['photo_path'] as String?,
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      locationName: map['location_name'] as String?,
      lastModifiedAt: map['last_modified_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_modified_at'] as int)
          : DateTime.now(),
      isSynced: (map['is_synced'] as int? ?? 1) == 1,
    );
  }
}
