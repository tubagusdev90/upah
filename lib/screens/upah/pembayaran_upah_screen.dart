import 'package:flutter/material.dart';

import '../../models/petukang.dart';
import '../../models/pembayaran_upah.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import 'slip_preview_dialog.dart';
import '../../utils/theme.dart';

class PembayaranUpahScreen extends StatefulWidget {
  final String? initialPetukangId;

  const PembayaranUpahScreen({super.key, this.initialPetukangId});

  @override
  State<PembayaranUpahScreen> createState() => _PembayaranUpahScreenState();
}

class _PembayaranUpahScreenState extends State<PembayaranUpahScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();

  bool _sedangMemperbaiki = false;

  Future<void> _konfirmasiPerbaikanUpahPetukang() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Perbaikan Upah Petukang'),
        content: const Text(
          'Perbaikan akan langsung memperbarui riwayat pembayaran upah petukang di Firestore.\n\n'
          'Pastikan konfigurasi perbaikan pada DatabaseService sudah benar. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.build_circle_outlined),
            label: const Text('Ya, Perbaiki'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    setState(() => _sedangMemperbaiki = true);
    try {
      await _db.perbaikiRiwayatPembayaranPetukang();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perbaikan upah petukang berhasil.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Gagal memperbaiki riwayat upah: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbaiki upah petukang: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _sedangMemperbaiki = false);
    }
  }

  // Form State
  String? _selectedPetukangId;
  DateTime _tanggalBayar = DateTime.now();
  late DateTime _periodeAwal;
  late DateTime _periodeAkhir;
  int _jumlahHariKerja = 0;
  double _potonganKasbon = 0.0;
  final TextEditingController _potonganKasbonController = TextEditingController(
    text: '0',
  );
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

  void _hitungUlangHariKerja(Petukang p) {
    final unpaid = _db.getUnpaidWorkDays(
      p.id,
      _periodeAwal,
      _periodeAkhir,
    );
    _jumlahHariKerja = unpaid.length;
  }

  void _setPetukangData(Petukang p) {
    _selectedPetukangId = p.id;
    // Periode baru dimulai sehari setelah akhir periode kerja yang sudah dibayar.
    _periodeAwal = _db.hitungPeriodeAwal(p);
    // Default akhir periode mengikuti tanggal bayar. Pengguna dapat
    // memundurkannya jika tanggal pembayaran mencakup hari kerja berikutnya.
    _periodeAkhir = DateTime(
      _tanggalBayar.year,
      _tanggalBayar.month,
      _tanggalBayar.day,
    );

    _hitungUlangHariKerja(p);

    // Rekomendasi potongan kasbon: potong sebagian atau 0 jika tidak ada
    if (p.sisaKasbon > 0) {
      // default potong setengah kasbon atau maksimal upah kotor
      final upahKotor = _jumlahHariKerja * p.upahHarian;
      final saranPotong = (p.sisaKasbon * 0.5).clamp(0.0, upahKotor).toDouble();
      _potonganKasbon = saranPotong;
      _potonganKasbonController.text = _potonganKasbon.toStringAsFixed(0);
    } else {
      _potonganKasbon = 0;
      _potonganKasbonController.text = '0';
    }
  }


Future<void> _showSlipPreview(PembayaranUpah slip) async {
  if (!mounted) return;

  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (dialogContext) {
      return SlipPreviewDialog(slip: slip);
    },
  );
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

          if (_selectedPetukangId == null ||
              !petukangList.any((p) => p.id == _selectedPetukangId)) {
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
    final upahBersih = (upahKotor - _potonganKasbon).clamp(
      0.0,
      double.infinity,
    );
    final sisaKasbonAkhir = (petukang.sisaKasbon - _potonganKasbon).clamp(
      0.0,
      double.infinity,
    );

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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Pilih Petukang yang Akan Dibayar Upahnya',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value:
                            allPetukang.any((p) => p.id == _selectedPetukangId)
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
                            child: Text('${p.nama} | ${p.role.label}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final p = allPetukang.firstWhere(
                              (x) => x.id == val,
                            );
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
                            _miniInfo(
                              'Tanggal Join',
                              DateFormatter.formatShort(petukang.tanggalJoin),
                            ),
                            _miniInfo(
                              'Upah Harian',
                              CurrencyFormatter.format(petukang.upahHarian),
                            ),
                            _miniInfo(
                              'Bayar Terakhir',
                              petukang.tanggalBayarTerakhir != null
                                  ? DateFormatter.formatShort(
                                      petukang.tanggalBayarTerakhir,
                                    )
                                  : 'Belum Pernah',
                            ),
                            _miniInfo(
                              'Kasbon Berjalan',
                              CurrencyFormatter.format(petukang.sisaKasbon),
                              color: petukang.sisaKasbon > 0
                                  ? Colors.red
                                  : Colors.green,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2. Periode Pembayaran & Kehadiran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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
                                'Tentukan tanggal awal dan akhir periode kerja. Tanggal pembayaran dapat berbeda dari akhir periode.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tanggal pembayaran upah
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _tanggalBayar,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );

                          if (picked != null) {
                            setState(() {
                              _tanggalBayar = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              );

                              // Periode kerja tidak boleh melewati tanggal bayar.
                              if (_periodeAkhir.isAfter(_tanggalBayar)) {
                                _periodeAkhir = _tanggalBayar;
                              }
                              if (_periodeAwal.isAfter(_tanggalBayar)) {
                                _periodeAwal = _tanggalBayar;
                              }
                              if (_periodeAkhir.isBefore(_periodeAwal)) {
                                _periodeAkhir = _periodeAwal;
                              }

                              _hitungUlangHariKerja(petukang);
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
                      const SizedBox(height: 14),

                      const Text(
                        'Periode Kerja *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Tanggal awal periode kerja
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _periodeAwal.isAfter(_tanggalBayar)
                                      ? _tanggalBayar
                                      : _periodeAwal,
                                  firstDate: DateTime(2020),
                                  lastDate: _periodeAkhir.isBefore(_tanggalBayar)
                                      ? _periodeAkhir
                                      : _tanggalBayar,
                                );

                                if (picked != null) {
                                  setState(() {
                                    _periodeAwal = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                    );
                                    _hitungUlangHariKerja(petukang);
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Awal *',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  DateFormatter.formatShort(_periodeAwal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tanggal akhir periode kerja
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                if (_tanggalBayar.isBefore(_periodeAwal)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tanggal pembayaran tidak boleh sebelum awal periode kerja.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _periodeAkhir.isBefore(_periodeAwal)
                                      ? _periodeAwal
                                      : (_periodeAkhir.isAfter(_tanggalBayar)
                                          ? _tanggalBayar
                                          : _periodeAkhir),
                                  firstDate: _periodeAwal,
                                  lastDate: _tanggalBayar,
                                );

                                if (picked != null) {
                                  setState(() {
                                    _periodeAkhir = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                    );
                                    _hitungUlangHariKerja(petukang);
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Akhir *',
                                  prefixIcon: Icon(Icons.event_available),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  DateFormatter.formatShort(_periodeAkhir),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                                  'Menghitung absensi Masuk yang belum dibayar dalam rentang periode di atas.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  '$_jumlahHariKerja Hari',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.add),
                                onPressed: () =>
                                    setState(() => _jumlahHariKerja++),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3. Penyesuaian Potongan Kasbon & Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Upah Kotor
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upah Kotor ($_jumlahHariKerja hari x ${CurrencyFormatter.format(petukang.upahHarian)}):',
                          ),
                          Text(
                            CurrencyFormatter.format(upahKotor),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  'Sisa Kasbon: ${CurrencyFormatter.format(petukang.sisaKasbon)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _potonganKasbonController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                labelText: 'Nominal Potongan Kasbon (Rp)',
                                hintText: '0',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _potonganKasbon = CurrencyFormatter.parse(
                                    val,
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sisa kasbon setelah pembayaran ini: ${CurrencyFormatter.format(sisaKasbonAkhir)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
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
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green.shade600,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'TOTAL UPAH DITERIMA (BERSIH)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF14532D),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Upah Kotor dikurangi Potongan Kasbon',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              CurrencyFormatter.format(upahBersih),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Proses Pembayaran & Cetak Slip Upah',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
              const Text(
                'Filter Petukang: ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _historyFilterPetukangId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua Petukang'),
                    ),
                    ...allPetukang.map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.nama)),
                    ),
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
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat slip pembayaran upah',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
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
                            child: const Icon(
                              Icons.receipt,
                              color: Colors.indigo,
                            ),
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(
                                        slip.totalUpahBersih,
                                      ),
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
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Tgl Bayar: ${DateFormatter.formatShort(slip.tanggalBayar)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (slip.potonganKasbon > 0) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Potong Kasbon: ${CurrencyFormatter.format(slip.potonganKasbon)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Print Button
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.indigo,
                            ),
                            tooltip: 'Cetak Slip Upah PDF',
                            icon: const Icon(Icons.print, size: 20),
                            
                            onPressed: () async {
                              await _showSlipPreview(slip);
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

      
Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
  child: SizedBox(
    width: double.infinity,
    height: 46,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: _sedangMemperbaiki
          ? null
          : _konfirmasiPerbaikanUpahPetukang,
      icon: _sedangMemperbaiki
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.build_circle_outlined),
      label: Text(
        _sedangMemperbaiki
            ? 'Sedang Memperbaiki...'
            : 'Perbaikan Upah Petukang',
      ),
    ),
  ),
),
      ],
  );
  }

  Widget _miniInfo(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
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
        const SnackBar(
          content: Text('Jumlah hari kerja harus minimal 1 hari.'),
        ),
      );
      return;
    }
    if (_potonganKasbon < 0 ||
        _potonganKasbon > petukang.sisaKasbon ||
        _potonganKasbon > upahKotor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Potongan kasbon tidak boleh melebihi sisa kasbon atau total upah kotor.',
          ),
        ),
      );
      return;
    }
    if (DateFormatter.normalize(_periodeAkhir).isBefore(
          DateFormatter.normalize(_periodeAwal),
        ) ||
        DateFormatter.normalize(_periodeAkhir).isAfter(
          DateFormatter.normalize(_tanggalBayar),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Periode kerja harus valid: tanggal awal tidak boleh melewati tanggal akhir, dan tanggal akhir tidak boleh melewati tanggal pembayaran.',
          ),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Proses & Cetak'),
          ),
        ],
      ),
    );

    
if (confirm != true) return;

try {
  debugPrint('Memulai proses pembayaran petukang: ${petukang.nama}');

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

  debugPrint('Pembayaran berhasil. ID slip: ${slip.id}');

  if (!mounted) return;

  await _showSlipPreview(slip);
} catch (e, stackTrace) {
  debugPrint('ERROR PEMBAYARAN / SLIP: $e');
  debugPrintStack(stackTrace: stackTrace);

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Gagal memproses pembayaran: $e'),
      backgroundColor: Colors.red,
    ),
  );
}

  }
}
