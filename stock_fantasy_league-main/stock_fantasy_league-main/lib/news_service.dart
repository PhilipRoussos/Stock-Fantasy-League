import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  static const String apiKey = '6b5fd553fb0a4bd98d5d6ce96cf6eb3b'; 

  static const String trustedDomains = 
      'bloomberg.com,cnbc.com,reuters.com,wsj.com,marketwatch.com,'
      'finance.yahoo.com,barrons.com,ft.com,investing.com';

  static Future<List<dynamic>> getNews({String? query}) async {
    try {
      Uri url;

      if (query != null && query.isNotEmpty) {
        print("🔍 STRICT Financial Search for: $query");
        
        url = Uri.https('newsapi.org', '/v2/everything', {
          'q': query,
          'searchIn': 'title',       
          'domains': trustedDomains,
          'language': 'en',
          'sortBy': 'publishedAt',  
          'apiKey': apiKey,
        });
      } else {
        url = Uri.https('newsapi.org', '/v2/everything', {
          'domains': trustedDomains, 
          'language': 'en',
          'sortBy': 'publishedAt',
          'apiKey': apiKey,
        });
      }

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'error') return [];

        final List<dynamic> articles = data['articles'];
        
        final filtered = articles.where((article) => 
          article['urlToImage'] != null && 
          article['title'] != null && 
          !article['title'].toString().contains("[Removed]")
        ).toList();

        print("✅ Found ${filtered.length} pure financial articles");
        return filtered;
      } else {
        return [];
      }
    } catch (e) {
      print("Error: $e");
      return []; 
    }
  }
}