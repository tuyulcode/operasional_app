class Area {
  final int id;
  final String nama;
  final String? alamat;
  final bool kenaPpn;

  Area({
    required this.id,
    required this.nama,
    this.alamat,
    this.kenaPpn = false,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'],
      nama: json['nama'],
      alamat: json['alamat'],
      kenaPpn: json['kena_ppn'] ?? false,
    );
  }
}
