import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> validateUpiId(String upiId) async {
  final String keyId = 'rzp_test_d15RxnRWKBC4rm';
  final String keySecret = '51cyp6yftL33wJK4HzW51Hsm';
  final String auth = 'Basic ' + base64Encode(utf8.encode('$keyId:$keySecret'));

  final response = await http.post(
    Uri.parse('https://api.razorpay.com/v1/fund_accounts/validate/vpa'),
    headers: {
      'Authorization': auth,
      'Content-Type': 'application/json',
    },
    body: json.encode({'vpa': upiId}),
  );

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);
    print(responseData);
    return responseData['success'];
  } else {
    final responseData = json.decode(response.body);
    print(responseData);
    throw Exception('Failed to validate UPI ID');
  }
}
