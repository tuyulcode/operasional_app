class TagihanAirFoto {
  final int id;
  final String url;

  TagihanAirFoto({required this.id, required this.url});

  factory TagihanAirFoto.fromJson(Map<String, dynamic> json) {
    return TagihanAirFoto(
      id: json['id'],
      url: json['url'] ?? '',
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
    required this.jumlah,
    this.fotos = const [],
    this.createdAt,
    this.updatedAt,
  });

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
      jumlah: (json['jumlah'] as num).toDouble(),
      fotos: (json['fotos'] as List<dynamic>? ?? [])
          .map((f) => TagihanAirFoto.fromJson(f))
          .toList(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
