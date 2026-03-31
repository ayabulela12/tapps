
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AlertType {
  severe('Severe Weather', Icons.warning, Colors.red),
  moderate('Moderate Weather', Icons.info, Colors.orange),
  advisory('Weather Advisory', Icons.info_outline, Colors.yellow),
  info('Weather Update', Icons.cloud, Colors.blue),
  dam('Dam Level Alert', Icons.water_drop, Colors.cyan),
  drought('Drought Warning', Icons.dry, Colors.amber);

  const AlertType(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

enum AlertPriority {
  critical('Critical', 1),
  high('High', 2),
  medium('Medium', 3),
  low('Low', 4);

  const AlertPriority(this.displayName, this.priority);
  final String displayName;
  final int priority;
}

class WeatherAlert {
  final String id;
  final String title;
  final String description;
  final AlertType type;
  final AlertPriority priority;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String? region;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final String? actionUrl;

  WeatherAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.issuedAt,
    this.expiresAt,
    this.region,
    this.latitude,
    this.longitude,
    this.metadata,
    this.isRead = false,
    this.actionUrl,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.info,
      ),
      priority: AlertPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => AlertPriority.medium,
      ),
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String) 
          : null,
      region: json['region'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
      'metadata': metadata,
      'isRead': isRead,
      'actionUrl': actionUrl,
    };
  }

  WeatherAlert copyWith({
    String? id,
    String? title,
    String? description,
    AlertType? type,
    AlertPriority? priority,
    DateTime? issuedAt,
    DateTime? expiresAt,
    String? region,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? metadata,
    bool? isRead,
    String? actionUrl,
  }) {
    return WeatherAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      region: region ?? this.region,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  bool get isActive => !isExpired && !isRead;
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(issuedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
  
  String get expiresAtText {
    if (expiresAt == null) return 'No expiration';
    final now = DateTime.now();
    final difference = expiresAt!.difference(now);

    if (difference.inDays > 0) {
      return 'Expires in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'Expires in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'Expires in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Expires soon';
    }
  }

  bool isWithinRange(double userLat, double userLon, {double radiusKm = 50.0}) {
    if (latitude == null || longitude == null) return true; // Region-wide alert
    
    final distance = _calculateDistance(
      userLat, userLon, 
      latitude!, longitude!
    );
    
    return distance <= radiusKm;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}
