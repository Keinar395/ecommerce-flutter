import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  late TextEditingController _nameController;
  final _phoneController = TextEditingController(); // Şimdilik sadece görsel
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Kullanıcının mevcut verisini çekip Text alanına yazıyoruz
    final user = Supabase.instance.client.auth.currentUser;
    final currentName = user?.userMetadata?['full_name'] as String? ?? '';
    _nameController = TextEditingController(text: currentName);
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      // Supabase'in metadata özelliğini kullanarak Ad-Soyad kaydediyoruz
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': _nameController.text.trim()}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bilgiler başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true döndürerek Hesabım sayfasına "Veri değişti, kendini yenile" mesajı veriyoruz
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (user?.email ?? 'U');
    final initial = displayName.substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Kişisel Bilgilerim',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black,
              child: Text(
                initial,
                style: GoogleFonts.lato(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoField(
              'E-posta Adresi',
              user?.email ?? '',
              Icons.email_outlined,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: _inputStyle(
                'Ad Soyad',
                Icons.person_outline,
                hint: 'Adınızı girin',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: _inputStyle(
                'Telefon Numarası',
                Icons.phone_outlined,
                hint: '05XX XXX XX XX',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                        'Kaydet',
                        style: GoogleFonts.lato(
                          fontSize: 16,
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

  Widget _buildInfoField(
    String label,
    String value,
    IconData icon, {
    bool readOnly = false,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      readOnly: readOnly,
      decoration: _inputStyle(label, icon),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
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
    );
  }
}
