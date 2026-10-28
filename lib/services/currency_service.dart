import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  // Tambahkan timestamp agar tidak kena cache
  static Future<Map<String, double>> getRates() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = Uri.parse('https://open.er-api.com/v6/latest/IDR?t=$timestamp');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['result'] == 'success') {
          final Map<String, dynamic> rates = data['rates'];
          return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
        }
      }
      return {}; 
    } catch (e) {
      print("Error fetching rates: $e");
      return {};
    }
  }
}