import 'menu_item.dart';

class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int ratingCount;
  final List<String> cuisines;
  final int pickupMins;
  final double distanceKm;
  final String pickupPointLabel;
  final int costForTwo;
  final bool isVegOnly;
  final bool hasOffer;
  final String? offerText;
  final String moreInfo;
  final List<MenuItem> menu;

  const Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.ratingCount,
    required this.cuisines,
    required this.pickupMins,
    required this.distanceKm,
    required this.pickupPointLabel,
    required this.costForTwo,
    required this.isVegOnly,
    required this.hasOffer,
    this.offerText,
    required this.moreInfo,
    required this.menu,
  });

  bool get isFastPickup => pickupMins <= 15;

  bool get hasNonVeg => menu.any((m) => !m.isVeg);

  String get cuisineLine => cuisines.join(', ');
}
