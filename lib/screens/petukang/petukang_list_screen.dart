import 'package:flutter/material.dart';
import '../../models/petukang.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import 'petukang_form_dialog.dart';
import 'naikkan_upah_dialog.dart';

class PetukangListScreen extends StatefulWidget {
  const PetukangListScreen({super.key});

  @override
  State<PetukangListScreen> createState() => _PetukangListScreenState();
}

class _PetukangListScreenState extends State<PetukangListScreen> {
  final DatabaseService _db = DatabaseService();
  String _searchQuery = '';
  WorkerRole? _selectedRoleFilter;

  Color _getRoleColor(WorkerRole role) {
    switch (role) {
      case WorkerRole.kepalaTukang:
        return Colors.purple.shade700;
      case WorkerRole.petukang:
        return Colors.blue.shade700;
      case WorkerRole.kenek:
        return Colors.teal.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Petukang'),
        actions: [
          IconButton(
            tooltip: 'Tambah Petukang Baru',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _openAddDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Petukang'),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau nomor WhatsApp...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.toLowerCase().trim());
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua Role'),
                        selected: _selectedRoleFilter == null,
                        onSelected: (_) => setState(() => _selectedRoleFilter = null),
                      ),
                      const SizedBox(width: 8),
                      ...WorkerRole.values.map((role) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(role.label),
                            selected: _selectedRoleFilter == role,
                            onSelected: (selected) {
                              setState(() {
                                _selectedRoleFilter = selected ? role : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Worker List Stream
          Expanded(
            child: StreamBuilder<List<Petukang>>(
              stream: _db.getPetukangList(),
              initialData: _db.currentPetukangList,
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];

                final filteredList = list.where((p) {
                  final matchesSearch = p.nama.toLowerCase().contains(_searchQuery) ||
                      p.nomorWa.contains(_searchQuery);
                  final matchesRole = _selectedRoleFilter == null || p.role == _selectedRoleFilter;
                  return matchesSearch && matchesRole;
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.engineering_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada data petukang',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _openAddDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Petukang Baru'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final petukang = filteredList[index];
                    final roleColor = _getRoleColor(petukang.role);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Worker Photo
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: roleColor.withOpacity(0.15),
                              backgroundImage: petukang.fotoUrl.isNotEmpty
                                  ? NetworkImage(petukang.fotoUrl)
                                  : null,
                              child: petukang.fotoUrl.isEmpty
                                  ? Icon(Icons.person, color: roleColor, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 14),

                            // Main Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          petukang.nama,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: roleColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: roleColor.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          petukang.role.label,
                                          style: TextStyle(
                                            color: roleColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_android, size: 14, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        petukang.nomorWa,
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.blueGrey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Join: ${DateFormatter.formatShort(petukang.tanggalJoin)}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                      if (petukang.tanggalBayarTerakhir != null) ...[
                                        const SizedBox(width: 12),
                                        const Icon(Icons.check_circle_outline, size: 14, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Bayar terakhir: ${DateFormatter.formatShort(petukang.tanggalBayarTerakhir)}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Upah & Kasbon Badges
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.payments, size: 14, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${CurrencyFormatter.format(petukang.upahHarian)}/hari',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: petukang.sisaKasbon > 0
                                              ? Colors.red.shade50
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: petukang.sisaKasbon > 0
                                                ? Colors.red.shade300
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.money_off,
                                              size: 14,
                                              color: petukang.sisaKasbon > 0 ? Colors.red : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Kasbon: ${CurrencyFormatter.format(petukang.sisaKasbon)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: petukang.sisaKasbon > 0
                                                    ? Colors.red.shade900
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Actions Popup
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _openEditDialog(petukang);
                                } else if (val == 'naikkan') {
                                  _openNaikkanUpahDialog(petukang);
                                } else if (val == 'hapus') {
                                  _confirmDelete(petukang);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'naikkan',
                                  child: Row(
                                    children: [
                                      Icon(Icons.trending_up, color: Colors.green, size: 20),
                                      SizedBox(width: 8),
                                      Text('Naikkan Upah'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.indigo, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit Data'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'hapus',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('Hapus Petukang'),
                                    ],
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
      ),
    );
  }

  void _openAddDialog() async {
    final result = await showDialog<Petukang>(
      context: context,
      builder: (context) => const PetukangFormDialog(),
    );
    if (result != null) {
      await _db.addPetukang(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Petukang "${result.nama}" berhasil ditambahkan')),
        );
      }
    }
  }

  void _openEditDialog(Petukang petukang) async {
    final result = await showDialog<Petukang>(
      context: context,
      builder: (context) => PetukangFormDialog(petukang: petukang),
    );
    if (result != null) {
      await _db.updatePetukang(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data "${result.nama}" berhasil diperbarui')),
        );
      }
    }
  }

  void _openNaikkanUpahDialog(Petukang petukang) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => NaikkanUpahDialog(petukang: petukang),
    );
    if (result != null) {
      final upahBaru = result['upahBaru'] as double;
      final alasan = result['alasan'] as String?;
      await _db.updateUpahHarian(petukang.id, upahBaru, alasan: alasan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Text(
              'Upah "${petukang.nama}" berhasil dinaikkan menjadi ${CurrencyFormatter.format(upahBaru)}/hari!',
            ),
          ),
        );
      }
    }
  }

  void _confirmDelete(Petukang petukang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Petukang?'),
        content: Text('Apakah Anda yakin ingin menghapus data "${petukang.nama}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deletePetukang(petukang.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Petukang "${petukang.nama}" dihapus')),
        );
      }
    }
  }
}
