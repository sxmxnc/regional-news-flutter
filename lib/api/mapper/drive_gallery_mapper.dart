import '../../features/content/gallery.dart';
import 'json_fields.dart';

abstract final class DriveGalleryMapper {
  static GalleryImage? fromJson(Map<String, Object?> json) {
    final String? id = jsonString(json['id']);
    final String? url = jsonString(json['url']);
    if (id == null || url == null) return null;

    return GalleryImage(
      id: id,
      url: url,
      name: jsonString(json['name']),
      description: jsonString(json['description']),
      width: jsonInt(json['width']),
      height: jsonInt(json['height']),
    );
  }

  static List<GalleryImage> fromList(List<Map<String, Object?>> json) {
    return json.map(fromJson).whereType<GalleryImage>().toList(growable: false);
  }
}
