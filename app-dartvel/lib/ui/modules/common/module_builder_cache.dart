// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Upstream edits a module through its `Builder` (raw strings: a half-typed
// DoH URL, a port without an address) and only validates on save. Here every
// edit writes the module JSON at once, so the raw builder lives in this cache,
// keyed by module id, next to the JSON it last wrote. While the draft still
// holds that JSON the builder is reused, so half-typed text survives a
// rebuild; when the module changed from elsewhere it is rebuilt from JSON.

import '../../../domain/profile.dart';

final class ModuleBuilderCache<B> {
  ModuleBuilderCache(this._fromJson);

  final B Function(Map<String, dynamic> value) _fromJson;
  final Map<String, ({Map<String, dynamic> written, B builder})> _entries =
      <String, ({Map<String, dynamic> written, B builder})>{};

  /// The builder for [module]: the cached one if the draft still holds what
  /// it last wrote, else a fresh one from the module JSON.
  B resolve(TaggedModule module) {
    final value = module.value;
    final entry = _entries[module.id];
    if (entry != null && jsonEquals(entry.written, value)) return entry.builder;
    final builder = _fromJson(value);
    _entries[module.id] = (written: value, builder: builder);
    return builder;
  }

  /// Applies [changes] to [module] with `withField` (null removes the key,
  /// keys not in [changes] are kept), remembers [builder] against the result
  /// and returns the edited module.
  TaggedModule write(TaggedModule module, B builder, Map<String, Object?> changes) {
    var next = module;
    changes.forEach((key, value) => next = next.withField(key, value));
    _entries[module.id] = (written: next.value, builder: builder);
    return next;
  }

  /// Forgets every builder (tests).
  void clear() => _entries.clear();
}

/// Deep equality of decoded JSON values.
bool jsonEquals(Object? left, Object? right) {
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) || !jsonEquals(left[key], right[key])) return false;
    }
    return true;
  }
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (!jsonEquals(left[i], right[i])) return false;
    }
    return true;
  }
  return left == right;
}

/// One row of an editable list, with an id that survives edits and removals
/// (upstream `EditableListSectionItem`).
final class ListItem<T> {
  ListItem(this.value) : id = _nextId++;

  ListItem.withId(this.id, this.value);

  static int _nextId = 0;

  final int id;
  T value;

  ListItem<T> copyWith(T value) => ListItem<T>.withId(id, value);
}

List<ListItem<String>> stringItems(Iterable<dynamic>? values) =>
    <ListItem<String>>[for (final value in values ?? const <dynamic>[]) ListItem<String>('$value')];
