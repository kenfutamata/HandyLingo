class Point3D {
  final double x;
  final double y;
  final double z;

  Point3D({required this.x, required this.y, required this.z});

  factory Point3D.fromJson(dynamic json) {
    try {
      // If Python sends a List: [0.5, 0.1, 0.2]
      if (json is List) {
        return Point3D(
          x: (json[0] as num).toDouble(),
          y: (json[1] as num).toDouble(),
          z: (json[2] as num).toDouble(),
        );
      } 
      // If Python sends a Map: {"x": 0.5, "y": 0.1, "z": 0.2}
      if (json is Map) {
        return Point3D(
          x: (json['x'] as num? ?? 0.0).toDouble(),
          y: (json['y'] as num? ?? 0.0).toDouble(),
          z: (json['z'] as num? ?? 0.0).toDouble(),
        );
      }
    } catch (e) {
      print("Error parsing point: $e");
    }
    return Point3D(x: 0, y: 0, z: 0); // Default fallback
  }
}

class LandmarkFrame {
  final List<Point3D> points;
  LandmarkFrame({required this.points});

  factory LandmarkFrame.fromJson(dynamic json) {
    if (json is List) {
      return LandmarkFrame(
        points: json.map((p) => Point3D.fromJson(p)).toList(),
      );
    }
    return LandmarkFrame(points: []);
  }
}