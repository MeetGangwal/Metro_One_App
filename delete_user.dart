import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyBuJzVcUV4gugwySX3oi6GmymVhDjYlfP4';
  
  // 1. Sign In
  print('Signing in as sapan@gmail.com...');
  final signInResponse = await http.post(
    Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'sapna@gmail.com',
      'password': 'ssssss',
      'returnSecureToken': true,
    }),
  );

  if (signInResponse.statusCode != 200) {
    print('Failed to sign in: ${signInResponse.body}');
    return;
  }

  final idToken = jsonDecode(signInResponse.body)['idToken'];
  print('Successfully signed in. Deleting account...');

  // 2. Delete Account
  final deleteResponse = await http.post(
    Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$apiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'idToken': idToken,
    }),
  );

  if (deleteResponse.statusCode == 200) {
    print('Successfully deleted user sapan@gmail.com from Firebase Auth.');
  } else {
    print('Failed to delete user: ${deleteResponse.body}');
  }
}
