import 'package:flutter/material.dart';

enum AbsenStatus {
  kerjaBelumBayar, // Biru: kerja tapi upah belum dibayar
  kerjaSudahBayar, // Hijau: kerja dengan upah yang sudah dibayar
  tanggalBayarUpah, // Amber: tanggal pembayaran upah
  libur, // Merah: libur
}

extension AbsenStatusExt on AbsenStatus {
  String get label {
    switch (this) {
      case AbsenStatus.kerjaBelumBayar:
        return 'Kerja (Upah Belum Dibayar)';
      case AbsenStatus.kerjaSudahBayar:
        return 'Kerja (Upah Sudah Dibayar)';
      case AbsenStatus.tanggalBayarUpah:
        return 'Tanggal Pembayaran Upah';
      case AbsenStatus.libur:
        return 'Libur / Tidak Masuk';
    }
  }

  Color get color {
    switch (this) {
      case AbsenStatus.kerjaBelumBayar:
        return const Color(0xFF2563EB); // Biru (Blue 600)
      case AbsenStatus.kerjaSudahBayar:
        return const Color(0xFF16A34A); // Hijau (Green 600)
      case AbsenStatus.tanggalBayarUpah:
        return const Color(0xFFD97706); // Amber (Amber 600)
      case AbsenStatus.libur:
        return const Color(0xFFDC2626); // Merah (Red 600)
    }
  }

  static AbsenStatus fromString(String? val) {
    switch (val) {
      case 'kerjaSudahBayar':
        return AbsenStatus.kerjaSudahBayar;
      case 'tanggalBayarUpah':
        return AbsenStatus.tanggalBayarUpah;
      case 'libur':
        return AbsenStatus.libur;
      case 'kerjaBelumBayar':
      default:
        return AbsenStatus.kerjaBelumBayar;
    }
  }
}

class Absensi {
  final String id;
  final String petukangId;
  final DateTime tanggal; // Normalized to YYYY-MM-DD
  final AbsenStatus status;
  final double upahHarian;
  final String? pembayaranId;
  final String? keterangan;

  Absensi({
    required this.id,
    required this.petukangId,
    required this.tanggal,
    required this.status,
    required this.upahHarian,
    this.pembayaranId,
    this.keterangan,
  });

  Absensi copyWith({
    String? id,
    String? petukangId,
    DateTime? tanggal,
    AbsenStatus? status,
    double? upahHarian,
    String? pembayaranId,
    String? keterangan,
  }) {
    return Absensi(
      id: id ?? this.id,
      petukangId: petukangId ?? this.petukangId,
      tanggal: tanggal ?? this.tanggal,
      status: status ?? this.status,
      upahHarian: upahHarian ?? this.upahHarian,
      pembayaranId: pembayaranId ?? this.pembayaranId,
      keterangan: keterangan ?? this.keterangan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petukangId': petukangId,
      'tanggal': "${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}",
      'status': status.name,
      'upahHarian': upahHarian,
      'pembayaranId': pembayaranId,
      'keterangan': keterangan,
    };
  }

  factory Absensi.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;
    if (map['tanggal'] != null) {
      parsedDate = DateTime.tryParse(map['tanggal'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }
    // Normalize to date only
    final normalizedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

    return Absensi(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      petukangId: map['petukangId'] ?? '',
      tanggal: normalizedDate,
      status: AbsenStatusExt.fromString(map['status'] as String?),
      upahHarian: (map['upahHarian'] as num?)?.toDouble() ?? 0.0,
      pembayaranId: map['pembayaranId'],
      keterangan: map['keterangan'],
    );
  }
}
