import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'checkout_screen.dart';
import '../services/cart_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CartService(),
      builder: (context, child) {
        final cartItems = CartService().items;

        // İKİ FİYATI DA ÇEKİYORUZ
        final totalPrice = CartService().totalPrice;
        final originalTotalPrice = CartService().originalTotalPrice;

        // EĞER ORİJİNAL FİYAT, İNDİRİMLİ FİYATTAN BÜYÜKSE SEPETTE İNDİRİM VAR DEMEKTİR
        final bool hasCartDiscount = originalTotalPrice > totalPrice;

        if (cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Sepetiniz şu an boş',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final product = item.product;

                  final originalPriceRaw = product['price'];
                  final originalPrice = originalPriceRaw != null
                      ? (originalPriceRaw as num).toDouble()
                      : 0.0;

                  final discountPriceRaw = product['discount_price'];
                  bool hasDiscount = false;
                  double discountPrice = 0.0;

                  if (discountPriceRaw != null) {
                    discountPrice = (discountPriceRaw as num).toDouble();
                    if (discountPrice > 0 && discountPrice < originalPrice) {
                      hasDiscount = true;
                    }
                  }

                  String imageUrl = 'https://via.placeholder.com/60';
                  if (product['image_url'] != null &&
                      product['image_url'].toString().isNotEmpty) {
                    imageUrl = product['image_url'].toString();
                  } else if (product['image_urls'] != null) {
                    final urls = product['image_urls'] as List;
                    if (urls.isNotEmpty &&
                        urls.first != null &&
                        urls.first.toString().isNotEmpty) {
                      imageUrl = urls.first.toString();
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[100],
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.grey,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name']?.toString() ?? 'İsimsiz Ürün',
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),

                                if (hasDiscount)
                                  Row(
                                    children: [
                                      Text(
                                        '${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)} ₺',
                                        style: GoogleFonts.lato(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[500],
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${discountPrice.toStringAsFixed(discountPrice.truncateToDouble() == discountPrice ? 0 : 2)} ₺',
                                        style: GoogleFonts.lato(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    '${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)} ₺',
                                    style: GoogleFonts.lato(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => CartService()
                                    .decrementQuantity(product['id']),
                              ),
                              Text(
                                '${item.quantity}',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () =>
                                    CartService().addToCart(product),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Toplam Tutar',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        // --- YENİ EKLENEN: TOPLAM TUTARDA ÜSTÜ ÇİZİLİ FİYAT ---
                        if (hasCartDiscount)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${originalTotalPrice.toStringAsFixed(originalTotalPrice.truncateToDouble() == originalTotalPrice ? 0 : 2)} ₺',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${totalPrice.toStringAsFixed(totalPrice.truncateToDouble() == totalPrice ? 0 : 2)} ₺',
                                style: GoogleFonts.lato(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '${totalPrice.toStringAsFixed(totalPrice.truncateToDouble() == totalPrice ? 0 : 2)} ₺',
                            style: GoogleFonts.lato(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (cartItems.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckoutScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Onayla',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
