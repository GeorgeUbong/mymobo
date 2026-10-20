/// Which colour template the user picked.
/// Only an identifier lives here. The actual colours belong to the
/// card theme (themes/card_theme.dart), which maps each template to
/// light/dark colours.
enum CardTemplate { teal, orange, navy, burgundy }

enum CardType {
  visa,
  mastercard,
  amex,
  verve,
  other;

  String get label => switch (this) {
        CardType.visa => 'Visa',
        CardType.mastercard => 'Mastercard',
        CardType.amex => 'Amex',
        CardType.verve => 'Verve',
        CardType.other => 'Other',
      };

  /// Guess the type from the card number prefix.
  static CardType detect(String number) {
    final n = number.replaceAll(RegExp(r'\s'), '');
    if (n.startsWith('4')) return CardType.visa;
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(n)) return CardType.mastercard;
    if (RegExp(r'^3[47]').hasMatch(n)) return CardType.amex;
    if (RegExp(r'^(506|650)').hasMatch(n)) return CardType.verve;
    return CardType.other;
  }
}

class CardModel {
  final String id;
  final String name; // custom name, shown before authentication
  final CardTemplate template;

  // Sensitive details, shown only after authentication
  final String number;
  final String cvv;
  final String expiry; // "MM/YY"
  final CardType type;

  final bool isActive;

  const CardModel({
    required this.id,
    required this.name,
    required this.template,
    required this.number,
    required this.cvv,
    required this.expiry,
    required this.type,
    this.isActive = true,
  });

  String get maskedNumber {
    final digits = number.replaceAll(RegExp(r'\s'), '');
    final last4 =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    return '**** **** **** $last4';
  }

  String get formattedNumber {
    final digits = number.replaceAll(RegExp(r'\s'), '');
    return digits
        .replaceAllMapped(RegExp(r'.{1,4}'), (m) => '${m.group(0)} ')
        .trim();
  }

  CardModel copyWith({
    String? name,
    CardTemplate? template,
    String? number,
    String? cvv,
    String? expiry,
    CardType? type,
    bool? isActive,
  }) {
    return CardModel(
      id: id,
      name: name ?? this.name,
      template: template ?? this.template,
      number: number ?? this.number,
      cvv: cvv ?? this.cvv,
      expiry: expiry ?? this.expiry,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'template': template.name,
        'number': number,
        'cvv': cvv,
        'expiry': expiry,
        'type': type.name,
        'isActive': isActive,
      };

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
        id: json['id'] as String,
        name: json['name'] as String,
        template: CardTemplate.values.byName(json['template'] as String),
        number: json['number'] as String,
        cvv: json['cvv'] as String,
        expiry: json['expiry'] as String,
        type: CardType.values.byName(json['type'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );
}