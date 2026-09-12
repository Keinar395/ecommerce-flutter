import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/cart_service.dart';
import 'home_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  String? _favoriteId;

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', widget.product['id'])
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (response != null) {
            _isFavorite = true;
            _favoriteId = response['id'];
          }
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoadingFavorite = true);

    try {
      if (_isFavorite && _favoriteId != null) {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('id', _favoriteId!);
        if (mounted) {
          setState(() {
            _isFavorite = false;
            _favoriteId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorilerden çıkarıldı')),
          );
        }
      } else {
        final response = await Supabase.instance.client
            .from('favorites')
            .insert({'user_id': userId, 'product_id': widget.product['id']})
            .select('id')
            .single();

        if (mounted) {
          setState(() {
            _isFavorite = true;
            _favoriteId = response['id'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favorilere eklendi!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Bir hata oluştu')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    // --- GÜVENLİ STOK PARÇALAMA ---
    int stockQuantity = 0;
    if (product['stock_quantity'] != null) {
      stockQuantity = int.tryParse(product['stock_quantity'].toString()) ?? 0;
    }
    final bool inStock = stockQuantity > 0;

    // --- YENİ: İNDİRİM VE FİYAT MATEMATİĞİ ---
    double originalPrice = double.tryParse(product['price'].toString()) ?? 0.0;
    double? discountPrice = product['discount_price'] != null
        ? double.tryParse(product['discount_price'].toString())
        : null;

    // Eğer indirimli fiyat var ve normal fiyattan küçükse indirim geçerlidir
    bool hasDiscount =
        discountPrice != null &&
        discountPrice > 0 &&
        discountPrice < originalPrice;

    // İndirim yüzdesini hesapla (Örn: 1000₺'lik ürün 800₺ ise %20 indirim)
    int discountPercentage = 0;
    if (hasDiscount) {
      discountPercentage =
          (((originalPrice - discountPrice) / originalPrice) * 100).round();
    }

    // --- GÜVENLİ RESİM DİZİSİ ---
    List<String> images = [];
    if (product['image_urls'] != null) {
      try {
        final urls = product['image_urls'] as List;
        for (var url in urls) {
          if (url != null && url.toString().isNotEmpty) {
            images.add(url.toString());
          }
        }
      } catch (e) {
        debugPrint("Resim dizisi okunamadı: $e");
      }
    }

    if (images.isEmpty &&
        product['image_url'] != null &&
        product['image_url'].toString().isNotEmpty) {
      images.add(product['image_url'].toString());
    }

    if (images.isEmpty) {
      images.add('https://via.placeholder.com/300');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Ürün Detayı',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          _isLoadingFavorite
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.black,
                  ),
                  onPressed: _toggleFavorite,
                ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () =>
                                      _showFullScreenImage(images[index]),
                                  child: Image.network(
                                    images[index],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: const Color(0xFFF8F9FA),
                                              child: const Icon(
                                                Icons.music_note,
                                                size: 120,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // YENİ EKLENEN: Kırmızı İndirim Rozeti (Eğer indirim varsa sol üste çizilir)
                        if (hasDiscount)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[700],
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '%$discountPercentage İNDİRİM',
                                style: GoogleFonts.lato(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (images.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              width: _currentImageIndex == index ? 24.0 : 8.0,
                              height: 8.0,
                              decoration: BoxDecoration(
                                color: _currentImageIndex == index
                                    ? Colors.black
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // YENİ EKLENEN: Başlık ve Dinamik İndirimli Fiyat Alanı
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product['name'] ?? 'İsimsiz Ürün',
                            style: GoogleFonts.lato(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (hasDiscount)
                              Text(
                                '${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)} ₺',
                                style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              hasDiscount
                                  ? '${discountPrice.toStringAsFixed(discountPrice.truncateToDouble() == discountPrice ? 0 : 2)} ₺'
                                  : '${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)} ₺',
                              style: GoogleFonts.lato(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: hasDiscount
                                    ? Colors.red[700]
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: inStock ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        inStock
                            ? 'Stokta var ($stockQuantity adet)'
                            : 'Tükendi',
                        style: GoogleFonts.lato(
                          color: inStock ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Ürün Açıklaması',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      product['description'] ??
                          'Bu ürün için henüz bir açıklama girilmemiş.',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(24.0),
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
              child: ElevatedButton(
                onPressed: inStock
                    ? () {
                        CartService().addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product['name']} sepete eklendi!'),
                            backgroundColor: Colors.green[700],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            action: SnackBarAction(
                              label: 'Sepete Git',
                              textColor: Colors.white,
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const HomeScreen(initialIndex: 2),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                ),
                child: Text(
                  inStock ? 'Sepete Ekle' : 'Stokta Yok',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
