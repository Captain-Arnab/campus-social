import 'package:get/get.dart';

import '../../../data/pref_service.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/pickup_point.dart';
import '../models/restaurant.dart';
import 'orders_controller.dart';

class CartController extends GetxController {
  final restaurant = Rxn<Restaurant>();
  final items = <CartItem>[].obs;
  final pickupPoint = PickupPoint.mainGate.obs;

  static const double taxRate = 0.05;
  static const double platformFee = 5.0;

  @override
  void onInit() {
    super.onInit();
    _loadPickupPreference();
  }

  Future<void> _loadPickupPreference() async {
    final key = await PrefService.getFoodPickupPoint();
    pickupPoint.value = PickupPointX.fromStorage(key);
  }

  Future<void> setPickupPoint(PickupPoint point) async {
    pickupPoint.value = point;
    await PrefService.setFoodPickupPoint(point.storageKey);
  }

  int qtyFor(String menuItemId) {
    final found = items.firstWhereOrNull((i) => i.menuItem.id == menuItemId);
    return found?.quantity ?? 0;
  }

  int get totalQty => items.fold(0, (s, i) => s + i.quantity);

  double get itemTotal => items.fold(0.0, (s, i) => s + i.lineTotal);

  double get taxes => double.parse((itemTotal * taxRate).toStringAsFixed(2));

  double get grandTotal =>
      double.parse((itemTotal + taxes + (items.isEmpty ? 0 : platformFee)).toStringAsFixed(2));

  bool get isEmpty => items.isEmpty;

  /// Adding from another restaurant clears the previous cart.
  void addItem(Restaurant from, MenuItem menuItem) {
    if (restaurant.value != null && restaurant.value!.id != from.id) {
      items.clear();
    }
    restaurant.value = from;
    final existing = items.firstWhereOrNull((i) => i.menuItem.id == menuItem.id);
    if (existing != null) {
      existing.quantity += 1;
      items.refresh();
    } else {
      items.add(CartItem(menuItem: menuItem, quantity: 1));
    }
  }

  void increment(String menuItemId) {
    final existing = items.firstWhereOrNull((i) => i.menuItem.id == menuItemId);
    if (existing == null) return;
    existing.quantity += 1;
    items.refresh();
  }

  void decrement(String menuItemId) {
    final existing = items.firstWhereOrNull((i) => i.menuItem.id == menuItemId);
    if (existing == null) return;
    if (existing.quantity <= 1) {
      items.remove(existing);
      if (items.isEmpty) restaurant.value = null;
    } else {
      existing.quantity -= 1;
      items.refresh();
    }
  }

  void clear() {
    items.clear();
    restaurant.value = null;
  }

  FoodOrder placeOrder() {
    final r = restaurant.value;
    if (r == null || items.isEmpty) {
      throw StateError('Cart is empty');
    }
    final order = FoodOrder(
      id: 'ORD-${1000 + DateTime.now().millisecondsSinceEpoch % 9000}',
      restaurantId: r.id,
      restaurantName: r.name,
      restaurantImageUrl: r.imageUrl,
      items: items.map((i) => CartItem(menuItem: i.menuItem, quantity: i.quantity)).toList(),
      itemTotal: itemTotal,
      taxes: taxes,
      platformFee: platformFee,
      grandTotal: grandTotal,
      pickupPoint: pickupPoint.value,
      status: OrderStatus.placed,
      placedAt: DateTime.now(),
      etaMins: r.pickupMins,
    );
    if (Get.isRegistered<OrdersController>()) {
      Get.find<OrdersController>().addOrder(order);
    }
    clear();
    return order;
  }
}
