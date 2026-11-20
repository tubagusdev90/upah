import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final _picker = ImagePicker();

  late final TextEditingController _namaController;
  late final TextEditingController _nomorWaController;
  late final TextEditingController _upahHarianController;
  late final TextEditingController _fotoUrlController;

  late WorkerRole _selectedRole;
  late DateTime _selectedTanggalJoin;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isSaving = false;

  final List<String> _presetAvatars = const [
    'https://images.unsplash.com/photo-1541888946425-d0fbb1861593?w=150',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
  ];

  bool get _isEditing => widget.petukang != null;

  @override
  void initState() {
    super.initState();
    final p = widget.petukang;
    _namaController = TextEditingController(text: p?.nama ?? '');
    _nomorWaController = TextEditingController(text: p?.nomorWa ?? '');
    _upahHarianController = TextEditingController(
      text: p?.upahHarian.toStringAsFixed(0) ?? '150000',
    );
    _fotoUrlController = TextEditingController(
      text: p?.fotoUrl ?? _presetAvatars.first,
    );
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

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
        _fotoUrlController.clear();
      });
    } catch (e) {
      if (mounted) _message('Gagal memilih foto: $e', error: true);
    }
  }

  Future<String> _uploadFoto() async {
    if (_selectedImageBytes == null) return _fotoUrlController.text.trim();

    final name = _selectedImageName ?? 'foto.jpg';
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref().child('petukang/$fileName');

    final result = await ref.putData(
      _selectedImageBytes!,
      SettableMetadata(contentType: contentType),
    );
    return result.ref.getDownloadURL();
  }

  Future<void> _selectTanggalJoin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalJoin,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTanggalJoin = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _selectPreset(String url) {
    setState(() {
      _fotoUrlController.text = url;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    try {
      final old = widget.petukang;
      final fotoUrl = await _uploadFoto();
      final result = Petukang(
        id: old?.id ?? '',
        nama: _namaController.text.trim(),
        role: _selectedRole,
        nomorWa: _nomorWaController.text.trim(),
        fotoUrl: fotoUrl,
        tanggalJoin: _selectedTanggalJoin,
        upahHarian: CurrencyFormatter.parse(_upahHarianController.text),
        sisaKasbon: old?.sisaKasbon ?? 0,
        tanggalBayarTerakhir: old?.tanggalBayarTerakhir,
        isAktif: old?.isAktif ?? true,
        tanggalKenaikanUpah: old?.tanggalKenaikanUpah,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (mounted) _message('Gagal menyimpan data: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ImageProvider? get _avatarImage {
    if (_selectedImageBytes != null) return MemoryImage(_selectedImageBytes!);
    final url = _fotoUrlController.text.trim();
    return url.isEmpty ? null : NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_isEditing ? Icons.edit_note : Icons.person_add_alt_1,
              color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_isEditing ? 'Edit Data Petukang' : 'Tambah Petukang Baru'),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.indigo.shade100,
                        backgroundImage: _avatarImage,
                        child: _avatarImage == null
                            ? const Icon(Icons.person, size: 48, color: Colors.indigo)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _pickImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Pilih Foto dari Galeri'),
                      ),
                      const Text('Atau gunakan foto profil cepat',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: _presetAvatars.map((url) {
                          final selected = _selectedImageBytes == null &&
                              _fotoUrlController.text == url;
                          return InkWell(
                            onTap: _isSaving ? null : () => _selectPreset(url),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? Colors.indigo : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(url),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _namaController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap Petukang *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<WorkerRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Posisi / Jabatan *',
                    prefixIcon: Icon(Icons.engineering_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: WorkerRole.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _selectedRole = v);
                        },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nomorWaController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp *',
                    prefixIcon: Icon(Icons.phone_android),
                    hintText: '081234567890',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nomor WhatsApp wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _upahHarianController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Upah Harian (Rp) *',
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Upah wajib diisi';
                    if (CurrencyFormatter.parse(v) <= 0) return 'Upah harus lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _isSaving ? null : _selectTanggalJoin,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Bergabung *',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
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
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving
              ? 'Mengunggah...'
              : (_isEditing ? 'Simpan Perubahan' : 'Tambah Petukang')),
        ),
      ],
    );
  }
}
