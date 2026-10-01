import 'storage_provider.dart';

/// Maps a provider id to its implementation.
class ProviderRegistry {
  ProviderRegistry(Iterable<StorageProvider> providers)
    : _byId = {for (final p in providers) p.id: p};

  final Map<String, StorageProvider> _byId;

  StorageProvider get(String id) {
    final p = _byId[id];
    if (p == null) throw ArgumentError.value(id, 'id', 'Unknown provider');
    return p;
  }

  List<String> get ids => List.unmodifiable(_byId.keys);
}
