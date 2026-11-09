enum WorkerRole {
  kepalaTukang,
  petukang,
  kenek,
}

extension WorkerRoleExt on WorkerRole {
  String get label {
    switch (this) {
      case WorkerRole.kepalaTukang:
        return 'Kepala Tukang';
      case WorkerRole.petukang:
        return 'Petukang';
      case WorkerRole.kenek:
        return 'Kenek';
    }
  }

  static WorkerRole fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'kepala tukang':
      case 'kepalatukang':
        return WorkerRole.kepalaTukang;
      case 'kenek':
        return WorkerRole.kenek;
      default:
        return WorkerRole.petukang;
    }
  }
}

class Petukang {
  final String id;
  final String nama;
  final WorkerRole role;
  final String nomorWa;
  final String fotoUrl;
  final DateTime tanggalJoin;
  final double upahHarian;
  final double sisaKasbon;
  final DateTime? tanggalBayarTerakhir;
  final bool isAktif;
  // New field to record the date of the latest wage increase
  final DateTime? tanggalKenaikanUpah;

  Petukang({
    required this.id,
    required this.nama,
    required this.role,
    required this.nomorWa,
    this.fotoUrl = '',
    required this.tanggalJoin,
    required this.upahHarian,
    this.sisaKasbon = 0.0,
    this.tanggalBayarTerakhir,
    this.isAktif = true,
    this.tanggalKenaikanUpah,
  });

  Petukang copyWith({
    String? id,
    String? nama,
    WorkerRole? role,
    String? nomorWa,
    String? fotoUrl,
    DateTime? tanggalJoin,
    double? upahHarian,
    double? sisaKasbon,
    DateTime? tanggalBayarTerakhir,
    bool? isAktif,
    DateTime? tanggalKenaikanUpah,
  }) {
    return Petukang(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      role: role ?? this.role,
      nomorWa: nomorWa ?? this.nomorWa,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      tanggalJoin: tanggalJoin ?? this.tanggalJoin,
      upahHarian: upahHarian ?? this.upahHarian,
      sisaKasbon: sisaKasbon ?? this.sisaKasbon,
      tanggalBayarTerakhir: tanggalBayarTerakhir ?? this.tanggalBayarTerakhir,
      isAktif: isAktif ?? this.isAktif,
      tanggalKenaikanUpah: tanggalKenaikanUpah ?? this.tanggalKenaikanUpah,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'role': role.label,
      'nomorWa': nomorWa,
      'fotoUrl': fotoUrl,
      'tanggalJoin': tanggalJoin.toIso8601String(),
      'upahHarian': upahHarian,
      'sisaKasbon': sisaKasbon,
      'tanggalBayarTerakhir': tanggalBayarTerakhir?.toIso8601String(),
      'isAktif': isAktif,
      'tanggalKenaikanUpah': tanggalKenaikanUpah?.toIso8601String(),
    };
  }

  factory Petukang.fromMap(Map<String, dynamic> map, String docId) {
    return Petukang(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      nama: map['nama'] ?? '',
      role: WorkerRoleExt.fromString(map['role'] as String?),
      nomorWa: map['nomorWa'] ?? '',
      fotoUrl: map['fotoUrl'] ?? '',
      tanggalJoin: map['tanggalJoin'] != null
          ? DateTime.tryParse(map['tanggalJoin'].toString()) ?? DateTime.now()
          : DateTime.now(),
      upahHarian: (map['upahHarian'] as num?)?.toDouble() ?? 0.0,
      sisaKasbon: (map['sisaKasbon'] as num?)?.toDouble() ?? 0.0,
      tanggalBayarTerakhir: map['tanggalBayarTerakhir'] != null
          ? DateTime.tryParse(map['tanggalBayarTerakhir'].toString())
          : null,
      isAktif: map['isAktif'] ?? true,
      tanggalKenaikanUpah: map['tanggalKenaikanUpah'] != null
          ? DateTime.tryParse(map['tanggalKenaikanUpah'].toString())
          : null,
    );
  }
}
