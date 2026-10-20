class UserModel {
  final String name;
  final int age;
  final double yearlyEarning;

  const UserModel({
    required this.name,
    required this.age,
    required this.yearlyEarning,
  });

  double get monthlyEarning => yearlyEarning / 12;

  UserModel copyWith({String? name, int? age, double? yearlyEarning}) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      yearlyEarning: yearlyEarning ?? this.yearlyEarning,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'yearlyEarning': yearlyEarning,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        name: json['name'] as String,
        age: json['age'] as int,
        yearlyEarning: (json['yearlyEarning'] as num).toDouble(),
      );
}