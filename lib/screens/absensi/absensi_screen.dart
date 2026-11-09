import 'package:flutter/material.dart';
import '../../models/petukang.dart';
import '../../models/absensi.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class AbsensiScreen extends StatefulWidget {
  final String? initialPetukangId;

  const AbsensiScreen({super.key, this.initialPetukangId});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  final DatabaseService _db = DatabaseService();

  late DateTime _currentMonth;
  String? _selectedPetukangId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedPetukangId = widget.initialPetukangId;
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Absensi Petukang'),
      ),
      body: StreamBuilder<List<Petukang>>(
        stream: _db.getPetukangList(),
        initialData: _db.currentPetukangList,
        builder: (context, petukangSnapshot) {
          final petukangList = petukangSnapshot.data ?? [];

          if (petukangList.isEmpty) {
            return const Center(child: Text('Belum ada data petukang. Tambahkan petukang terlebih dahulu.'));
          }

          // Ensure selected petukang
          final petukang = petukangList.firstWhere(
            (p) => p.id == _selectedPetukangId,
            orElse: () => petukangList.first,
          );
          _selectedPetukangId = petukang.id;

          return StreamBuilder<List<Absensi>>(
            stream: _db.getAbsensiForPetukang(petukang.id),
            initialData: _db.getAbsensiSync(petukang.id),
            builder: (context, absensiSnapshot) {
              final absensiList = absensiSnapshot.data ?? [];

              // Map absensi by day dateKey
              final Map<String, Absensi> absensiMap = {};
              for (var a in absensiList) {
                absensiMap[DateFormatter.dateKey(a.tanggal)] = a;
              }

              // Compute month stats
              int countBiru = 0;
              int countHijau = 0;
              int countAmber = 0;
              int countMerah = 0;

              final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
              for (int day = 1; day <= daysInMonth; day++) {
                final d = DateTime(_currentMonth.year, _currentMonth.month, day);
                final key = DateFormatter.dateKey(d);
                final abs = absensiMap[key];
                if (abs != null) {
                  switch (abs.status) {
                    case AbsenStatus.kerjaBelumBayar:
                      countBiru++;
                      break;
                    case AbsenStatus.kerjaSudahBayar:
                      countHijau++;
                      break;
                    case AbsenStatus.tanggalBayarUpah:
                      countAmber++;
                      break;
                    case AbsenStatus.libur:
                      countMerah++;
                      break;
                  }
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Petukang Selector Card
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: petukang.fotoUrl.isNotEmpty
                                      ? NetworkImage(petukang.fotoUrl)
                                      : null,
                                  child: petukang.fotoUrl.isEmpty ? const Icon(Icons.person) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedPetukangId,
                                      isExpanded: true,
                                      items: petukangList.map((p) {
                                        return DropdownMenuItem(
                                          value: p.id,
                                          child: Text(
                                            '${p.nama} (${p.role.label}) - ${CurrencyFormatter.format(p.upahHarian)}/hari',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newId) {
                                        if (newId != null) {
                                          setState(() => _selectedPetukangId = newId);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Month Navigation Bar
                        Card(
                          elevation: 0,
                          color: Colors.indigo.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.indigo),
                                  onPressed: _prevMonth,
                                ),
                                Text(
                                  DateFormatter.monthYear(_currentMonth),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade900,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.indigo),
                                  onPressed: _nextMonth,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Legend
                        _buildLegend(),
                        const SizedBox(height: 12),

                        // Monthly Summary Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStat(
                                'Belum Dibayar',
                                '$countBiru Hari',
                                CurrencyFormatter.format(countBiru * petukang.upahHarian),
                                const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStat(
                                'Sudah Dibayar',
                                '$countHijau Hari',
                                CurrencyFormatter.format(countHijau * petukang.upahHarian),
                                const Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStat(
                                'Tgl Bayar',
                                '$countAmber Kali',
                                'Selesai',
                                const Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStat(
                                'Libur',
                                '$countMerah Hari',
                                'Tidak masuk',
                                const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Calendar Grid
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Day headers (Senin - Minggu)
                                Row(
                                  children: const [
                                    Expanded(child: Center(child: Text('Sen', style: TextStyle(fontWeight: FontWeight.bold)))),
                                    Expanded(child: Center(child: Text('Sel', style: TextStyle(fontWeight: FontWeight.bold)))),
                                    Expanded(child: Center(child: Text('Rab', style: TextStyle(fontWeight: FontWeight.bold)))),
                                    Expanded(child: Center(child: Text('Kam', style: TextStyle(fontWeight: FontWeight.bold)))),
                                    Expanded(child: Center(child: Text('Jum', style: TextStyle(fontWeight: FontWeight.bold)))),
                                    Expanded(child: Center(child: Text('Sab', style: TextStyle(fontWeight: FontWeight.bold)))),
                                    Expanded(child: Center(child: Text('Min', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)))),
                                  ],
                                ),
                                const Divider(height: 20),

                                // Day Cells
                                _buildCalendarGrid(petukang, absensiMap),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tip
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Klik tanggal pada kalender untuk mengubah status kehadiran (Kerja, Libur, dll).',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _legendItem(const Color(0xFF2563EB), 'Biru: Kerja (Upah Belum Dibayar)'),
            _legendItem(const Color(0xFF16A34A), 'Hijau: Kerja (Sudah Dibayar)'),
            _legendItem(const Color(0xFFD97706), 'Amber: Tanggal Pembayaran'),
            _legendItem(const Color(0xFFDC2626), 'Merah: Libur / Tidak Masuk'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: TextStyle(fontSize: 9, color: Colors.grey.shade600), maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(Petukang petukang, Map<String, Absensi> absensiMap) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    // weekday: 1 = Monday, 7 = Sunday
    final startWeekday = firstDayOfMonth.weekday; // 1 to 7

    List<Widget> rows = [];
    List<Widget> currentWeek = [];

    // Empty cells before first day
    for (int i = 1; i < startWeekday; i++) {
      currentWeek.add(const Expanded(child: SizedBox(height: 52)));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final key = DateFormatter.dateKey(date);
      final abs = absensiMap[key];

      Color cellBg = Colors.transparent;
      Color textColor = Colors.black87;
      Color borderColor = Colors.grey.shade200;
      String statusIndicator = '';

      if (abs != null) {
        cellBg = abs.status.color.withOpacity(0.18);
        borderColor = abs.status.color;
        textColor = abs.status.color;
        switch (abs.status) {
          case AbsenStatus.kerjaBelumBayar:
            statusIndicator = 'Kerja';
            break;
          case AbsenStatus.kerjaSudahBayar:
            statusIndicator = 'Lunas';
            break;
          case AbsenStatus.tanggalBayarUpah:
            statusIndicator = 'Bayar';
            break;
          case AbsenStatus.libur:
            statusIndicator = 'Libur';
            break;
        }
      } else if (date.weekday == 7) {
        // Default Sunday is red
        textColor = Colors.red.shade400;
      }

      currentWeek.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: InkWell(
              onTap: () => _openAbsenDialog(petukang, date, abs),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: cellBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: abs != null ? 1.5 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: abs != null ? FontWeight.bold : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (statusIndicator.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: abs!.status.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusIndicator,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      if (date.weekday == 7) {
        rows.add(Row(children: List.from(currentWeek)));
        currentWeek.clear();
      }
    }

    // Trailing empty cells
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(const Expanded(child: SizedBox(height: 52)));
      }
      rows.add(Row(children: List.from(currentWeek)));
    }

    return Column(children: rows);
  }

  void _openAbsenDialog(Petukang petukang, DateTime date, Absensi? currentAbs) async {
    AbsenStatus selectedStatus = currentAbs?.status ??
        (date.weekday == 7 ? AbsenStatus.libur : AbsenStatus.kerjaBelumBayar);
    final noteController = TextEditingController(text: currentAbs?.keterangan ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit_calendar, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(DateFormatter.formatWithDay(date)),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Petukang: ${petukang.nama}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Tarif Upah: ${CurrencyFormatter.format(petukang.upahHarian)}/hari',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 14),
                    const Text('Pilih Status Kehadiran:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

                    // 4 Options
                    ...AbsenStatus.values.map((status) {
                      final isSelected = selectedStatus == status;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? status.color.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? status.color : Colors.grey.shade300,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: RadioListTile<AbsenStatus>(
                          dense: true,
                          value: status,
                          groupValue: selectedStatus,
                          activeColor: status.color,
                          title: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  status.label,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? status.color : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedStatus = val);
                            }
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan / Keterangan (Opsional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedStatus.color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Simpan Kehadiran'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _db.setAbsensiStatus(
        petukangId: petukang.id,
        date: date,
        status: selectedStatus,
        upahHarian: petukang.upahHarian,
        keterangan: noteController.text.trim(),
      );
    }
  }
}
