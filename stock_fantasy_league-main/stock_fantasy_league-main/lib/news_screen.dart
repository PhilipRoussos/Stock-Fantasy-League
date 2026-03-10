import 'package:flutter/material.dart';
import 'data_model.dart';
import 'news_service.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isWatchlistSelected = false;
  Future<List<dynamic>>? newsFuture;
  String _currentTitle = "MARKET NEWS"; 

  final Map<String, String> strictKeywords = {
    "AAPL": '(Apple OR iPhone OR AAPL)',
    "TSLA": '(Tesla OR Musk OR TSLA)',
    "NVDA": '(Nvidia OR NVDA)',
    "AMZN": '(Amazon OR AWS OR AMZN)',
    "GOOG": '(Google OR Alphabet OR Gemini)',
    "MSFT": '(Microsoft OR MSFT OR Azure)',
    "BTC":  '(Bitcoin OR Crypto)',
    "META": '(Meta OR Facebook)',
    "NFLX": '(Netflix)',
    "AMD":  '(AMD OR Advanced Micro Devices)',
    "DIS":  '(Disney OR Bob Iger OR DIS)',
    "COIN": '(Coinbase OR COIN OR Crypto)',
  };
  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  void _loadNews() {
    setState(() {
      if (_isWatchlistSelected) {
        final ownedSymbols = AppData().leagues
            .expand((l) => l.myStocks.map((s) => s.symbol))
            .toSet()
            .toList();

        if (ownedSymbols.isEmpty) {
          _currentTitle = "PORTFOLIO (Empty)";
          newsFuture = Future.value([]); 
        } else {
          _currentTitle = "MY PORTFOLIO NEWS"; 
          
          List<String> queryParts = [];
          for (var symbol in ownedSymbols) {
            String part = strictKeywords[symbol] ?? symbol;
            queryParts.add(part);
          }
          String query = queryParts.join(' OR ');
          
          newsFuture = NewsService.getNews(query: query);
        }
      } else {
        _currentTitle = "TOP FINANCIAL HEADLINES";
        newsFuture = NewsService.getNews(); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNews)
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text("Error loading news."));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.feed_outlined, size: 50, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                            _isWatchlistSelected 
                            ? "No strict headlines found for your portfolio in major financial outlets today." 
                            : "No financial news available.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final newsList = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: newsList.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildNewsCard(newsList[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: const Color(0xFF2A0D55),
      child: Row(
        children: [
          _tab("MARKET HEADLINES", !_isWatchlistSelected, () {
            _isWatchlistSelected = false;
            _loadNews();
          }),
          _tab("MY PORTFOLIO", _isWatchlistSelected, () {
            _isWatchlistSelected = true;
            _loadNews();
          }),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: active ? Colors.greenAccent : Colors.transparent, width: 3)),
          ),
          child: Text(label, textAlign: TextAlign.center, 
            style: TextStyle(color: active ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article) {
    String title = article['title'] ?? "";
    String imageUrl = article['urlToImage'] ?? "https://via.placeholder.com/500";
    String source = article['source']['name'] ?? "News";
    String time = article['publishedAt'] != null ? article['publishedAt'].toString().substring(0, 10) : "";

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => 
            NewsDetailScreen(title: title, url: article['url'], imageUrl: imageUrl)
          ));
        },
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(height: 160, color: Colors.grey[300], child: const Icon(Icons.image)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(source, style: TextStyle(color: Colors.blue[800], fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerRight, child: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}