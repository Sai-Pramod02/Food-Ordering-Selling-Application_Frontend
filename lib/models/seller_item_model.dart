class SellerItemModel {
  final String name;
  final String sellerPhone;
  final String rating;
  final String photoUrl;
  final String fssai_code;
  final List<Map<String, dynamic>> allItems;
  SellerItemModel({
    required this.name,
    required this.sellerPhone,
    required this.rating,
    required this.photoUrl,
    required this.allItems,
    required this.fssai_code,
  });

  factory SellerItemModel.fromJson(Map<String, dynamic> json) {
    return SellerItemModel(
      name: json['name'] ?? '',
      sellerPhone: json['seller_phone'] ?? '',
      rating: json['rating'] ?? '0.0',
      photoUrl: json['photoUrl'] ?? '',
      fssai_code: json['fssai_code'],
      allItems: (json['allItems'] as List<dynamic>).cast<Map<String, dynamic>>(),
    );
  }
}
