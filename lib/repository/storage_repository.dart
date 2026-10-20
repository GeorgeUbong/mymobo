import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/card_model.dart';

/// Stores cards encrypted on the device
/// (Android Keystore / iOS Keychain via flutter_secure_storage).
///
/// The whole card list is saved as one JSON string under a single key,
/// which keeps reads/writes simple and atomic.
class CardStorageRepository {
  static const _cardsKey = 'digiwallet_cards';

  final FlutterSecureStorage _storage;

  CardStorageRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Returns all saved cards (empty list if none or data is unreadable).
  Future<List<CardModel>> getCards() async {
    try {
      final raw = await _storage.read(key: _cardsKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt or unreadable data: fail safe with an empty list.
      return [];
    }
  }

  /// Adds a new card, or replaces the existing one with the same id.
  /// Use this for the active/inactive toggle too (via copyWith).
  Future<void> saveCard(CardModel card) async {
    final cards = await getCards();
    final index = cards.indexWhere((c) => c.id == card.id);

    if (index >= 0) {
      cards[index] = card;
    } else {
      cards.add(card);
    }
    await _writeAll(cards);
  }

  Future<void> deleteCard(String id) async {
    final cards = await getCards();
    cards.removeWhere((c) => c.id == id);
    await _writeAll(cards);
  }

  /// Removes every saved card.
  Future<void> clearAll() => _storage.delete(key: _cardsKey);

  Future<void> _writeAll(List<CardModel> cards) {
    final encoded = jsonEncode(cards.map((c) => c.toJson()).toList());
    return _storage.write(key: _cardsKey, value: encoded);
  }
}