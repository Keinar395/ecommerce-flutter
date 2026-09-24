import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'brand_products_screen.dart';
import 'cart_screen.dart';
import 'account_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import 'products_screen.dart';
import 'campaign_products_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  List<Map<String, dynamic>> _popularBrands = [];
  bool _isLoadingBrands = true;

  List<Map<String, dynamic>> _campaigns = [];
  bool _isLoadingCampaigns = true;

  final Color _cangozOrange = const Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchCategories(),
      _fetchPopularBrands(),
      _fetchCampaigns(),
    ]);

    if (_categories.isEmpty || _campaigns.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _fetchCategories();
        _fetchPopularBrands();
        _fetchCampaigns();
      }
    }
  }

  Future<void> _fetchCampaigns() async {
    try {
      final response = await Supabase.instance.client
          .from('campaigns')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _campaigns = List<Map<String, dynamic>>.from(response);
          _isLoadingCampaigns = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCampaigns = false);
    }
  }

  Future<void> _fetchPopularBrands() async {
    try {
      final response = await Supabase.instance.client
          .from('brands')
          .select()
          .eq('is_popular', true)
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _popularBrands = List<Map<String, dynamic>>.from(response);
          _isLoadingBrands = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBrands = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select();
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response);
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      color: _cangozOrange,
      onRefresh: () async {
        setState(() {
          _isLoadingCampaigns = true;
          _isLoadingBrands = true;
          _isLoadingCategories = true;
        });
        await Future.wait([
          _fetchCampaigns(),
          _fetchPopularBrands(),
          _fetchCategories(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: TextField(
                readOnly: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                ),
                decoration: InputDecoration(
                  hintText: 'Gitar, piyano, marka ara...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: _cangozOrange),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            _isLoadingCampaigns
                ? SizedBox(
                    height: 140,
                    child: Center(
                      child: CircularProgressIndicator(color: _cangozOrange),
                    ),
                  )
                : _campaigns.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _campaigns.length,
                      itemBuilder: (context, index) {
                        final campaign = _campaigns[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildPromoCard(campaign),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Popüler Markalar',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isLoadingBrands
                ? Center(child: CircularProgressIndicator(color: _cangozOrange))
                : SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _popularBrands.length,
                      itemBuilder: (context, index) {
                        final brand = _popularBrands[index];
                        final brandName = brand['name'];
                        final brandLogo = brand['logo'] ?? '🎸';
                        final brandImageUrl = brand['image_url'];

                        return Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BrandProductsScreen(brandName: brandName),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child:
                                        brandImageUrl != null &&
                                            brandImageUrl.toString().isNotEmpty
                                        ? ClipOval(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                10.0,
                                              ),
                                              child: Image.network(
                                                brandImageUrl,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Text(
                                                      brandLogo,
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            brandLogo,
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  brandName,
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Kategoriler',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isLoadingCategories
                ? Center(child: CircularProgressIndicator(color: _cangozOrange))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.5,
                        ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductsScreen(
                              categoryId: category['id'],
                              categoryName: category['name'],
                            ),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _cangozOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              category['name'],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> campaign) {
    final title = campaign['title'] ?? '';
    final subtitle = campaign['subtitle'] ?? '';
    final imageUrl = campaign['image_url'];

    String hexString = campaign['color_hex'] ?? '0xFFE65100';
    Color bgColor = _cangozOrange;
    try {
      bgColor = Color(int.parse(hexString));
    } catch (e) {
      bgColor = _cangozOrange;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampaignProductsScreen(
              campaignId: campaign['id'],
              campaignTitle: title,
            ),
          ),
        );
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          image: imageUrl != null && imageUrl.toString().isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.4),
                    BlendMode.darken,
                  ),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      const FavoritesScreen(),
      const CartScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'Cangöz Müzik',
                style: GoogleFonts.lato(
                  color: _cangozOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              centerTitle: false,
            )
          : null,
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: _cangozOrange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Sepet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hesabım',
          ),
        ],
      ),
    );
  }
}
