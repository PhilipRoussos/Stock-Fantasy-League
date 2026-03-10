import 'dart:async';
import 'package:flutter/material.dart';
import 'data_model.dart';
import 'database_service.dart';
import 'league_leaderboard_screen.dart';
import 'create_league_screen.dart'; 
import 'join_league_screen.dart';   

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leagues = AppData().leagues;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("HOME", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2A0D55),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const CreateLeagueScreen())
                      ).then((_) => setState(() {})); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2A0D55),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("CREATE LEAGUE", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const JoinLeagueScreen())
                      ).then((_) => setState(() {})); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A0D55),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("JOIN LEAGUE", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            const Row(
              children: [
                Text("LEADERBOARDS", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2A0D55))),
                SizedBox(width: 8),
                Icon(Icons.circle, color: Colors.red, size: 12),
                SizedBox(width: 4),
                Text("LIVE", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),

            leagues.isEmpty 
            ? Container(
                padding: const EdgeInsets.all(30),
                alignment: Alignment.center,
                child: const Text("No leagues yet.\nCreate or Join one to start!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
              )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), 
              itemCount: leagues.length,
              itemBuilder: (context, index) {
                final league = leagues[index];
                
                league.updateLeaderboard();
                
                return StreamBuilder<List<Player>>(
                  stream: DatabaseService().getLeagueLeaderboard(league.id),
                  builder: (context, snapshot) {
                    List<Player> players = snapshot.hasData ? snapshot.data! : league.players;
                    
                    Player? me;
                    try {
                      me = players.firstWhere((p) => p.isMe);
                    } catch (e) {
                      me = null;
                    }

                    String myRankStr = "-";
                    double myVal = 0;
                    
                    if (me != null) {
                       int myIndex = players.indexOf(me);
                       myRankStr = myIndex == 0 ? "1st" : myIndex == 1 ? "2nd" : myIndex == 2 ? "3rd" : "${myIndex + 1}th";
                       myVal = me.score;
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LeagueLeaderboardScreen(leagueId: league.id)),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Όνομα Λίγκας
                              Text(league.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A0D55))),
                              const Divider(),
                              
                              // Top 3 Παίκτες (Live)
                              if (players.isNotEmpty) _buildRankRow("1", players[0].name, players[0].score),
                              if (players.length > 1) _buildRankRow("2", players[1].name, players[1].score),
                              if (players.length > 2) _buildRankRow("3", players[2].name, players[2].score),

                              const SizedBox(height: 10),
                              
                              // MY RANK (Highlight) - Live Ενημέρωση
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E0FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF2A0D55).withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("My Rank: $myRankStr", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A0D55))),
                                    // Live Score
                                    Text("Val: €${myVal.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankRow(String rank, String name, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
             SizedBox(width: 25, child: Text(rank, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
             Text(name, style: const TextStyle(fontSize: 15)),
          ]),
          // Live Score
          Text("€ ${score.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}