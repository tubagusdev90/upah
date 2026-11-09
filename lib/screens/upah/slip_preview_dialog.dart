import 'package:flutter/material.dart';
import '../../models/pembayaran_upah.dart';
import '../../services/pdf_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class SlipPreviewDialog extends StatelessWidget {
  final PembayaranUpah slip;

  const SlipPreviewDialog({super.key, required this.slip});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_long, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Preview Slip Upah'),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Slip Container Visual
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.indigo.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SLIP UPAH PETUKANG',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            Text(
                              'Sistem Manajemen Mandor Proyek',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'NO: ${slip.id.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormatter.format(slip.tanggalBayar),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1.5),

                    // Info Worker & Period
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Nama Petukang', slip.petukangNama, isBold: true),
                          const SizedBox(height: 4),
                          _buildDetailRow('Jabatan / Role', slip.petukangRole),
                          const SizedBox(height: 4),
                          _buildDetailRow(
                            'Periode Upah',
                            '${DateFormatter.formatShort(slip.periodeAwal)} s/d ${DateFormatter.formatShort(slip.periodeAkhir)}',
                          ),
                          const SizedBox(height: 4),
                          _buildDetailRow('Tgl Pembayaran', DateFormatter.format(slip.tanggalBayar)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rincian Pembayaran
                    const Text(
                      'RINCIAN UPAH & POTONGAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Hari kerja & upah kotor
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hari Kerja (${slip.jumlahHariKerja} Hari)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '@ ${CurrencyFormatter.format(slip.upahHarian)}/hari',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(slip.totalUpahKotor),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // Potongan Kasbon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Potongan Kasbon Sebagian',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Kasbon: ${CurrencyFormatter.format(slip.sisaKasbonSebelumnya)} -> Sisa: ${CurrencyFormatter.format(slip.sisaKasbonSetelahnya)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Text(
                          '- ${CurrencyFormatter.format(slip.potonganKasbon)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1.5),

                    // Total Upah Bersih
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade400, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL DITERIMA (BERSIH):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF14532D),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(slip.totalUpahBersih),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF14532D),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (slip.keterangan.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Catatan: ${slip.keterangan}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Tanda Tangan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            const Text('Penerima Upah,', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 40),
                            Text(
                              '( ${slip.petukangNama} )',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Mandor / Bendahara,', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 40),
                            const Text(
                              '( ..................................... )',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.print),
          label: const Text('Cetak / Print Slip PDF'),
          onPressed: () async {
            await PdfService.printSlip(slip);
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
