import 'package:flutter/material.dart';
import '../../models/petukang.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.construction, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'UpahPetukang',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: db.isFirebaseConnected ? Colors.green.shade50 : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: db.isFirebaseConnected ? Colors.green.shade400 : Colors.amber.shade600,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  db.isFirebaseConnected ? Icons.cloud_done : Icons.cloud_queue,
                  size: 16,
                  color: db.isFirebaseConnected ? Colors.green.shade800 : Colors.amber.shade900,
                ),
                const SizedBox(width: 6),
                Text(
                  db.isFirebaseConnected ? 'Firebase Aktif' : 'Local DB / Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: db.isFirebaseConnected ? Colors.green.shade800 : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Petukang>>(
        stream: db.getPetukangList(),
        initialData: db.currentPetukangList,
        builder: (context, petukangSnap) {
          final petukangList = petukangSnap.data ?? [];
          final totalPetukang = petukangList.length;
        final totalKasbon = petukangList.fold(0.0, (sum, p) => sum + p.sisaKasbon);
        // New aggregates
        final pembayaranList = db.currentPembayaranList;
        final totalUpahPaid = pembayaranList.fold(0.0, (sum, p) => sum + p.totalUpahBersih);
        final totalUpahUnpaid = pembayaranList.fold(0.0, (sum, p) => sum + (p.totalUpahKotor - p.totalUpahBersih));
        final totalKasbonPaid = db.currentKasbonList.fold(0.0, (sum, k) => sum + (k.sisa == 0 ? k.jumlah : 0));
        final totalKasbonUnpaid = db.currentKasbonList.fold(0.0, (sum, k) => sum + (k.sisa > 0 ? k.sisa : 0));
          final totalKasbon = petukangList.fold(0.0, (sum, p) => sum + p.sisaKasbon);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Sistem Manajemen Upah & Petukang',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Kelola absensi kalender warna, kasbon fleksibel, kenaikan upah, dan cetak slip pembayaran resmi.',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.handyman_rounded, size: 48, color: Colors.white38),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmall = constraints.maxWidth < 600;
                        return GridView.count(
                          crossAxisCount: isSmall ? 2 : 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: isSmall ? 1.5 : 1.6,
                          children: [
                            StatCard(
                              title: 'Total Petukang',
                              value: '$totalPetukang Orang',
                              subtitle: '${petukangList.where((p) => p.role == WorkerRole.kepalaTukang).length} Kepala, ${petukangList.where((p) => p.role == WorkerRole.petukang).length} Tukang, ${petukangList.where((p) => p.role == WorkerRole.kenek).length} Kenek',
                              icon: Icons.groups,
                              color: Colors.indigo,
                              onTap: () => onNavigateTab(1),
                            ),
                            StatCard(
                              title: 'Total Kasbon Berjalan',
                              value: CurrencyFormatter.format(totalKasbon),
                              subtitle: 'Boleh melebihi upah',
                              icon: Icons.money_off,
                              color: Colors.red.shade700,
                              onTap: () => onNavigateTab(3),
                            ),
                            StatCard(
                              title: 'Status Kehadiran',
                              value: 'Kalender Warna',
                              subtitle: 'Biru, Hijau, Amber, Merah',
                              icon: Icons.calendar_month,
                              color: Colors.blue.shade700,
                              onTap: () => onNavigateTab(2),
                            ),
                            StatCard(
                              title: 'Total Upah Dibayar',
                              value: CurrencyFormatter.format(totalUpahPaid),
                              subtitle: 'Upah yang sudah dibayarkan',
                              icon: Icons.attach_money,
                              color: Colors.green.shade700,
                              onTap: () => onNavigateTab(4),
                            ),
                            StatCard(
                              title: 'Total Upah Belum Dibayar',
                              value: CurrencyFormatter.format(totalUpahUnpaid),
                              subtitle: 'Upah yang masih harus dibayar',
                              icon: Icons.money_off_csred,
                              color: Colors.orange.shade700,
                              onTap: () => onNavigateTab(4),
                            ),
                            StatCard(
                              title: 'Kasbon Sudah Bayar',
                              value: CurrencyFormatter.format(totalKasbonPaid),
                              subtitle: 'Kasbon yang sudah lunas',
                              icon: Icons.check_circle,
                              color: Colors.teal.shade700,
                              onTap: () => onNavigateTab(3),
                            ),
                            StatCard(
                              title: 'Kasbon Belum Bayar',
                              value: CurrencyFormatter.format(totalKasbonUnpaid),
                              subtitle: 'Kasbon masih tersisa',
                              icon: Icons.error,
                              color: Colors.red.shade700,
                              onTap: () => onNavigateTab(3),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Menu Aksi Cepat',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.payment),
                            label: const Text('Upah & Slip', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => onNavigateTab(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.money_off),
                            label: const Text('Kasbon', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => onNavigateTab(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Absensi', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => onNavigateTab(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Daftar Petukang Ringkas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Daftar Petukang Aktif',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => onNavigateTab(1),
                          child: const Text('Lihat Semua Petukang ->'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: petukangList.take(5).length,
                      itemBuilder: (context, index) {
                        final p = petukangList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: p.fotoUrl.isNotEmpty ? NetworkImage(p.fotoUrl) : null,
                              child: p.fotoUrl.isEmpty ? const Icon(Icons.person) : null,
                            ),
                            title: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${p.role.label} • Upah: ${CurrencyFormatter.format(p.upahHarian)}/hari'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (p.sisaKasbon > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Text(
                                      'Kasbon: ${CurrencyFormatter.format(p.sisaKasbon)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onPressed: () => onNavigateTab(1),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
