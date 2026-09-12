import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  // Adresleri çeken fonksiyon
  Future<List<Map<String, dynamic>>> _fetchAddresses() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return await Supabase.instance.client
        .from('user_addresses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  // Yeni Adres Ekleme Formunu (Bottom Sheet) Açan Fonksiyon
  void _showAddAddressModal() {
    final titleController = TextEditingController();
    final cityController = TextEditingController();
    final districtController = TextEditingController();
    final fullAddressController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavyenin üstüne çıkabilmesi için
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // Klavye açılınca yukarı kayar
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yeni Adres Ekle',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: _inputStyle(
                      'Adres Başlığı (Örn: Evim, İş Yerim)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: _inputStyle('İl'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: districtController,
                          decoration: _inputStyle('İlçe'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fullAddressController,
                    maxLines: 3,
                    decoration: _inputStyle('Açık Adres'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (titleController.text.isEmpty ||
                                  cityController.text.isEmpty ||
                                  fullAddressController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lütfen alanları doldurun.'),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSaving = true);
                              try {
                                final userId = Supabase
                                    .instance
                                    .client
                                    .auth
                                    .currentUser!
                                    .id;
                                await Supabase.instance.client
                                    .from('user_addresses')
                                    .insert({
                                      'user_id': userId,
                                      'title': titleController.text.trim(),
                                      'city': cityController.text.trim(),
                                      'district': districtController.text
                                          .trim(),
                                      'full_address': fullAddressController.text
                                          .trim(),
                                    });
                                if (context.mounted) {
                                  Navigator.pop(context); // Formu kapat
                                  setState(
                                    () {},
                                  ); // Ana ekranı yenile ki yeni adres görünsün
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Hata: $e')),
                                  );
                                }
                              } finally {
                                setModalState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Adresi Kaydet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Kayıtlı Adreslerim',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }
          final addresses = snapshot.data;
          if (addresses == null || addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz kayıtlı bir adresiniz bulunmuyor.',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final addr = addresses[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.black),
                  ),
                  title: Text(
                    addr['title'],
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${addr['city']} / ${addr['district']}\n${addr['full_address']}',
                    style: const TextStyle(height: 1.4),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAddressModal,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
