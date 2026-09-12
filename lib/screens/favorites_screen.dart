import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Future<List<Map<String, dynamic>>> _fetchFavorites() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final response = await Supabase.instance.client
        .from('favorites')
        .select('id, products(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _removeFavorite(String favoriteId) async {
    await Supabase.instance.client
        .from('favorites')
        .delete()
        .eq('id', favoriteId);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün favorilerden çıkarıldı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Favorilerim',
            style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchFavorites(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                );
              }

              final favorites = snapshot.data;
              if (favorites == null || favorites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Favori listeniz henüz boş.',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final favoriteRow = favorites[index];
                  final product =
                      favoriteRow['products'] as Map<String, dynamic>;
                  final favoriteId = favoriteRow['id'];

                  // --- İNDİRİM MATEMATİĞİ ---
                  final originalPriceRaw = product['price'];
                  final originalPrice = originalPriceRaw != null
                      ? (originalPriceRaw as num).toDouble()
                      : 0.0;

                  final discountPriceRaw = product['discount_price'];
                  bool hasDiscount = false;
                  double discountPrice = 0.0;
                  int discountPercentage = 0;

                  if (discountPriceRaw != null) {
                    discountPrice = (discountPriceRaw as num).toDouble();
                    if (discountPrice > 0 && discountPrice < originalPrice) {
                      hasDiscount = true;
                      discountPercentage =
                          (((originalPrice - discountPrice) / originalPrice) *
                                  100)
                              .round();
                    }
                  }

                  // --- GÜVENLİ RESİM ÇEKİMİ ---
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
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
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
                            // KÜÇÜK İNDİRİM ROZETİ (Resmin sol üstüne)
                            if (hasDiscount)
                              Positioned(
                                top: 0,
                                left: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[700],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    '%$discountPercentage',
                                    style: GoogleFonts.lato(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      title: Text(
                        product['name']?.toString() ?? 'İsimsiz Ürün',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // FİYAT KISMI (Eski ve Yeni Fiyat)
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 4),
                          if (hasDiscount)
                            Text(
                              '${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)} ₺',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            hasDiscount
                                ? '${discountPrice.toStringAsFixed(discountPrice.truncateToDouble() == discountPrice ? 0 : 2)} ₺'
                                : '${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)} ₺',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: hasDiscount
                                  ? Colors.red[700]
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => _removeFavorite(favoriteId),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(product: product),
                          ),
                        ).then((_) {
                          // Detaydan dönünce favori listesini yenile
                          setState(() {});
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
