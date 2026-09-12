import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:async';

import '../services/cart_service.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Timer? _debounce;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  Set<String> _favoriteProductIds = {};
  List<String> _availableBrands = [];

  // Filtre/Sıralama State'leri
  String _selectedSort = 'created_at_desc';
  String? _selectedBrand;
  bool _onlyInStock = false;
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _loadFavoriteIds();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    try {
      final response = await Supabase.instance.client
          .from('brands')
          .select('name')
          .order('name', ascending: true);
      if (mounted) {
        setState(
          () =>
              _availableBrands = List<Map<String, dynamic>>.from(response)
                  .map((e) => e['name'] as String)
                  .toList(),
        );
      }
    } catch (e) {
      debugPrint('Markalar çekilirken hata: $e');
    }
  }

  Future<void> _loadFavoriteIds() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('favorites')
          .select('product_id')
          .eq('user_id', userId);
      if (mounted) {
        setState(
          () => _favoriteProductIds = response
              .map<String>((row) => row['product_id'] as String)
              .toSet(),
        );
      }
    } catch (e) {}
  }

  Future<List<Map<String, dynamic>>> _fetchSearchResults() async {
    if (_searchQuery.isEmpty) return [];

    var filterQuery = Supabase.instance.client.rpc(
      'search_products',
      params: {'search_term': _searchQuery},
    );

    if (_selectedBrand != null) {
      filterQuery = filterQuery.eq('brand', _selectedBrand!);
    }
    if (_onlyInStock) {
      filterQuery = filterQuery.gt('stock_quantity', 0);
    }
    if (_minPrice != null) {
      filterQuery = filterQuery.gte('price', _minPrice!);
    }
    if (_maxPrice != null) {
      filterQuery = filterQuery.lte('price', _maxPrice!);
    }

    if (_selectedSort == 'price_asc') {
      final response = await filterQuery.order('price', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } else if (_selectedSort == 'price_desc') {
      final response = await filterQuery.order('price', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } else if (_selectedSort == 'name_asc') {
      final response = await filterQuery.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } else {
      final response = await filterQuery;
      return List<Map<String, dynamic>>.from(response);
    }
  }

  Future<void> _toggleFavorite(String productId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final isAlreadyFavorite = _favoriteProductIds.contains(productId);
    setState(
      () => isAlreadyFavorite
          ? _favoriteProductIds.remove(productId)
          : _favoriteProductIds.add(productId),
    );
    try {
      if (isAlreadyFavorite) {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
      } else {
        await Supabase.instance.client.from('favorites').insert({
          'user_id': userId,
          'product_id': productId,
        });
      }
    } catch (e) {
      setState(
        () => isAlreadyFavorite
            ? _favoriteProductIds.add(productId)
            : _favoriteProductIds.remove(productId),
      );
    }
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sıralama',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption('En Yeniler', 'created_at_desc'),
              _buildSortOption('En Düşük Fiyat', 'price_asc'),
              _buildSortOption('En Yüksek Fiyat', 'price_desc'),
              _buildSortOption('Ürün Adı (A-Z)', 'name_asc'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, String value) {
    final isSelected = _selectedSort == value;
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.lato(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.black)
          : null,
      onTap: () {
        setState(() => _selectedSort = value);
        Navigator.pop(context);
      },
    );
  }

  void _showFilterModal() {
    String? tempBrand = _selectedBrand;
    bool tempInStock = _onlyInStock;
    final minController = TextEditingController(
      text: _minPrice?.toInt().toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _maxPrice?.toInt().toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtrele',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setModalState(() {
                            tempBrand = null;
                            tempInStock = false;
                            minController.clear();
                            maxController.clear();
                          }),
                          child: const Text(
                            'Temizle',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Marka',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableBrands.map((brand) {
                        final isSelected = tempBrand == brand;
                        return ChoiceChip(
                          label: Text(brand),
                          selected: isSelected,
                          selectedColor: Colors.black,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          onSelected: (selected) => setModalState(
                            () => tempBrand = selected ? brand : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Fiyat Aralığı (₺)',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Min ₺',
                              filled: true,
                              fillColor: Color(0xFFF1F3F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('-'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Max ₺',
                              filled: true,
                              fillColor: Color(0xFFF1F3F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Sadece Stoktakiler',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: tempInStock,
                      activeThumbColor: Colors.black,
                      onChanged: (val) =>
                          setModalState(() => tempInStock = val),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedBrand = tempBrand;
                            _onlyInStock = tempInStock;
                            _minPrice = double.tryParse(minController.text);
                            _maxPrice = double.tryParse(maxController.text);
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Uygula',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilter =
        _selectedBrand != null ||
        _onlyInStock ||
        _minPrice != null ||
        _maxPrice != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ürün ara...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              setState(() {
                _searchQuery = value.trim();
              });
            });
          },
          textInputAction: TextInputAction.search,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showSortModal,
                      icon: const Icon(
                        Icons.sort,
                        size: 18,
                        color: Colors.black,
                      ),
                      label: Text(
                        'Sırala',
                        style: GoogleFonts.lato(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showFilterModal,
                      icon: Icon(
                        Icons.filter_list,
                        size: 18,
                        color: hasActiveFilter
                            ? Colors.blue[700]
                            : Colors.black,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Filtrele',
                            style: GoogleFonts.lato(
                              color: hasActiveFilter
                                  ? Colors.blue[700]
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasActiveFilter) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: hasActiveFilter
                              ? Colors.blue[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Ne aramıştınız?',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchSearchResults(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.black),
                        );
                      }
                      final products = snapshot.data;
                      if (products == null || products.isEmpty) {
                        return Center(
                          child: Text(
                            'Aramanıza uygun ürün bulunamadı.',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.65, // <-- BOYUT UZATILDI
                            ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final isFavorite = _favoriteProductIds.contains(
                            product['id'],
                          );

                          // --- YENİ EKLENEN: İNDİRİM MATEMATİĞİ ---
                          final originalPriceRaw = product['price'];
                          final originalPrice = originalPriceRaw != null
                              ? (originalPriceRaw as num).toDouble()
                              : 0.0;

                          final discountPriceRaw = product['discount_price'];
                          bool hasDiscount = false;
                          double discountPrice = 0.0;
                          int discountPercentage = 0;

                          if (discountPriceRaw != null) {
                            discountPrice = (discountPriceRaw as num)
                                .toDouble();
                            if (discountPrice > 0 &&
                                discountPrice < originalPrice) {
                              hasDiscount = true;
                              discountPercentage =
                                  (((originalPrice - discountPrice) /
                                              originalPrice) *
                                          100)
                                      .round();
                            }
                          }

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailScreen(product: product),
                              ),
                            ).then((_) => _loadFavoriteIds()),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                        child: SizedBox(
                                          height: 130,
                                          width: double.infinity,
                                          child: Image.network(
                                            product['image_url'] ?? '',
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                                  color: Colors.grey[100],
                                                  child: const Icon(
                                                    Icons.music_note,
                                                    color: Colors.grey,
                                                    size: 40,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      // YENİ EKLENEN: Kırmızı Rozet
                                      if (hasDiscount)
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red[700],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '%$discountPercentage',
                                              style: GoogleFonts.lato(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            iconSize: 20,
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFavorite
                                                  ? Colors.red
                                                  : Colors.grey[400],
                                            ),
                                            onPressed: () =>
                                                _toggleFavorite(product['id']),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            product['name'],
                                            style: GoogleFonts.lato(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // YENİ EKLENEN: Fiyat Sütunu
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (hasDiscount)
                                                      Text(
                                                        '${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)} ₺',
                                                        style: GoogleFonts.lato(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[500],
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    Text(
                                                      hasDiscount
                                                          ? '${discountPrice.toStringAsFixed(discountPrice.truncateToDouble() == discountPrice ? 0 : 2)} ₺'
                                                          : '${originalPrice.toStringAsFixed(originalPrice.truncateToDouble() == originalPrice ? 0 : 2)} ₺',
                                                      style: GoogleFonts.lato(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color: hasDiscount
                                                            ? Colors.red[700]
                                                            : Colors.black,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  CartService().addToCart(
                                                    product,
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '${product['name']} sepete eklendi!',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green[700],
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.add_shopping_cart,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
