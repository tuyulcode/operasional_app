class AktivitasTerakhir {
  final int id;
  final String titikMeter;
  final String area;
  final String periode;
  final double jumlah;
  final String status;
  final String updatedAt;

  AktivitasTerakhir({
    required this.id,
    required this.titikMeter,
    required this.area,
    required this.periode,
    required this.jumlah,
    required this.status,
    required this.updatedAt,
  });

  factory AktivitasTerakhir.fromJson(Map<String, dynamic> json) {
    return AktivitasTerakhir(
      id: json['id'],
      titikMeter: json['titik_meter'] ?? '-',
      area: json['area'] ?? '-',
      periode: json['periode'] ?? '',
      jumlah: (json['jumlah'] as num).toDouble(),
      status: json['status'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class ProgressInput {
  final int sudahInput;
  final int totalTarget;
  final int persen;

  ProgressInput({
    required this.sudahInput,
    required this.totalTarget,
    required this.persen,
  });

  factory ProgressInput.fromJson(Map<String, dynamic> json) {
    return ProgressInput(
      sudahInput: json['sudah_input'] ?? 0,
      totalTarget: json['total_target'] ?? 0,
      persen: json['persen'] ?? 0,
    );
  }
}

class DashboardStats {
  final double totalTagihan;
  final double totalPemakaian;
  final int totalArea;
  final int totalTitikMeter;
  final ProgressInput progress;
  final String periodeLabel;
  final List<AktivitasTerakhir> aktivitasTerakhir;

  DashboardStats({
    required this.totalTagihan,
    required this.totalPemakaian,
    required this.totalArea,
    required this.totalTitikMeter,
    required this.progress,
    required this.periodeLabel,
    required this.aktivitasTerakhir,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalTagihan: (json['total_tagihan'] as num).toDouble(),
      totalPemakaian: (json['total_pemakaian'] as num).toDouble(),
      totalArea: json['total_area'] ?? 0,
      totalTitikMeter: json['total_titik_meter'] ?? 0,
      progress: ProgressInput.fromJson(json['progress'] ?? {}),
      periodeLabel: json['periode_label'] ?? '',
      aktivitasTerakhir: (json['aktivitas_terakhir'] as List<dynamic>? ?? [])
          .map((a) => AktivitasTerakhir.fromJson(a))
          .toList(),
    );
  }
}
