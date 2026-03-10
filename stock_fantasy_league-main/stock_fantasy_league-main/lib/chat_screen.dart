import 'package:flutter/material.dart';
import 'data_model.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    final leagues = AppData().leagues;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("LEAGUE CHATS", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2A0D55),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: leagues.isEmpty
          ? const Center(child: Text("Join a league to start chatting!"))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: leagues.length,
              itemBuilder: (context, index) {
                final league = leagues[index];
                
                String lastMsg = "No messages yet";
                if (league.lastMessage != null) {
                   lastMsg = "${league.lastMessageSender ?? 'User'}: ${league.lastMessage}";
                } else if (league.messages.isNotEmpty) {
                   lastMsg = "${league.messages.last.sender}: ${league.messages.last.text}";
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2A0D55),
                      child: Text(league.name[0], style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(league.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(leagueId: league.id),
                        ),
                      ).then((_) => setState((){})); 
                    },
                  ),
                );
              },
            ),
    );
  }
}