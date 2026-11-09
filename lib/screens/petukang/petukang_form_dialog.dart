import 'package:flutter/material.dart';
import '../../models/petukang.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class PetukangFormDialog extends StatefulWidget {
  final Petukang? petukang;

  const PetukangFormDialog({super.key, this.petukang});

  @override
  State<PetukangFormDialog> createState() => _PetukangFormDialogState();
}

class _PetukangFormDialogState extends State<PetukangFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _nomorWaController;
  late TextEditingController _upahHarianController;
  late TextEditingController _fotoUrlController;

  late WorkerRole _selectedRole;
  late DateTime _selectedTanggalJoin;

  // Preset Avatar options
  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1541888946425-d0fbb1861593?w=150',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.petukang;
    _namaController = TextEditingController(text: p?.nama ?? '');
    _nomorWaController = TextEditingController(text: p?.nomorWa ?? '');
    _upahHarianController = TextEditingController(
      text: p != null ? p.upahHarian.toStringAsFixed(0) : '150000',
    );
    _fotoUrlController = TextEditingController(text: p?.fotoUrl ?? _presetAvatars.first);
    _selectedRole = p?.role ?? WorkerRole.petukang;
    _selectedTanggalJoin = p?.tanggalJoin ?? DateTime.now();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nomorWaController.dispose();
    _upahHarianController.dispose();
    _fotoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.petukang != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(isEditing ? Icons.edit_note : Icons.person_add_alt_1, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(isEditing ? 'Edit Data Petukang' : 'Tambah Petukang Baru'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar preview & preset selector
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.indigo.shade100,
                        backgroundImage: _fotoUrlController.text.isNotEmpty
                            ? NetworkImage(_fotoUrlController.text)
                            : null,
                        child: _fotoUrlController.text.isEmpty
                            ? const Icon(Icons.person, size: 40, color: Colors.indigo)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      const Text('Pilih Foto Profil Cepat:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _presetAvatars.map((url) {
                          final isSelected = _fotoUrlController.text == url;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _fotoUrlController.text = url;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.indigo : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(url),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Nama Lengkap
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap Petukang *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // Role Petukang
                DropdownButtonFormField<WorkerRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role / Jabatan *',
                    prefixIcon: Icon(Icons.engineering),
                    border: OutlineInputBorder(),
                  ),
                  items: WorkerRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 14),

                // Nomor WhatsApp
                TextFormField(
                  controller: _nomorWaController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp *',
                    prefixIcon: Icon(Icons.phone_android),
                    hintText: 'Contoh: 081234567890',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nomor WA wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // Upah Harian
                TextFormField(
                  controller: _upahHarianController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Upah Harian (Rp) *',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                    hintText: '150000',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Upah harian wajib diisi';
                    final numVal = CurrencyFormatter.parse(v);
                    if (numVal <= 0) return 'Upah harus lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Tanggal Join
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedTanggalJoin,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedTanggalJoin = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Bergabung (Joint) *',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormatter.format(_selectedTanggalJoin)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final upah = CurrencyFormatter.parse(_upahHarianController.text);
              final petukang = Petukang(
                id: widget.petukang?.id ?? '',
                nama: _namaController.text.trim(),
                role: _selectedRole,
                nomorWa: _nomorWaController.text.trim(),
                fotoUrl: _fotoUrlController.text.trim(),
                tanggalJoin: _selectedTanggalJoin,
                upahHarian: upah,
                sisaKasbon: widget.petukang?.sisaKasbon ?? 0.0,
                tanggalBayarTerakhir: widget.petukang?.tanggalBayarTerakhir,
                isAktif: widget.petukang?.isAktif ?? true,
              );
              Navigator.pop(context, petukang);
            }
          },
          child: Text(isEditing ? 'Simpan Perubahan' : 'Tambah Petukang'),
        ),
      ],
    );
  }
}
