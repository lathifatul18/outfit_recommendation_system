import '../core/constants/api_constants.dart';

/// Favorite item model
class FavoriteModel {
  final int idFavorit;
  final int idItem;
  final String namaItem;
  final String? subCategory;
  final String gambar;

  const FavoriteModel({
    required this.idFavorit,
    required this.idItem,
    required this.namaItem,
    this.subCategory,
    required this.gambar,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      idFavorit: json['id_favorit'] as int,
      idItem: json['id_item'] as int,
      namaItem: json['nama_item'] as String,
      subCategory: json['sub_category'] as String?,
      gambar: json['gambar'] as String,
    );
  }

  /// Full URL gambar
  String get imageUrl => ApiConstants.imageUrl(gambar);
}
