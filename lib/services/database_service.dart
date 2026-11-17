import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/petukang.dart';
import '../models/absensi.dart';
import '../models/kasbon.dart';
import '../models/pembayaran_upah.dart';
import '../utils/date_formatter.dart';
import 'firebase_options.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const _uuid = Uuid();
  bool _isFirebaseInitialized = false;
  FirebaseFirestore? _firestore;

  bool get isFirebaseConnected => _isFirebaseInitialized && _firestore != null;

  // Local In-Memory Fallback Caches
  final List<Petukang> _localPetukang = [];
  final List<Absensi> _localAbsensi = [];
  final List<Kasbon> _localKasbon = [];
  final List<PembayaranUpah> _localPembayaran = [];

  // Stream Controllers for Local Realtime Updates
  final _petukangController = StreamController<List<Petukang>>.broadcast();
  final _absensiController = StreamController<List<Absensi>>.broadcast();
  final _kasbonController = StreamController<List<Kasbon>>.broadcast();
  final _pembayaranController =
      StreamController<List<PembayaranUpah>>.broadcast();

  Future<void> initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      await Firebase.initializeApp(options: options);
      _firestore = FirebaseFirestore.instance;
      _isFirebaseInitialized = true;
      debugPrint("Firebase initialized successfully with Firestore.");

      // Sync Firestore collections into local memory cache
      _firestore!.collection('petukang').snapshots().listen((snapshot) {
        _localPetukang.clear();
        _localPetukang.addAll(
          snapshot.docs.map((doc) => Petukang.fromMap(doc.data(), doc.id)),
        );
        _petukangController.add(List.unmodifiable(_localPetukang));
      }, onError: (e) => debugPrint("Error syncing petukang: $e"));

      _firestore!.collection('absensi').snapshots().listen((snapshot) {
        _localAbsensi.clear();
        _localAbsensi.addAll(
          snapshot.docs.map((doc) => Absensi.fromMap(doc.data(), doc.id)),
        );
        _absensiController.add(List.unmodifiable(_localAbsensi));
      }, onError: (e) => debugPrint("Error syncing absensi: $e"));

      _firestore!.collection('kasbon').snapshots().listen((snapshot) {
        _localKasbon.clear();
        _localKasbon.addAll(
          snapshot.docs.map((doc) => Kasbon.fromMap(doc.data(), doc.id)),
        );
        _kasbonController.add(List.unmodifiable(_localKasbon));
      }, onError: (e) => debugPrint("Error syncing kasbon: $e"));

      _firestore!.collection('pembayaran_upah').snapshots().listen((snapshot) {
        _localPembayaran.clear();
        _localPembayaran.addAll(
          snapshot.docs.map(
            (doc) => PembayaranUpah.fromMap(doc.data(), doc.id),
          ),
        );
        _pembayaranController.add(List.unmodifiable(_localPembayaran));
      }, onError: (e) => debugPrint("Error syncing pembayaran: $e"));

      // Initial one-time fetch to populate immediately
      try {
        final snap = await _firestore!.collection('petukang').get();
        if (snap.docs.isNotEmpty) {
          _localPetukang.clear();
          _localPetukang.addAll(
            snap.docs.map((doc) => Petukang.fromMap(doc.data(), doc.id)),
          );
        }
      } catch (_) {}
    } catch (e) {
      debugPrint(
        "Firebase init failed or skipped: $e. Falling back to local storage.",
      );
      _isFirebaseInitialized = false;
      _seedMockData();
    }
  }

  void _seedMockData() {
    if (_localPetukang.isNotEmpty) return;

    final now = DateTime.now();
    final p1Id = _uuid.v4();
    final p2Id = _uuid.v4();
    final p3Id = _uuid.v4();

    _localPetukang.addAll([
      Petukang(
        id: p1Id,
        nama: 'Pak Slamet',
        role: WorkerRole.kepalaTukang,
        nomorWa: '081234567890',
        tanggalJoin: DateTime(now.year, now.month, 1),
        upahHarian: 180000,
        sisaKasbon: 350000,
        tanggalBayarTerakhir: DateTime(now.year, now.month, 3),
      ),
      Petukang(
        id: p2Id,
        nama: 'Mas Budi Hartono',
        role: WorkerRole.petukang,
        nomorWa: '082198765432',
        tanggalJoin: DateTime(now.year, now.month, 1),
        upahHarian: 140000,
        sisaKasbon: 100000,
      ),
      Petukang(
        id: p3Id,
        nama: 'Kang Asep Wahyudi',
        role: WorkerRole.kenek,
        nomorWa: '085712344321',
        tanggalJoin: DateTime(now.year, now.month, 1),
        upahHarian: 100000,
        sisaKasbon: 250000,
      ),
    ]);

    _localKasbon.addAll([
      Kasbon(
        id: _uuid.v4(),
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 5),
        jumlah: 350000,
        keterangan: 'Kasbon kebutuhan pribadi',
        sisa: 350000,
        createdAt: now,
      ),
      Kasbon(
        id: _uuid.v4(),
        petukangId: p2Id,
        tanggal: DateTime(now.year, now.month, 4),
        jumlah: 100000,
        keterangan: 'Kasbon kebutuhan keluarga',
        sisa: 100000,
        createdAt: now,
      ),
      Kasbon(
        id: _uuid.v4(),
        petukangId: p3Id,
        tanggal: DateTime(now.year, now.month, 5),
        jumlah: 250000,
        keterangan: 'Kasbon kebutuhan pribadi',
        sisa: 250000,
        createdAt: now,
      ),
    ]);

    // Data contoh absensi untuk bulan berjalan.
    for (final worker in _localPetukang) {
      final daysToSeed = now.day < 9 ? now.day : 9;
      for (int day = 1; day <= daysToSeed; day++) {
        final date = DateTime(now.year, now.month, day);
        final status = day == 3
            ? AbsenStatus.tanggalBayarUpah
            : day <= 2
            ? AbsenStatus.kerjaSudahBayar
            : AbsenStatus.kerjaBelumBayar;
        _localAbsensi.add(
          Absensi(
            id: '${worker.id}_${DateFormatter.dateKey(date)}',
            petukangId: worker.id,
            tanggal: date,
            status: status,
            upahHarian: status == AbsenStatus.libur ? 0 : worker.upahHarian,
            keterangan: status == AbsenStatus.tanggalBayarUpah
                ? 'Pembayaran upah'
                : null,
          ),
        );
      }
    }

    _notifyAll();
  }

  Stream<T> _streamWithInitial<T>(T initialValue, Stream<T> source) {
    return Stream<T>.multi((controller) {
      controller.add(initialValue);
      final subscription = source.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  void _notifyAll() {
    _petukangController.add(List.unmodifiable(_localPetukang));
    _absensiController.add(List.unmodifiable(_localAbsensi));
    _kasbonController.add(List.unmodifiable(_localKasbon));
    _pembayaranController.add(List.unmodifiable(_localPembayaran));
  }

  // ==================== PETUKANG CRUD ====================

  Stream<List<Petukang>> getPetukangList() {
    if (isFirebaseConnected) {
      return _firestore!.collection('petukang').snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((doc) => Petukang.fromMap(doc.data(), doc.id))
            .toList();
        _localPetukang.clear();
        _localPetukang.addAll(list);
        return list;
      });
    }
    return _streamWithInitial(
      List<Petukang>.unmodifiable(_localPetukang),
      _petukangController.stream,
    );
  }

  // Getters for current in-memory data
  List<Petukang> get currentPetukangList => List.unmodifiable(_localPetukang);
  List<Kasbon> get currentKasbonList => List.unmodifiable(_localKasbon);
  List<PembayaranUpah> get currentPembayaranList =>
      List.unmodifiable(_localPembayaran);

  Future<List<Petukang>> fetchPetukangList() async {
    if (isFirebaseConnected) {
      try {
        final snap = await _firestore!.collection('petukang').get();
        final list = snap.docs
            .map((doc) => Petukang.fromMap(doc.data(), doc.id))
            .toList();
        _localPetukang.clear();
        _localPetukang.addAll(list);
        return list;
      } catch (e) {
        debugPrint("Error fetchPetukangList: $e");
      }
    }
    return _localPetukang;
  }

  Future<void> addPetukang(Petukang petukang) async {
    final newId = petukang.id.isNotEmpty ? petukang.id : _uuid.v4();
    final p = petukang.copyWith(id: newId);

    if (isFirebaseConnected) {
      await _firestore!.collection('petukang').doc(newId).set(p.toMap());
    } else {
      _localPetukang.add(p);
      _notifyAll();
    }
  }

  Future<void> updatePetukang(Petukang petukang) async {
    if (isFirebaseConnected) {
      await _firestore!
          .collection('petukang')
          .doc(petukang.id)
          .update(petukang.toMap());
    } else {
      final index = _localPetukang.indexWhere((item) => item.id == petukang.id);
      if (index != -1) {
        _localPetukang[index] = petukang;
        _notifyAll();
      }
    }
  }

  Future<void> updateUpahHarian(
    String petukangId,
    double upahBaru, {
    String? alasan,
  }) async {
    if (isFirebaseConnected) {
      await _firestore!.collection('petukang').doc(petukangId).update({
        'upahHarian': upahBaru,
        'tanggalKenaikanUpah': DateTime.now().toIso8601String(),
      });
      await _firestore!.collection('upah_history').add({
        'petukangId': petukangId,
        'upahBaru': upahBaru,
        'alasan': alasan ?? 'Kenaikan Upah',
        'tanggal': DateTime.now().toIso8601String(),
      });
    } else {
      final index = _localPetukang.indexWhere((p) => p.id == petukangId);
      if (index != -1) {
        _localPetukang[index] = _localPetukang[index].copyWith(
          upahHarian: upahBaru,
          tanggalKenaikanUpah: DateTime.now(),
        );
        _notifyAll();
      }
    }
  }

  Future<void> deletePetukang(String id) async {
    if (isFirebaseConnected) {
      await _firestore!.collection('petukang').doc(id).delete();
    } else {
      _localPetukang.removeWhere((p) => p.id == id);
      _localAbsensi.removeWhere((a) => a.petukangId == id);
      _localKasbon.removeWhere((k) => k.petukangId == id);
      _localPembayaran.removeWhere((p) => p.petukangId == id);
      _notifyAll();
    }
  }

  // ==================== ABSENSI ====================

  Stream<List<Absensi>> getAbsensiForPetukang(String petukangId) {
    if (isFirebaseConnected) {
      return _firestore!
          .collection('absensi')
          .where('petukangId', isEqualTo: petukangId)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Absensi.fromMap(doc.data(), doc.id))
                .toList(),
          );
    }
    return _streamWithInitial(
      _localAbsensi.where((a) => a.petukangId == petukangId).toList(),
      _absensiController.stream.map(
        (list) => list.where((a) => a.petukangId == petukangId).toList(),
      ),
    );
  }

  List<Absensi> getAbsensiSync(String petukangId) {
    return _localAbsensi.where((a) => a.petukangId == petukangId).toList();
  }

  Future<void> setAbsensiStatus({
    required String petukangId,
    required DateTime date,
    required AbsenStatus status,
    required double upahHarian,
    String? keterangan,
  }) async {
    final normDate = DateFormatter.normalize(date);
    final docId = '${petukangId}_${DateFormatter.dateKey(normDate)}';

    final abs = Absensi(
      id: docId,
      petukangId: petukangId,
      tanggal: normDate,
      status: status,
      upahHarian: status == AbsenStatus.libur ? 0.0 : upahHarian,
      keterangan: keterangan,
    );

    if (isFirebaseConnected) {
      await _firestore!.collection('absensi').doc(docId).set(abs.toMap());
    } else {
      final index = _localAbsensi.indexWhere(
        (a) =>
            a.petukangId == petukangId &&
            a.tanggal.year == normDate.year &&
            a.tanggal.month == normDate.month &&
            a.tanggal.day == normDate.day,
      );

      if (index != -1) {
        _localAbsensi[index] = abs;
      } else {
        _localAbsensi.add(abs);
      }
      _notifyAll();
    }
  }

  // ==================== KASBON ====================

  Stream<List<Kasbon>> getKasbonList(String? petukangId) {
    if (isFirebaseConnected) {
      var query = _firestore!
          .collection('kasbon')
          .orderBy('tanggal', descending: true);
      if (petukangId != null && petukangId.isNotEmpty) {
        return _firestore!
            .collection('kasbon')
            .where('petukangId', isEqualTo: petukangId)
            .snapshots()
            .map(
              (snap) =>
                  snap.docs.map((d) => Kasbon.fromMap(d.data(), d.id)).toList(),
            );
      }
      return query.snapshots().map(
        (snap) => snap.docs.map((d) => Kasbon.fromMap(d.data(), d.id)).toList(),
      );
    }

    List<Kasbon> filter(List<Kasbon> list) {
      if (petukangId != null && petukangId.isNotEmpty) {
        return list.where((k) => k.petukangId == petukangId).toList();
      }
      return list;
    }

    return _streamWithInitial(
      filter(_localKasbon),
      _kasbonController.stream.map(filter),
    );
  }

  Future<void> addKasbon({
    required String petukangId,
    required double jumlah,
    required String keterangan,
    required DateTime tanggal,
  }) async {
    final kasbonId = _uuid.v4();
    final kasbon = Kasbon(
      id: kasbonId,
      petukangId: petukangId,
      tanggal: tanggal,
      jumlah: jumlah,
      keterangan: keterangan,
      sisa: jumlah,
      createdAt: DateTime.now(),
    );

    if (isFirebaseConnected) {
      await _firestore!.collection('kasbon').doc(kasbonId).set(kasbon.toMap());
      // Update worker sisa kasbon
      await _firestore!.collection('petukang').doc(petukangId).update({
        'sisaKasbon': FieldValue.increment(jumlah),
      });
    } else {
      _localKasbon.insert(0, kasbon);
      final pIndex = _localPetukang.indexWhere((p) => p.id == petukangId);
      if (pIndex != -1) {
        final currentP = _localPetukang[pIndex];
        _localPetukang[pIndex] = currentP.copyWith(
          sisaKasbon: currentP.sisaKasbon + jumlah,
        );
      }
      _notifyAll();
    }
  }

  // ==================== PEMBAYARAN UPAH & SLIP ====================

  Stream<List<PembayaranUpah>> getPembayaranList({String? petukangId}) {
    if (isFirebaseConnected) {
      var query = _firestore!
          .collection('pembayaran_upah')
          .orderBy('createdAt', descending: true);
      if (petukangId != null && petukangId.isNotEmpty) {
        return _firestore!
            .collection('pembayaran_upah')
            .where('petukangId', isEqualTo: petukangId)
            .snapshots()
            .map(
              (s) => s.docs
                  .map((d) => PembayaranUpah.fromMap(d.data(), d.id))
                  .toList(),
            );
      }
      return query.snapshots().map(
        (s) =>
            s.docs.map((d) => PembayaranUpah.fromMap(d.data(), d.id)).toList(),
      );
    }

    List<PembayaranUpah> filter(List<PembayaranUpah> list) {
      if (petukangId != null && petukangId.isNotEmpty) {
        return list.where((p) => p.petukangId == petukangId).toList();
      }
      return list;
    }

    return _streamWithInitial(
      filter(_localPembayaran),
      _pembayaranController.stream.map(filter),
    );
  }

  /// Menghitung periode pembayaran upah:
  /// Dimulai dari sehari setelah tanggal bayar terakhir (atau tgl join jika belum pernah),
  /// sampai tanggal pembayaran saat ini.
  DateTime hitungPeriodeAwal(Petukang petukang) {
    if (petukang.tanggalBayarTerakhir != null) {
      return DateFormatter.normalize(
        petukang.tanggalBayarTerakhir!.add(const Duration(days: 1)),
      );
    }
    return DateFormatter.normalize(petukang.tanggalJoin);
  }

  /// Menghitung hari kerja yang belum dibayar (status kerjaBelumBayar / biru) dalam periode tersebut
  
List<Absensi> getUnpaidWorkDays(
  String petukangId,
  DateTime start,
  DateTime end,
) {
  final normStart = DateFormatter.normalize(start);
  final normEnd = DateFormatter.normalize(end);

  final result = _localAbsensi.where((a) {
    if (a.petukangId != petukangId) return false;

    final aDate = DateFormatter.normalize(a.tanggal);
    final inPeriod =
        !aDate.isBefore(normStart) && !aDate.isAfter(normEnd);

    // Hanya hari Masuk yang belum dibayar.
    // Status Libur dan tanggal pembayaran tidak dihitung.
    return inPeriod &&
        a.status == AbsenStatus.kerjaBelumBayar;
  }).toList();

  result.sort((a, b) => a.tanggal.compareTo(b.tanggal));

  return result;
}


  /// Memproses pembayaran upah:
  /// - Catat slip pembayaran upah
  /// - Kurangi sisa kasbon petukang sebesar potonganKasbon
  /// - Update tanggalBayarTerakhir petukang menjadi tanggalBayar
  /// - Ubah status hari kerja yang belum dibayar (biru) menjadi sudah dibayar (hijau)
  /// - Tandai tanggal pembayaran upah dengan status amber
  Future<PembayaranUpah> prosesPembayaranUpah({
    required Petukang petukang,
    required DateTime tanggalBayar,
    required DateTime periodeAwal,
    required DateTime periodeAkhir,
    required int jumlahHariKerja,
    required double upahHarian,
    required double totalUpahKotor,
    required double potonganKasbon,
    required String keterangan,
  }) async {
    final sisaKasbonSebelumnya = petukang.sisaKasbon;
    if (potonganKasbon < 0 ||
        potonganKasbon > sisaKasbonSebelumnya ||
        potonganKasbon > totalUpahKotor) {
      throw ArgumentError(
        'Potongan kasbon tidak boleh melebihi sisa kasbon atau total upah kotor.',
      );
    }
    if (periodeAkhir.isBefore(periodeAwal) ||
        DateFormatter.normalize(periodeAkhir) !=
            DateFormatter.normalize(tanggalBayar)) {
      throw ArgumentError(
        'Tanggal akhir periode harus sama dengan tanggal pembayaran.',
      );
    }
    final sisaKasbonSetelahnya = (sisaKasbonSebelumnya - potonganKasbon)
        .clamp(0.0, double.infinity)
        .toDouble();
    final totalUpahBersih = totalUpahKotor - potonganKasbon;

    final bayarId = _uuid.v4();
    final pembayaran = PembayaranUpah(
      id: bayarId,
      petukangId: petukang.id,
      petukangNama: petukang.nama,
      petukangRole: petukang.role.label,
      tanggalBayar: DateFormatter.normalize(tanggalBayar),
      periodeAwal: DateFormatter.normalize(periodeAwal),
      periodeAkhir: DateFormatter.normalize(periodeAkhir),
      jumlahHariKerja: jumlahHariKerja,
      upahHarian: upahHarian,
      totalUpahKotor: totalUpahKotor,
      sisaKasbonSebelumnya: sisaKasbonSebelumnya,
      potonganKasbon: potonganKasbon,
      sisaKasbonSetelahnya: sisaKasbonSetelahnya,
      totalUpahBersih: totalUpahBersih,
      keterangan: keterangan,
      createdAt: DateTime.now(),
    );

    if (isFirebaseConnected) {
      await _firestore!
          .collection('pembayaran_upah')
          .doc(bayarId)
          .set(pembayaran.toMap());
      await _firestore!.collection('petukang').doc(petukang.id).update({
        'sisaKasbon': sisaKasbonSetelahnya,
        'tanggalBayarTerakhir': tanggalBayar.toIso8601String(),
      });
      // Mark unpaid days as paid
      final absensiDocs = await _firestore!
          .collection('absensi')
          .where('petukangId', isEqualTo: petukang.id)
          .where('status', isEqualTo: 'kerjaBelumBayar')
          .get();

      final batch = _firestore!.batch();
      for (var doc in absensiDocs.docs) {
        final a = Absensi.fromMap(doc.data(), doc.id);
        final aDate = DateFormatter.normalize(a.tanggal);
        if (!aDate.isBefore(periodeAwal) && !aDate.isAfter(periodeAkhir)) {
          batch.update(doc.reference, {
            'status': 'kerjaSudahBayar',
            'pembayaranId': bayarId,
          });
        }
      }
      // Add or update the payment date as amber (tanggalBayarUpah)
      // Add or update the payment date as amber (tanggalBayarUpah)
      final paymentDateDocId = '${petukang.id}_${DateFormatter.dateKey(tanggalBayar)}';
      batch.set(
        _firestore!.collection('absensi').doc(paymentDateDocId),
        {
          'id': paymentDateDocId,
          'petukangId': petukang.id,
          'tanggal': DateFormatter.dateKey(tanggalBayar),
          'status': 'tanggalBayarUpah',
          'upahHarian': upahHarian,
          'pembayaranId': bayarId,
          'keterangan': 'Pembayaran Upah ($jumlahHariKerja hari)',
        },
      );
      await batch.commit();
    } else {
      // Local Database update
      _localPembayaran.insert(0, pembayaran);

      // 1. Update petukang
      final pIndex = _localPetukang.indexWhere((p) => p.id == petukang.id);
      if (pIndex != -1) {
        _localPetukang[pIndex] = _localPetukang[pIndex].copyWith(
          sisaKasbon: sisaKasbonSetelahnya,
          tanggalBayarTerakhir: tanggalBayar,
        );
      }

      // 2. Update absensi in period: kerjaBelumBayar (blue) -> kerjaSudahBayar (green)
      for (int i = 0; i < _localAbsensi.length; i++) {
        final a = _localAbsensi[i];
        if (a.petukangId == petukang.id &&
            a.status == AbsenStatus.kerjaBelumBayar) {
          final aDate = DateFormatter.normalize(a.tanggal);
          if (!aDate.isBefore(periodeAwal) && !aDate.isAfter(periodeAkhir)) {
            _localAbsensi[i] = a.copyWith(
              status: AbsenStatus.kerjaSudahBayar,
              pembayaranId: bayarId,
            );
          }
        }
      }


      _notifyAll();
    }

    return pembayaran;
  }
}
