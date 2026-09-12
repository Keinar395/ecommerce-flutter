import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/cart_service.dart';
import 'home_screen.dart';
import 'payment_3d_screen.dart';

// --- KREDİ KARTI FORMATLAYICILARI (MASKING) ---
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\s+\b|\b\s'), '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != newText.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// --- ÖDEME EKRANI ---
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Adres Controller'ları
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressController = TextEditingController();

  // Kredi Kartı Controller'ları
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isLoading = false;

  // Adres Değişkenleri
  List<Map<String, dynamic>> _savedAddresses = [];
  Map<String, dynamic>? _selectedAddress;

  // --- YENİ EKLENEN: Kayıtlı Kart Değişkenleri ---
  List<Map<String, dynamic>> _savedCards = [];
  Map<String, dynamic>? _selectedCard;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    _loadSavedCards(); // Sayfa açılırken kartları da çek
  }

  Future<void> _loadSavedAddresses() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('user_addresses')
          .select()
          .eq('user_id', userId);

      if (mounted) {
        setState(() {
          _savedAddresses = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Adresler çekilemedi: $e');
    }
  }

  // --- YENİ EKLENEN: Supabase'den Kayıtlı Kartları çeken fonksiyon ---
  Future<void> _loadSavedCards() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('saved_cards')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _savedCards = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Kayıtlı kartlar çekilemedi: $e');
    }
  }
  // -------------------------------------------------------------

  Future<void> _completeOrder() async {
    if (_cityController.text.isEmpty ||
        _districtController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen teslimat adresini tam girin.')),
      );
      return;
    }

    if (_cardNumberController.text.length < 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kredi kartı numarası eksik.')),
      );
      return;
    }

    if (_expiryController.text.length < 5 || _cvvController.text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SKT veya CVV eksik/hatalı.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final cartItems = CartService().items;
      final totalPrice = CartService().totalPrice;

      final fullAddress =
          '${_addressController.text}, ${_districtController.text} / ${_cityController.text}';

      // 3D SECURE SİMÜLASYONU
      await Future.delayed(const Duration(seconds: 2));

      final Map<String, dynamic> mockApiResponse = {
        'status': 'success',
        'htmlContent': '''
          <html>
            <body style="display:flex; justify-content:center; align-items:center; height:100vh; font-family:sans-serif;">
              <div style="text-align:center;">
                <h2>Zuhal Müzik 3D Güvenli Ödeme</h2>
                <p>Lütfen bankanızdan telefonunuza gelen şifreyi giriniz.</p>
                <button onclick="window.location.href='https://zuhalmuzik.com/api/payment/callback'" style="padding:10px 20px; font-size:16px; background-color:black; color:white; border:none; border-radius:8px;">Şifreyi Onayla</button>
              </div>
            </body>
          </html>
        ''',
      };

      if (mockApiResponse['status'] == 'success') {
        if (!mounted) return;

        final bool? isCompleted = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Payment3DScreen(htmlContent: mockApiResponse['htmlContent']),
          ),
        );

        if (isCompleted == true) {
          final orderResponse = await Supabase.instance.client
              .from('orders')
              .insert({
                'user_id': user!.id,
                'delivery_address': fullAddress,
                'total_price': totalPrice,
              })
              .select()
              .single();

          final orderId = orderResponse['id'];

          final List<Map<String, dynamic>> orderItemsData = cartItems.map((
            item,
          ) {
            return {
              'order_id': orderId,
              'product_id': item.product['id'],
              'quantity': item.quantity,
              'price_at_purchase': item.product['price'],
            };
          }).toList();

          await Supabase.instance.client
              .from('order_items')
              .insert(orderItemsData);

          if (mounted) {
            CartService().clearCart();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Ödeme onaylandı, siparişiniz başarıyla alındı!',
                ),
                backgroundColor: Colors.green[700],
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ödeme işlemi iptal edildi.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sipariş oluşturulamadı: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Güvenli Ödeme',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ADRES BÖLÜMÜ
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Teslimat Adresi',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  if (_savedAddresses.isNotEmpty) ...[
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: _inputStyle('Kayıtlı Adreslerimden Seç'),
                      initialValue: _selectedAddress,
                      items: _savedAddresses.map((address) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: address,
                          child: Text(
                            address['address_title'] ?? 'Kayıtlı Adres',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedAddress = value;
                            _cityController.text = value['city'] ?? '';
                            _districtController.text = value['district'] ?? '';
                            _addressController.text =
                                value['full_address'] ?? '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'veya yeni girin',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: _inputStyle('İl (Örn: İstanbul)'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _districtController,
                          decoration: _inputStyle('İlçe (Örn: Kadıköy)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: _inputStyle('Mahalle, Sokak, Apartman No...'),
                  ),
                ],
              ),
            ),

            // KREDİ KARTI BÖLÜMÜ
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.credit_card, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            'Ödeme Bilgileri',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.lock_outline,
                        color: Colors.green[700],
                        size: 20,
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // --- YENİ EKLENEN: Kayıtlı Kart Dropdown Menüsü ---
                  if (_savedCards.isNotEmpty) ...[
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: _inputStyle('Kayıtlı Kartlarımdan Seç'),
                      initialValue: _selectedCard,
                      items: _savedCards.map((card) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: card,
                          child: Text(
                            '${card['card_title']} (**** ${card['last_four_digits']})',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCard = value;
                            _cardNameController.text =
                                value['card_holder_name'] ?? '';
                            // Gerçek numara olmadığı için maskelenmiş gösteriyoruz (Yıldızlar + Son 4 hane)
                            _cardNumberController.text =
                                '**** **** **** ${value['last_four_digits']}';
                            _expiryController.text = value['expire_date'] ?? '';
                            // Güvenlik gereği CVV asla doldurulmaz, kullanıcıdan istenir
                            _cvvController.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'veya yeni kart girin',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // -------------------------------------------------------------

                  TextField(
                    controller: _cardNameController,
                    decoration: _inputStyle('Kart Üzerindeki İsim'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardNumberController,
                    // Eğer kullanıcı kayıtlı kart seçtiyse, yıldızlı numarayı silip kendi girmesi için yardımcı ol
                    onTap: () {
                      if (_cardNumberController.text.startsWith('****')) {
                        _cardNumberController.clear();
                        setState(() {
                          _selectedCard = null;
                        });
                      }
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      // Eğer kayıtlı kart seçiliyse (içinde yıldız varsa) sadece rakam filtresini geçici olarak kaldır
                      if (!_cardNumberController.text.startsWith('****'))
                        FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        19,
                      ), // 16 rakam + 3 boşluk
                      if (!_cardNumberController.text.startsWith('****'))
                        CardNumberFormatter(),
                    ],
                    decoration: _inputStyle('Kart Numarası')
                        .copyWith(prefixIcon: const Icon(Icons.credit_card)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            ExpiryDateFormatter(),
                          ],
                          decoration: _inputStyle('SKT (AA/YY)'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          obscureText: true,
                          decoration: _inputStyle('CVV').copyWith(
                            // Kullanıcıya CVV'yi hatırlatmak için küçük ikon
                            suffixIcon: Tooltip(
                              message: 'Kartınızın arkasındaki 3 haneli güvenlik kodu',
                              child: Icon(
                                Icons.help_outline,
                                color: Colors.grey[400],
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      // ALT BAR
      bottomNavigationBar: Container(
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
                    'Ödenecek Tutar',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${CartService().totalPrice.toStringAsFixed(2)} ₺',
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _completeOrder,
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
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Ödemeyi Tamamla',
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
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
