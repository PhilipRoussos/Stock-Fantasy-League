import 'dart:async';
import 'package:flutter/material.dart';
import 'data_model.dart';
import 'database_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String leagueId;
  const ChatDetailScreen({super.key, required this.leagueId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  late LeagueData league;

  @override
  void initState() {
    super.initState();
    try {
      league = AppData().leagues.firstWhere((l) => l.id == widget.leagueId);
    } catch (e) {
      league = LeagueData(id: widget.leagueId, name: "League Chat", myCash: 0, myStocks: [], players: [], messages: []);
    }
  }

  void _send() async {
    if (_msgController.text.trim().isEmpty) return;
    String text = _msgController.text;
    _msgController.clear(); 
    
    await AppData().sendMessage(league.id, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(league.name), 
        backgroundColor: const Color(0xFF2A0D55),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: DatabaseService().getChatMessages(widget.leagueId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Start the conversation!", style: TextStyle(color: Colors.grey)));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Align(
                      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: msg.isMe ? const Color(0xFF2A0D55) : const Color(0xFF6A1B9A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!msg.isMe) 
                              Text(msg.sender, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                            Text(
                              msg.text,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2A0D55),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _send,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}