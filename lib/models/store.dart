import 'package:geolocator/geolocator.dart';

/// A Kaufland store location with helpers for distance and opening hours.
class Store {
  /// Unique identifier for the store (e.g. "DE3283").
  final String storeId;

  /// Display name of the store.
  final String name;

  /// Full address of the store.
  final String address;

  /// Weekly opening hours: "Mon: HH:MM-HH:MM, Tue: HH:MM-HH:MM, ...".
  final String openingHours;

  /// Geographic coordinates as `[latitude, longitude]`.
  final List<double> position;

  /// ISO country code (e.g. "DE").
  final String country;

  const Store({
    required this.storeId,
    required this.name,
    required this.address,
    required this.openingHours,
    required this.position,
    required this.country,
  });

  /// Fallback store used before the user has picked one.
  static const Store fallback = Store(
    storeId: 'DE3283',
    name: 'Kaufland Dresden-Striesen-West',
    address: 'Borsbergstraße 35, Dresden',
    openingHours:
        'Mon: 09:00-20:00, Tue: 09:00-20:00, Wed: 09:00-20:00, Thu: 09:00-20:00, Fri: 09:00-20:00, Sat: 09:00-20:00, Sun: 0:00-0:00',
    position: [51.044094, 13.7812778], // [latitude, longitude]
    country: 'DE',
  );

  factory Store.fromJson(Map<String, dynamic> json) => Store(
    storeId: json['storeId'] ?? '',
    name: json['name'] ?? '',
    address: json['address'] ?? '',
    openingHours: json['openingHours'] ?? '',
    position: [
      (json['latitude'] as num?)?.toDouble() ?? 0.0,
      (json['longitude'] as num?)?.toDouble() ?? 0.0,
    ],
    country: json['country'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'storeId': storeId,
    'name': name,
    'address': address,
    'openingHours': openingHours,
    'latitude': position[0],
    'longitude': position[1],
    'country': country,
  };

  /// Distance in kilometers from the given coordinates to this store.
  double getDistance(double userLatitude, double userLongitude) =>
      Geolocator.distanceBetween(
        userLatitude,
        userLongitude,
        position[0],
        position[1],
      ) /
      1000;

  /// Today's opening hours, or "Closed" / "no information available".
  String openingHoursForToday() {
    if (openingHours.isEmpty) return 'no information available';

    // Strip the weekday prefix ("Mon: ") from each segment. Trim first so the
    // leading space left by split(',') doesn't defeat the prefix removal.
    final hours = openingHours.split(',').map((segment) {
      segment = segment.trim();
      final space = segment.indexOf(' ');
      return space < 0 ? segment : segment.substring(space + 1).trim();
    }).toList();

    // DateTime.weekday: 1 = Monday ... 7 = Sunday.
    final index = DateTime.now().weekday - 1;
    if (index < 0 || index >= hours.length) return 'Closed';

    final today = hours[index];
    return today == '0:00-0:00' ? 'Closed' : today;
  }
}
