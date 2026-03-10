import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'data_model.dart';

class StockQuote {
  final double price;
  final double changePercent;
  StockQuote({required this.price, required this.changePercent});
}

class CachedData {
  final StockQuote quote;
  final DateTime timestamp;
  CachedData(this.quote, this.timestamp);
}

class StockService {
  static final Map<String, CachedData> _cache = {};

  static Future<StockQuote> getQuote(String symbol) async {
    if (_cache.containsKey(symbol)) {
      final cached = _cache[symbol]!;
      if (DateTime.now().difference(cached.timestamp).inSeconds < 2) {
        return cached.quote;
      }
    }

    final url = 'https://finnhub.io/api/v1/quote?symbol=${symbol.toUpperCase()}&token=${Config.finnhubApiKey}';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        double price = (data['c'] as num).toDouble();
        double dp = (data['dp'] as num).toDouble(); 
        
        final quote = StockQuote(price: price, changePercent: dp);
        
        _cache[symbol] = CachedData(quote, DateTime.now());
        
        return quote;
      }
      return StockQuote(price: 0.0, changePercent: 0.0);
    } catch (e) { 
      print("Error fetching stock: $e");
      return StockQuote(price: 0.0, changePercent: 0.0); 
    }
  }

  static Future<double> getPrice(String symbol) async {
    final quote = await getQuote(symbol);
    return quote.price;
  }

  static Future<void> updatePortfolio(List<Stock> stocks) async {
    final tasks = stocks.map((s) => getPrice(s.symbol)).toList();
    final prices = await Future.wait(tasks);
    
    for (int i = 0; i < stocks.length; i++) {
      if (prices[i] > 0) {
        stocks[i].currentPrice = prices[i];
      }
    }
  }
}