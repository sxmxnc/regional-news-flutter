import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../api/drive_gallery_client.dart';
import '../../api/mapper/drive_gallery_mapper.dart';
import '../../core/query.dart';
import 'gallery.dart';

final class GalleryKey extends QueryKey {
  const GalleryKey(
    super.language, {
    required this.accountId,
    required this.listToken,
    required this.sort,
  });

  final String accountId;

  /// `data-token` des Blocks: der Schlüssel dieser einen Galerie.
  final String listToken;

  /// `data-sort`, im Bestand durchweg `name:asc`. Steht im Schlüssel, weil
  /// er die Reihenfolge der Antwort bestimmt.
  final String sort;

  @override
  List<Object?> get parts => <Object?>[accountId, listToken, sort];
}

final FutureProviderFamily<List<GalleryImage>, GalleryKey> galleryProvider =
    FutureProvider.family<List<GalleryImage>, GalleryKey>((
      Ref ref,
      GalleryKey key,
    ) async {
      ref.cacheFor(key.freshFor);
      final List<Map<String, Object?>> raw = await ref
          .watch(driveGalleryClientProvider)
          .getImages(
            accountId: key.accountId,
            listToken: key.listToken,
            sort: key.sort,
          );
      final List<GalleryImage> images = DriveGalleryMapper.fromList(raw);
      ref.markSynced();
      return images;
    }, isAutoDispose: true);
