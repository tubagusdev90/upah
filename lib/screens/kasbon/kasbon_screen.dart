import 'package:flutter/material.dart';
import '../../models/petukang.dart';
import '../../models/kasbon.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class KasbonScreen extends StatefulWidget {
  const KasbonScreen({super.key});

  @override
  State<KasbonScreen> createState() => _KasbonScreenState();
}

class _KasbonScreenState extends State<KasbonScreen> {
  final DatabaseService _db = DatabaseService();
  String? _selectedPetukangFilter;
  List<Petukang> _currentPetukangList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kasbon Petukang'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kasbon'),
        onPressed: () => _openAddKasbonDialog(_currentPetukangList),
      ),
      body: StreamBuilder<List<Petukang>>(
        stream: _db.getPetukangList(),
        initialData: _db.currentPetukangList,
        builder: (context, petukangSnap) {
          final petukangList = petukangSnap.data ?? [];
          _currentPetukangList = petukangList;
          final double totalKasbonSemua = petukangList.fold(0.0, (sum, p) => sum + p.sisaKasbon);

          return Column(
            children: [
              // Summary Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.red.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL SISA KASBON BERJALAN',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Boleh > Upah',
                                style: TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(totalKasbonSemua),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kasbon dipotong sebagian secara fleksibel pada menu Bayar Upah.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Filter by Petukang
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text('Filter Petukang:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedPetukangFilter,
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
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Semua Petukang'),
                          ),
                          ...petukangList.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.nama} (Sisa: ${CurrencyFormatter.format(p.sisaKasbon)})'),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedPetukangFilter = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),

              // Kasbon List Stream
              Expanded(
                child: StreamBuilder<List<Kasbon>>(
                  stream: _db.getKasbonList(_selectedPetukangFilter),
                  builder: (context, kasbonSnap) {
                    final kasbonList = kasbonSnap.data ?? [];

                    if (kasbonList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.money_off_csred, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada riwayat kasbon',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemCount: kasbonList.length,
                      itemBuilder: (context, index) {
                        final kasbon = kasbonList[index];
                        final petukang = petukangList.firstWhere(
                          (p) => p.id == kasbon.petukangId,
                          orElse: () => Petukang(
                            id: '',
                            nama: 'Petukang Terhapus',
                            role: WorkerRole.petukang,
                            nomorWa: '',
                            tanggalJoin: DateTime.now(),
                            upahHarian: 0,
                          ),
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              child: const Icon(Icons.arrow_downward, color: Colors.red),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    petukang.nama,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(kasbon.jumlah),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  kasbon.keterangan.isNotEmpty ? kasbon.keterangan : 'Tanpa keterangan',
                                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormatter.format(kasbon.tanggal),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Sisa Kasbon Petukang: ${CurrencyFormatter.format(petukang.sisaKasbon)}',
                                        style: TextStyle(fontSize: 11, color: Colors.red.shade900),
                                      ),
                                    ),
                                  ],
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
        },
      ),
    );
  }

  void _openAddKasbonDialog([List<Petukang>? list]) async {
    List<Petukang> petukangList = (list != null && list.isNotEmpty)
        ? list
        : (_currentPetukangList.isNotEmpty ? _currentPetukangList : _db.currentPetukangList);

    if (petukangList.isEmpty) {
      petukangList = await _db.fetchPetukangList();
    }

    if (petukangList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan tambahkan data petukang terlebih dahulu.')),
        );
      }
      return;
    }

    if (!mounted) return;

    String selectedPetukangId = (_selectedPetukangFilter != null &&
            petukangList.any((p) => p.id == _selectedPetukangFilter))
        ? _selectedPetukangFilter!
        : petukangList.first.id;
    final jumlahController = TextEditingController();
    final keteranganController = TextEditingController();
    DateTime tanggalKasbon = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentSelected = petukangList.firstWhere((p) => p.id == selectedPetukangId);

            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.money_off, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Catat Kasbon Baru'),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Petukang Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedPetukangId,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Petukang *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        items: petukangList.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.nama} (${p.role.label})',style: TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedPetukangId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 8),

                      // Info current sisa kasbon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sisa Kasbon Saat Ini:'),
                            Text(
                              CurrencyFormatter.format(currentSelected.sisaKasbon),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Jumlah Kasbon
                      TextFormField(
                        controller: jumlahController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Kasbon (Rp) *',
                          prefixIcon: Icon(Icons.attach_money),
                          hintText: 'Contoh: 300000',
                          helperText: 'Boleh melebihi upah yang akan diterima',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tanggal Kasbon
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tanggalKasbon,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => tanggalKasbon = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Kasbon *',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(DateFormatter.format(tanggalKasbon)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Keterangan
                      TextFormField(
                        controller: keteranganController,
                        decoration: const InputDecoration(
                          labelText: 'Keperluan / Keterangan',
                          prefixIcon: Icon(Icons.notes),
                          hintText: 'Contoh: Uang saku keluarga, beli obat',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final amount = CurrencyFormatter.parse(jumlahController.text);
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Jumlah kasbon harus lebih dari 0')),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Simpan Kasbon'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final amount = CurrencyFormatter.parse(jumlahController.text);
      await _db.addKasbon(
        petukangId: selectedPetukangId,
        jumlah: amount,
        keterangan: keteranganController.text.trim(),
        tanggal: tanggalKasbon,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Kasbon senilai ${CurrencyFormatter.format(amount)} berhasil dicatat.'),
          ),
        );
      }
    }
  }
}
