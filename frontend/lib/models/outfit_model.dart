import 'fashion_item_model.dart';

class OutfitModel {
  final FashionItemModel uploadedItem;
  final FashionItemModel matchedItem;
  final FashionItemModel? upperwear;
  final FashionItemModel? bottomwear;
  final FashionItemModel? footwear;
  final FashionItemModel? accessories;

  const OutfitModel({
    required this.uploadedItem,
    required this.matchedItem,
    this.upperwear,
    this.bottomwear,
    this.footwear,
    this.accessories,
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    return OutfitModel(
      uploadedItem: FashionItemModel.fromJson(
        json['uploaded_item'] as Map<String, dynamic>,
      ),
      matchedItem: FashionItemModel.fromJson(
        json['matched_item'] as Map<String, dynamic>,
      ),
      upperwear: json['upperwear'] != null
          ? FashionItemModel.fromJson(
              json['upperwear'] as Map<String, dynamic>,
            )
          : null,
      bottomwear: json['bottomwear'] != null
          ? FashionItemModel.fromJson(
              json['bottomwear'] as Map<String, dynamic>,
            )
          : null,
      footwear: json['footwear'] != null
          ? FashionItemModel.fromJson(
              json['footwear'] as Map<String, dynamic>,
            )
          : null,
      accessories: json['accessories'] != null
          ? FashionItemModel.fromJson(
              json['accessories'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  List<MapEntry<String, FashionItemModel>> get outfitPieces {
    final pieces = <MapEntry<String, FashionItemModel>>[];
    if (upperwear != null) {
      pieces.add(MapEntry('Upperwear', upperwear!));
    }
    if (bottomwear != null) {
      pieces.add(MapEntry('Bottomwear', bottomwear!));
    }
    if (footwear != null) {
      pieces.add(MapEntry('Footwear', footwear!));
    }
    if (accessories != null) {
      pieces.add(MapEntry('Accessories', accessories!));
    }
    return pieces;
  }
}
