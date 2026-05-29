import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '395482754229-i9m8uvfq5ue2igckhm0f3oo9cpcqut11.apps.googleusercontent.com',
  );

  // Stream of current user auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // AUTHENTICATION
  // ---------------------------------------------------------------------------

  // Login
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Login Google dibatalkan oleh pengguna.');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);

    if (cred.user != null) {
      final docRef = _db.collection('users').doc(cred.user!.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final displayName = cred.user!.displayName ?? 'User';
        final email = cred.user!.email ?? '';
        final username = email.isNotEmpty ? email.split('@').first : 'user_${cred.user!.uid.substring(0, 5)}';
        
        await docRef.set({
          'user_id': cred.user!.uid,
          'username': username,
          'name': displayName,
          'email': email,
          'role': '', // Biarkan memilih role setelah ini
          'avatar_url': '🧑',
          'class_id': '',
          'school_name': 'SMP Negeri 1 Jakarta',
          'grade': '8A',
          'level': 1,
          'xp': 0,
          'gems': 0,
          'tickets': 100,
          'mmr': 80,
          'gacha_pity_epic': 0,
          'gacha_pity_legendary': 0,
          'weekly_xp': {
            'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
          },
          'weekly_xp_start_date': '',
          'daily_challenges': [],
          'daily_challenges_date': '',
          'streak': 0,
          'win_count': 0,
          'lose_count': 0,
          'total_duels': 0,
          'win_rate': 0.0,
          'is_premium': false,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        // Auto-assign first badge
        await docRef.collection('badges').doc('pioneer').set({
          'badge_id': 'pioneer',
          'badge_name': 'Pejuang Pertama',
          'badge_icon': '🏆',
          'description': 'Berhasil bergabung dengan StudyDuel!',
          'is_pinned': true,
          'earned_at': FieldValue.serverTimestamp(),
        });
      }
    }
    return cred;
  }

  // Register
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
    required String name,
    required String role, // siswa | guru | orang_tua
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (cred.user != null) {
      // Create user document in Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'user_id': cred.user!.uid,
        'username': username.trim(),
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'avatar_url': '🧑',
        'class_id': '',
        'school_name': 'SMP Negeri 1 Jakarta',
        'grade': '8A',
        'level': 1,
        'xp': 0,
        'gems': 0,
        'tickets': 100,
        'mmr': 80,
        'gacha_pity_epic': 0,
        'gacha_pity_legendary': 0,
        'weekly_xp': {
          'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
        },
        'weekly_xp_start_date': '',
        'daily_challenges': [],
        'daily_challenges_date': '',
        'streak': 0,
        'win_count': 0,
        'lose_count': 0,
        'total_duels': 0,
        'win_rate': 0.0,
        'is_premium': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // Auto-assign first badge
      await _db.collection('users').doc(cred.user!.uid).collection('badges').doc('pioneer').set({
        'badge_id': 'pioneer',
        'badge_name': 'Pejuang Pertama',
        'badge_icon': '🏆',
        'description': 'Berhasil bergabung dengan StudyDuel!',
        'is_pinned': true,
        'earned_at': FieldValue.serverTimestamp(),
      });
    }
    return cred;
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // ---------------------------------------------------------------------------
  // USER PROFILE
  // ---------------------------------------------------------------------------

  // Get user profile stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Get user subcollection badges
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserBadges(String uid) {
    return _db.collection('users').doc(uid).collection('badges').snapshots();
  }

  // Get user subcollection inventories
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserInventory(String uid) {
    return _db.collection('users').doc(uid).collection('inventories').snapshots();
  }

  // Update onboarding preferences
  Future<void> updateOnboarding(
    String uid, {
    required String source,
    required String reason,
    required List<String> subjects,
    required String timeLimit,
    required bool enableNotif,
  }) async {
    await _db.collection('users').doc(uid).update({
      'onboarding_source': source,
      'onboarding_reason': reason,
      'preferred_subjects': subjects,
      'preferred_time': timeLimit,
      'notifications_enabled': enableNotif,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Update specific fields
  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // FRIENDS SYSTEM
  // ---------------------------------------------------------------------------

  // Search users by username (case-insensitive, limit 10)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final myUid = currentUser?.uid;
    final cleanQuery = query.trim().toLowerCase();

    // To make it very robust and case-insensitive, we fetch user docs
    // and filter in Dart, which is perfect for this application.
    final snapshot = await _db.collection('users').limit(150).get();

    final results = <Map<String, dynamic>>[];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Exclude current user from results
      if (data['user_id'] == myUid) continue;
      
      final username = (data['username'] ?? '').toString().toLowerCase();
      final name = (data['name'] ?? '').toString().toLowerCase();
      
      if (username.contains(cleanQuery) || name.contains(cleanQuery)) {
        results.add({
          'user_id': data['user_id'] ?? doc.id,
          'username': data['username'] ?? '',
          'name': data['name'] ?? '',
          'avatar_url': data['avatar_url'] ?? '🧑',
          'level': data['level'] ?? 1,
          'xp': data['xp'] ?? 0,
          'school_name': data['school_name'] ?? 'SMP Negeri 1 Jakarta',
        });
      }
      if (results.length >= 10) break;
    }
    return results;
  }

  Future<void> sendFriendRequest(String targetUid) async {
    final myUid = currentUser!.uid;
    final myDoc = await _db.collection('users').doc(myUid).get();
    final myData = myDoc.data() ?? {};

    await _db
        .collection('users')
        .doc(targetUid)
        .collection('friend_requests')
        .doc(myUid)
        .set({
      'uid': myUid,
      'from_uid': myUid,
      'username': myData['username'] ?? '',
      'name': myData['name'] ?? '',
      'from_name': myData['name'] ?? '',
      'avatar_url': myData['avatar_url'] ?? '🧑',
      'from_avatar': myData['avatar_url'] ?? '🧑',
      'school_name': myData['school_name'] ?? 'SMP Negeri 1 Jakarta',
      'from_school': myData['school_name'] ?? 'SMP Negeri 1 Jakarta',
      'sent_at': FieldValue.serverTimestamp(),
    });
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String fromUid) async {
    final myUid = currentUser!.uid;

    // Get both user profiles
    final myDoc = await _db.collection('users').doc(myUid).get();
    final fromDoc = await _db.collection('users').doc(fromUid).get();
    final myData = myDoc.data() ?? {};
    final fromData = fromDoc.data() ?? {};

    // Add to my friends subcollection
    await _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(fromUid)
        .set({
      'uid': fromUid,
      'username': fromData['username'] ?? '',
      'name': fromData['name'] ?? '',
      'avatar_url': fromData['avatar_url'] ?? '🧑',
      'added_at': FieldValue.serverTimestamp(),
    });

    // Add to their friends subcollection
    await _db
        .collection('users')
        .doc(fromUid)
        .collection('friends')
        .doc(myUid)
        .set({
      'uid': myUid,
      'username': myData['username'] ?? '',
      'name': myData['name'] ?? '',
      'avatar_url': myData['avatar_url'] ?? '🧑',
      'added_at': FieldValue.serverTimestamp(),
    });

    // Remove friend request
    await _db
        .collection('users')
        .doc(myUid)
        .collection('friend_requests')
        .doc(fromUid)
        .delete();
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String fromUid) async {
    final myUid = currentUser!.uid;
    await _db
        .collection('users')
        .doc(myUid)
        .collection('friend_requests')
        .doc(fromUid)
        .delete();
  }

  // Remove friend
  Future<void> removeFriend(String friendUid) async {
    final myUid = currentUser!.uid;

    // Remove from both users' friends subcollection
    await _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(friendUid)
        .delete();

    await _db
        .collection('users')
        .doc(friendUid)
        .collection('friends')
        .doc(myUid)
        .delete();
  }

  // Stream friend requests
  Stream<QuerySnapshot<Map<String, dynamic>>> getFriendRequestsStream() {
    final myUid = currentUser!.uid;
    return getFriendRequests(myUid);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFriendRequests(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friend_requests')
        .orderBy('sent_at', descending: true)
        .snapshots();
  }

  // Stream friends list
  Stream<QuerySnapshot<Map<String, dynamic>>> getFriendsStream() {
    final myUid = currentUser!.uid;
    return getFriendsList(myUid);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFriendsList(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots();
  }

  // Get another user's profile (one-time read)
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return doc.data();
    return null;
  }

  // Get friends count
  Future<int> getFriendsCount(String uid) async {
    final snapshot =
        await _db.collection('users').doc(uid).collection('friends').get();
    return snapshot.docs.length;
  }

  // ---------------------------------------------------------------------------
  // LEADERBOARD
  // ---------------------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> getLeaderboardStream() {
    return _db
        .collection('users')
        .orderBy('xp', descending: true)
        .limit(10)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // DUEL & MATCHMAKING
  // ---------------------------------------------------------------------------

  // Search or create a duel session
  Future<String> matchmake({
    required String subject,
    required String difficulty,
    required String myName,
  }) async {
    final myUid = currentUser!.uid;
    final normalizedSubject = subject.toLowerCase();
    final normalizedDiff = difficulty.toLowerCase();

    // Fetch my profile to get MMR
    final myProfileDoc = await _db.collection('users').doc(myUid).get();
    final myMmr = myProfileDoc.data()?['mmr'] ?? 80;

    // 1. Search for an open session (waiting, same subject, same difficulty, not created by me)
    final query = await _db
        .collection('duel_sessions')
        .where('status', isEqualTo: 'waiting')
        .where('subject', isEqualTo: normalizedSubject)
        .where('difficulty', isEqualTo: normalizedDiff)
        .limit(10)
        .get();

    String? bestSessionId;
    int closestMmrDiff = 100000;

    for (var doc in query.docs) {
      final data = doc.data();
      if (data['player1_id'] != myUid) {
        final creatorMmr = data['player1_mmr'] ?? 80;
        final mmrDiff = (creatorMmr - myMmr).abs();
        if (mmrDiff < closestMmrDiff && mmrDiff <= 100) {
          closestMmrDiff = mmrDiff;
          bestSessionId = doc.id;
        }
      }
    }

    if (bestSessionId != null) {
      await _db.collection('duel_sessions').doc(bestSessionId).update({
        'player2_id': myUid,
        'player2_name': myName,
        'player2_mmr': myMmr,
        'status': 'ongoing',
        'started_at': FieldValue.serverTimestamp(),
      });
      return bestSessionId;
    }

    // 2. If no match found, create a new waiting session
    final newSessionRef = _db.collection('duel_sessions').doc();
    await newSessionRef.set({
      'session_id': newSessionRef.id,
      'player1_id': myUid,
      'player1_name': myName,
      'player1_mmr': myMmr,
      'player2_id': '',
      'player2_name': '',
      'player2_mmr': 0,
      'subject': normalizedSubject,
      'difficulty': normalizedDiff,
      'status': 'waiting',
      'questions_per_session': 5,
      'time_per_question': 30,
      'score_player1': 0,
      'score_player2': 0,
      'winner_id': '',
      'created_at': FieldValue.serverTimestamp(),
    });

    return newSessionRef.id;
  }

  // Start matching with BOT if timeout
  Future<void> startBotMatch(String sessionId) async {
    final names = ['Kinz Bot 🤖', 'Rara 🦾', 'Bima ⚡', 'Siti 🎓', 'Andy 🧠'];
    final botName = names[Random().nextInt(names.length)];

    await _db.collection('duel_sessions').doc(sessionId).update({
      'player2_id': 'bot_id',
      'player2_name': botName,
      'status': 'ongoing',
      'started_at': FieldValue.serverTimestamp(),
    });
  }

  // Stream specific duel session
  Stream<DocumentSnapshot<Map<String, dynamic>>> getDuelStream(String sessionId) {
    return _db.collection('duel_sessions').doc(sessionId).snapshots();
  }

  // Update scores in real-time
  Future<void> updateScore(String sessionId, bool isPlayer1, int score) async {
    await _db.collection('duel_sessions').doc(sessionId).update({
      isPlayer1 ? 'score_player1' : 'score_player2': score,
    });
  }

  // End the duel and reward the winner
  Future<Map<String, dynamic>> finishDuel(String sessionId, String myUid) async {
    final doc = await _db.collection('duel_sessions').doc(sessionId).get();
    if (!doc.exists) return {'xp': 0, 'gems': 0, 'result': 'draw'};

    final data = doc.data()!;
    final p1 = data['player1_id'];
    final p2 = data['player2_id'];
    final s1 = data['score_player1'] as int;
    final s2 = data['score_player2'] as int;

    final isP1 = myUid == p1;
    final myScore = isP1 ? s1 : s2;
    final oppScore = isP1 ? s2 : s1;

    String result = 'draw';
    int xpReward = 20;
    int gemsReward = 5;

    if (myScore > oppScore) {
      result = 'win';
      xpReward = 100;
      gemsReward = 20;
    } else if (myScore < oppScore) {
      result = 'lose';
      xpReward = 30;
      gemsReward = 5;
    }

    // Mark session finished in database if not already done (prevent double finish execution)
    if (data['status'] != 'finished') {
      String winner = '';
      if (s1 > s2) winner = p1;
      if (s2 > s1) winner = p2;
      
      await _db.collection('duel_sessions').doc(sessionId).update({
        'status': 'finished',
        'winner_id': winner,
        'ended_at': FieldValue.serverTimestamp(),
      });
    }

    // Update user stats
    final userDoc = await _db.collection('users').doc(myUid).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final currentXp = userData['xp'] as int;
      final currentGems = userData['gems'] as int;
      final totalDuels = (userData['total_duels'] as int) + 1;
      
      int wins = userData['win_count'] as int;
      int losses = userData['lose_count'] as int;
      if (result == 'win') wins++;
      if (result == 'lose') losses++;

      final winRate = totalDuels > 0 ? (wins / totalDuels) : 0.0;
      final newXp = currentXp + xpReward;
      final newLevel = 1 + (newXp ~/ 1000); // Level increases every 1000 XP

      // Check for streak (simplified daily streak)
      int streak = userData['streak'] as int;
      final lastActiveStr = userData['streak_last_date'];
      if (lastActiveStr != null) {
        final lastActive = (lastActiveStr as Timestamp).toDate();
        final now = DateTime.now();
        final diff = now.difference(lastActive).inDays;
        if (diff > 1) {
          streak = 1; // streak broken, reset to 1
        } else if (diff == 1) {
          streak++; // played yesterday, increment
        }
      } else {
        streak = 1; // first game
      }

      int mmr = userData['mmr'] ?? 80;
      if (result == 'win') {
        mmr += 20;
      } else if (result == 'lose') {
        mmr = max(0, mmr - 10);
      }

      await _db.collection('users').doc(myUid).update({
        'xp': newXp,
        'gems': currentGems + gemsReward,
        'level': newLevel,
        'total_duels': totalDuels,
        'win_count': wins,
        'lose_count': losses,
        'win_rate': winRate,
        'streak': streak,
        'streak_last_date': FieldValue.serverTimestamp(),
        'mmr': mmr,
      });

      // Update weekly XP
      await addWeeklyXp(myUid, xpReward);

      // Save to my duel history
      final opponentName = isP1 ? data['player2_name'] : data['player1_name'];
      String opponentAvatar = '🧑';
      if (opponentName.isNotEmpty) {
        if (opponentName.contains('Bot') || p2 == 'bot_id' || p1 == 'bot_id') {
          opponentAvatar = '🤖';
        } else {
          final oppDoc = await _db.collection('users').doc(isP1 ? p2 : p1).get();
          if (oppDoc.exists) {
            opponentAvatar = oppDoc.data()?['avatar_url'] ?? '🧑';
          }
        }
      }
      
      await _db.collection('users').doc(myUid).collection('duel_history').add({
        'opponent_name': opponentName.isEmpty ? 'Lawan' : opponentName,
        'opponent_avatar': opponentAvatar,
        'subject': data['subject'] ?? 'Matematika',
        'result': result,
        'xp_earned': xpReward,
        'gems_earned': gemsReward, // Poin
        'created_at': FieldValue.serverTimestamp(),
      });

      // Update daily challenges progress
      if (result == 'win') {
        await incrementChallengeProgressByType(myUid, 'win_duel', 1);
      }
      
      final correctAnswersCount = myScore ~/ 100;
      if (correctAnswersCount > 0) {
        await incrementChallengeProgressByType(myUid, 'correct_answer', correctAnswersCount);
      }

      if (p2 != 'bot_id' && p2.isNotEmpty) {
        await incrementChallengeProgressByType(myUid, 'duel_friend', 1);
      }

      // Write transaction to logs
      await _db.collection('wallet_logs').add({
        'log_id': _db.collection('wallet_logs').doc().id,
        'user_id': myUid,
        'amount': gemsReward,
        'type': 'earn',
        'source': 'duel_$result',
        'reference_id': sessionId,
        'balance_after': currentGems + gemsReward,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    return {'xp': xpReward, 'gems': gemsReward, 'result': result};
  }

  // Load questions for the duel
  Future<List<Map<String, dynamic>>> getQuestionsForDuel(String subject, String difficulty) async {
    final query = await _db
        .collection('questions')
        .where('subject', isEqualTo: subject.toLowerCase())
        .where('difficulty', isEqualTo: difficulty.toLowerCase())
        .limit(10)
        .get();

    if (query.docs.isNotEmpty) {
      final list = query.docs.map((d) => d.data()).toList();
      list.shuffle();
      return list.take(5).toList();
    }

    // Return fallback sample questions if database is empty
    return _getFallbackQuestions(subject);
  }

  // ---------------------------------------------------------------------------
  // GACHA SYSTEM
  // ---------------------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> getGachaBanners() {
    return _db.collection('gacha_banners').snapshots();
  }

  Future<List<Map<String, dynamic>>> pullGacha({
    required String bannerId,
    required String bannerName,
    required int cost,
    required int pullCount, // 1 or 10
  }) async {
    final myUid = currentUser!.uid;
    final userDocRef = _db.collection('users').doc(myUid);
    final userDoc = await userDocRef.get();
    
    if (!userDoc.exists) throw Exception('Pengguna tidak ditemukan!');
    final userData = userDoc.data()!;
    final currentGems = userData['gems'] as int;

    if (currentGems < cost) {
      throw Exception('Gems tidak cukup!');
    }

    // Deduct gems
    await userDocRef.update({
      'gems': currentGems - cost,
    });

    // Write wallet log
    await _db.collection('wallet_logs').add({
      'log_id': _db.collection('wallet_logs').doc().id,
      'user_id': myUid,
      'amount': -cost,
      'type': 'spend',
      'source': 'gacha_pull',
      'reference_id': bannerId,
      'balance_after': currentGems - cost,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Roll gacha items based on rates
    final poolQuery = await _db
        .collection('gacha_banners')
        .doc(bannerId)
        .collection('item_pool')
        .get();

    List<Map<String, dynamic>> pool = [];
    if (poolQuery.docs.isNotEmpty) {
      pool = poolQuery.docs.map((d) => d.data()).toList();
    } else {
      pool = _getFallbackItemPool();
    }

    final rand = Random();
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < pullCount; i++) {
      // Pick item based on drop rate
      double roll = rand.nextDouble(); // 0.0 to 1.0
      double cumulative = 0.0;
      Map<String, dynamic> selectedItem = pool.last;

      for (var item in pool) {
        cumulative += (item['drop_rate'] ?? 0.1);
        if (roll <= cumulative) {
          selectedItem = item;
          break;
        }
      }

      results.add(selectedItem);

      // Save to user inventories collection
      final itemId = selectedItem['item_id'];
      final invRef = userDocRef.collection('inventories').doc(itemId);
      final invDoc = await invRef.get();

      if (invDoc.exists) {
        await invRef.update({
          'quantity': (invDoc.data()!['quantity'] as int) + 1,
        });
      } else {
        await invRef.set({
          'item_id': itemId,
          'item_name': selectedItem['item_name'],
          'item_type': selectedItem['item_type'] ?? 'avatar',
          'item_image': selectedItem['item_image'] ?? '🧑',
          'is_equipped': false,
          'quantity': 1,
          'obtained_at': FieldValue.serverTimestamp(),
        });
      }

      // Record gacha pull log
      await _db.collection('gacha_pulls').add({
        'pull_id': _db.collection('gacha_pulls').doc().id,
        'user_id': myUid,
        'banner_id': bannerId,
        'item_id': itemId,
        'rarity': selectedItem['rarity'] ?? 'common',
        'pulled_at': FieldValue.serverTimestamp(),
      });
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // EQUIP ITEM
  // ---------------------------------------------------------------------------

  // Equip an item from inventory
  Future<void> equipItem(String itemId, String itemType) async {
    final myUid = currentUser!.uid;
    final invRef = _db.collection('users').doc(myUid).collection('inventories');

    // 1. Unequip all items of the same type
    final sameType = await invRef
        .where('item_type', isEqualTo: itemType)
        .where('is_equipped', isEqualTo: true)
        .get();
    for (var doc in sameType.docs) {
      await doc.reference.update({'is_equipped': false});
    }

    // 2. Equip the selected item
    await invRef.doc(itemId).update({'is_equipped': true});

    // 3. Update user document based on type
    if (itemType == 'avatar') {
      final itemDoc = await invRef.doc(itemId).get();
      if (itemDoc.exists) {
        await _db.collection('users').doc(myUid).update({
          'avatar_url': itemDoc.data()!['item_image'] ?? '🧑',
        });
      }
    } else if (itemType == 'background') {
      final itemDoc = await invRef.doc(itemId).get();
      if (itemDoc.exists) {
        await _db.collection('users').doc(myUid).update({
          'theme_id': itemId,
        });
      }
    } else if (itemType == 'effect') {
      final itemDoc = await invRef.doc(itemId).get();
      if (itemDoc.exists) {
        await _db.collection('users').doc(myUid).update({
          'effect_id': itemId,
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BADGES
  // ---------------------------------------------------------------------------

  // Get all badge definitions
  List<Map<String, dynamic>> getAllBadgeDefinitions() {
    return [
      {'badge_id': 'pioneer', 'badge_name': 'Pejuang Pertama', 'badge_icon': '🏆', 'description': 'Berhasil bergabung dengan StudyDuel!'},
      {'badge_id': 'first_duel', 'badge_name': 'Petarung Baru', 'badge_icon': '⚔️', 'description': 'Menyelesaikan duel pertamamu!'},
      {'badge_id': 'top10', 'badge_name': 'Top 10 Global', 'badge_icon': '🎖️', 'description': 'Meraih peringkat 10 besar di leaderboard global'},
      {'badge_id': 'win100', 'badge_name': '100 Winstreak', 'badge_icon': '🏅', 'description': 'Memenangkan 100 pertandingan berturut-turut'},
      {'badge_id': 'ipa_expert', 'badge_name': 'IPA Expert', 'badge_icon': '🔬', 'description': 'Memenangkan 100 duel mata pelajaran IPA'},
      {'badge_id': 'math_master', 'badge_name': 'Math Master', 'badge_icon': '🧮', 'description': 'Memenangkan 100 duel Matematika'},
      {'badge_id': 'social_star', 'badge_name': 'Social Star', 'badge_icon': '🌍', 'description': 'Memenangkan 100 duel IPS'},
      {'badge_id': 'bahasa_boss', 'badge_name': 'Bahasa Boss', 'badge_icon': '📚', 'description': 'Memenangkan 100 duel Bahasa'},
      {'badge_id': 'first_gacha', 'badge_name': 'Lucky Pull', 'badge_icon': '🎰', 'description': 'Melakukan gacha pertamamu!'},
      {'badge_id': 'collector', 'badge_name': 'Kolektor', 'badge_icon': '🎒', 'description': 'Mengumpulkan 10 item dari gacha'},
    ];
  }

  // Award a badge to a user
  Future<void> awardBadge(String uid, String badgeId) async {
    final badges = getAllBadgeDefinitions();
    final badge = badges.firstWhere(
      (b) => b['badge_id'] == badgeId,
      orElse: () => {},
    );
    if (badge.isEmpty) return;

    final ref = _db.collection('users').doc(uid).collection('badges').doc(badgeId);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        ...badge,
        'is_pinned': false,
        'earned_at': FieldValue.serverTimestamp(),
      });
    }
  }

  // ---------------------------------------------------------------------------
  // SEED SAMPLE DATA (AUTO INITIALIZE IF EMPTY)
  // ---------------------------------------------------------------------------

  Future<void> initializeDataIfNeeded() async {
    try {
      final banners = await _db.collection('gacha_banners').limit(1).get();
      if (banners.docs.isEmpty) {
        // Populate banners
        final bannerRef = _db.collection('gacha_banners').doc('default_banner');
        await bannerRef.set({
          'banner_id': 'default_banner',
          'name': 'Cosmic Gacha',
          'description': 'Dapatkan latar belakang, efek nitro, dan avatar pejuang spesial!',
          'cost': 1,
          'cost_type': 'tickets',
          'is_featured': true,
          'banner_image': '🎰',
          'created_at': FieldValue.serverTimestamp(),
        });

        // Populate item pool
        final pool = _getFallbackItemPool();
        for (var item in pool) {
          await bannerRef.collection('item_pool').doc(item['item_id']).set(item);
        }
      } else {
        // Always populate/update item pool to include new backgrounds & effects
        final bannerRef = _db.collection('gacha_banners').doc('default_banner');
        final pool = _getFallbackItemPool();
        for (var item in pool) {
          await bannerRef.collection('item_pool').doc(item['item_id']).set(item);
        }
      }

      // Check if we need to seed questions
      final questionsQuery = await _db.collection('questions').limit(10).get();
      if (questionsQuery.docs.length < 10) {
        // Seed 100+ questions
        final subjects = ['matematika', 'ipa', 'ips', 'bahasa indonesia', 'bahasa'];
        for (var subj in subjects) {
          final list = _getFallbackQuestions(subj);
          for (var i = 0; i < list.length; i++) {
            final q = list[i];
            String diff = 'mudah';
            if (i >= 7 && i < 14) diff = 'sedang';
            if (i >= 14) diff = 'sulit';
            
            final qId = 'q_${subj}_${diff}_$i';
            await _db.collection('questions').doc(qId).set({
              'question_id': qId,
              'created_by': 'system',
              'subject': subj,
              'difficulty': diff,
              'content': q['q'],
              'options': q['opts'],
              'correct_answer': q['opts'][q['ans']],
              'ans': q['ans'],
              'is_validated': true,
              'created_at': FieldValue.serverTimestamp(),
            });
          }
        }
        print("StudyDuel: Database questions seeded successfully!");
      }
    } catch (e) {
      print("StudyDuel Seed Error: $e");
    }
  }

  // Fallback Questions Provider
  List<Map<String, dynamic>> _getFallbackQuestions(String subject) {
    final s = subject.toLowerCase().trim();
    if (s == 'matematika') {
      return [
        {'q': 'Hasil dari 2³ × 5² adalah...', 'opts': ['100', '200', '150', '250'], 'ans': 1},
        {'q': 'Berapa jumlah sisi pada bangun ruang kubus?', 'opts': ['4', '6', '8', '12'], 'ans': 1},
        {'q': 'Jika x + 5 = 12, maka nilai x adalah...', 'opts': ['5', '6', '7', '8'], 'ans': 2},
        {'q': 'Luas segitiga dengan alas 10 cm dan tinggi 8 cm adalah...', 'opts': ['40 cm²', '80 cm²', '20 cm²', '30 cm²'], 'ans': 0},
        {'q': 'Faktor Persekutuan Terbesar (FPB) dari 12 dan 18 adalah...', 'opts': ['2', '3', '6', '12'], 'ans': 2},
        {'q': 'Nilai dari 7² - 4² adalah...', 'opts': ['30', '33', '35', '40'], 'ans': 1},
        {'q': 'Berapa jumlah titik sudut pada bangun balok?', 'opts': ['4', '6', '8', '12'], 'ans': 2},
        {'q': 'Median dari data: 2, 4, 5, 6, 8 adalah...', 'opts': ['4', '5', '6', '8'], 'ans': 1},
        {'q': 'Rumus keliling lingkaran adalah...', 'opts': ['πr²', '2πr', 'πd²', '2πr²'], 'ans': 1},
        {'q': 'Kelipatan Persekutuan Terkecil (KPK) dari 6 dan 8 adalah...', 'opts': ['12', '16', '18', '24'], 'ans': 3},
        {'q': 'Hasil dari 15 + 4 × 5 adalah...', 'opts': ['95', '35', '75', '45'], 'ans': 1},
        {'q': 'Nilai dari √144 adalah...', 'opts': ['10', '11', '12', '14'], 'ans': 2},
        {'q': 'Hasil dari 3/4 + 1/2 adalah...', 'opts': ['4/6', '5/4', '1', '1/4'], 'ans': 1},
        {'q': 'Berapa besar sudut dalam pada segitiga sama sisi?', 'opts': ['45°', '60°', '90°', '180°'], 'ans': 1},
        {'q': 'Gradien dari persamaan garis y = 2x + 5 adalah...', 'opts': ['1', '2', '3', '5'], 'ans': 1},
        {'q': 'Volume kubus dengan rusuk 5 cm adalah...', 'opts': ['25 cm³', '50 cm³', '100 cm³', '125 cm³'], 'ans': 3},
        {'q': 'Hasil dari 20% dari 150 adalah...', 'opts': ['15', '20', '30', '40'], 'ans': 2},
        {'q': 'Berapa jumlah sisi pada prisma segitiga?', 'opts': ['3', '4', '5', '6'], 'ans': 2},
        {'q': 'Nilai dari (3 + 2)³ adalah...', 'opts': ['25', '75', '125', '225'], 'ans': 2},
        {'q': 'Jika 2x = 10, maka nilai 3x adalah...', 'opts': ['12', '15', '18', '20'], 'ans': 1},
      ];
    } else if (s == 'ipa' || s == 'science' || s == 'sains') {
      return [
        {'q': 'Planet terdekat dengan matahari adalah...', 'opts': ['Venus', 'Bumi', 'Merkurius', 'Mars'], 'ans': 2},
        {'q': 'Rumus kimia air adalah...', 'opts': ['CO₂', 'H₂O', 'O₂', 'NaCl'], 'ans': 1},
        {'q': 'Bagian sel tumbuhan yang berfungsi untuk fotosintesis adalah...', 'opts': ['Vakuola', 'Dinding Sel', 'Kloroplas', 'Mitokondria'], 'ans': 2},
        {'q': 'Gaya tarik bumi disebut juga gaya...', 'opts': ['Magnet', 'Gesek', 'Gravitasi', 'Pegas'], 'ans': 2},
        {'q': 'Hewan yang memakan tumbuhan saja disebut...', 'opts': ['Karnivora', 'Herbivora', 'Omnivora', 'Insektivora'], 'ans': 1},
        {'q': 'Gas yang kita hirup saat bernapas adalah...', 'opts': ['Oksigen', 'Karbondioksida', 'Nitrogen', 'Helium'], 'ans': 0},
        {'q': 'Logam cair yang digunakan pada termometer raksa adalah...', 'opts': ['Besi', 'Emas', 'Raksa', 'Tembaga'], 'ans': 2},
        {'q': 'Organ tubuh yang memompa darah ke seluruh tubuh adalah...', 'opts': ['Paru-paru', 'Jantung', 'Hati', 'Ginjal'], 'ans': 1},
        {'q': 'Perubahan wujud zat padat menjadi gas disebut...', 'opts': ['Mencair', 'Menguap', 'Menyublim', 'Membeku'], 'ans': 2},
        {'q': 'Satuan energi dalam Sistem Internasional (SI) adalah...', 'opts': ['Watt', 'Joule', 'Newton', 'Volt'], 'ans': 1},
        {'q': 'Tulang yang berfungsi melindungi organ otak manusia adalah...', 'opts': ['Tengkorak', 'Rusuk', 'Belikat', 'Dada'], 'ans': 0},
        {'q': 'Pencernaan kimiawi protein dimulai di organ...', 'opts': ['Mulut', 'Kerongkongan', 'Lambung', 'Usus Besar'], 'ans': 2},
        {'q': 'Simbiosis antara lebah dan bunga adalah contoh simbiosis...', 'opts': ['Mutualisme', 'Komensalisme', 'Parasitisme', 'Amensalisme'], 'ans': 0},
        {'q': 'Tumbuhan membuat makanan sendiri melalui proses...', 'opts': ['Respirasi', 'Fotosintesis', 'Transpirasi', 'Osmosis'], 'ans': 1},
        {'q': 'Sumber energi utama bagi kehidupan di bumi adalah...', 'opts': ['Batu Bara', 'Minyak Bumi', 'Matahari', 'Listrik'], 'ans': 2},
        {'q': 'Bagian mata yang berfungsi mengatur jumlah cahaya yang masuk adalah...', 'opts': ['Retina', 'Iris', 'Pupil', 'Kornea'], 'ans': 2},
        {'q': 'Lapisan terluar dari struktur bumi disebut...', 'opts': ['Kerak Bumi', 'Selimut Bumi', 'Inti Luar', 'Inti Dalam'], 'ans': 0},
        {'q': 'Perkembangbiakan vegetatif pada pohon pisang dilakukan dengan...', 'opts': ['Spora', 'Tunas', 'Geragih', 'Umbi Batang'], 'ans': 1},
        {'q': 'Zat hijau daun pada tumbuhan disebut...', 'opts': ['Klorofil', 'Kloroplas', 'Karoten', 'Stomata'], 'ans': 0},
        {'q': 'Suhu mendidih air pada tekanan udara normal (1 atm) adalah...', 'opts': ['80°C', '90°C', '100°C', '120°C'], 'ans': 2},
      ];
    } else if (s == 'ips' || s == 'social' || s == 'sosial') {
      return [
        {'q': 'Ibu kota negara Indonesia saat ini adalah...', 'opts': ['Surabaya', 'Bandung', 'Jakarta', 'Medan'], 'ans': 2},
        {'q': 'Benua terbesar di dunia adalah benua...', 'opts': ['Afrika', 'Asia', 'Amerika', 'Eropa'], 'ans': 1},
        {'q': 'Mata uang negara Jepang adalah...', 'opts': ['Yen', 'Won', 'Dollar', 'Rupiah'], 'ans': 0},
        {'q': 'Negara di Asia Tenggara yang tidak pernah dijajah adalah...', 'opts': ['Malaysia', 'Thailand', 'Filipina', 'Vietnam'], 'ans': 1},
        {'q': 'Candi Buddha terbesar di Indonesia adalah...', 'opts': ['Prambanan', 'Borobudur', 'Mendut', 'Kalasan'], 'ans': 1},
        {'q': 'Samudra terluas di dunia adalah...', 'opts': ['Hindia', 'Pasifik', 'Atlantik', 'Arktik'], 'ans': 1},
        {'q': 'Peristiwa Rengasdengklok berkaitan erat dengan...', 'opts': ['Sumpah Pemuda', 'Proklamasi Kemerdekaan', 'Perang Diponegoro', 'Bandung Lautan Api'], 'ans': 1},
        {'q': 'Batas wilayah Indonesia sebelah utara berbatasan langsung dengan...', 'opts': ['Australia', 'Malaysia', 'Timor Leste', 'Papua Nugini'], 'ans': 1},
        {'q': 'Benua terkecil di dunia adalah...', 'opts': ['Eropa', 'Antartika', 'Australia', 'Amerika Selatan'], 'ans': 2},
        {'q': 'Gunung tertinggi di dunia adalah...', 'opts': ['Semeru', 'Fuji', 'Kilimanjaro', 'Everest'], 'ans': 3},
        {'q': 'Negara kincir angin adalah sebutan populer untuk negara...', 'opts': ['Belanda', 'Inggris', 'Jerman', 'Prancis'], 'ans': 0},
        {'q': 'Pendiri utama organisasi pergerakan nasional Budi Utomo adalah...', 'opts': ['Dr. Soetomo', 'Ir. Soekarno', 'Ki Hajar Dewantara', 'Dr. Wahidin Sudirohusodo'], 'ans': 0},
        {'q': 'Organisasi regional negara-negara Asia Tenggara (ASEAN) didirikan pada tahun...', 'opts': ['1945', '1955', '1967', '1975'], 'ans': 2},
        {'q': 'Benua hitam adalah sebutan akrab bagi benua...', 'opts': ['Asia', 'Amerika', 'Afrika', 'Eropa'], 'ans': 2},
        {'q': 'Kerajaan Hindu tertua di Indonesia adalah...', 'opts': ['Tarumanegara', 'Kutai', 'Majapahit', 'Sriwijaya'], 'ans': 1},
        {'q': 'Garis khayal yang membagi bumi menjadi belahan utara dan selatan disebut...', 'opts': ['Khatulistiwa', 'Meridian', 'Lintang', 'Bujur'], 'ans': 0},
        {'q': 'Danau terbesar di Indonesia yang terbentuk akibat aktivitas vulkanik adalah...', 'opts': ['Danau Toba', 'Danau Singkarak', 'Danau Maninjau', 'Danau Poso'], 'ans': 0},
        {'q': 'Lagu kebangsaan negara Indonesia berjudul...', 'opts': ['Satu Nusa Satu Bangsa', 'Indonesia Raya', 'Bagimu Negeri', 'Hari Merdeka'], 'ans': 1},
        {'q': 'Pahlawan nasional dari Makassar yang mendapat julukan Ayam Jantan dari Timur adalah...', 'opts': ['Sultan Hasanuddin', 'Pangeran Diponegoro', 'Tuanku Imam Bonjol', 'Pattimura'], 'ans': 0},
        {'q': 'Ibukota provinsi Jawa Barat berada di kota...', 'opts': ['Bogor', 'Bandung', 'Bekasi', 'Depok'], 'ans': 1},
      ];
    } else if (s == 'bahasa indonesia' || s == 'b. indonesia' || s == 'indonesian') {
      return [
        {'q': 'Lawan kata (antonim) dari kata "subur" adalah...', 'opts': ['Makmur', 'Gersang', 'Rindang', 'Basah'], 'ans': 1},
        {'q': 'Kata dasar dari "menulis" adalah...', 'opts': ['Tulis', 'Nulis', 'Penulis', 'Tulisan'], 'ans': 0},
        {'q': 'Kalimat yang subjeknya melakukan suatu pekerjaan disebut kalimat...', 'opts': ['Aktif', 'Pasif', 'Tanya', 'Perintah'], 'ans': 0},
        {'q': 'Dongeng tentang hewan yang bertingkah laku seperti manusia disebut...', 'opts': ['Legenda', 'Mite', 'Fabel', 'Sage'], 'ans': 2},
        {'q': 'Ide pokok yang terkandung dalam sebuah paragraf disebut...', 'opts': ['Gagasan Utama', 'Kalimat Penjelas', 'Simpulan', 'Alur'], 'ans': 0},
        {'q': 'Singkatan resmi dari "Majelis Permusyawaratan Rakyat" adalah...', 'opts': ['DPR', 'MPR', 'DPD', 'MK'], 'ans': 1},
        {'q': 'Penulisan kata depan di di bawah ini yang tepat adalah...', 'opts': ['di sekolah', 'disekolah', 'di tulis', 'ditoko'], 'ans': 0},
        {'q': 'Sinonim dari kata "pandai" adalah...', 'opts': ['Bodoh', 'Pintar', 'Malas', 'Rajin'], 'ans': 1},
        {'q': 'Tanda baca yang digunakan untuk mengakhiri kalimat berita adalah...', 'opts': ['Koma', 'Tanya', 'Seru', 'Titik'], 'ans': 3},
        {'q': 'Gaya bahasa yang membandingkan benda mati seolah hidup disebut majas...', 'opts': ['Metafora', 'Hiperbola', 'Personifikasi', 'Asosiasi'], 'ans': 2},
        {'q': 'Kata tanya yang digunakan untuk menanyakan suatu tempat adalah...', 'opts': ['Siapa', 'Kapan', 'Di mana', 'Bagaimana'], 'ans': 2},
        {'q': 'Buku yang memuat kumpulan karya puisi disebut buku...', 'opts': ['Novel', 'Biografi', 'Antologi', 'Kamus'], 'ans': 2},
        {'q': 'Persamaan bunyi di akhir baris pada bait puisi disebut...', 'opts': ['Bait', 'Baris', 'Rima', 'Tema'], 'ans': 2},
        {'q': 'Manakah dari kata berikut yang merupakan kata baku?', 'opts': ['Apotik', 'Apotek', 'Nasehat', 'Jadwal'], 'ans': 1},
        {'q': 'Kalimat yang hanya memiliki satu pola kalimat (S-P) disebut...', 'opts': ['Kalimat Tunggal', 'Kalimat Majemuk', 'Kalimat Aktif', 'Kalimat Pasif'], 'ans': 0},
        {'q': 'Tokoh utama yang berwatak baik dalam suatu cerita disebut...', 'opts': ['Protagonis', 'Antagonis', 'Tritagonis', 'Figuran'], 'ans': 0},
        {'q': 'Lawan kata dari "panas" adalah...', 'opts': ['Dingin', 'Hangat', 'Sejuk', 'Basah'], 'ans': 0},
        {'q': 'Paragraf yang kalimat utamanya terletak di awal paragraf disebut...', 'opts': ['Deduktif', 'Induktif', 'Campuran', 'Naratif'], 'ans': 0},
        {'q': 'Kata "mengendarai" memiliki kata dasar...', 'opts': ['Kendara', 'Kendarai', 'Pengendara', 'Kendaraan'], 'ans': 1},
        {'q': 'Cerita rekaan atau cerita khayalan yang tidak nyata disebut cerita...', 'opts': ['Fiksi', 'Nonfiksi', 'Sejarah', 'Biografi'], 'ans': 0},
      ];
    } else {
      return [
        {'q': 'What is the English of "Perpustakaan"?', 'opts': ['Classroom', 'Office', 'Library', 'Canteen'], 'ans': 2},
        {'q': 'She ... to school every day by bicycle.', 'opts': ['go', 'goes', 'went', 'going'], 'ans': 1},
        {'q': 'The opposite of the word "heavy" is...', 'opts': ['light', 'dark', 'small', 'big'], 'ans': 0},
        {'q': 'I have a ... of new shoes.', 'opts': ['pair', 'some', 'group', 'piece'], 'ans': 0},
        {'q': 'We use a ... to tell the current time.', 'opts': ['calendar', 'map', 'clock', 'compass'], 'ans': 2},
        {'q': 'The Indonesian meaning of the word "beautiful" is...', 'opts': ['jelek', 'cantik', 'pandai', 'tinggi'], 'ans': 1},
        {'q': 'What is the past tense form of the verb "go"?', 'opts': ['goes', 'going', 'went', 'gone'], 'ans': 2},
        {'q': 'They ... playing football in the field now.', 'opts': ['is', 'am', 'are', 'was'], 'ans': 2},
        {'q': 'He is a ... He works at the hospital and cures sick people.', 'opts': ['teacher', 'doctor', 'pilot', 'driver'], 'ans': 1},
        {'q': 'Which one of these is a type of fruit?', 'opts': ['Carrot', 'Spinach', 'Apple', 'Potato'], 'ans': 2},
        {'q': 'The opposite of the word "happy" is...', 'opts': ['sad', 'angry', 'glad', 'excited'], 'ans': 0},
        {'q': 'How do you say "Selamat pagi" in English?', 'opts': ['Good morning', 'Good afternoon', 'Good evening', 'Good night'], 'ans': 0},
        {'q': 'What is the capital city of England?', 'opts': ['Paris', 'London', 'Berlin', 'Rome'], 'ans': 1},
        {'q': 'A person who flies an airplane is called a...', 'opts': ['pilot', 'captain', 'astronaut', 'sailor'], 'ans': 0},
        {'q': 'What ... you doing last night?', 'opts': ['are', 'was', 'were', 'do'], 'ans': 2},
        {'q': 'I ... a letter to my friend yesterday.', 'opts': ['write', 'wrote', 'written', 'writing'], 'ans': 1},
        {'q': 'The plural form of the word "child" is...', 'opts': ['childs', 'childes', 'children', 'childrens'], 'ans': 2},
        {'q': 'The word "Book" is a type of...', 'opts': ['noun', 'verb', 'adjective', 'adverb'], 'ans': 0},
        {'q': 'We have ... fingers on each hand.', 'opts': ['four', 'five', 'ten', 'eight'], 'ans': 1},
        {'q': 'Yesterday was Wednesday. Today is...', 'opts': ['Monday', 'Tuesday', 'Thursday', 'Friday'], 'ans': 2},
      ];
    }
  }

  List<Map<String, dynamic>> _getFallbackItemPool() {
    return [
      {'item_id': 'einstein', 'item_name': 'Albert Einstein', 'item_type': 'avatar', 'item_image': '👴', 'rarity': 'legendary', 'drop_rate': 0.03},
      {'item_id': 'astronaut', 'item_name': 'Astronot', 'item_type': 'avatar', 'item_image': '👨‍🚀', 'rarity': 'epic', 'drop_rate': 0.06},
      {'item_id': 'wizard', 'item_name': 'Penyihir Kinz', 'item_type': 'avatar', 'item_image': '🧙', 'rarity': 'epic', 'drop_rate': 0.08},
      {'item_id': 'owl', 'item_name': 'Burung Hantu Bijak', 'item_type': 'avatar', 'item_image': '🦉', 'rarity': 'rare', 'drop_rate': 0.12},
      {'item_id': 'ninja', 'item_name': 'Ninja Master', 'item_type': 'avatar', 'item_image': '🥷', 'rarity': 'rare', 'drop_rate': 0.12},
      
      {'item_id': 'crimson_spark', 'item_name': 'Crimson Spark', 'item_type': 'background', 'item_image': '🍁', 'rarity': 'legendary', 'drop_rate': 0.03},
      {'item_id': 'galaxy_requiem', 'item_name': 'Galaxy Requiem', 'item_type': 'background', 'item_image': '🌌', 'rarity': 'mythical', 'drop_rate': 0.01},
      {'item_id': 'neon_cyberpunk', 'item_name': 'Neon Cyberpunk', 'item_type': 'background', 'item_image': '🌆', 'rarity': 'legendary', 'drop_rate': 0.03},
      {'item_id': 'forest_serenade', 'item_name': 'Forest Serenade', 'item_type': 'background', 'item_image': '🌲', 'rarity': 'rare', 'drop_rate': 0.08},
      {'item_id': 'sunset_breeze', 'item_name': 'Sunset Breeze', 'item_type': 'background', 'item_image': '🌅', 'rarity': 'rare', 'drop_rate': 0.08},
      
      {'item_id': 'sun_blaster', 'item_name': 'Sun Blaster', 'item_type': 'effect', 'item_image': '☀️', 'rarity': 'legendary', 'drop_rate': 0.03},
      {'item_id': 'thunder_blade', 'item_name': 'Thunder Blade', 'item_type': 'effect', 'item_image': '⚡', 'rarity': 'epic', 'drop_rate': 0.06},
      {'item_id': 'star_spark', 'item_name': 'Star Spark', 'item_type': 'effect', 'item_image': '✨', 'rarity': 'common', 'drop_rate': 0.16},
      {'item_id': 'sakura_breeze', 'item_name': 'Sakura Breeze', 'item_type': 'effect', 'item_image': '🌸', 'rarity': 'epic', 'drop_rate': 0.06},
      {'item_id': 'matrix_digital', 'item_name': 'Matrix Digital', 'item_type': 'effect', 'item_image': '🟢', 'rarity': 'mythical', 'drop_rate': 0.01},
      {'item_id': 'aqua_bubbles', 'item_name': 'Aqua Bubbles', 'item_type': 'effect', 'item_image': '🫧', 'rarity': 'common', 'drop_rate': 0.14},
    ];
  }

  // ---------------------------------------------------------------------------
  // NEW USER SYNC & CHALLENGE METHODS
  // ---------------------------------------------------------------------------

  Future<void> checkAndSyncUserData(String uid, Map<String, dynamic> userData) async {
    final Map<String, dynamic> updates = {};

    final tickets = userData['tickets'] ?? 0;
    if (tickets < 100) {
      updates['tickets'] = 100;
    }

    if (userData['mmr'] == null) {
      updates['mmr'] = 80;
    }

    if (userData['gacha_pity_epic'] == null) {
      updates['gacha_pity_epic'] = 0;
    }
    if (userData['gacha_pity_legendary'] == null) {
      updates['gacha_pity_legendary'] = 0;
    }

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStr = "${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}";
    final weeklyXpStart = userData['weekly_xp_start_date'] as String?;
    
    if (weeklyXpStart != mondayStr || userData['weekly_xp'] == null) {
      updates['weekly_xp'] = {
        'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
      };
      updates['weekly_xp_start_date'] = mondayStr;
    }

    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final challengesDate = userData['daily_challenges_date'] as String?;
    if (challengesDate != todayStr || userData['daily_challenges'] == null) {
      final randomChallenges = _generateRandomChallenges();
      updates['daily_challenges'] = randomChallenges;
      updates['daily_challenges_date'] = todayStr;
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  List<Map<String, dynamic>> _generateRandomChallenges() {
    final pool = [
      {'challenge_id': 'win_1_duel', 'title': 'Menangkan 1 Duel Arena', 'target_progress': 1, 'xp_reward': 40, 'gems_reward': 10},
      {'challenge_id': 'win_3_duels', 'title': 'Menangkan 3 Duel Arena', 'target_progress': 3, 'xp_reward': 100, 'gems_reward': 25},
      {'challenge_id': 'answer_5_correct', 'title': 'Jawab 5 Soal Benar', 'target_progress': 5, 'xp_reward': 30, 'gems_reward': 10},
      {'challenge_id': 'answer_10_correct', 'title': 'Jawab 10 Soal Benar', 'target_progress': 10, 'xp_reward': 60, 'gems_reward': 20},
      {'challenge_id': 'play_offline', 'title': 'Main Mode Offline', 'target_progress': 1, 'xp_reward': 30, 'gems_reward': 10},
      {'challenge_id': 'do_gacha', 'title': 'Lakukan Gacha 1 Kali', 'target_progress': 1, 'xp_reward': 40, 'gems_reward': 15},
      {'challenge_id': 'add_friend', 'title': 'Tambahkan 1 Teman Baru', 'target_progress': 1, 'xp_reward': 30, 'gems_reward': 10},
      {'challenge_id': 'duel_friend', 'title': 'Duel dengan Teman', 'target_progress': 1, 'xp_reward': 50, 'gems_reward': 20},
    ];

    pool.shuffle();
    return pool.take(5).map((c) => {
      ...c,
      'current_progress': 0,
      'claimed': false,
    }).toList();
  }

  Future<void> incrementChallengeProgressByType(String uid, String actionType, int increment) async {
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final challenges = data['daily_challenges'] as List<dynamic>?;
    if (challenges == null || challenges.isEmpty) return;

    final List<Map<String, dynamic>> updated = [];
    bool changed = false;

    for (var c in challenges) {
      final map = Map<String, dynamic>.from(c as Map);
      final id = map['challenge_id'] as String;
      final claimed = map['claimed'] ?? false;

      bool match = false;
      if (actionType == 'win_duel' && (id == 'win_1_duel' || id == 'win_3_duels')) match = true;
      if (actionType == 'correct_answer' && (id == 'answer_5_correct' || id == 'answer_10_correct')) match = true;
      if (actionType == 'play_offline' && id == 'play_offline') match = true;
      if (actionType == 'do_gacha' && id == 'do_gacha') match = true;
      if (actionType == 'add_friend' && id == 'add_friend') match = true;
      if (actionType == 'duel_friend' && id == 'duel_friend') match = true;

      if (match && !claimed) {
        final current = map['current_progress'] ?? 0;
        final target = map['target_progress'] ?? 1;
        if (current < target) {
          map['current_progress'] = min(target, current + increment);
          changed = true;
        }
      }
      updated.add(map);
    }

    if (changed) {
      await docRef.update({'daily_challenges': updated});
    }
  }

  Future<void> claimChallenge(String uid, String challengeId) async {
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final challenges = data['daily_challenges'] as List<dynamic>?;
    if (challenges == null || challenges.isEmpty) return;

    int xpReward = 0;
    int gemsReward = 0;
    final List<Map<String, dynamic>> updated = [];
    bool found = false;

    for (var c in challenges) {
      final map = Map<String, dynamic>.from(c as Map);
      if (map['challenge_id'] == challengeId && !(map['claimed'] ?? false)) {
        final current = map['current_progress'] ?? 0;
        final target = map['target_progress'] ?? 1;
        if (current >= target) {
          map['claimed'] = true;
          xpReward = map['xp_reward'] ?? 0;
          gemsReward = map['gems_reward'] ?? 0;
          found = true;
        }
      }
      updated.add(map);
    }

    if (found) {
      final currentXp = data['xp'] as int? ?? 0;
      final currentGems = data['gems'] as int? ?? 0;
      
      final newXp = currentXp + xpReward;
      final newLevel = 1 + (newXp ~/ 1000);
      
      await docRef.update({
        'daily_challenges': updated,
        'xp': newXp,
        'gems': currentGems + gemsReward,
        'level': newLevel,
      });

      await addWeeklyXp(uid, xpReward);
    }
  }

  Future<void> addWeeklyXp(String uid, int xpAmount) async {
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final now = DateTime.now();
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayKey = days[now.weekday - 1];

    final weeklyXp = Map<String, dynamic>.from(data['weekly_xp'] ?? {
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
    });
    
    weeklyXp[todayKey] = (weeklyXp[todayKey] ?? 0) + xpAmount;
    
    await docRef.update({
      'weekly_xp': weeklyXp,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDuelHistoryStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('duel_history')
        .orderBy('created_at', descending: true)
        .limit(10)
        .snapshots();
  }

}
