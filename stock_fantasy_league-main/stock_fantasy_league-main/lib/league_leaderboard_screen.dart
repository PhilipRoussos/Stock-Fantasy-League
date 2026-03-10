import 'package:flutter/material.dart';
import 'data_model.dart'; 
import 'database_service.dart';
import 'invite_players_screen.dart';

class LeagueLeaderboardScreen extends StatefulWidget {
  final String leagueId;

  const LeagueLeaderboardScreen({super.key, required this.leagueId});

  @override
  State<LeagueLeaderboardScreen> createState() => _LeagueLeaderboardScreenState();
}

class _LeagueLeaderboardScreenState extends State<LeagueLeaderboardScreen> {

  @override
  Widget build(BuildContext context) {
    LeagueData? league;
    try {
      league = AppData().leagues.firstWhere((l) => l.id == widget.leagueId);
    } catch (e) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(league.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2A0D55),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            tooltip: "Leave League",
            onPressed: () {
              showDialog(
                context: context, 
                builder: (ctx) => AlertDialog(
                  title: const Text("Leave League?"),
                  content: const Text("Are you sure you want to leave? All your progress in this league will be lost."),
                  actions: [
                    TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx); 
                        await AppData().leaveLeague(league!.id);
                        if (context.mounted) Navigator.pop(context); 
                      }, 
                      child: const Text("Leave", style: TextStyle(color: Colors.red))
                    ),
                  ],
                )
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => InvitePlayersScreen(leagueCode: league!.id),
                 ),
               );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF2A0D55),
            child: const Row(
              children: [
                SizedBox(width: 50, child: Text("Rank", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                Expanded(child: Text("Player", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                Text("Score", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<Player>>(
              stream: DatabaseService().getLeagueLeaderboard(widget.leagueId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Player> players = snapshot.data!;
                
                if (players.isEmpty) {
                   return const Center(child: Text("No players found."));
                }

                return ListView.separated(
                  itemCount: players.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final rank = index + 1;

                    return Container(
                      color: player.isMe ? const Color(0xFFE0E0FF) : Colors.white,
                      child: ListTile(
                        leading: _buildRankBadge(rank),
                        title: Text(
                          player.name, 
                          style: TextStyle(
                            fontWeight: player.isMe ? FontWeight.bold : FontWeight.normal, 
                            color: const Color(0xFF2A0D55),
                            fontSize: 18,
                          )
                        ),
                        trailing: Text(
                          "€ ${player.score.toStringAsFixed(0)}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Widget content;
    if (rank == 1) content = const Text("🥇", style: TextStyle(fontSize: 32));
    else if (rank == 2) content = const Text("🥈", style: TextStyle(fontSize: 32));
    else if (rank == 3) content = const Text("🥉", style: TextStyle(fontSize: 32));
    else {
      content = Container(
        width: 30, height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
        child: Text("$rank", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
      );
    }
    
    return SizedBox(
      width: 40, 
      height: 40, 
      child: Center(child: content),
    );
  }
}