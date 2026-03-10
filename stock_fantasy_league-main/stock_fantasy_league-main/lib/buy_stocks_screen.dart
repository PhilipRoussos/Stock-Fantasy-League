import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'data_model.dart';
import 'stock_service.dart';

class BuyStocksScreen extends StatefulWidget {
  final LeagueData league;
  const BuyStocksScreen({super.key, required this.league});

  @override
  State<BuyStocksScreen> createState() => _BuyStocksScreenState();
}

class _BuyStocksScreenState extends State<BuyStocksScreen> {
  Timer? _timer;
  final Map<String, String> _companyDomains = {
    "AAPL": "apple.com", "TSLA": "tesla.com", "NVDA": "nvidia.com", "AMZN": "amazon.com",
    "GOOG": "google.com", "MSFT": "microsoft.com", "NFLX": "netflix.com", "META": "meta.com",
    "AMD": "amd.com", "DIS": "disney.com", "COIN": "coinbase.com",
  };

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (t) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LIVE MARKET"), 
        backgroundColor: const Color(0xFF2A0D55), 
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {}))],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: AppData().marketSymbols.length,
        itemBuilder: (context, index) {
          String symbol = AppData().marketSymbols[index];
          String domain = _companyDomains[symbol] ?? "google.com";
          String logoUrl = "https://www.google.com/s2/favicons?domain=$domain&sz=64";

          return FutureBuilder<StockQuote>(
            future: StockService.getQuote(symbol),
            builder: (context, snapshot) {
              StockQuote quote = snapshot.data ?? StockQuote(price: 0.0, changePercent: 0.0);
              double price = quote.price;
              double percent = quote.changePercent;
              Color color = percent >= 0 ? Colors.green : Colors.red;
              String sign = percent >= 0 ? "+" : "";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 50, height: 50, padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(logoUrl, fit: BoxFit.contain, 
                        errorBuilder: (c, e, s) => Center(child: Text(symbol[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)))),
                    ),
                  ),
                  title: Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  // ΔΙΟΡΘΩΣΗ: Αφαιρέθηκε το subtitle "Real-time Quote"
                  
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      price > 0 
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("€${price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A0D55), fontSize: 16)),
                            Text("$sign${percent.toStringAsFixed(2)}%", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                          ],
                        )
                      : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        onPressed: price > 0 ? () => _showBuyDialog(symbol, logoUrl) : null,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text("BUY"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showBuyDialog(String symbol, String logoUrl) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (c) => LiveBuyDialog(league: widget.league, symbol: symbol, logoUrl: logoUrl)
    );
  }
}

class LiveBuyDialog extends StatefulWidget {
  final LeagueData league; 
  final String symbol;
  final String logoUrl;
  const LiveBuyDialog({super.key, required this.league, required this.symbol, required this.logoUrl});
  @override State<LiveBuyDialog> createState() => _LiveBuyDialogState();
}

class _LiveBuyDialogState extends State<LiveBuyDialog> {
  int qty = 1;
  Timer? _dialogTimer;

  @override
  void initState() {
    super.initState();
    _dialogTimer = Timer.periodic(const Duration(seconds: 15), (t) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _dialogTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: StockService.getPrice(widget.symbol),
      builder: (context, snapshot) {
        double price = snapshot.data ?? 0.0;
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
        }
        double cost = qty * price;
        bool canAfford = widget.league.myCash >= cost;

        return Container(
          padding: const EdgeInsets.all(24), 
          height: 500,
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 45, height: 45, margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(4),
                    child: Image.network(widget.logoUrl, errorBuilder: (c,o,s) => const Icon(Icons.show_chart)),
                  ),
                  Text("Buy ${widget.symbol}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              Text("Live Price: €${price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(onPressed: () => setState(() { if(qty > 1) qty--; }), icon: const Icon(Icons.remove_circle_outline, size: 30)),
                  const SizedBox(width: 20),
                  Text("$qty", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                  IconButton(onPressed: () => setState(() { qty++; }), icon: const Icon(Icons.add_circle_outline, size: 30)),
              ]),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Total Cost:", style: TextStyle(fontSize: 16)),
                  Text("€${cost.toStringAsFixed(2)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: (canAfford && price > 0) ? () async {
                  if (AppData().isVibrationOn) {
                    HapticFeedback.heavyImpact(); 
                  }
                  
                  if (AppData().isSoundOn) {
                    final player = AudioPlayer();
                    await player.play(AssetSource('sounds/buy.mp3'));
                  }
                  
                  await AppData().buyStock(widget.league, widget.symbol, qty);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchase Successful! 🔔")));
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A0D55), foregroundColor: Colors.white, 
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: Text(canAfford ? "CONFIRM" : "INSUFFICIENT FUNDS"),
              )
            ],
          ),
        );
      }
    );
  }
}