import 'package:get/get.dart';

import '../data/dummy_data.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/restaurant.dart';
import 'cart_controller.dart';

class OrdersController extends GetxController {
  final orders = <FoodOrder>[].obs;

  @override
  void onInit() {
    super.onInit();
    orders.assignAll(FoodDummyData.seedOrders());
  }

  List<FoodOrder> get activeOrders =>
      orders.where((o) => o.status.isActive).toList();

  List<FoodOrder> get pastOrders =>
      orders.where((o) => !o.status.isActive).toList();

  FoodOrder? byId(String id) {
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  void addOrder(FoodOrder order) {
    orders.insert(0, order);
  }

  void advanceStatus(String orderId) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    final current = orders[idx];
    final next = switch (current.status) {
      OrderStatus.placed => OrderStatus.accepted,
      OrderStatus.accepted => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.readyForPickup,
      OrderStatus.readyForPickup => OrderStatus.pickedUp,
      OrderStatus.pickedUp => OrderStatus.pickedUp,
    };
    orders[idx] = FoodOrder(
      id: current.id,
      restaurantId: current.restaurantId,
      restaurantName: current.restaurantName,
      restaurantImageUrl: current.restaurantImageUrl,
      items: current.items,
      itemTotal: current.itemTotal,
      taxes: current.taxes,
      platformFee: current.platformFee,
      grandTotal: current.grandTotal,
      pickupPoint: current.pickupPoint,
      status: next,
      placedAt: current.placedAt,
      etaMins: next == OrderStatus.pickedUp ? 0 : current.etaMins,
    );
  }

  void reorder(FoodOrder order) {
    final restaurant = FoodDummyData.byId(order.restaurantId);
    if (restaurant == null) return;
    final cart = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);
    cart.clear();
    cart.restaurant.value = restaurant;
    for (final item in order.items) {
      cart.items.add(CartItem(menuItem: item.menuItem, quantity: item.quantity));
    }
    cart.pickupPoint.value = order.pickupPoint;
  }

  Restaurant? restaurantFor(FoodOrder order) => FoodDummyData.byId(order.restaurantId);
}
