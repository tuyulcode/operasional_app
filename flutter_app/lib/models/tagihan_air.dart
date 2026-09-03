class TagihanAirFoto {
  final int id;
  final String? url;
  final String? photoStatus; // "ok" | "not_found" | null (data lama sebelum fix API)

  const TagihanAirFoto({
    required this.id,
    this.url,
    this.photoStatus,
  });

  /// Apakah foto ini bisa ditampilkan (url ada & status bukan not_found)
  bool get isAvailable =>
      url != null && url!.isNotEmpty && photoStatus != 'not_found';

  factory TagihanAirFoto.fromJson(Map<String, dynamic> json) {
    return TagihanAirFoto(
      id: json['id'],
      url: json['url'],
      photoStatus: json['photo_status'],
    );
  }
}

class TagihanAir {
  final int id;
  final int titikMeterId;
  final String titikMeterNama;
  final int? areaId;
  final String areaNama;
  final String? lokasiFlowMeter;
  final String periode; // "2026-08"
  final String periodeLabel; // "Agustus 2026"
  final double meterLalu;
  final double meterIni;
  final double meterFaktor;
  final double tarif;
  final double pemakaian;
  final double ppnPersentase;
  final double ppnNominal;
  final double jumlah;
  final List<TagihanAirFoto> fotos;
  final String? createdAt;
  final String? updatedAt;

  TagihanAir({
    required this.id,
    required this.titikMeterId,
    required this.titikMeterNama,
    this.areaId,
    required this.areaNama,
    this.lokasiFlowMeter,
    required this.periode,
    required this.periodeLabel,
    required this.meterLalu,
    required this.meterIni,
    required this.meterFaktor,
    required this.tarif,
    required this.pemakaian,
    this.ppnPersentase = 0,
    this.ppnNominal = 0,
    required this.jumlah,
    this.fotos = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Total sebelum PPN ditambahkan (pemakaian * tarif) — turunan, bukan
  /// disimpan terpisah di backend, dihitung balik dari jumlah - ppnNominal
  /// supaya selalu konsisten dengan apa yang benar-benar tersimpan.
  double get jumlahSebelumPpn => jumlah - ppnNominal;

  /// True kalau tagihan ini kena PPN (persentase > 0).
  bool get kenaPpn => ppnPersentase > 0;

  factory TagihanAir.fromJson(Map<String, dynamic> json) {
    return TagihanAir(
      id: json['id'],
      titikMeterId: json['titik_meter_id'],
      titikMeterNama: json['titik_meter_nama'] ?? '-',
      areaId: json['area_id'],
      areaNama: json['area_nama'] ?? '-',
      lokasiFlowMeter: json['lokasi_flow_meter'],
      periode: json['periode'],
      periodeLabel: json['periode_label'] ?? '',
      meterLalu: (json['meter_lalu'] as num).toDouble(),
      meterIni: (json['meter_ini'] as num).toDouble(),
      meterFaktor: (json['meter_faktor'] as num).toDouble(),
      tarif: (json['tarif'] as num).toDouble(),
      pemakaian: (json['pemakaian'] as num).toDouble(),
      ppnPersentase: (json['ppn_persentase'] as num?)?.toDouble() ?? 0,
      ppnNominal: (json['ppn_nominal'] as num?)?.toDouble() ?? 0,
      jumlah: (json['jumlah'] as num).toDouble(),
      fotos: (json['fotos'] as List<dynamic>? ?? [])
          .map((f) => TagihanAirFoto.fromJson(f))
          .toList(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}