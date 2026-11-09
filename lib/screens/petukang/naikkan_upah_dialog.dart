import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/petukang.dart';
import '../../utils/currency_formatter.dart';

class NaikkanUpahDialog extends StatefulWidget {
  final Petukang petukang;

  const NaikkanUpahDialog({super.key, required this.petukang});

  @override
  State<NaikkanUpahDialog> createState() => _NaikkanUpahDialogState();
}

class _NaikkanUpahDialogState extends State<NaikkanUpahDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _upahBaruController;
  final TextEditingController _alasanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inisialisasi awal dengan format Rupiah yang rapi (upah lama + 10.000)
    final initialAmount = widget.petukang.upahHarian + 10000;
    _upahBaruController = TextEditingController(
      text: CurrencyFormatter.format(initialAmount),
    );
  }

  @override
  void dispose() {
    _upahBaruController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Colors.teal; // Menggunakan warna yang lebih profesional

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.trending_up, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Kenaikan Upah Petukang',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Identitas Petukang
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.15),
                    child: Text(
                      widget.petukang.nama.isNotEmpty ? widget.petukang.nama[0].toUpperCase() : 'P',
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.petukang.nama,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.petukang.role.label,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Kartu Informasi Upah Saat Ini
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upah Saat Ini',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    Text(
                      CurrencyFormatter.format(widget.petukang.upahHarian),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input Upah Baru dengan Formatter Otomatis Titik
              TextFormField(
                controller: _upahBaruController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(), // Menggunakan formatter otomatis ribuan
                ],
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Upah Harian Baru',
                  hintText: 'Rp 0',
                  prefixIcon: const Icon(Icons.payments_outlined, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Upah baru wajib diisi';
                  }
                  final amount = CurrencyFormatter.parse(val);
                  if (amount <= widget.petukang.upahHarian) {
                    return 'Upah baru harus lebih besar dari upah saat ini';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Input Alasan Kenaikan
              TextFormField(
                controller: _alasanController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Alasan Kenaikan (Opsional)',
                  hintText: 'Contoh: Kinerja sangat baik / penyesuaian proyek',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Icon(Icons.notes_outlined, color: primaryColor),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final upahBaru = CurrencyFormatter.parse(_upahBaruController.text);
              Navigator.pop(context, {
                'upahBaru': upahBaru,
                'alasan': _alasanController.text.trim(),
              });
            }
          },
          child: const Text(
            'Simpan Kenaikan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}