import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Formatlayıcılar için eklendi
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- KREDİ KARTI FORMATLAYICILARI ---
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
// ------------------------------------

class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({super.key});

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final response = await Supabase.instance.client
          .from('saved_cards')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _cards = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kartlar yüklenemedi.')));
      }
    }
  }

  Future<void> _deleteCard(String id) async {
    try {
      await Supabase.instance.client.from('saved_cards').delete().eq('id', id);
      _fetchCards();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kart başarıyla silindi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silme işlemi başarısız oldu.')),
        );
      }
    }
  }

  void _showAddCardModal() {
    final titleController = TextEditingController();
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final dateController = TextEditingController();
    final cvvController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                      'Yeni Kart Ekle',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kart bilgileriniz şifrelenerek saklanır. Güvenliğiniz için CVV numarası kaydedilmez.',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: titleController,
                  decoration: _inputDec('Kart Başlığı (Örn: İş Bankası)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: _inputDec('Kart Üzerindeki İsim'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    CardNumberFormatter(),
                  ],
                  decoration: _inputDec('Kart Numarası')
                      .copyWith(prefixIcon: const Icon(Icons.credit_card)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          ExpiryDateFormatter(),
                        ],
                        decoration: _inputDec('AA/YY'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: cvvController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        obscureText: true,
                        decoration: _inputDec('CVV').copyWith(
                          suffixIcon: Tooltip(
                            message: 'Kart arkasındaki 3 hane',
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Formatlanmış metni doğrula (16 rakam + 3 boşluk = 19 karakter)
                      if (numberController.text.length < 19 ||
                          dateController.text.length < 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lütfen geçerli kart bilgileri giriniz',
                            ),
                          ),
                        );
                        return;
                      }

                      final userId =
                          Supabase.instance.client.auth.currentUser!.id;
                      final last4 = numberController.text.substring(15); // Son 4 hane artık 15. indexten başlıyor (boşluklar yüzünden)
                      final mockToken =
                          'tok_${DateTime.now().millisecondsSinceEpoch}';

                      try {
                        await Supabase.instance.client
                            .from('saved_cards')
                            .insert({
                              'user_id': userId,
                              'card_title': titleController.text.isEmpty
                                  ? 'Yeni Kart'
                                  : titleController.text,
                              'card_holder_name': nameController.text,
                              'last_four_digits': last4,
                              'expire_date': dateController.text,
                              'mock_token': mockToken,
                            });

                        if (mounted) {
                          Navigator.pop(context);
                          _fetchCards();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Kart kaydedilirken bir hata oluştu.',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kartı Güvenle Kaydet',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F3F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Kayıtlı Kartlarım',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _cards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz kayıtlı kartınız bulunmuyor.',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearBinding(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                      ).gradient,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              card['card_title'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white54,
                                size: 20,
                              ),
                              onPressed: () => _deleteCard(card['id']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '**** **** **** ${card['last_four_digits']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 2,
                            fontFamily: 'Courier',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              card['card_holder_name'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              card['expire_date'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardModal,
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Kart Ekle',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class LinearBinding {
  final Alignment begin;
  final Alignment end;
  final List<Color> colors;
  const LinearBinding({
    required this.begin,
    required this.end,
    required this.colors,
  });
  LinearGradient get gradient =>
      LinearGradient(begin: begin, end: end, colors: colors);
}
