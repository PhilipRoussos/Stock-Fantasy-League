import 'dart:async';
import 'package:flutter/material.dart';
import 'data_model.dart';
import 'portfolio_detail_screen.dart';

class PortfoliosScreen extends StatefulWidget {
  const PortfoliosScreen({super.key});

  @override
  State<PortfoliosScreen> createState() => _PortfoliosScreenState();
}

class _PortfoliosScreenState extends State<PortfoliosScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {}); 
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final leagues = AppData().leagues;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("PORTFOLIOS", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2A0D55),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: leagues.isEmpty 
          ? const Center(child: Text("No portfolios yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leagues.length,
              itemBuilder: (context, index) {
                final league = leagues[index];
                
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PortfolioDetailScreen(leagueId: league.id),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2A0D55), Color(0xFF4527A0)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Όνομα Λίγκας
                        Text(
                          league.name,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Rank (Αλλάζει Live)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Place", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(
                                  league.myRank, 
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            
                            // Total Value (Αλλάζει Live)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("Total Value", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(
                                  "€ ${league.totalValue.toStringAsFixed(2)}",
                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white24),
                        const Center(child: Icon(Icons.touch_app, color: Colors.white30, size: 20)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}