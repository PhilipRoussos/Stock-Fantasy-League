import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'data_model.dart';
import 'stock_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- LEAGUES ---

  Future<String?> createLeague(String name, double startingCash, String creatorName) async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    String leagueCode = _generateLeagueCode();
    
    await _db.collection('leagues').doc(leagueCode).set({
      'name': name,
      'startingCash': startingCash,
      'createdAt': FieldValue.serverTimestamp(),
      'members': [user.uid], 
    });

    await _db.collection('leagues').doc(leagueCode).collection('players').doc(user.uid).set({
      'name': creatorName,
      'score': startingCash,
      'cash': startingCash,
      'stocks': [], 
    });

    await _db.collection('leagues').doc(leagueCode).collection('messages').add({
      'text': "Welcome to $name! Start trading.",
      'sender': "System",
      'timestamp': FieldValue.serverTimestamp(),
      'uid': 'system',
    });

    return leagueCode;
  }

  Future<bool> joinLeague(String leagueCode, String userName) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      leagueCode = leagueCode.trim().toUpperCase();

      DocumentSnapshot leagueDoc = await _db.collection('leagues').doc(leagueCode).get();
      if (!leagueDoc.exists) {
        print("League $leagueCode does not exist.");
        return false;
      }

      var data = leagueDoc.data() as Map<String, dynamic>;
      List<dynamic> members = data['members'] ?? [];

      if (members.contains(user.uid)) {
        throw "ALREADY_JOINED";
      }

      double startingCash = (data['startingCash'] as num?)?.toDouble() ?? 1000.0;

      await _db.collection('leagues').doc(leagueCode).update({
        'members': FieldValue.arrayUnion([user.uid])
      });

      await _db.collection('leagues').doc(leagueCode).collection('players').doc(user.uid).set({
        'name': userName,
        'score': startingCash,
        'cash': startingCash,
        'stocks': [], 
      });

      await sendMessage(leagueCode, "$userName joined the league!", isSystem: true);
      
      return true;
    } catch (e) {
      if (e == "ALREADY_JOINED") rethrow; 
      print("JOIN LEAGUE ERROR: $e");
      return false; 
    }
  }

  Future<void> leaveLeague(String leagueId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('leagues').doc(leagueId).update({
      'members': FieldValue.arrayRemove([user.uid])
    });

    await _db.collection('leagues').doc(leagueId).collection('players').doc(user.uid).delete();

    await sendMessage(leagueId, "${user.displayName ?? 'A player'} left the league.", isSystem: true);
  }

  Stream<List<LeagueData>> getMyLeagues() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('leagues')
      .where('members', arrayContains: user.uid)
      .snapshots()
      .asyncMap((snapshot) async {
        List<LeagueData> leagues = [];
        for (var doc in snapshot.docs) {
          var data = doc.data();
          String leagueId = doc.id;
          
          var playerDoc = await _db.collection('leagues').doc(leagueId).collection('players').doc(user.uid).get();
          var playerData = playerDoc.data() ?? {};

          List<dynamic> stocksList = playerData['stocks'] ?? [];
          List<Stock> myStocks = stocksList.map((s) => Stock.fromJson(s)).toList();

          var playersSnap = await _db.collection('leagues').doc(leagueId).collection('players').orderBy('score', descending: true).get();
          List<Player> allPlayers = playersSnap.docs.map((pDoc) {
             return Player(
               name: pDoc['name'] ?? "Unknown",
               score: (pDoc['score'] ?? 0).toDouble(),
               isMe: pDoc.id == user.uid
             );
          }).toList();

          leagues.add(LeagueData(
            id: leagueId,
            name: data['name'] ?? "Unknown League",
            myCash: (playerData['cash'] ?? 0).toDouble(),
            myStocks: myStocks,
            players: allPlayers, 
            messages: [],
            lastMessage: data['lastMessage'],
            lastMessageSender: data['lastMessageSender']
          ));
        }
        return leagues;
      });
  }

  Stream<List<Player>> getLeagueLeaderboard(String leagueId) {
    User? currentUser = _auth.currentUser;
    return _db.collection('leagues').doc(leagueId).collection('players')
      .orderBy('score', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          var data = doc.data();
          return Player(
            name: data['name'] ?? "Unknown", 
            score: (data['score'] ?? 0).toDouble(),
            isMe: doc.id == currentUser?.uid
          );
        }).toList();
      });
  }


  Future<LeagueData?> getLeague(String leagueId) async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot leagueDoc = await _db.collection('leagues').doc(leagueId).get();
    if (!leagueDoc.exists) return null;
    var data = leagueDoc.data() as Map<String, dynamic>;

    var playerDoc = await _db.collection('leagues').doc(leagueId).collection('players').doc(user.uid).get();
    var playerData = playerDoc.data() ?? {};

    List<dynamic> stocksList = playerData['stocks'] ?? [];
    List<Stock> myStocks = stocksList.map((s) => Stock.fromJson(s)).toList();

    return LeagueData(
      id: leagueId,
      name: data['name'] ?? "Unknown League",
      myCash: (playerData['cash'] ?? 0).toDouble(),
      myStocks: myStocks,
      players: [],
      messages: [],
    );
  }

  // --- STOCKS ---

  Future<void> buyStock(String leagueId, String symbol, int quantity, double price) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    
    DocumentReference playerRef = _db.collection('leagues').doc(leagueId).collection('players').doc(user.uid);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(playerRef);
      if (!snapshot.exists) return;
      
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      double currentCash = (data['cash'] ?? 0).toDouble();
      List<dynamic> stocks = data['stocks'] ?? [];

      double cost = quantity * price;

      if (currentCash >= cost) {
        currentCash -= cost;
        
        int index = stocks.indexWhere((s) => s['symbol'] == symbol);
        if (index != -1) {
          var s = stocks[index];
          int oldQty = s['quantity'];
          double oldAvg = (s['avgPrice'] as num).toDouble();
          
          double newAvg = ((oldQty * oldAvg) + (quantity * price)) / (oldQty + quantity);
          stocks[index] = {
            'symbol': symbol,
            'name': symbol, 
            'quantity': oldQty + quantity,
            'avgPrice': newAvg,
            'currentPrice': price 
          };
        } else {
          stocks.add({
            'symbol': symbol,
            'name': symbol,
            'quantity': quantity,
            'avgPrice': price,
            'currentPrice': price
          });
        }
        
        transaction.update(playerRef, {'cash': currentCash, 'stocks': stocks});
      }
    });
  }

  Future<void> sellStock(String leagueId, String symbol, int quantity, double price) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference playerRef = _db.collection('leagues').doc(leagueId).collection('players').doc(user.uid);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(playerRef);
      if (!snapshot.exists) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      double currentCash = (data['cash'] ?? 0).toDouble();
      List<dynamic> stocks = List.from(data['stocks'] ?? []); 

      int index = stocks.indexWhere((s) => s['symbol'] == symbol);
      if (index != -1) {
        var s = stocks[index];
        int currentQty = s['quantity'];
        
        if (currentQty >= quantity) {
           currentCash += (quantity * price);
           s['quantity'] = currentQty - quantity;
           
           if (s['quantity'] == 0) {
             stocks.removeAt(index);
           } else {
             stocks[index] = s;
           }

           transaction.update(playerRef, {'cash': currentCash, 'stocks': stocks});
        }
      }
    });
  }

  Future<void> updatePortfolioValue(String leagueId, List<Stock> myStocks) async {
    
    User? user = _auth.currentUser;
    if (user == null) return;
    
    DocumentReference playerRef = _db.collection('leagues').doc(leagueId).collection('players').doc(user.uid);
    DocumentSnapshot snapshot = await playerRef.get();
    if(!snapshot.exists) return;

    double cash = (snapshot.data() as Map<String, dynamic>)['cash'] ?? 0.0;
    
    double stockValue = 0;
    for (var s in myStocks) {
      stockValue += (s.quantity * s.currentPrice);
    }
    
    await playerRef.update({'score': cash + stockValue});
  }


  // --- CHAT ---

  Stream<List<ChatMessage>> getChatMessages(String leagueId) {
    User? user = _auth.currentUser;
    return _db.collection('leagues').doc(leagueId).collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          var data = doc.data();
          return ChatMessage(
            sender: data['sender'] ?? "Unknown",
            text: data['text'] ?? "",
            isMe: data['uid'] == user?.uid
          );
        }).toList();
      });
  }

  Future<void> sendMessage(String leagueId, String text, {bool isSystem = false}) async {
    User? user = _auth.currentUser;
    if (user == null && !isSystem) return;

    var senderName = isSystem ? "System" : (user?.displayName ?? "Anonymous");

    await _db.collection('leagues').doc(leagueId).collection('messages').add({
      'text': text,
      'sender': senderName,
      'uid': isSystem ? 'system' : user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db.collection('leagues').doc(leagueId).update({
      'lastMessage': text,
      'lastMessageSender': senderName,
      'lastMessageTime': FieldValue.serverTimestamp()
    });
  }


  Future<void> updatePlayerName(String newName) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    var snapshot = await _db.collection('leagues').where('members', arrayContains: user.uid).get();

    WriteBatch batch = _db.batch();
    
    for (var doc in snapshot.docs) {
      DocumentReference playerRef = _db.collection('leagues').doc(doc.id).collection('players').doc(user.uid);
      batch.update(playerRef, {'name': newName});
    }

    await batch.commit();
  }

  // --- UTILS ---
  String _generateLeagueCode() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789'; // No I, L, 1, 0, O
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length)))).toUpperCase();
  }
}
