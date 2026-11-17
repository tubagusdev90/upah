
import 'package:flutter/material.dart';

import '../../models/absensi.dart';
import '../../models/kasbon.dart';
import '../../models/pembayaran_upah.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/theme.dart';

class SlipPreviewDialog extends StatelessWidget {
  final PembayaranUpah slip;

   SlipPreviewDialog({
    super.key,
    required this.slip,



  });

        String _formatDateWithDay(DateTime date) {
        const namaHari = [
          'Senin',
          'Selasa',
          'Rabu',
          'Kamis',
          'Jumat',
          'Sabtu',
          'Minggu',
        ];

        final hari = namaHari[date.weekday - 1];
        final tanggal = date.day.toString().padLeft(2, '0');
        final bulan = date.month.toString().padLeft(2, '0');

        return '$hari, $tanggal/$bulan/${date.year}';
      }


  final DatabaseService _db =  _DatabaseServiceHolder().service;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final slipNumber = slip.id.length >= 8
        ? slip.id.substring(0, 8).toUpperCase()
        : slip.id.toUpperCase();

    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: screenHeight * 0.90,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildDataContent(slipNumber),
              ),
            ),

            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Preview Slip Upah',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataContent(String slipNumber) {
    final absensiAwal = _db.getAbsensiSync(slip.petukangId);

    final kasbonAwal = _db.currentKasbonList
        .where((item) => item.petukangId == slip.petukangId)
        .toList();

    return StreamBuilder<List<Absensi>>(
      stream: _db.getAbsensiForPetukang(slip.petukangId),
      initialData: absensiAwal,
      builder: (context, absensiSnapshot) {
        if (absensiSnapshot.hasError) {
          return const Text('Gagal memuat data absensi.');
        }

        final absensi = _filterAbsensi(
          absensiSnapshot.data ?? [],
        );

        return StreamBuilder<List<Kasbon>>(
          stream: _db.getKasbonList(slip.petukangId),
          initialData: kasbonAwal,
          builder: (context, kasbonSnapshot) {
            if (kasbonSnapshot.hasError) {
              return const Text('Gagal memuat data kasbon.');
            }

            final kasbon = _filterKasbon(
              kasbonSnapshot.data ?? [],
            );

            return _buildSlipContent(
              slipNumber: slipNumber,
              absensi: absensi,
              kasbon: kasbon,
            );
          },
        );
      },
    );
  }

  List<Absensi> _filterAbsensi(List<Absensi> data) {
    final start = DateFormatter.normalize(slip.periodeAwal);
    final end = DateFormatter.normalize(slip.periodeAkhir);

    final result = data.where((item) {
      final date = DateFormatter.normalize(item.tanggal);

      final inPeriod =
          !date.isBefore(start) && !date.isAfter(end);

      final isAttendance =
          item.status == AbsenStatus.kerjaSudahBayar ||
          item.status == AbsenStatus.kerjaBelumBayar ||
          item.status == AbsenStatus.libur;

      return inPeriod && isAttendance;
    }).toList();

    result.sort((a, b) => a.tanggal.compareTo(b.tanggal));

    return result;
  }

  List<Kasbon> _filterKasbon(List<Kasbon> data) {
    final end = DateFormatter.normalize(slip.periodeAkhir);

    final result = data.where((item) {
      final date = DateFormatter.normalize(item.tanggal);
      return !date.isAfter(end);
    }).toList();

    result.sort((a, b) => a.tanggal.compareTo(b.tanggal));

    return result;
  }

  Widget _buildSlipContent({
    required String slipNumber,
    required List<Absensi> absensi,
    required List<Kasbon> kasbon,
  }) {
    final jumlahMasuk = absensi
        .where(
          (item) =>
              item.status == AbsenStatus.kerjaSudahBayar ||
              item.status == AbsenStatus.kerjaBelumBayar,
        )
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: AppTheme.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSlipTitle(slipNumber),

          const Divider(height: 28),

          _buildSectionTitle('INFORMASI PETUKANG'),
          const SizedBox(height: 10),

          _buildDetailRow(
            'Nama Petukang',
            slip.petukangNama,
            bold: true,
          ),
          _buildDetailRow(
            'Jabatan / Role',
            slip.petukangRole,
          ),
          _buildDetailRow(
            'Periode Upah',
            '${DateFormatter.formatShort(slip.periodeAwal)} s/d '
                '${DateFormatter.formatShort(slip.periodeAkhir)}',
          ),
          _buildDetailRow(
            'Tanggal Bayar',
            DateFormatter.format(slip.tanggalBayar),
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('DATA MASUK KERJA'),
          const SizedBox(height: 8),

          _buildAttendanceTable(absensi),

          const SizedBox(height: 20),

          _buildSectionTitle('DATA KASBON'),
          const SizedBox(height: 8),

          _buildKasbonTable(kasbon),

          const SizedBox(height: 20),

          _buildSectionTitle('RINGKASAN KEHADIRAN'),
          const SizedBox(height: 10),

          _buildDetailRow(
            'Jumlah Masuk',
            '$jumlahMasuk Hari',
            bold: true,
          ),
          _buildDetailRow(
            'Upah Harian',
            CurrencyFormatter.format(slip.upahHarian),
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('RINCIAN PEMBAYARAN'),
          const SizedBox(height: 10),

          _buildCalculationRow(
            'Total Upah',
            CurrencyFormatter.format(slip.totalUpahKotor),
          ),

          _buildCalculationRow(
            'Jumlah Masuk x Upah Harian',
            '${slip.jumlahHariKerja} x '
                '${CurrencyFormatter.format(slip.upahHarian)}',
          ),

          const Divider(height: 20),

          _buildCalculationRow(
            'Total Potongan',
            CurrencyFormatter.format(slip.potonganKasbon),
            color: Colors.red.shade700,
          ),

          const SizedBox(height: 14),

          _buildTotal(),

          if (jumlahMasuk != slip.jumlahHariKerja) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan: Jumlah absensi Masuk yang tercatat ($jumlahMasuk hari) '
              'berbeda dengan jumlah hari kerja pada transaksi pembayaran '
              '(${slip.jumlahHariKerja} hari). Perhitungan pembayaran '
              'mengikuti data transaksi slip.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade800,
              ),
            ),
          ],

          if (slip.keterangan.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNote(),
          ],

          const SizedBox(height: 28),

          _buildSignatures(),
        ],
      ),
    );
  }

  Widget _buildSlipTitle(String slipNumber) {
    return Column(
      children: [
        Text(
          'SLIP UPAH PETUKANG',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.navy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'NO: $slipNumber',
            style: TextStyle(
              color: AppTheme.blue,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormatter.format(slip.tanggalBayar),
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.blue,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildAttendanceTable(List<Absensi> data) {
    if (data.isEmpty) {
      return _buildEmptyData('Belum ada data absensi pada periode ini.');
    }

    return _buildTable(
      headers: const ['No.', 'Tanggal', 'Status', 'Ket.'],
      rows: [
        for (int i = 0; i < data.length; i++)
          [
            '${i + 1}',
           _formatDateWithDay(data[i].tanggal),
            data[i].status == AbsenStatus.libur
                ? 'Libur'
                : 'Masuk',
            data[i].keterangan?.trim().isNotEmpty == true
                ? data[i].keterangan!
                : '-',
          ],
      ],
      flexes: const [1, 3, 2, 3],
    );
  }

  Widget _buildKasbonTable(List<Kasbon> data) {
    if (data.isEmpty) {
      return _buildEmptyData('Belum ada riwayat kasbon.');
    }

    return _buildTable(
      headers: const ['No.', 'Tanggal', 'Jumlah Kasbon'],
      rows: [
        for (int i = 0; i < data.length; i++)
          [
            '${i + 1}',
            _formatDateWithDay(data[i].tanggal),
            CurrencyFormatter.format(data[i].jumlah),
          ],
      ],
      // Tabel kasbon
flexes: const [1, 3, 4],
    );
  }

  Widget _buildTable({
    required List<String> headers,
    required List<List<String>> rows,
    required List<int> flexes,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 510,
            child: Table(
              columnWidths: {
                for (int i = 0; i < flexes.length; i++)
                  i: FlexColumnWidth(flexes[i].toDouble()),
              },
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: AppTheme.border,
                ),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                  ),
                  children: [
                    for (final header in headers)
                      _tableCell(
                        header,
                        isHeader: true,
                      ),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    children: [
                      for (final value in row)
                        _tableCell(value),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableCell(
    String value, {
    bool isHeader = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 7,
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader
              ? FontWeight.bold
              : FontWeight.normal,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyData(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const Text(':  '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: bold
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(
          color: Colors.green.shade300,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'TOTAL DITERIMA (BERSIH)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green.shade800,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(slip.totalUpahBersih),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green.shade900,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${CurrencyFormatter.format(slip.totalUpahKotor)} - '
            '${CurrencyFormatter.format(slip.potonganKasbon)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green.shade800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Pembayaran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            slip.keterangan,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatures() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSignatureColumn(
            title: 'Penerima Upah,',
            name: slip.petukangNama,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSignatureColumn(
            title: 'Mandor / Bendahara,',
            name: '________________________',
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureColumn({
    required String title,
    required String name,
  }) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 48),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                try {
                  await PdfService.printSlip(slip);
                } catch (e) {
                  debugPrint('Gagal mencetak slip: $e');

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mencetak slip: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Cetak PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatabaseServiceHolder {
  const _DatabaseServiceHolder();

  DatabaseService get service => DatabaseService();
}
