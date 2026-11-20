import 'package:flutter/material.dart';

import '../../models/petukang.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import 'petukang_form_dialog.dart';

class PetukangListScreen extends StatefulWidget {
  const PetukangListScreen({super.key});

  @override
  State<PetukangListScreen> createState() => _PetukangListScreenState();
}

class _PetukangListScreenState extends State<PetukangListScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _openForm({Petukang? petukang}) async {
    final result = await showDialog<Petukang>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PetukangFormDialog(petukang: petukang),
    );
    if (result == null || !mounted) return;

    try {
      if (petukang == null) {
        await _db.addPetukang(result);
      } else {
        await _db.updatePetukang(result);
      }
      if (mounted) {
        _showMessage(petukang == null
            ? 'Petukang berhasil ditambahkan.'
            : 'Data petukang berhasil diperbarui.');
      }
    } catch (e) {
      if (mounted) _showMessage('Gagal menyimpan data: $e', error: true);
    }
  }

  Future<void> _deletePetukang(Petukang petukang) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Petukang'),
        content: Text('Yakin ingin menghapus ${petukang.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;

    try {
      await _db.deletePetukang(petukang.id);
      if (mounted) _showMessage('${petukang.nama} berhasil dihapus.');
    } catch (e) {
      if (mounted) _showMessage('Gagal menghapus data: $e', error: true);
    }
  }

  List<Petukang> _filter(List<Petukang> source) {
    final q = _keyword.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((p) =>
      p.nama.toLowerCase().contains(q) ||
      p.nomorWa.toLowerCase().contains(q) ||
      p.role.label.toLowerCase().contains(q)
    ).toList();
  }

  Widget _empty(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 3),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: color ?? Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _petukangCard(Petukang p) {
    final foto = p.fotoUrl.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.indigo.shade50,
                  backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                  child: foto.isEmpty
                      ? const Icon(Icons.person, color: Colors.indigo)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nama, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(p.role.label, style: TextStyle(
                          color: Colors.indigo.shade700, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(p.nomorWa.isEmpty ? 'Nomor WA belum diisi' : p.nomorWa,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _openForm(petukang: p);
                    if (v == 'delete') _deletePetukang(p);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
            const Divider(height: 22),
            Row(
              children: [
                _info('Upah Harian', CurrencyFormatter.format(p.upahHarian),
                    Icons.payments_outlined),
                const SizedBox(width: 12),
                _info('Sisa Kasbon', CurrencyFormatter.format(p.sisaKasbon),
                    Icons.account_balance_wallet_outlined,
                    color: p.sisaKasbon > 0 ? Colors.red.shade700 : Colors.green.shade700),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _info('Tanggal Join', DateFormatter.formatShort(p.tanggalJoin),
                    Icons.calendar_today_outlined),
                const SizedBox(width: 12),
                _info('Status', p.isAktif ? 'Aktif' : 'Tidak Aktif',
                    Icons.verified_user_outlined,
                    color: p.isAktif ? Colors.green.shade700 : Colors.grey.shade700),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openForm(petukang: p),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Petukang'),
        actions: [
          IconButton(
            tooltip: 'Tambah Petukang',
            onPressed: () => _openForm(),
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _keyword = v),
              decoration: InputDecoration(
                hintText: 'Cari nama, posisi, atau nomor WhatsApp...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _keyword.isEmpty ? null : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _keyword = '');
                  },
                  icon: const Icon(Icons.close),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Petukang>>(
              stream: _db.getPetukangList(),
              initialData: _db.currentPetukangList,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _empty(Icons.error_outline, 'Gagal memuat data',
                      snapshot.error.toString());
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data ?? [];
                final data = _filter(all);
                if (all.isEmpty) {
                  return _empty(Icons.engineering_outlined, 'Belum ada petukang',
                      'Tekan tombol tambah untuk memasukkan data petukang.');
                }
                if (data.isEmpty) {
                  return _empty(Icons.search_off, 'Data tidak ditemukan',
                      'Coba gunakan kata kunci pencarian lain.');
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: data.length,
                  itemBuilder: (_, i) => _petukangCard(data[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Petukang'),
      ),
    );
  }
}
