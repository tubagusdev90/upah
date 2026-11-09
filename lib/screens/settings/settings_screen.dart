import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan & Panduan Sistem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Firebase Status Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: db.isFirebaseConnected ? Colors.green.shade300 : Colors.amber.shade300,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              db.isFirebaseConnected ? Icons.cloud_done : Icons.cloud_off,
                              color: db.isFirebaseConnected ? Colors.green : Colors.amber.shade800,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    db.isFirebaseConnected
                                        ? 'Database Terhubung ke Firebase Firestore'
                                        : 'Mode Database Lokal (Offline-First Ready)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    db.isFirebaseConnected
                                        ? 'Data tersinkronisasi langsung ke Firebase Firestore Cloud.'
                                        : 'Aplikasi berjalan lancar tanpa error menggunakan Database Lokal & data demo petukang.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text(
                          'Cara Mengaktifkan Firebase Firestore Anda:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '1. Buat project baru di Firebase Console (https://console.firebase.google.com)\n'
                            '2. Aktifkan Cloud Firestore Database pada mode Test / Production\n'
                            '3. Jalankan perintah di terminal:\n'
                            '   dart pub global activate flutterfire_cli\n'
                            '   flutterfire configure\n'
                            '4. File lib/services/firebase_options.dart akan terisi otomatis dengan kredensial project Anda.',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Panduan Aturan Bisnis
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aturan & Panduan Penggunaan Fitur',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        _buildRuleTile(
                          icon: Icons.engineering,
                          color: Colors.purple,
                          title: '1. Manajemen Petukang & Role',
                          desc: 'Mendukung 3 role utama: Kepala Tukang, Petukang, dan Kenek. Menyimpan data nama, WhatsApp, foto profil, tanggal join, dan upah harian.',
                        ),
                        _buildRuleTile(
                          icon: Icons.trending_up,
                          color: Colors.green,
                          title: '2. Kenaikan Upah Fleksibel',
                          desc: 'Upah harian petukang dapat dinaikkan kapan saja dengan tombol "Naikkan Upah" di menu Manajemen Petukang.',
                        ),
                        _buildRuleTile(
                          icon: Icons.calendar_month,
                          color: Colors.blue,
                          title: '3. Kalender Absensi 4 Warna',
                          desc: '• Biru: Hari kerja yang belum dibayar upahnya\n'
                              '• Hijau: Hari kerja yang sudah lunas dibayar upahnya\n'
                              '• Amber: Tanggal pembayaran upah proyek\n'
                              '• Merah: Hari libur atau tidak masuk kerja',
                        ),
                        _buildRuleTile(
                          icon: Icons.money_off,
                          color: Colors.red,
                          title: '4. Kasbon Fleksibel & Potongan Bertahap',
                          desc: 'Karyawan/petukang diizinkan kasbon melebihi total upah yang didapat. Saat pembayaran upah, mandor dapat menentukan berapa potongan kasbon yang ingin disesuaikan (bisa potong sebagian atau penuh).',
                        ),
                        _buildRuleTile(
                          icon: Icons.receipt_long,
                          color: Colors.indigo,
                          title: '5. Cetak Slip Upah Resmi',
                          desc: 'Slip upah otomatis dihitung per periode (dimulai dari sehari setelah tanggal bayar terakhir). Dilengkapi tombol cetak / download PDF dengan rincian hari kerja, kasbon, dan tanda tangan.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleTile({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
