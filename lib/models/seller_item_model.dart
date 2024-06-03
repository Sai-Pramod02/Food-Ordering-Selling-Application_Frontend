class SellerItemModel {
  final String name;
  final String sellerPhone;
  final String rating;
  final String photoUrl;
  final List<Map<String, dynamic>> allItems;

  SellerItemModel({
    required this.name,
    required this.sellerPhone,
    required this.rating,
    required this.photoUrl,
    required this.allItems,
  });

  factory SellerItemModel.fromJson(Map<String, dynamic> json) {
    return SellerItemModel(
      name: json['name'] ?? '',
      sellerPhone: json['seller_phone'] ?? '',
      rating: json['rating'] ?? '0.0',
      photoUrl: json['photoUrl'] ?? '',
      allItems: (json['allItems'] as List<dynamic>).cast<Map<String, dynamic>>(),
    );
  }
}
