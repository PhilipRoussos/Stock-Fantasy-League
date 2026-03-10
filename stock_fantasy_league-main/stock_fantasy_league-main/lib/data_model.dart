import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'stock_service.dart';
import 'database_service.dart';

// --- CLASSES ---

class Stock {
  String symbol;
  String name;
  int quantity;
  double avgPrice;     
  double currentPrice; 

  Stock({required this.symbol, required this.name, required this.quantity, required this.avgPrice, required this.currentPrice});

  double get totalValue => quantity * currentPrice;
  double get profitPercentage => avgPrice == 0 ? 0 : ((currentPrice - avgPrice) / avgPrice) * 100;

  Map<String, dynamic> toJson() => {
    'symbol': symbol, 'name': name, 'quantity': quantity, 'avgPrice': avgPrice, 'currentPrice': currentPrice,
  };

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
    symbol: json['symbol'], name: json['name'], quantity: json['quantity'],
    avgPrice: (json['avgPrice'] as num).toDouble(),
    currentPrice: (json['currentPrice'] as num).toDouble(),
  );
}

class Player {
  String name; double score; bool isMe;
  Player({required this.name, required this.score, this.isMe = false});
  Map<String, dynamic> toJson() => {'name': name, 'score': score, 'isMe': isMe};
  factory Player.fromJson(Map<String, dynamic> json) => Player(name: json['name'], score: (json['score'] as num).toDouble(), isMe: json['isMe'] ?? false);
}

class ChatMessage {
  String sender; String text; bool isMe;
  ChatMessage({required this.sender, required this.text, this.isMe = false});
  Map<String, dynamic> toJson() => {'sender': sender, 'text': text, 'isMe': isMe};
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(sender: json['sender'], text: json['text'], isMe: json['isMe'] ?? false);
}

class LeagueData {
  String id; 
  String name; 
  List<Player> players; 
  List<Stock> myStocks; 
  double myCash; 
  List<ChatMessage> messages;
  String? lastMessage;
  String? lastMessageSender;

  LeagueData({
    required this.id, 
    required this.name, 
    required this.players, 
    required this.myStocks, 
    required this.myCash, 
    required this.messages,
    this.lastMessage,
    this.lastMessageSender
  });

  double get totalValue => myCash + myStocks.fold(0.0, (sum, s) => sum + s.totalValue);

  void updateLeaderboard() {
    for (var p in players) { if (p.isMe) p.score = totalValue; }
    players.sort((a, b) => b.score.compareTo(a.score));
  }

  String get myRank {
    int index = players.indexWhere((p) => p.isMe);
    if (index == -1) return "-";
    return index == 0 ? "1st" : index == 1 ? "2nd" : index == 2 ? "3rd" : "${index + 1}th";
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'myCash': myCash,
    'players': players.map((x) => x.toJson()).toList(),
    'myStocks': myStocks.map((x) => x.toJson()).toList(),
    'messages': messages.map((x) => x.toJson()).toList(),
    'lastMessage': lastMessage,
    'lastMessageSender': lastMessageSender,
  };

  factory LeagueData.fromJson(Map<String, dynamic> json) => LeagueData(
    id: json['id'], name: json['name'], myCash: (json['myCash'] as num).toDouble(),
    players: List<Player>.from(json['players'].map((x) => Player.fromJson(x))),
    myStocks: List<Stock>.from(json['myStocks'].map((x) => Stock.fromJson(x))),
    messages: List<ChatMessage>.from(json['messages'].map((x) => ChatMessage.fromJson(x))),
    lastMessage: json['lastMessage'],
    lastMessageSender: json['lastMessageSender'],
  );
}


class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  
  AppData._internal();

  List<LeagueData> leagues = [];
  String currentUserName = "You";
  String? currentProfilePic;
  
  bool isSoundOn = true;
  bool isVibrationOn = true;

  final List<String> marketSymbols = ["AAPL", "TSLA", "NVDA", "NFLX", "META", "AMZN", "GOOG", "MSFT", "AMD", "DIS", "COIN"];

  Future<void> init() async {
    DatabaseService().getMyLeagues().listen((newLeagues) {
      leagues = newLeagues;
      print("UPDATED LEAGUES FROM FIRESTORE: ${leagues.length}");
    });
    
    _startAutoUpdate();
  }


  Future<void> createNewLeague(String name, double startingCash) async {
    await DatabaseService().createLeague(name, startingCash, currentUserName);
  }

  Future<bool> joinLeague(String code) async {
    return await DatabaseService().joinLeague(code, currentUserName);
  }

  Future<void> leaveLeague(String leagueId) async {
    await DatabaseService().leaveLeague(leagueId);
  }

  Future<void> buyStock(LeagueData league, String symbol, int quantity) async {
    var quote = await StockService.getQuote(symbol);
    double price = quote.price;
    if (price <= 0) return;

    await DatabaseService().buyStock(league.id, symbol, quantity, price);
    
    await _refreshLeague(league.id);
  }

  Future<void> sellStock(LeagueData league, Stock stock, int quantity, double price) async {
    await DatabaseService().sellStock(league.id, stock.symbol, quantity, price);
    await _refreshLeague(league.id);
  }

  Future<void> _refreshLeague(String leagueId) async {
    LeagueData? updated = await DatabaseService().getLeague(leagueId);
    if (updated != null) {
       int index = leagues.indexWhere((l) => l.id == leagueId);
       if (index != -1) {
         leagues[index].myCash = updated.myCash;
         leagues[index].myStocks = updated.myStocks;
       }
    }
  }

  Future<void> sendMessage(String leagueId, String text) async {
    await DatabaseService().sendMessage(leagueId, text);
  }

  Future<void> updateUserName(String newName) async {
    currentUserName = newName;
    await DatabaseService().updatePlayerName(newName);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newName); 
  }

  void _startAutoUpdate() {
    Timer.periodic(const Duration(seconds: 15), (t) async {
      for (var l in leagues) { 
        if (l.myStocks.isNotEmpty) {
           await StockService.updatePortfolio(l.myStocks);
           await DatabaseService().updatePortfolioValue(l.id, l.myStocks);
        } 
      }
    });
  }

  Future<void> loadLeaguesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    isSoundOn = prefs.getBool('sound_enabled') ?? true;
    isVibrationOn = prefs.getBool('vibration_enabled') ?? true;
    currentProfilePic = prefs.getString('profile_pic');
    
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      currentUserName = user.displayName!;
      prefs.setString('username', currentUserName);
    } else {
      currentUserName = prefs.getString('username') ?? "You";
    }

    await init();
  }

  Future<void> saveLeaguesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', currentUserName);
    if (currentProfilePic != null) await prefs.setString('profile_pic', currentProfilePic!);
    await prefs.setBool('sound_enabled', isSoundOn);
    await prefs.setBool('vibration_enabled', isVibrationOn);
  }
}