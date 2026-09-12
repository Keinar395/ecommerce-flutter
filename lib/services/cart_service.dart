import 'package:flutter/material.dart';

class CartItem {
  final Map<String, dynamic> product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addToCart(Map<String, dynamic> product) {
    final index = _items.indexWhere(
      (item) => item.product['id'] == product['id'],
    );

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }

    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product['id'] == productId);
    notifyListeners();
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product['id'] == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // YENİ EKLENEN: İndirimsiz (Orijinal) Toplam Tutar Hesaplama
  double get originalTotalPrice {
    return _items.fold(0, (sum, item) {
      final originalPrice = (item.product['price'] as num).toDouble();
      return sum + (originalPrice * item.quantity);
    });
  }

  // İndirimli Toplam Tutar Hesaplama
  double get totalPrice {
    return _items.fold(0, (sum, item) {
      final originalPrice = (item.product['price'] as num).toDouble();
      final discountPriceRaw = item.product['discount_price'];

      double activePrice = originalPrice;

      if (discountPriceRaw != null) {
        final dp = (discountPriceRaw as num).toDouble();
        if (dp > 0 && dp < originalPrice) {
          activePrice = dp;
        }
      }

      return sum + (activePrice * item.quantity);
    });
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
