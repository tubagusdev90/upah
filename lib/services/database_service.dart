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
  final _pembayaranController = StreamController<List<PembayaranUpah>>.broadcast();

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
        _localPetukang.addAll(snapshot.docs.map((doc) => Petukang.fromMap(doc.data(), doc.id)));
        _petukangController.add(List.unmodifiable(_localPetukang));
      }, onError: (e) => debugPrint("Error syncing petukang: $e"));

      _firestore!.collection('absensi').snapshots().listen((snapshot) {
        _localAbsensi.clear();
        _localAbsensi.addAll(snapshot.docs.map((doc) => Absensi.fromMap(doc.data(), doc.id)));
        _absensiController.add(List.unmodifiable(_localAbsensi));
      }, onError: (e) => debugPrint("Error syncing absensi: $e"));

      _firestore!.collection('kasbon').snapshots().listen((snapshot) {
        _localKasbon.clear();
        _localKasbon.addAll(snapshot.docs.map((doc) => Kasbon.fromMap(doc.data(), doc.id)));
        _kasbonController.add(List.unmodifiable(_localKasbon));
      }, onError: (e) => debugPrint("Error syncing kasbon: $e"));

      _firestore!.collection('pembayaran_upah').snapshots().listen((snapshot) {
        _localPembayaran.clear();
        _localPembayaran.addAll(snapshot.docs.map((doc) => PembayaranUpah.fromMap(doc.data(), doc.id)));
        _pembayaranController.add(List.unmodifiable(_localPembayaran));
      }, onError: (e) => debugPrint("Error syncing pembayaran: $e"));

      // Initial one-time fetch to populate immediately
      try {
        final snap = await _firestore!.collection('petukang').get();
        if (snap.docs.isNotEmpty) {
          _localPetukang.clear();
          _localPetukang.addAll(snap.docs.map((doc) => Petukang.fromMap(doc.data(), doc.id)));
        }
      } catch (_) {}
    } catch (e) {
      debugPrint("Firebase init failed or skipped: $e. Falling back to local storage.");
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
        fotoUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb1861593?w=150',
        tanggalJoin: DateTime(now.year, now.month, 1),
        upahHarian: 180000.0,
        sisaKasbon: 350000.0,
        tanggalBayarTerakhir: DateTime(now.year, now.month, 3),
      ),
      Petukang(
        id: p2Id,
        nama: 'Mas Budi Hartono',
        role: WorkerRole.petukang,
        nomorWa: '082198765432',
        fotoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        tanggalJoin: DateTime(now.year, now.month, 1),
        upahHarian: 140000.0,
        sisaKasbon: 100000.0,
        tanggalBayarTerakhir: null,
      ),
      Petukang(
        id: p3Id,
        nama: 'Kang Asep Wahyudi',
        role: WorkerRole.kenek,
        nomorWa: '085712344321',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime(now.year, now.month, 1),
        upahHarian: 100000.0,
        sisaKasbon: 250000.0,
        tanggalBayarTerakhir: null,
      ),
    ]);

    // Seed Kasbon
    _localKasbon.addAll([
      Kasbon(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 2),
        jumlah: 350000.0,
        keterangan: 'Keperluan beli beras keluarga',
        sisa: 350000.0,
        createdAt: DateTime.now(),
      ),
      Kasbon(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p2Id,
        tanggal: DateTime(now.year, now.month, 4),
        jumlah: 100000.0,
        keterangan: 'Bensin motor & pulsa',
        sisa: 100000.0,
        createdAt: DateTime.now(),
      ),
      Kasbon(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p3Id,
        tanggal: DateTime(now.year, now.month, 5),
        jumlah: 250000.0,
        keterangan: 'Beli obat anak sakit',
        sisa: 250000.0,
        createdAt: DateTime.now(),
      ),
    ]);

    // Seed Absensi for current month
    // P1: Hari 1-2 hijau (sudah bayar), hari 3 amber (tgl bayar), hari 4-6 biru (belum bayar), hari 7 merah (libur), hari 8-9 biru
    _localAbsensi.addAll([
      // Absensi(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 1),
        status: AbsenStatus.kerjaSudahBayar,
        upahHarian: 180000.0,
      ),
      // Absensi(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 2),
        status: AbsenStatus.kerjaSudahBayar,
        upahHarian: 180000.0,
      ),
      // Absensi(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 3),
        status: AbsenStatus.tanggalBayarUpah,
        upahHarian: 180000.0,
        keterangan: 'Hari Pembayaran Upah Periode 1',
      ),
      // Absensi(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 4),
        status: AbsenStatus.kerjaBelumBayar,
        upahHarian: 180000.0,
      ),
      // Absensi(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 5),
        status: AbsenStatus.kerjaBelumBayar,
        upahHarian: 180000.0,
      ),
      // Absensi(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 6),
        status: AbsenStatus.kerjaBelumBayar,
        upahHarian: 180000.0,
      ),
      // Absensi(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 7),
        status: AbsenStatus.libur,
        upahHarian: 0.0,
        keterangan: 'Hari Minggu Libur',
      ),
      // Absensi(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 8),
        status: AbsenStatus.kerjaBelumBayar,
        upahHarian: 180000.0,
      ),
      // Absensi(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        petukangId: p1Id,
        tanggal: DateTime(now.year, now.month, 9),
        status: AbsenStatus.kerjaBelumBayar,
        upahHarian: 180000.0,
      ),
    ]);

    // Seed P2 Absensi
    // ... existing P2 absensi code remains unchanged
    // Add new Petukang Ujang with upah increase
    _localPetukang.add(
      Petukang(
        id: 'efd27303-f787-4367-9e1f-ec935605e205',
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),

        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
      ),
    );
    // Note: sebelumnya upah 120.000, diubah menjadi 150.000 efektif 3 Nov 2026.

    for (int day = 1; day <= 8; day++) {
      if (day == 7) {
        _localAbsensi.add(// Removed invalid Absensi entries for Ujang (incorrect positional arguments) that caused compile errors.
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
          petukangId: p2Id,
          tanggal: DateTime(now.year, now.month, day),
          status: AbsenStatus.libur,
          upahHarian: 0,
        ));
      } else {
        _localAbsensi.add(// Removed invalid Absensi entries for Ujang (incorrect positional arguments) that caused compile errors.
        nama: 'Ujang',
        role: WorkerRole.petukang,
        nomorWa: '',
        fotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        tanggalJoin: DateTime.now().subtract(const Duration(days: 180)),
        upahHarian: 150000.0, // upah naik dari 120.000 sejak 3 Nov 2026
        sisaKasbon: 0.0,
        tanggalBayarTerakhir: null,
        tanggalKenaikanUpah: DateTime(2026, 11, 3),
        isAktif: true,
,
          petukangId: p2Id,
          tanggal: DateTime(now.year, now.month, day),
          status: AbsenStatus.kerjaBelumBayar,
          upahHarian: 140000.0,
        ));
      }
    }

    _notifyAll();
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
      return _firestore!
          .collection('petukang')
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => Petukang.fromMap(doc.data(), doc.id)).toList();
            _localPetukang.clear();
            _localPetukang.addAll(list);
            return list;
          });
    }
    // Return stream seeded with current data
    return _petukangController.stream.transform(
      StreamTransformer<List<Petukang>, List<Petukang>>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
      ),
    )..listen(null, onDone: () {});
  }

  // Getters for current in-memory data
  List<Petukang> get currentPetukangList => List.unmodifiable(_localPetukang);
  List<Kasbon> get currentKasbonList => List.unmodifiable(_localKasbon);
  List<PembayaranUpah> get currentPembayaranList => List.unmodifiable(_localPembayaran);
 List.unmodifiable(_localPetukang);

  Future<List<Petukang>> fetchPetukangList() async {
    if (isFirebaseConnected) {
      try {
        final snap = await _firestore!.collection('petukang').get();
        final list = snap.docs.map((doc) => Petukang.fromMap(doc.data(), doc.id)).toList();
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
      await _firestore!.collection('petukang').doc(petukang.id).update(petukang.toMap());
    } else {
      final index = _localPetukang.indexWhere((item) => item.id == petukang.id);
      if (index != -1) {
        _localPetukang[index] = petukang;
        _notifyAll();
      }
    }
  }

  Future<void> updateUpahHarian(String petukangId, double upahBaru, {String? alasan}) async {
    if (isFirebaseConnected) {
      await _firestore!.collection('petukang').doc(petukangId).update({'upahHarian': upahBaru});
      await _firestore!.collection('upah_history').add({
        'petukangId': petukangId,
        'upahBaru': upahBaru,
        'alasan': alasan ?? 'Kenaikan Upah',
        'tanggal': DateTime.now().toIso8601String(),
      });
    } else {
      final index = _localPetukang.indexWhere((p) => p.id == petukangId);
      if (index != -1) {
        _localPetukang[index] = _localPetukang[index].copyWith(upahHarian: upahBaru);
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
          .map((snapshot) => snapshot.docs.map((doc) => Absensi.fromMap(doc.data(), doc.id)).toList());
    }
    return _absensiController.stream.map((list) => list.where((a) => a.petukangId == petukangId).toList());
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

    final abs = // Absensi(
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
      final index = _localAbsensi.indexWhere((a) =>
          a.petukangId == petukangId &&
          a.tanggal.year == normDate.year &&
          a.tanggal.month == normDate.month &&
          a.tanggal.day == normDate.day);

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
      var query = _firestore!.collection('kasbon').orderBy('tanggal', descending: true);
      if (petukangId != null && petukangId.isNotEmpty) {
        return _firestore!
            .collection('kasbon')
            .where('petukangId', isEqualTo: petukangId)
            .snapshots()
            .map((snap) => snap.docs.map((d) => Kasbon.fromMap(d.data(), d.id)).toList());
      }
      return query.snapshots().map((snap) => snap.docs.map((d) => Kasbon.fromMap(d.data(), d.id)).toList());
    }

    return _kasbonController.stream.map((list) {
      if (petukangId != null && petukangId.isNotEmpty) {
        return list.where((k) => k.petukangId == petukangId).toList();
      }
      return list;
    });
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
        _localPetukang[pIndex] = currentP.copyWith(sisaKasbon: currentP.sisaKasbon + jumlah);
      }
      _notifyAll();
    }
  }

  // ==================== PEMBAYARAN UPAH & SLIP ====================

  Stream<List<PembayaranUpah>> getPembayaranList({String? petukangId}) {
    if (isFirebaseConnected) {
      var query = _firestore!.collection('pembayaran_upah').orderBy('createdAt', descending: true);
      if (petukangId != null && petukangId.isNotEmpty) {
        return _firestore!
            .collection('pembayaran_upah')
            .where('petukangId', isEqualTo: petukangId)
            .snapshots()
            .map((s) => s.docs.map((d) => PembayaranUpah.fromMap(d.data(), d.id)).toList());
      }
      return query.snapshots().map((s) => s.docs.map((d) => PembayaranUpah.fromMap(d.data(), d.id)).toList());
    }

    return _pembayaranController.stream.map((list) {
      if (petukangId != null && petukangId.isNotEmpty) {
        return list.where((p) => p.petukangId == petukangId).toList();
      }
      return list;
    });
  }

  /// Menghitung periode pembayaran upah:
  /// Dimulai dari sehari setelah tanggal bayar terakhir (atau tgl join jika belum pernah),
  /// sampai tanggal pembayaran saat ini.
  DateTime hitungPeriodeAwal(Petukang petukang) {
    if (petukang.tanggalBayarTerakhir != null) {
      return DateFormatter.normalize(petukang.tanggalBayarTerakhir!.add(const Duration(days: 1)));
    }
    return DateFormatter.normalize(petukang.tanggalJoin);
  }

  /// Menghitung hari kerja yang belum dibayar (status kerjaBelumBayar / biru) dalam periode tersebut
  List<Absensi> getUnpaidWorkDays(String petukangId, DateTime start, DateTime end) {
    final normStart = DateFormatter.normalize(start);
    final normEnd = DateFormatter.normalize(end);

    return _localAbsensi.where((a) {
      if (a.petukangId != petukangId) return false;
      final aDate = DateFormatter.normalize(a.tanggal);
      final inPeriod = !aDate.isBefore(normStart) && !aDate.isAfter(normEnd);
      return inPeriod && a.status == AbsenStatus.kerjaBelumBayar;
    }).toList();
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
    final sisaKasbonSetelahnya = (sisaKasbonSebelumnya - potonganKasbon).clamp(0.0, double.infinity);
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
      await _firestore!.collection('pembayaran_upah').doc(bayarId).set(pembayaran.toMap());
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
        if (a.petukangId == petukang.id && a.status == AbsenStatus.kerjaBelumBayar) {
          final aDate = DateFormatter.normalize(a.tanggal);
          if (!aDate.isBefore(periodeAwal) && !aDate.isAfter(periodeAkhir)) {
            _localAbsensi[i] = a.copyWith(
              status: AbsenStatus.kerjaSudahBayar,
              pembayaranId: bayarId,
            );
          }
        }
      }

      // 3. Set payment day to amber (tanggalBayarUpah)
      final normTanggalBayar = DateFormatter.normalize(tanggalBayar);
      final paymentAbsIndex = _localAbsensi.indexWhere((a) =>
          a.petukangId == petukang.id &&
          a.tanggal.year == normTanggalBayar.year &&
          a.tanggal.month == normTanggalBayar.month &&
          a.tanggal.day == normTanggalBayar.day);

      final amberAbs = // Absensi(
        id: '${petukang.id}_${DateFormatter.dateKey(normTanggalBayar)}',
        petukangId: petukang.id,
        tanggal: normTanggalBayar,
        status: AbsenStatus.tanggalBayarUpah,
        upahHarian: upahHarian,
        pembayaranId: bayarId,
        keterangan: 'Pembayaran Upah ($jumlahHariKerja hari)',
      );

      if (paymentAbsIndex != -1) {
        _localAbsensi[paymentAbsIndex] = amberAbs;
      } else {
        _localAbsensi.add(amberAbs);
      }

      _notifyAll();
    }

    return pembayaran;
  }
}
