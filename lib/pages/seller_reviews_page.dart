import 'package:flutter/material.dart';
import 'package:food_buddies/pages/ api_service.dart';

class SellerReviewsPage extends StatelessWidget {
  final String sellerPhone;

  SellerReviewsPage({required this.sellerPhone});

  Future<List<Map<String, dynamic>>> fetchReviews() async {
    return await APIService.getSellerReviews(sellerPhone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reviews & Ratings',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white), // Makes the back button white
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.grey[850],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error fetching reviews',
                    style: TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No reviews available',
                    style: TextStyle(color: Colors.white)));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final review = snapshot.data![index];
                final rating = review['order_rating'];
                final reviewText = review['order_review'];

                return Card(
                  color: Colors.grey[800],
                  margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        SizedBox(height: 10),
                        if (reviewText != null)
                          Text(
                            reviewText,
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
