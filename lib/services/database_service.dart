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


  /// Membayar kasbon secara langsung, terpisah dari proses pembayaran upah.
  ///
  /// Pembayaran dialokasikan ke kasbon yang paling lama terlebih dahulu.
  /// Setiap pembayaran dicatat pada koleksi `pembayaran_kasbon`.
  Future<void> bayarKasbon({
    required String petukangId,
    required double jumlah,
    required DateTime tanggalBayar,
  }) async {
    if (jumlah <= 0) {
      throw Exception('Jumlah pembayaran kasbon harus lebih dari 0.');
    }

    final tanggalNormal = DateTime(
      tanggalBayar.year,
      tanggalBayar.month,
      tanggalBayar.day,
    );
    final pembayaranId = _uuid.v4();
    final sekarang = DateTime.now();

    DateTime parseTanggalKasbon(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime(1970);
    }

    if (isFirebaseConnected) {
      final firestore = _firestore!;
      final workerRef = firestore.collection('petukang').doc(petukangId);
      final kasbonQuery = firestore
          .collection('kasbon')
          .where('petukangId', isEqualTo: petukangId);

      // Ambil daftar referensi kasbon terlebih dahulu. Nilai dokumen dibaca
      // kembali di dalam transaction agar saldo yang dipakai adalah nilai terbaru.
      final daftarKasbon = await kasbonQuery.get();
      final paymentRef = firestore
          .collection('pembayaran_kasbon')
          .doc(pembayaranId);

      await firestore.runTransaction((transaction) async {
        final workerSnapshot = await transaction.get(workerRef);
        if (!workerSnapshot.exists) {
          throw Exception('Data petukang tidak ditemukan.');
        }

        final kasbonTerbaru = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final item in daftarKasbon.docs) {
          final snapshot = await transaction.get(item.reference);
          if (snapshot.exists) kasbonTerbaru.add(snapshot);
        }

        kasbonTerbaru.sort((a, b) {
          final tanggalA = parseTanggalKasbon(a.data()?['tanggal']);
          final tanggalB = parseTanggalKasbon(b.data()?['tanggal']);
          final compareTanggal = tanggalA.compareTo(tanggalB);
          if (compareTanggal != 0) return compareTanggal;
          return a.id.compareTo(b.id);
        });

        double totalSisa = 0;
        for (final doc in kasbonTerbaru) {
          final data = doc.data() ?? {};
          final sisa = (data['sisa'] as num?)?.toDouble() ??
              (data['jumlah'] as num?)?.toDouble() ??
              0.0;
          totalSisa += sisa < 0 ? 0 : sisa;
        }

        if (totalSisa <= 0) {
          throw Exception('Petukang ini tidak memiliki sisa kasbon.');
        }
        if (jumlah > totalSisa) {
          throw Exception(
            'Jumlah pembayaran melebihi sisa kasbon '
            '(${totalSisa.toStringAsFixed(0)}).',
          );
        }

        // Alokasikan pembayaran ke kasbon tertua terlebih dahulu.
        double sisaPembayaran = jumlah;
        final rincian = <Map<String, dynamic>>[];

        for (final doc in kasbonTerbaru) {
          if (sisaPembayaran <= 0) break;

          final data = doc.data() ?? {};
          final sisaKasbon = (data['sisa'] as num?)?.toDouble() ??
              (data['jumlah'] as num?)?.toDouble() ??
              0.0;

          if (sisaKasbon <= 0) continue;

          final dibayar = sisaPembayaran < sisaKasbon
              ? sisaPembayaran
              : sisaKasbon;
          final sisaBaru = (sisaKasbon - dibayar)
              .clamp(0.0, double.infinity)
              .toDouble();

          transaction.update(doc.reference, {
            'sisa': sisaBaru,
            'updatedAt': sekarang.toIso8601String(),
          });

          rincian.add({
            'kasbonId': doc.id,
            'jumlahDibayar': dibayar,
          });
          sisaPembayaran -= dibayar;
        }

        final saldoAkhir = (totalSisa - jumlah)
            .clamp(0.0, double.infinity)
            .toDouble();

        transaction.update(workerRef, {
          'sisaKasbon': saldoAkhir,
        });

        transaction.set(paymentRef, {
          'id': pembayaranId,
          'petukangId': petukangId,
          'tanggalBayar': tanggalNormal.toIso8601String(),
          'jumlah': jumlah,
          'rincian': rincian,
          'metode': 'pembayaran_langsung',
          'keterangan': 'Pembayaran kasbon langsung',
          'createdAt': sekarang.toIso8601String(),
        });
      });
    } else {
      final indexPetukang =
          _localPetukang.indexWhere((p) => p.id == petukangId);
      if (indexPetukang == -1) {
        throw Exception('Data petukang tidak ditemukan.');
      }

      final kasbonPetukang = _localKasbon
          .where((k) => k.petukangId == petukangId)
          .toList()
        ..sort((a, b) {
          final compareTanggal = a.tanggal.compareTo(b.tanggal);
          return compareTanggal != 0
              ? compareTanggal
              : a.id.compareTo(b.id);
        });

      final totalSisa = kasbonPetukang.fold<double>(
        0,
        (total, item) => total + item.sisa,
      );

      if (totalSisa <= 0) {
        throw Exception('Petukang ini tidak memiliki sisa kasbon.');
      }
      if (jumlah > totalSisa) {
        throw Exception(
          'Jumlah pembayaran melebihi sisa kasbon '
          '(${totalSisa.toStringAsFixed(0)}).',
        );
      }

      double sisaPembayaran = jumlah;
      for (final kasbon in kasbonPetukang) {
        if (sisaPembayaran <= 0) break;
        if (kasbon.sisa <= 0) continue;

        final dibayar = sisaPembayaran < kasbon.sisa
            ? sisaPembayaran
            : kasbon.sisa;
        final indexKasbon =
            _localKasbon.indexWhere((item) => item.id == kasbon.id);

        if (indexKasbon != -1) {
          _localKasbon[indexKasbon] = kasbon.copyWith(
            sisa: (kasbon.sisa - dibayar)
                .clamp(0.0, double.infinity)
                .toDouble(),
          );
        }
        sisaPembayaran -= dibayar;
      }

      final petukang = _localPetukang[indexPetukang];
      _localPetukang[indexPetukang] = petukang.copyWith(
        sisaKasbon: (totalSisa - jumlah)
            .clamp(0.0, double.infinity)
            .toDouble(),
      );
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

  /// Awal periode adalah sehari setelah akhir periode kerja yang terakhir dibayar.
  /// Tanggal transfer/pembayaran tidak digunakan sebagai penentu awal periode.
  DateTime hitungPeriodeAwal(Petukang petukang) {
  final tanggalAkhir =
      petukang.tanggalAkhirPeriodeTerakhir ??
      petukang.tanggalBayarTerakhir;

  if (tanggalAkhir != null) {
    return DateFormatter.normalize(
      tanggalAkhir.add(const Duration(days: 1)),
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
  /// - Simpan tanggal pembayaran dan akhir periode kerja secara terpisah
  /// - Ubah hanya absensi kerjaBelumBayar dalam rentang periode menjadi sudah dibayar
  /// - Tidak mengubah status absensi pada tanggal pembayaran di luar periode
  
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
  // =====================================================
  // 1. NORMALISASI TANGGAL
  // =====================================================

  final tanggalBayarNormal =
      DateFormatter.normalize(tanggalBayar);

  final periodeAwalNormal =
      DateFormatter.normalize(periodeAwal);

  final periodeAkhirNormal =
      DateFormatter.normalize(periodeAkhir);

  // =====================================================
  // 2. VALIDASI PERIODE
  // =====================================================

  if (periodeAwalNormal.isAfter(periodeAkhirNormal)) {
    throw ArgumentError(
      'Tanggal awal periode tidak boleh melewati '
      'tanggal akhir periode.',
    );
  }

  // Tanggal pembayaran boleh setelah tanggal akhir periode,
  // tetapi tidak boleh sebelum tanggal akhir periode.
  if (tanggalBayarNormal.isBefore(periodeAkhirNormal)) {
    throw ArgumentError(
      'Tanggal pembayaran tidak boleh lebih awal '
      'dari tanggal akhir periode.',
    );
  }

  if (jumlahHariKerja <= 0) {
    throw ArgumentError(
      'Jumlah hari kerja minimal 1 hari.',
    );
  }

  if (upahHarian < 0 || totalUpahKotor < 0) {
    throw ArgumentError(
      'Upah harian dan total upah tidak boleh negatif.',
    );
  }

  // Pastikan perhitungan upah konsisten.
  final totalSeharusnya = jumlahHariKerja * upahHarian;

  if ((totalUpahKotor - totalSeharusnya).abs() > 1) {
    throw ArgumentError(
      'Total upah kotor tidak sesuai dengan '
      'jumlah hari kerja x upah harian.',
    );
  }

  // =====================================================
  // 3. VALIDASI KASBON
  // =====================================================

  final sisaKasbonSebelumnya = petukang.sisaKasbon;

  if (potonganKasbon < 0 ||
      potonganKasbon > sisaKasbonSebelumnya ||
      potonganKasbon > totalUpahKotor) {
    throw ArgumentError(
      'Potongan kasbon tidak boleh melebihi '
      'sisa kasbon atau total upah kotor.',
    );
  }

  final sisaKasbonSetelahnya =
      (sisaKasbonSebelumnya - potonganKasbon)
          .clamp(0.0, double.infinity)
          .toDouble();

  final totalUpahBersih =
      totalUpahKotor - potonganKasbon;

  // =====================================================
  // 4. BUAT DATA PEMBAYARAN
  // =====================================================

  final bayarId = _uuid.v4();

  final pembayaran = PembayaranUpah(
    id: bayarId,
    petukangId: petukang.id,
    petukangNama: petukang.nama,
    petukangRole: petukang.role.label,
    tanggalBayar: tanggalBayarNormal,
    periodeAwal: periodeAwalNormal,
    periodeAkhir: periodeAkhirNormal,
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

  // =====================================================
  // 5. PROSES FIREBASE FIRESTORE
  // =====================================================

  if (isFirebaseConnected) {
    final firestore = _firestore!;

    // Ambil absensi Masuk yang belum dibayar.
    final absensiDocs = await firestore
        .collection('absensi')
        .where(
          'petukangId',
          isEqualTo: petukang.id,
        )
        .where(
          'status',
          isEqualTo: 'kerjaBelumBayar',
        )
        .get();

    // Siapkan batch Firestore.
    final batch = firestore.batch();

    // -------------------------------------------------
    // A. SIMPAN RIWAYAT PEMBAYARAN
    // -------------------------------------------------

    batch.set(
      firestore
          .collection('pembayaran_upah')
          .doc(bayarId),
      pembayaran.toMap(),
    );

    // -------------------------------------------------
    // B. UPDATE DATA PETUKANG
    // -------------------------------------------------

    batch.update(
      firestore
          .collection('petukang')
          .doc(petukang.id),
      {
        'sisaKasbon': sisaKasbonSetelahnya,

        // Tanggal uang dibayarkan.
        'tanggalBayarTerakhir':
            tanggalBayarNormal.toIso8601String(),

        // Tanggal terakhir pekerjaan yang sudah dibayar.
        'tanggalAkhirPeriodeTerakhir':
            periodeAkhirNormal.toIso8601String(),
      },
    );

    // -------------------------------------------------
    // C. UPDATE ABSENSI DALAM PERIODE
    // -------------------------------------------------

    int jumlahAbsensiDiperbarui = 0;

    for (final doc in absensiDocs.docs) {
      final data = doc.data();

      final tanggalValue = data['tanggal'];

      DateTime? tanggalAbsensi;

      if (tanggalValue is Timestamp) {
        tanggalAbsensi = tanggalValue.toDate();
      } else if (tanggalValue is DateTime) {
        tanggalAbsensi = tanggalValue;
      } else if (tanggalValue != null) {
        tanggalAbsensi =
            DateTime.tryParse(tanggalValue.toString());
      }

      if (tanggalAbsensi == null) continue;

      final tanggalNormal =
          DateFormatter.normalize(tanggalAbsensi);

      final dalamPeriode =
          !tanggalNormal.isBefore(periodeAwalNormal) &&
          !tanggalNormal.isAfter(periodeAkhirNormal);

      if (dalamPeriode) {
        batch.update(
          doc.reference,
          {
            'status': 'kerjaSudahBayar',
            'pembayaranId': bayarId,
          },
        );

        jumlahAbsensiDiperbarui++;
      }
    }

    // -------------------------------------------------
    // D. COMMIT FIRESTORE
    // -------------------------------------------------

    await batch.commit();

    debugPrint('================================');
    debugPrint('PEMBAYARAN UPAH BERHASIL');
    debugPrint('Petukang: ${petukang.nama}');
    debugPrint('Tanggal bayar: $tanggalBayarNormal');
    debugPrint('Periode awal: $periodeAwalNormal');
    debugPrint('Periode akhir: $periodeAkhirNormal');
    debugPrint('Hari kerja: $jumlahHariKerja');
    debugPrint(
      'Absensi diperbarui: $jumlahAbsensiDiperbarui',
    );
    debugPrint('Upah kotor: $totalUpahKotor');
    debugPrint('Potongan kasbon: $potonganKasbon');
    debugPrint('Upah bersih: $totalUpahBersih');
    debugPrint('================================');
  }

  // =====================================================
  // 6. PROSES LOCAL DATABASE
  // =====================================================

  else {
    // Simpan riwayat pembayaran.
    _localPembayaran.insert(0, pembayaran);

    // Update data petukang.
    final pIndex = _localPetukang.indexWhere(
      (p) => p.id == petukang.id,
    );

    if (pIndex != -1) {
      _localPetukang[pIndex] =
          _localPetukang[pIndex].copyWith(
        sisaKasbon: sisaKasbonSetelahnya,
        tanggalBayarTerakhir: tanggalBayarNormal,
        tanggalAkhirPeriodeTerakhir:
            periodeAkhirNormal,
      );
    }

    // Update hanya absensi Masuk yang belum dibayar
    // dan berada dalam rentang periode.
    for (int i = 0; i < _localAbsensi.length; i++) {
      final absensi = _localAbsensi[i];

      if (absensi.petukangId != petukang.id) {
        continue;
      }

      if (absensi.status !=
          AbsenStatus.kerjaBelumBayar) {
        continue;
      }

      final tanggalAbsensi =
          DateFormatter.normalize(absensi.tanggal);

      final dalamPeriode =
          !tanggalAbsensi.isBefore(periodeAwalNormal) &&
          !tanggalAbsensi.isAfter(periodeAkhirNormal);

      if (dalamPeriode) {
        _localAbsensi[i] = absensi.copyWith(
          status: AbsenStatus.kerjaSudahBayar,
          pembayaranId: bayarId,
        );
      }
    }

    _notifyAll();
  }

  // =====================================================
  // 7. KEMBALIKAN DATA SLIP
  // =====================================================

  return pembayaran;
}




/// Menjalankan perbaikan riwayat pembayaran upah secara langsung.
  ///
  /// Dipanggil oleh tombol "Perbaikan Upah Petukang" pada screen.
  /// Tidak menggunakan mode simulasi.
  Future<List<String>> perbaikiRiwayatPembayaranPetukang() async {
    if (!isFirebaseConnected) {
      throw Exception('Firebase belum terhubung.');
    }

    return migrasiRiwayatPembayaranNovember2026(simpan: true);
  }

  /// MIGRASI RIWAYAT PEMBAYARAN UPAH NOVEMBER 2026
///
/// Jalankan pertama kali dengan simpan: false untuk simulasi.
/// Setelah hasil pemeriksaan benar, jalankan dengan simpan: true.

Future<List<String>> migrasiRiwayatPembayaranNovember2026({
  bool simpan = false,
}) async {
  if (!isFirebaseConnected) {
    throw Exception('Firebase belum terhubung.');
  }

  final firestore = _firestore!;
  final laporan = <String>[];

  DateTime normal(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? parseTanggal(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return normal(value.toDate());
    if (value is DateTime) return normal(value);

    return DateTime.tryParse(value.toString()) == null
        ? null
        : normal(DateTime.parse(value.toString()));
  }

  double angka(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String tanggalKey(DateTime d) {
    final t = normal(d);
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  DateTime tanggal(int day, int month) =>
      DateTime(2026, month, day);

  final workersSnapshot =
      await firestore.collection('petukang').get();

  final configs = [
    {
      'nama': 'ujang',
      'tanggalBayar': [
        tanggal(16, 10),
        tanggal(18, 10),
        tanggal(25, 10),
        tanggal(3, 11),
        tanggal(10, 11),
        tanggal(17, 11),
      ],
      'awalPertama': tanggal(16, 10),
      'upah': 130000.0,
      'upahBaru': 150000.0,
      'tanggalNaik': tanggal(4, 11),
      'akhirKhusus': <String, DateTime>{},
    },
    {
      'nama': 'mang jasun',
      'tanggalBayar': [
        tanggal(3, 11),
        tanggal(10, 11),
        tanggal(18, 11),
      ],
      'awalPertama': null,
      'upah': 180000.0,
      'akhirKhusus': {
        tanggalKey(tanggal(18, 11)): tanggal(17, 11),
      },
    },
    {
      'nama': 'pak jajang',
      'tanggalBayar': [
        tanggal(17, 11),
      ],
      'awalPertama': null,
      'upah': 180000.0,
      'akhirKhusus': <String, DateTime>{},
    },
    {
      'nama': 'hasan',
      'tanggalBayar': [
        tanggal(17, 11),
      ],
      'awalPertama': null,
      'upah': 150000.0,
      'akhirKhusus': <String, DateTime>{},
    },
  ];

  final batch = firestore.batch();
  var jumlahOperasi = 0;

  void cekBatasBatch() {
    if (jumlahOperasi >= 450) {
      throw Exception(
        'Operasi migrasi melebihi batas aman batch. '
        'Pisahkan migrasi menjadi beberapa tahap.',
      );
    }
  }

  for (final config in configs) {
    final nama = config['nama'] as String;
    final tanggalBayar =
        config['tanggalBayar'] as List<DateTime>;

    final workerMatches = workersSnapshot.docs.where((doc) {
      final workerName =
          (doc.data()['nama'] ?? '').toString().toLowerCase();
      return workerName.contains(nama);
    }).toList();

    if (workerMatches.length != 1) {
      throw Exception(
        'Petukang "$nama" ditemukan ${workerMatches.length} data. '
        'Pastikan nama petukang unik.',
      );
    }

    final workerDoc = workerMatches.first;
    final worker = workerDoc.data();
    final workerId = workerDoc.id;
    final workerNama = worker['nama']?.toString() ?? nama;
    final workerRole = worker['role']?.toString() ?? '';

    final absensiSnapshot = await firestore
        .collection('absensi')
        .where('petukangId', isEqualTo: workerId)
        .get();

    final absensiDocs = absensiSnapshot.docs.toList();

    DateTime? tanggalAbsensi(Map<String, dynamic> data) {
      return parseTanggal(data['tanggal']);
    }

    final tanggalTersedia = absensiDocs
        .map((doc) => tanggalAbsensi(doc.data()))
        .whereType<DateTime>()
        .toList()
      ..sort();

    final awalPertama =
        config['awalPertama'] as DateTime? ??
        (tanggalTersedia.isNotEmpty
            ? tanggalTersedia.first
            : parseTanggal(worker['tanggalJoin']) ??
                tanggalBayar.first);

    final paymentsSnapshot = await firestore
        .collection('pembayaran_upah')
        .where('petukangId', isEqualTo: workerId)
        .get();

    final existingPayments = paymentsSnapshot.docs;

    DateTime previousEnd =
        awalPertama.subtract(const Duration(days: 1));

    double saldoKasbonBerjalan = 0;

    for (final bayarDate in tanggalBayar) {
      final keyBayar = tanggalKey(bayarDate);

      final akhirKhusus =
          config['akhirKhusus'] as Map<String, DateTime>;

      final periodeAkhir =
          akhirKhusus[keyBayar] ?? bayarDate;

      final periodeAwal =
          previousEnd.add(const Duration(days: 1));

      if (periodeAkhir.isBefore(periodeAwal)) {
        throw Exception(
          'Periode tidak valid untuk $workerNama: '
          '${tanggalKey(periodeAwal)} sampai '
          '${tanggalKey(periodeAkhir)}',
        );
      }

      // Cari pembayaran yang sudah ada berdasarkan tanggal bayar.
      final paymentMatches = existingPayments.where((doc) {
        final date = parseTanggal(doc.data()['tanggalBayar']);
        return date != null && tanggalKey(date) == keyBayar;
      }).toList();

      if (paymentMatches.length > 1) {
        throw Exception(
          'Duplikat riwayat pembayaran $workerNama tanggal $keyBayar.',
        );
      }

      final existingDoc =
          paymentMatches.isEmpty ? null : paymentMatches.first;
      final oldPayment = existingDoc?.data() ?? {};

      // Ambil hari kerja yang berada dalam periode.
      final hariKerja = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      // Data historis Ujang tanggal 16 Oktober tidak memiliki dokumen
      // absensi karena tanggal tersebut sekaligus tanggal pembayaran.
      // Tanggal ini tetap dihitung sebagai satu hari kerja dan dibayar.
      final isPembayaranPertamaUjang = nama == 'ujang' &&
          keyBayar == tanggalKey(tanggal(16, 10));
      final absensiUjang16 = isPembayaranPertamaUjang
          ? absensiDocs.where((doc) {
              final date = tanggalAbsensi(doc.data());
              return date != null &&
                  tanggalKey(date) == tanggalKey(tanggal(16, 10));
            }).toList()
          : <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      if (absensiUjang16.length > 1) {
        throw Exception(
          'Ditemukan lebih dari satu absensi Ujang tanggal 16 Oktober 2026.',
        );
      }

      for (final doc in absensiDocs) {
        final data = doc.data();
        final date = tanggalAbsensi(data);

        if (date == null) continue;

        final inPeriod =
            !date.isBefore(periodeAwal) &&
            !date.isAfter(periodeAkhir);

        if (!inPeriod) continue;

        final status = data['status']?.toString();

        if (status == 'kerjaBelumBayar' ||
            status == 'kerjaSudahBayar') {
          hariKerja.add(doc);
        }
      }

      final absensiKhususUjang16BelumTerhitung =
          isPembayaranPertamaUjang &&
          !hariKerja.any((doc) {
            final date = tanggalAbsensi(doc.data());
            return date != null &&
                tanggalKey(date) == tanggalKey(tanggal(16, 10));
          });

      if (hariKerja.isEmpty &&
          !absensiKhususUjang16BelumTerhitung) {
        throw Exception(
          'Tidak ditemukan absensi kerja untuk $workerNama '
          'periode ${tanggalKey(periodeAwal)} - '
          '${tanggalKey(periodeAkhir)}. '
          'Migrasi dihentikan agar tidak membuat nominal nol.',
        );
      }

      // Hitung upah setiap tanggal.
      double totalKotor =
          absensiKhususUjang16BelumTerhitung ? 130000.0 : 0.0;
      final tarifPerHari = <double>[];

      for (final doc in hariKerja) {
        final data = doc.data();
        final date = tanggalAbsensi(data)!;

        double tarif;

        if (nama == 'ujang') {
          tarif = date.isBefore(tanggal(4, 11))
              ? 130000
              : 150000;
        } else {
          tarif = config['upah'] as double;
        }

        tarifPerHari.add(tarif);
        totalKotor += tarif;
      }

      final jumlahHari = hariKerja.length +
          (absensiKhususUjang16BelumTerhitung ? 1 : 0);
      final upahRataRata = totalKotor / jumlahHari;

      // Potongan dari dokumen lama dipertahankan.
      double potongan =
          angka(oldPayment['potonganKasbon']);

      double sisaSebelumnya =
          oldPayment.containsKey('sisaKasbonSebelumnya')
              ? angka(oldPayment['sisaKasbonSebelumnya'])
              : saldoKasbonBerjalan;

      // Ketentuan khusus Ujang:
      // Kasbon Rp600.000 tanggal 1 November
      // dipotong pada pembayaran 3 November.
      if (nama == 'ujang' &&
          keyBayar == tanggalKey(tanggal(3, 11))) {
        potongan = 600000;
        sisaSebelumnya = 600000;
      }

      if (potongan < 0 ||
          potongan > sisaSebelumnya ||
          potongan > totalKotor) {
        throw Exception(
          'Potongan kasbon tidak valid untuk $workerNama '
          'tanggal $keyBayar.',
        );
      }

      final sisaSetelahnya =
          (sisaSebelumnya - potongan)
              .clamp(0.0, double.infinity)
              .toDouble();

      final totalBersih = totalKotor - potongan;

      final paymentId = existingDoc?.id ?? _uuid.v4();

      final paymentData = <String, dynamic>{
        'id': paymentId,
        'petukangId': workerId,
        'petukangNama': workerNama,
        'petukangRole': workerRole,
        'tanggalBayar': bayarDate.toIso8601String(),
        'periodeAwal': periodeAwal.toIso8601String(),
        'periodeAkhir': periodeAkhir.toIso8601String(),
        'jumlahHariKerja': jumlahHari,
        'upahHarian': upahRataRata,
        'totalUpahKotor': totalKotor,
        'sisaKasbonSebelumnya': sisaSebelumnya,
        'potonganKasbon': potongan,
        'sisaKasbonSetelahnya': sisaSetelahnya,
        'totalUpahBersih': totalBersih,
        'keterangan': oldPayment['keterangan'] ??
            'Migrasi riwayat pembayaran upah',
        'createdAt': oldPayment['createdAt'] ??
            DateTime.now().toIso8601String(),
      };

      laporan.add(
        '$workerNama | $keyBayar | '
        '${tanggalKey(periodeAwal)} - ${tanggalKey(periodeAkhir)} | '
        '$jumlahHari hari | '
        'Kotor Rp${totalKotor.toStringAsFixed(0)} | '
        'Kasbon Rp${potongan.toStringAsFixed(0)} | '
        'Bersih Rp${totalBersih.toStringAsFixed(0)}',
      );

      if (simpan) {
        cekBatasBatch();

        batch.set(
          firestore.collection('pembayaran_upah').doc(paymentId),
          paymentData,
        );
        jumlahOperasi++;

        // Hanya hari kerja di dalam periode yang menjadi lunas.
        for (final doc in hariKerja) {
          cekBatasBatch();

          final date = tanggalAbsensi(doc.data())!;

          final tarif = nama == 'ujang'
              ? (date.isBefore(tanggal(4, 11)) ? 130000.0 : 150000.0)
              : config['upah'] as double;

          batch.update(doc.reference, {
            'status': 'kerjaSudahBayar',
            'pembayaranId': paymentId,
            'upahHarian': tarif,
          });

          jumlahOperasi++;
        }

        // Buat/perbaiki absensi Ujang 16 Oktober sebagai hari kerja
        // yang sudah dibayar, terhubung ke slip pembayaran tanggal 16.
        if (absensiKhususUjang16BelumTerhitung) {
          cekBatasBatch();
          final absensiDoc = absensiUjang16.isNotEmpty
              ? absensiUjang16.first.reference
              : firestore.collection('absensi').doc(
                  '${workerId}_${tanggalKey(tanggal(16, 10))}',
                );
          batch.set(
            absensiDoc,
            {
              'id': absensiDoc.id,
              'petukangId': workerId,
              'tanggal': tanggal(16, 10).toIso8601String().substring(0, 10),
              'status': 'kerjaSudahBayar',
              'upahHarian': 130000.0,
              'pembayaranId': paymentId,
              'keterangan': absensiUjang16.isNotEmpty
                  ? (absensiUjang16.first.data()['keterangan'] ??
                      'Kerja dan dibayar pada 16 Oktober 2026')
                  : 'Kerja dan dibayar pada 16 Oktober 2026',
            },
          );
          jumlahOperasi++;
        }
      }

      saldoKasbonBerjalan = sisaSetelahnya;
      previousEnd = periodeAkhir;
    }

    if (simpan) {
      cekBatasBatch();

      final lastPaymentDate = tanggalBayar.last;
      final lastPeriodEnd =
          (config['akhirKhusus'] as Map<String, DateTime>)[
              tanggalKey(lastPaymentDate)] ??
          lastPaymentDate;

      final updateWorker = <String, dynamic>{
        'tanggalBayarTerakhir': lastPaymentDate.toIso8601String(),
        'tanggalAkhirPeriodeTerakhir':
            lastPeriodEnd.toIso8601String(),
        'upahHarian': nama == 'ujang'
            ? 150000.0
            : config['upah'],
      };

      if (nama == 'ujang') {
        updateWorker['tanggalKenaikanUpah'] =
            tanggal(4, 11).toIso8601String();
      }

      batch.update(workerDoc.reference, updateWorker);
      jumlahOperasi++;
    }
  }

  // Pastikan kasbon Ujang 1 November Rp600.000
  // tercatat sudah lunas.
  final ujangDoc = workersSnapshot.docs.where((doc) {
    return (doc.data()['nama'] ?? '')
        .toString()
        .toLowerCase()
        .contains('ujang');
  }).single;

  final kasbonSnapshot = await firestore
      .collection('kasbon')
      .where('petukangId', isEqualTo: ujangDoc.id)
      .get();

  final kasbonUjang = kasbonSnapshot.docs.where((doc) {
    final data = doc.data();
    final date = parseTanggal(data['tanggal']);

    return date != null &&
        tanggalKey(date) == tanggalKey(tanggal(1, 11)) &&
        angka(data['jumlah']) == 600000;
  }).toList();

  if (kasbonUjang.length != 1) {
    throw Exception(
      'Kasbon Ujang tanggal 1 November Rp600.000 '
      'harus ditemukan tepat satu dokumen. '
      'Ditemukan: ${kasbonUjang.length}.',
    );
  }

  if (simpan) {
    cekBatasBatch();

    batch.update(kasbonUjang.first.reference, {
      'sisa': 0,
    });

    await batch.commit();
  }

  laporan.insert(
    0,
    simpan
        ? 'MIGRASI BERHASIL. Total operasi: $jumlahOperasi'
        : 'SIMULASI SAJA. Belum ada data Firestore yang diubah.',
  );

  for (final item in laporan) {
    debugPrint(item);
  }

  return laporan;
}


}
