class PembayaranUpah {
  final String id;
  final String petukangId;
  final String petukangNama;
  final String petukangRole;
  final DateTime tanggalBayar;
  final DateTime periodeAwal;
  final DateTime periodeAkhir;
  final int jumlahHariKerja;
  final double upahHarian;
  final double totalUpahKotor;
  final double sisaKasbonSebelumnya;
  final double potonganKasbon;
  final double sisaKasbonSetelahnya;
  final double totalUpahBersih;
  final String keterangan;
  final DateTime createdAt;

  PembayaranUpah({
    required this.id,
    required this.petukangId,
    required this.petukangNama,
    required this.petukangRole,
    required this.tanggalBayar,
    required this.periodeAwal,
    required this.periodeAkhir,
    required this.jumlahHariKerja,
    required this.upahHarian,
    required this.totalUpahKotor,
    required this.sisaKasbonSebelumnya,
    required this.potonganKasbon,
    required this.sisaKasbonSetelahnya,
    required this.totalUpahBersih,
    this.keterangan = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petukangId': petukangId,
      'petukangNama': petukangNama,
      'petukangRole': petukangRole,
      'tanggalBayar': tanggalBayar.toIso8601String(),
      'periodeAwal': periodeAwal.toIso8601String(),
      'periodeAkhir': periodeAkhir.toIso8601String(),
      'jumlahHariKerja': jumlahHariKerja,
      'upahHarian': upahHarian,
      'totalUpahKotor': totalUpahKotor,
      'sisaKasbonSebelumnya': sisaKasbonSebelumnya,
      'potonganKasbon': potonganKasbon,
      'sisaKasbonSetelahnya': sisaKasbonSetelahnya,
      'totalUpahBersih': totalUpahBersih,
      'keterangan': keterangan,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PembayaranUpah.fromMap(Map<String, dynamic> map, String docId) {
    return PembayaranUpah(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      petukangId: map['petukangId'] ?? '',
      petukangNama: map['petukangNama'] ?? '',
      petukangRole: map['petukangRole'] ?? '',
      tanggalBayar: map['tanggalBayar'] != null
          ? DateTime.tryParse(map['tanggalBayar'].toString()) ?? DateTime.now()
          : DateTime.now(),
      periodeAwal: map['periodeAwal'] != null
          ? DateTime.tryParse(map['periodeAwal'].toString()) ?? DateTime.now()
          : DateTime.now(),
      periodeAkhir: map['periodeAkhir'] != null
          ? DateTime.tryParse(map['periodeAkhir'].toString()) ?? DateTime.now()
          : DateTime.now(),
      jumlahHariKerja: (map['jumlahHariKerja'] as num?)?.toInt() ?? 0,
      upahHarian: (map['upahHarian'] as num?)?.toDouble() ?? 0.0,
      totalUpahKotor: (map['totalUpahKotor'] as num?)?.toDouble() ?? 0.0,
      sisaKasbonSebelumnya: (map['sisaKasbonSebelumnya'] as num?)?.toDouble() ?? 0.0,
      potonganKasbon: (map['potonganKasbon'] as num?)?.toDouble() ?? 0.0,
      sisaKasbonSetelahnya: (map['sisaKasbonSetelahnya'] as num?)?.toDouble() ?? 0.0,
      totalUpahBersih: (map['totalUpahBersih'] as num?)?.toDouble() ?? 0.0,
      keterangan: map['keterangan'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
