import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'data_model.dart';
import 'buy_stocks_screen.dart';

class PortfolioDetailScreen extends StatefulWidget {
  final String leagueId;
  const PortfolioDetailScreen({super.key, required this.leagueId});

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  late Timer _timer;
  late LeagueData league;

  @override
  void initState() {
    super.initState();
    league = AppData().leagues.firstWhere((l) => l.id == widget.leagueId);
    _timer = Timer.periodic(const Duration(seconds: 2), (t) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(league.name), backgroundColor: const Color(0xFF2A0D55), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => BuyStocksScreen(league: league))),
              icon: const Icon(Icons.swap_vert),
              label: const Text("TRADE STOCKS"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: league.myStocks.length,
              itemBuilder: (context, index) {
                final stock = league.myStocks[index];
                return Card(
                  elevation: 1, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(stock.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text("${stock.quantity} Units Owned"),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("€${stock.totalValue.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: stock.profitPercentage >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text("${stock.profitPercentage >= 0 ? '+' : ''}${stock.profitPercentage.toStringAsFixed(2)}%", style: TextStyle(color: stock.profitPercentage >= 0 ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    onTap: () => _showSellDialog(stock),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2A0D55), Color(0xFF4527A0)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(children: [
          const Text("Portfolio Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text("€${league.totalValue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_summaryItem("Available Cash", "€${league.myCash.toStringAsFixed(2)}"), _summaryItem("League Rank", league.myRank)]),
      ]),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]);
  }

  void _showSellDialog(Stock stock) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))), builder: (c) => LiveSellDialog(league: league, stock: stock));
  }
}

class LiveSellDialog extends StatefulWidget {
  final LeagueData league;
  final Stock stock;
  const LiveSellDialog({super.key, required this.league, required this.stock});
  @override State<LiveSellDialog> createState() => _LiveSellDialogState();
}

class _LiveSellDialogState extends State<LiveSellDialog> {
  int qty = 1;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24), height: 350,
      child: Column(children: [
          Text("Sell ${widget.stock.symbol}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Market Price: €${widget.stock.currentPrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.blue)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: () => setState(() { if(qty > 1) qty--; }), icon: const Icon(Icons.remove_circle_outline, size: 30)),
              const SizedBox(width: 20),
              Text("$qty", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              IconButton(onPressed: () => setState(() { if(qty < widget.stock.quantity) qty++; }), icon: const Icon(Icons.add_circle_outline, size: 30)),
          ]),
          const Spacer(),
          
              // --- CONFIRM SELL ---
              ElevatedButton(
                onPressed: () async {
                  if (AppData().isVibrationOn) {
                    if (await Vibration.hasVibrator() ?? false) {
                       Vibration.vibrate(duration: 500);
                    }
                  }
                  
                  if (AppData().isSoundOn) {
                    final player = AudioPlayer();
                    await player.play(AssetSource('sounds/sell.mp3'));
                  }

              await AppData().sellStock(widget.league, widget.stock, qty, widget.stock.currentPrice);
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sold $qty shares of ${widget.stock.symbol} 💸")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("CONFIRM SELL", style: TextStyle(fontWeight: FontWeight.bold)),
          )
      ]),
    );
  }
}