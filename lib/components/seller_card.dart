import 'package:flutter/material.dart';

class SellerCard extends StatelessWidget {
  final String sellerName;
  final String sellerPhotoUrl;
  final double sellerRating;
  final List<Map<String, dynamic>> allItems;
  final Function() onPressed;

  SellerCard({
    required this.sellerName,
    required this.sellerPhotoUrl,
    required this.sellerRating,
    required this.allItems,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> topItems = allItems.take(2).toList();
    print(topItems);
    final String baseUrl = 'http://localhost:4000/';

    return GestureDetector(
      onTap: onPressed,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
              child: sellerPhotoUrl.isNotEmpty
                  ? Image.network(
                baseUrl + sellerPhotoUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Placeholder(), // Placeholder for null photo
            ),
            Padding(
              padding: EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sellerName.isNotEmpty ? sellerName : 'Unknown', // Use 'Unknown' for null name
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.yellow),
                          SizedBox(width: 5.0),
                          Text(
                            sellerRating != null
                                ? sellerRating.toString()
                                : 'N/A', // Use 'N/A' for null rating
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    'Top Items:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: topItems.map((item) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['name'] ?? 'Unknown', // Use 'Unknown' for null name
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              Text(
                                item['price'] != null
                                    ? '₹${item['price']}'
                                    : 'N/A', // Use 'N/A' for null price
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.0),
                          Text(
                            item['description'] ?? '', // Use empty string for null description
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
