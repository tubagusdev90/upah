import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(num? amount) {
    if (amount == null) return 'Rp 0';
    return _formatter.format(amount);
  }

  static double parse(String text) {
    // Menghapus semua karakter selain angka
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}

/// Custom TextInputFormatter untuk format Rupiah otomatis saat mengetik
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Jika kosong, biarkan kosong
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Ambil hanya angka dari input pengguna
    final numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numericString.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Ubah ke angka (int/double)
    final number = int.parse(numericString);

    // Format dengan titik sebagai pemisah ribuan menggunakan intl
    final formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);

    // Kembalikan nilai baru beserta posisi kursor di akhir teks
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}