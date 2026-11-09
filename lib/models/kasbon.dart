class Kasbon {
  final String id;
  final String petukangId;
  final DateTime tanggal;
  final double jumlah;
  final String keterangan;
  final double sisa;
  final DateTime createdAt;

  Kasbon({
    required this.id,
    required this.petukangId,
    required this.tanggal,
    required this.jumlah,
    this.keterangan = '',
    required this.sisa,
    required this.createdAt,
  });

  Kasbon copyWith({
    String? id,
    String? petukangId,
    DateTime? tanggal,
    double? jumlah,
    String? keterangan,
    double? sisa,
    DateTime? createdAt,
  }) {
    return Kasbon(
      id: id ?? this.id,
      petukangId: petukangId ?? this.petukangId,
      tanggal: tanggal ?? this.tanggal,
      jumlah: jumlah ?? this.jumlah,
      keterangan: keterangan ?? this.keterangan,
      sisa: sisa ?? this.sisa,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petukangId': petukangId,
      'tanggal': tanggal.toIso8601String(),
      'jumlah': jumlah,
      'keterangan': keterangan,
      'sisa': sisa,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Kasbon.fromMap(Map<String, dynamic> map, String docId) {
    return Kasbon(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      petukangId: map['petukangId'] ?? '',
      tanggal: map['tanggal'] != null
          ? DateTime.tryParse(map['tanggal'].toString()) ?? DateTime.now()
          : DateTime.now(),
      jumlah: (map['jumlah'] as num?)?.toDouble() ?? 0.0,
      keterangan: map['keterangan'] ?? '',
      sisa: (map['sisa'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
