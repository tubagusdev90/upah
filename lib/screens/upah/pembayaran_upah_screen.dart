import 'package:flutter/material.dart';
import '../../models/petukang.dart';
import '../../models/pembayaran_upah.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import 'slip_preview_dialog.dart';

class PembayaranUpahScreen extends StatefulWidget {
  final String? initialPetukangId;

  const PembayaranUpahScreen({super.key, this.initialPetukangId});

  @override
  State<PembayaranUpahScreen> createState() => _PembayaranUpahScreenState();
}

class _PembayaranUpahScreenState extends State<PembayaranUpahScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();

  // Form State
  String? _selectedPetukangId;
  DateTime _tanggalBayar = DateTime.now();
  late DateTime _periodeAwal;
  late DateTime _periodeAkhir;
  int _jumlahHariKerja = 0;
  double _potonganKasbon = 0.0;
  final TextEditingController _potonganKasbonController = TextEditingController(text: '0');
  final TextEditingController _keteranganController = TextEditingController();

  String? _historyFilterPetukangId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedPetukangId = widget.initialPetukangId;
    _tanggalBayar = DateTime.now();
    _periodeAkhir = _tanggalBayar;
    _periodeAwal = _tanggalBayar.subtract(const Duration(days: 6));

    final currentList = _db.currentPetukangList;
    if (currentList.isNotEmpty) {
      final initial = currentList.firstWhere(
        (p) => p.id == _selectedPetukangId,
        orElse: () => currentList.first,
      );
      _setPetukangData(initial);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _potonganKasbonController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _setPetukangData(Petukang p) {
    _selectedPetukangId = p.id;
    // Per aturan: Tiap periode pembayaran dihitung mulai sehari setelah tanggal pembayaran sebelumnya
    _periodeAwal = _db.hitungPeriodeAwal(p);
    _periodeAkhir = _tanggalBayar;

    // Hitung hari kerja belum bayar (biru) dalam periode ini
    final unpaid = _db.getUnpaidWorkDays(p.id, _periodeAwal, _periodeAkhir);
    _jumlahHariKerja = unpaid.isNotEmpty ? unpaid.length : 6; // default 6 jika belum ada catatan spesifik

    // Rekomendasi potongan kasbon: potong sebagian atau 0 jika tidak ada
    if (p.sisaKasbon > 0) {
      // default potong setengah kasbon atau maksimal upah kotor
      final upahKotor = _jumlahHariKerja * p.upahHarian;
      final saranPotong = (p.sisaKasbon * 0.5).clamp(0.0, upahKotor);
      _potonganKasbon = saranPotong;
      _potonganKasbonController.text = _potonganKasbon.toStringAsFixed(0);
    } else {
      _potonganKasbon = 0;
      _potonganKasbonController.text = '0';
    }
  }

  void _onPetukangChanged(Petukang p) {
    setState(() {
      _setPetukangData(p);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran & Slip Upah'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.payment), text: 'Bayar Upah Baru'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Riwayat Slip Upah'),
          ],
        ),
      ),
      body: StreamBuilder<List<Petukang>>(
        stream: _db.getPetukangList(),
        initialData: _db.currentPetukangList,
        builder: (context, petukangSnap) {
          final petukangList = petukangSnap.data ?? [];

          if (petukangList.isEmpty) {
            return const Center(child: Text('Belum ada data petukang.'));
          }

          if (_selectedPetukangId == null || !petukangList.any((p) => p.id == _selectedPetukangId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _onPetukangChanged(petukangList.first);
              }
            });
          }

          final selectedPetukang = petukangList.firstWhere(
            (p) => p.id == _selectedPetukangId,
            orElse: () => petukangList.first,
          );

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Form Pembayaran Upah
              _buildFormPembayaran(selectedPetukang, petukangList),

              // Tab 2: Riwayat Slip & Print
              _buildRiwayatSlip(petukangList),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormPembayaran(Petukang petukang, List<Petukang> allPetukang) {
    final upahKotor = _jumlahHariKerja * petukang.upahHarian;
    final upahBersih = (upahKotor - _potonganKasbon).clamp(0.0, double.infinity);
    final sisaKasbonAkhir = (petukang.sisaKasbon - _potonganKasbon).clamp(0.0, double.infinity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Pilih Petukang
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Pilih Petukang yang Akan Dibayar Upahnya',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: allPetukang.any((p) => p.id == _selectedPetukangId)
                            ? _selectedPetukangId
                            : petukang.id,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          labelText: 'Nama Petukang',
                          border: OutlineInputBorder(),
                        ),
                        items: allPetukang.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.nama} | ${p.role.label}',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final p = allPetukang.firstWhere((x) => x.id == val);
                            _onPetukangChanged(p);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Info Singkat Petukang
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _miniInfo('Tanggal Join', DateFormatter.formatShort(petukang.tanggalJoin)),
                            _miniInfo('Upah Harian', CurrencyFormatter.format(petukang.upahHarian)),
                            _miniInfo(
                              'Bayar Terakhir',
                              petukang.tanggalBayarTerakhir != null
                                  ? DateFormatter.formatShort(petukang.tanggalBayarTerakhir)
                                  : 'Belum Pernah',
                            ),
                            _miniInfo(
                              'Kasbon Berjalan',
                              CurrencyFormatter.format(petukang.sisaKasbon),
                              color: petukang.sisaKasbon > 0 ? Colors.red : Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card Periode & Hari Kerja
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2. Periode Pembayaran & Kehadiran',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.rule, color: Colors.blue, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Periode dihitung otomatis mulai sehari setelah tanggal bayar terakhir.',
                                style: TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // Tanggal Bayar
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _tanggalBayar,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _tanggalBayar = picked;
                                    _periodeAkhir = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Pembayaran *',
                                  prefixIcon: Icon(Icons.event),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(DateFormatter.format(_tanggalBayar)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Rentang Periode
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Rentang Periode Upah',
                                prefixIcon: Icon(Icons.date_range),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                '${DateFormatter.formatShort(_periodeAwal)} s/d ${DateFormatter.formatShort(_periodeAkhir)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Jumlah Hari Kerja Counter
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Jumlah Hari Masuk Kerja:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Dihitung dari kalender absensi (biru) atau sesuaikan manual',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton.filledTonal(
                                icon: const Icon(Icons.remove),
                                onPressed: _jumlahHariKerja > 0
                                    ? () => setState(() => _jumlahHariKerja--)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$_jumlahHariKerja Hari',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => _jumlahHariKerja++),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card Kasbon & Perhitungan Bersih
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3. Penyesuaian Potongan Kasbon & Total',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),

                      // Upah Kotor
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Upah Kotor ($_jumlahHariKerja hari x ${CurrencyFormatter.format(petukang.upahHarian)}):'),
                          Text(
                            CurrencyFormatter.format(upahKotor),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Potongan Kasbon Field
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Potongan Kasbon Sebagian (Fleksibel):',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                                Text(
                                  'Sisa Kasbon: ${CurrencyFormatter.format(petukang.sisaKasbon)}',
                                  style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _potonganKasbonController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.remove_circle_outline, color: Colors.red),
                                labelText: 'Nominal Potongan Kasbon (Rp)',
                                hintText: '0',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _potonganKasbon = CurrencyFormatter.parse(val);
                                });
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sisa kasbon setelah pembayaran ini: ${CurrencyFormatter.format(sisaKasbonAkhir)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Catatan
                      TextField(
                        controller: _keteranganController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Pembayaran (Opsional)',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1.5),

                      // Total Bersih Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade600, width: 2),
                        ),
                        child: Column(
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              //crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'TOTAL UPAH DITERIMA (BERSIH):',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
                                ),
                                Text(
                                  'Upah Kotor dikurangi Potongan Kasbon',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.format(upahBersih),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF14532D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Proses Pembayaran & Cetak Slip Upah',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _prosesPembayaran(petukang),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatSlip(List<Petukang> allPetukang) {
    return Column(
      children: [
        // Filter by Petukang
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Filter Petukang: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _historyFilterPetukangId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Petukang')),
                    ...allPetukang.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nama))),
                  ],
                  onChanged: (val) {
                    setState(() => _historyFilterPetukangId = val);
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // List Stream
        Expanded(
          child: StreamBuilder<List<PembayaranUpah>>(
            stream: _db.getPembayaranList(petukangId: _historyFilterPetukangId),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat slip pembayaran upah',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final slip = list[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.indigo.shade50,
                            child: const Icon(Icons.receipt, color: Colors.indigo),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        slip.petukangNama,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(slip.totalUpahBersih),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF14532D),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Periode: ${DateFormatter.formatShort(slip.periodeAwal)} s/d ${DateFormatter.formatShort(slip.periodeAkhir)} (${slip.jumlahHariKerja} Hari Kerja)',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Tgl Bayar: ${DateFormatter.formatShort(slip.tanggalBayar)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    if (slip.potonganKasbon > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Potong Kasbon: ${CurrencyFormatter.format(slip.potonganKasbon)}',
                                          style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Print Button
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: Colors.indigo),
                            tooltip: 'Cetak Slip Upah PDF',
                            icon: const Icon(Icons.print, size: 20),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => SlipPreviewDialog(slip: slip),
                              );
                            },
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
    );
  }

  Widget _miniInfo(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  void _prosesPembayaran(Petukang petukang) async {
    final upahKotor = _jumlahHariKerja * petukang.upahHarian;
    if (_jumlahHariKerja <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah hari kerja harus minimal 1 hari.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran Upah'),
        content: Text(
          'Proses upah untuk "${petukang.nama}" senilai ${CurrencyFormatter.format(upahKotor - _potonganKasbon)} '
          'dengan potongan kasbon ${CurrencyFormatter.format(_potonganKasbon)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Proses & Cetak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final slip = await _db.prosesPembayaranUpah(
        petukang: petukang,
        tanggalBayar: _tanggalBayar,
        periodeAwal: _periodeAwal,
        periodeAkhir: _periodeAkhir,
        jumlahHariKerja: _jumlahHariKerja,
        upahHarian: petukang.upahHarian,
        totalUpahKotor: upahKotor,
        potonganKasbon: _potonganKasbon,
        keterangan: _keteranganController.text.trim(),
      );

      if (mounted) {
        // Show success slip dialog
        showDialog(
          context: context,
          builder: (context) => SlipPreviewDialog(slip: slip),
        );
      }
    }
  }
}
