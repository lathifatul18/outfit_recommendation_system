import '../core/constants/api_constants.dart';

/// Single fashion/outfit item
class FashionItemModel {
  final int idItem;
  final String namaItem;
  final String gambar;
  final String? subCategory;
  final double? score;

  const FashionItemModel({
    required this.idItem,
    required this.namaItem,
    required this.gambar,
    this.subCategory,
    this.score,
  });

  factory FashionItemModel.fromJson(Map<String, dynamic> json) {
    return FashionItemModel(
      idItem: json['id_item'] as int,
      namaItem: json['nama_item'] as String,
      gambar: json['gambar'] as String,
      subCategory: json['sub_category'] as String?,
      score: json['score'] != null
          ? (json['score'] as num).toDouble()
          : null,
    );
  }

  /// Full URL gambar untuk Image.network
  String get imageUrl => ApiConstants.imageUrl(gambar);

  /// Persentase similarity (0-100)
  int get scorePercent => score != null ? (score! * 100).round() : 0;
}
