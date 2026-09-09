import 'cart_item.dart';
import 'pickup_point.dart';

enum OrderStatus {
  placed,
  accepted,
  preparing,
  readyForPickup,
  pickedUp,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.pickedUp:
        return 'Picked Up';
    }
  }

  bool get isActive => this != OrderStatus.pickedUp;

  int get stageIndex {
    switch (this) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.readyForPickup:
        return 3;
      case OrderStatus.pickedUp:
        return 4;
    }
  }
}

class FoodOrder {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImageUrl;
  final List<CartItem> items;
  final double itemTotal;
  final double taxes;
  final double platformFee;
  final double grandTotal;
  final PickupPoint pickupPoint;
  final OrderStatus status;
  final DateTime placedAt;
  final int etaMins;

  const FoodOrder({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.items,
    required this.itemTotal,
    required this.taxes,
    required this.platformFee,
    required this.grandTotal,
    required this.pickupPoint,
    required this.status,
    required this.placedAt,
    required this.etaMins,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
}
