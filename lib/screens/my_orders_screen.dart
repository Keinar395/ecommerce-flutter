import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchMyOrders() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return await Supabase.instance.client
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  int _getStatusStep(String status) {
    final s = status.toLowerCase();
    if (s.contains('bekliyor') || s.contains('alındı')) return 0;
    if (s.contains('hazırlanıyor')) return 1;
    if (s.contains('kargoya')) return 2;
    if (s.contains('teslim')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Siparişlerim',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          final orders = snapshot.data;
          if (orders == null || orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz siparişiniz bulunmuyor.',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Alışverişe Başla',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final date = DateTime.parse(order['created_at']).toLocal();
              final dateString =
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

              final String statusText = order['status'] ?? 'Bekliyor';
              final int currentStep = _getStatusStep(statusText);

              final trackingNo =
                  'ZH-${order['id'].toString().substring(0, 8).toUpperCase()}';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(16),
                    iconColor: Colors.black,
                    collapsedIconColor: Colors.grey,
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: currentStep == 3
                            ? Colors.green[50]
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        currentStep == 3
                            ? Icons.check_circle
                            : Icons.local_shipping_outlined,
                        color: currentStep == 3
                            ? Colors.green[700]
                            : Colors.blue[700],
                      ),
                    ),
                    title: Text(
                      '${order['total_price']} ₺',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        '$dateString • $statusText',
                        style: GoogleFonts.lato(
                          color: currentStep == 3
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 16),
                            Text(
                              'Sipariş Durumu',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                _buildTimelineStep(
                                  Icons.receipt_long,
                                  'Alındı',
                                  currentStep >= 0,
                                ),
                                _buildTimelineLine(currentStep >= 1),
                                _buildTimelineStep(
                                  Icons.inventory_2,
                                  'Hazırlanıyor',
                                  currentStep >= 1,
                                ),
                                _buildTimelineLine(currentStep >= 2),
                                _buildTimelineStep(
                                  Icons.local_shipping,
                                  'Kargoda',
                                  currentStep >= 2,
                                ),
                                _buildTimelineLine(currentStep >= 3),
                                _buildTimelineStep(
                                  Icons.home,
                                  'Teslim',
                                  currentStep >= 3,
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // YENİ EKLENEN: EXPANDED (Taşmayı Önler)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kargo Takip No',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          trackingNo,
                                          style: GoogleFonts.lato(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Kargo firması sayfasına yönlendiriliyor...',
                                              ),
                                            ),
                                          );
                                    },
                                    icon: const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.black,
                                    ),
                                    label: const Text(
                                      'Kargom Nerede?',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildTimelineStep(IconData icon, String label, bool isCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.black : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              color: isCompleted ? Colors.black : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isCompleted) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        height: 3,
        color: isCompleted ? Colors.black : Colors.grey[200],
      ),
    );
  }
}
