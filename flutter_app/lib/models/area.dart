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

  // Supaya 2 objek Area dengan id yang sama dianggap "sama" oleh Dart.
  // Tanpa ini, DropdownButton bisa error "There should be exactly one
  // item with [DropdownButton]'s value" walau datanya sebenarnya sama.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Area && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}