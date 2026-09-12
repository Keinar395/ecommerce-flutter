import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'my_orders_screen.dart';
import 'addresses_screen.dart';
import 'profile_info_screen.dart';
import 'update_password_screen.dart';
import 'saved_cards_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Senkop Kırmızısı
  final Color _senkopRed = const Color(0xFFD32F2F);

  Future<void> _signOut(BuildContext context) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Çıkış Yap',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'İptal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Çıkış Yap',
                  style: TextStyle(color: _senkopRed), // Güncellendi
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String?;
    final displayName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (user?.email ?? 'Kullanıcı');
    final initial = displayName.substring(0, 1).toUpperCase();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: _senkopRed, // Güncellendi
                  child: Text(
                    initial,
                    style: GoogleFonts.lato(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuOption(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'Siparişlerim',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
              );
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.location_on_outlined,
            title: 'Kayıtlı Adreslerim',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressesScreen(),
                ),
              );
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.credit_card_outlined,
            title: 'Kayıtlı Kartlarım',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedCardsScreen(),
                ),
              );
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.person_outline,
            title: 'Kişisel Bilgilerim',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileInfoScreen(),
                ),
              );
              if (result == true) setState(() {});
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.lock_outline,
            title: 'Şifre Güncelle',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdatePasswordScreen(),
                ),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(),
          ),

          const SizedBox(height: 16),
          _buildMenuOption(
            context,
            icon: Icons.logout,
            title: 'Çıkış Yap',
            isDestructive: true,
            onTap: () => _signOut(context),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // İkon arka planı Senkop kırmızısının çok hafif transparan bir tonu yapıldı
              color: isDestructive
                  ? Colors.red[50]
                  : _senkopRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            // İkonun kendi rengi de siyah yerine Senkop Kırmızısı yapıldı
            child: Icon(icon, color: isDestructive ? Colors.red : _senkopRed),
          ),
          title: Text(
            title,
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: isDestructive ? Colors.red : Colors.black,
            ),
          ),
          trailing:
              trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }
}
