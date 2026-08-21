class TitikMeter {
  final int id;
  final int areaId;
  final String nama;
  final String? lokasiFlowMeter;
  final double meterFaktor;
  final double tarifHarga;
  final String status;
  final String areaNama;

  TitikMeter({
    required this.id,
    required this.areaId,
    required this.nama,
    this.lokasiFlowMeter,
    required this.meterFaktor,
    required this.tarifHarga,
    required this.status,
    required this.areaNama,
  });

  factory TitikMeter.fromJson(Map<String, dynamic> json) {
    return TitikMeter(
      id: json['id'],
      areaId: json['area_id'],
      nama: json['nama'],
      lokasiFlowMeter: json['lokasi_flow_meter'],
      meterFaktor: (json['meter_faktor'] as num).toDouble(),
      tarifHarga: (json['tarif_harga'] as num).toDouble(),
      status: json['status'],
      areaNama: json['area_nama'] ?? '-',
    );
  }
}
