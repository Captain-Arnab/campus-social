import 'package:get/get.dart';

import '../data/dummy_data.dart';
import '../models/restaurant.dart';

enum FoodSortBy {
  relevance,
  rating,
  pickupTime,
  costLowHigh,
  costHighLow,
}

class FoodFilterState {
  FoodSortBy sortBy;
  bool veg;
  bool nonVeg;
  bool pureVeg;
  bool fastPickup;
  bool offers;
  bool rating4Plus;
  double priceMin;
  double priceMax;

  FoodFilterState({
    this.sortBy = FoodSortBy.relevance,
    this.veg = false,
    this.nonVeg = false,
    this.pureVeg = false,
    this.fastPickup = false,
    this.offers = false,
    this.rating4Plus = false,
    this.priceMin = 0,
    this.priceMax = 500,
  });

  FoodFilterState copy() => FoodFilterState(
        sortBy: sortBy,
        veg: veg,
        nonVeg: nonVeg,
        pureVeg: pureVeg,
        fastPickup: fastPickup,
        offers: offers,
        rating4Plus: rating4Plus,
        priceMin: priceMin,
        priceMax: priceMax,
      );

  bool get hasActiveFilters =>
      sortBy != FoodSortBy.relevance ||
      veg ||
      nonVeg ||
      pureVeg ||
      fastPickup ||
      offers ||
      rating4Plus ||
      priceMin > 0 ||
      priceMax < 500;

  void clear() {
    sortBy = FoodSortBy.relevance;
    veg = false;
    nonVeg = false;
    pureVeg = false;
    fastPickup = false;
    offers = false;
    rating4Plus = false;
    priceMin = 0;
    priceMax = 500;
  }
}

class FoodHomeController extends GetxController {
  final searchQuery = ''.obs;
  final selectedCuisine = 'all'.obs;
  final filter = FoodFilterState().obs;
  final restaurants = <Restaurant>[].obs;

  @override
  void onInit() {
    super.onInit();
    applyFilters();
  }

  void setSearch(String q) {
    searchQuery.value = q.trim();
    applyFilters();
  }

  void setCuisine(String id) {
    selectedCuisine.value = id;
    applyFilters();
  }

  void applyFilterState(FoodFilterState next) {
    filter.value = next;
    filter.refresh();
    applyFilters();
  }

  void clearFilters() {
    filter.value.clear();
    filter.refresh();
    applyFilters();
  }

  int previewResultCount(FoodFilterState draft) {
    return _filterList(draft, searchQuery.value, selectedCuisine.value).length;
  }

  void applyFilters() {
    restaurants.assignAll(
      _filterList(filter.value, searchQuery.value, selectedCuisine.value),
    );
  }

  List<Restaurant> _filterList(
    FoodFilterState f,
    String query,
    String cuisineId,
  ) {
    var list = List<Restaurant>.from(FoodDummyData.restaurants);

    if (cuisineId != 'all') {
      final cat = FoodDummyData.categories
          .firstWhere((c) => c.id == cuisineId, orElse: () => FoodDummyData.categories.first);
      final name = cat.name.toLowerCase();
      list = list.where((r) {
        return r.cuisines.any((c) => c.toLowerCase().contains(name.split(' ').first));
      }).toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((r) {
        return r.name.toLowerCase().contains(q) ||
            r.cuisines.any((c) => c.toLowerCase().contains(q));
      }).toList();
    }

    if (f.pureVeg) {
      list = list.where((r) => r.isVegOnly).toList();
    } else {
      if (f.veg && !f.nonVeg) {
        list = list.where((r) => r.menu.any((m) => m.isVeg)).toList();
      }
      if (f.nonVeg && !f.veg) {
        list = list.where((r) => r.hasNonVeg).toList();
      }
    }

    if (f.fastPickup) {
      list = list.where((r) => r.isFastPickup).toList();
    }
    if (f.offers) {
      list = list.where((r) => r.hasOffer).toList();
    }
    if (f.rating4Plus) {
      list = list.where((r) => r.rating >= 4.0).toList();
    }

    list = list
        .where((r) => r.costForTwo >= f.priceMin && r.costForTwo <= f.priceMax)
        .toList();

    switch (f.sortBy) {
      case FoodSortBy.relevance:
        break;
      case FoodSortBy.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case FoodSortBy.pickupTime:
        list.sort((a, b) => a.pickupMins.compareTo(b.pickupMins));
        break;
      case FoodSortBy.costLowHigh:
        list.sort((a, b) => a.costForTwo.compareTo(b.costForTwo));
        break;
      case FoodSortBy.costHighLow:
        list.sort((a, b) => b.costForTwo.compareTo(a.costForTwo));
        break;
    }

    return list;
  }
}
