import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://nasfakcqzmpfcpqttmti.supabase.co/rest/v1/?apikey=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hc2Zha2Nxem1wZmNwcXR0bXRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2MDcxNTEsImV4cCI6MjA4NzE4MzE1MX0.p5YyyIGZZmnKzIcv-UlK8G05Yy3UDNZwT1FodihfVaM';
  
  final httpClient = HttpClient();
  try {
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> spec = jsonDecode(responseBody);
      final paths = spec['paths'] as Map<String, dynamic>;
      
      print('=== RPC FUNCTIONS CURRENTLY IN SUPABASE ===');
      for (var path in paths.keys) {
        if (path.startsWith('/rpc/')) {
          print('- $path');
        }
      }
    } else {
      print('Error fetching: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    httpClient.close();
  }
}
