import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notification_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  static final Map<String, List<Map<String, dynamic>>> _cachedItemPools = {};

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
          'avatar_url': 'kinz.png',
          'class_id': '',
          'school_name': 'SMP Negeri 1 Jakarta',
          'grade': '8A',
          'level': 1,
          'xp': 0,
          'gems': 0,
          'tickets': 0,
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
          'badge_icon': 'emoji_events_rounded',
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
    required String schoolName,
    required String grade,
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
        'avatar_url': 'kinz.png',
        'class_id': '',
        'school_name': schoolName.trim(),
        'grade': grade.trim(),
        'level': 1,
        'xp': 0,
        'gems': 0,
        'tickets': 0,
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
        'badge_icon': 'emoji_events_rounded',
        'description': 'Berhasil bergabung dengan StudyDuel!',
        'is_pinned': true,
        'earned_at': FieldValue.serverTimestamp(),
      });
    }
    return cred;
  }

  // Logout
  Future<void> signOut() async {
    try {
      await NotificationService().clearTokenFromFirestore();
    } catch (e) {
      // ignore: avoid_print
      print("Error clearing FCM token during logout: $e");
    }
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
          'avatar_url': data['avatar_url'] ?? 'kinz.png',
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
      'avatar_url': myData['avatar_url'] ?? 'kinz.png',
      'from_avatar': myData['avatar_url'] ?? 'kinz.png',
      'school_name': myData['school_name'] ?? 'SMP Negeri 1 Jakarta',
      'from_school': myData['school_name'] ?? 'SMP Negeri 1 Jakarta',
      'sent_at': FieldValue.serverTimestamp(),
    });

    // Send notification to the target user (disabled as requested)
    // await _db
    //     .collection('users')
    //     .doc(targetUid)
    //     .collection('notifications')
    //     .add({
    //   'type': 'friend_request',
    //   'title': 'Permintaan Pertemanan',
    //   'body': '${myData['name'] ?? 'Seseorang'} mengirimkan permintaan pertemanan.',
    //   'from_uid': myUid,
    //   'from_name': myData['name'] ?? 'Seseorang',
    //   'from_avatar': myData['avatar_url'] ?? 'kinz.png',
    //   'status': 'pending',
    //   'created_at': FieldValue.serverTimestamp(),
    // });
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
      'avatar_url': fromData['avatar_url'] ?? 'kinz.png',
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
      'avatar_url': myData['avatar_url'] ?? 'kinz.png',
      'added_at': FieldValue.serverTimestamp(),
    });

    // Remove friend request
    await _db
        .collection('users')
        .doc(myUid)
        .collection('friend_requests')
        .doc(fromUid)
        .delete();

    // Send notification to the user who sent the request (disabled as requested)
    // await _db
    //     .collection('users')
    //     .doc(fromUid)
    //     .collection('notifications')
    //     .add({
    //   'type': 'friend_accepted',
    //   'title': 'Permintaan Pertemanan Diterima',
    //   'body': '${myData['name'] ?? 'Seseorang'} menerima permintaan pertemananmu. Sekarang kalian berteman!',
    //   'from_uid': myUid,
    //   'from_name': myData['name'] ?? 'Seseorang',
    //   'from_avatar': myData['avatar_url'] ?? 'kinz.png',
    //   'status': 'unread',
    //   'created_at': FieldValue.serverTimestamp(),
    // });

    // Trigger daily challenge progress for both users
    try {
      await incrementChallengeProgressByType(myUid, 'add_friend', 1);
      await incrementChallengeProgressByType(fromUid, 'add_friend', 1);
    } catch (e) {
      print('[Challenge] Failed to increment add_friend challenge: $e');
    }
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

  // ---------------------------------------------------------------------------
  // REAL-TIME CHAT WITH FRIENDS
  // ---------------------------------------------------------------------------

  String _getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChatMessagesStream(String friendUid) {
    final myUid = currentUser!.uid;
    final chatId = _getChatId(myUid, friendUid);
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sent_at', descending: true)
        .snapshots();
  }

  Future<void> sendChatMessage(String friendUid, String text) async {
    final myUid = currentUser!.uid;
    final chatId = _getChatId(myUid, friendUid);
    
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'sender_id': myUid,
      'text': text,
      'sent_at': FieldValue.serverTimestamp(),
    });

    // Send notification to the friend
    final myDoc = await _db.collection('users').doc(myUid).get();
    final myName = myDoc.data()?['name'] ?? 'Teman';
    
    await _db
        .collection('users')
        .doc(friendUid)
        .collection('notifications')
        .add({
      'type': 'chat_message',
      'from_uid': myUid,
      'from_name': myName,
      'message': text,
      'status': 'unread',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChatMessage(String friendUid, String messageId) async {
    final myUid = currentUser!.uid;
    final chatId = _getChatId(myUid, friendUid);
    
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
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
        .orderBy('mmr', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<int> getUserLeaderboardRank(String uid) async {
    final query = await _db.collection('users').orderBy('mmr', descending: true).get();
    for (int i = 0; i < query.docs.length; i++) {
      if (query.docs[i].id == uid) {
        return i + 1;
      }
    }
    return 1;
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

    print('[Matchmaking] matchmake started by $myUid ($myName) for subject: $normalizedSubject, diff: $normalizedDiff, MMR: $myMmr');

    // 1. Search for an open session (waiting, same subject, same difficulty, not created by me, and not expired)
    final query = await _db
        .collection('duel_sessions')
        .where('status', isEqualTo: 'waiting')
        .where('subject', isEqualTo: normalizedSubject)
        .where('difficulty', isEqualTo: normalizedDiff)
        .limit(20)
        .get();

    String? bestSessionId;
    int closestMmrDiff = 100000;
    final now = DateTime.now();
    // A waiting session is active if created within the last 5 minutes (to tolerate client/server clock skew)
    final activeThreshold = now.subtract(const Duration(minutes: 5));

    print('[Matchmaking] Query returned ${query.docs.length} sessions');

    for (var doc in query.docs) {
      final data = doc.data();
      print('[Matchmaking] Session ID: ${doc.id}');
      print('[Matchmaking] - Creator ID: ${data['player1_id']} (Name: ${data['player1_name']}, MMR: ${data['player1_mmr']})');
      
      if (data['player1_id'] != myUid) {
        final createdAt = (data['created_at'] as Timestamp?)?.toDate();
        print('[Matchmaking] - Created at: $createdAt, activeThreshold: $activeThreshold');
        if (createdAt != null && createdAt.isBefore(activeThreshold)) {
          print('[Matchmaking]   - Skip: Session has expired.');
          continue; // Skip abandoned/expired sessions
        }
        final creatorMmr = data['player1_mmr'] ?? 80;
        final mmrDiff = (creatorMmr - myMmr).abs();
        print('[Matchmaking]   - MMR Diff: $mmrDiff (closestMmrDiff: $closestMmrDiff)');
        if (mmrDiff < closestMmrDiff && mmrDiff <= 500) {
          closestMmrDiff = mmrDiff;
          bestSessionId = doc.id;
          print('[Matchmaking]   - New best session candidate: $bestSessionId');
        }
      } else {
        print('[Matchmaking] - Skip: Session was created by myself.');
      }
    }

    if (bestSessionId != null) {
      print('[Matchmaking] Attempting to join session: $bestSessionId');
      final docRef = _db.collection('duel_sessions').doc(bestSessionId);
      final joined = await _db.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final data = snapshot.data()!;
          final p2Id = data['player2_id'] as String? ?? '';
          final status = data['status'] as String? ?? '';
          if (p2Id.isEmpty && status == 'waiting') {
            transaction.update(docRef, {
              'player2_id': myUid,
              'player2_name': myName,
              'player2_mmr': myMmr,
              'status': 'ongoing',
              'started_at': FieldValue.serverTimestamp(),
            });
            return true;
          }
        }
        return false;
      });

      if (joined) {
        print('[Matchmaking] Successfully joined session: $bestSessionId');
        return bestSessionId;
      } else {
        print('[Matchmaking] Failed to join session: $bestSessionId (already filled or status changed)');
      }
    }

    // 2. If no match found, create a new waiting session
    print('[Matchmaking] No suitable session found. Creating a new waiting session.');
    final newSessionRef = _db.collection('duel_sessions').doc();
    final questions = await getQuestionsForDuel(normalizedSubject, normalizedDiff);
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
      'questions_per_session': 10,
      'time_per_question': 30,
      'score_player1': 0,
      'score_player2': 0,
      'winner_id': '',
      'created_at': FieldValue.serverTimestamp(),
      'questions': questions,
    });

    print('[Matchmaking] Created session: ${newSessionRef.id}');
    return newSessionRef.id;
  }

  // Start matching with BOT if timeout
  Future<void> startBotMatch(String sessionId) async {
    final names = ['Kinz Bot', 'Rara', 'Bima', 'Siti', 'Andy'];
    final botName = names[Random().nextInt(names.length)];

    final docRef = _db.collection('duel_sessions').doc(sessionId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final p2Id = data['player2_id'] as String? ?? '';
        final status = data['status'] as String? ?? '';
        if (p2Id.isEmpty && (status == 'waiting' || status == 'waiting_friend')) {
          transaction.update(docRef, {
            'player2_id': 'bot_id',
            'player2_name': botName,
            'player2_mmr': 0,
            'status': 'ongoing',
            'started_at': FieldValue.serverTimestamp(),
          });
        }
      }
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

    final isBotMatch = (p2 == 'bot_id' || p1 == 'bot_id');

    String result = 'draw';
    int xpReward = 20;
    int gemsReward = 5;

    if (isBotMatch) {
      if (myScore > oppScore) {
        result = 'win';
        xpReward = 15;
        gemsReward = 2;
      } else if (myScore < oppScore) {
        result = 'lose';
        xpReward = 5;
        gemsReward = 0;
      } else {
        result = 'draw';
        xpReward = 8;
        gemsReward = 1;
      }
    } else {
      if (myScore > oppScore) {
        result = 'win';
        xpReward = 100;
        gemsReward = 20;
      } else if (myScore < oppScore) {
        result = 'lose';
        xpReward = 30;
        gemsReward = 5;
      }
    }

    final isFriendDuel = data['is_friend_duel'] ?? false;

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

    if (isFriendDuel) {
      return {
        'xp': 0,
        'gems': 0,
        'result': result,
      };
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
        
        // Gunakan perbandingan tanggal (year, month, day) alih-alih durasi 24 jam
        final lastActiveDate = DateTime(lastActive.year, lastActive.month, lastActive.day);
        final nowDate = DateTime(now.year, now.month, now.day);
        final dayDiff = nowDate.difference(lastActiveDate).inDays;

        if (dayDiff > 1) {
          streak = 1; // streak broken, reset to 1
        } else if (dayDiff == 1) {
          streak++; // played yesterday, increment
        }
        // Jika dayDiff == 0 (hari yang sama), streak tidak berubah
      } else {
        streak = 1; // first game
      }

      int mmrChange = 0;
      if (!isBotMatch) {
        if (result == 'win') {
          mmrChange = (30 + (myScore ~/ 20)).clamp(30, 40);
        } else if (result == 'lose') {
          mmrChange = (-15 + (myScore ~/ 20)).clamp(-15, -10);
        }
      }

      int mmr = userData['mmr'] ?? 80;
      mmr = max(0, mmr + mmrChange);

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
      String opponentAvatar = 'kinz.png';
      if (opponentName.isNotEmpty) {
        if (opponentName.toLowerCase().contains('bot') || p2 == 'bot_id' || p1 == 'bot_id') {
          opponentAvatar = 'robot';
        } else {
          final oppDoc = await _db.collection('users').doc(isP1 ? p2 : p1).get();
          if (oppDoc.exists) {
            opponentAvatar = oppDoc.data()?['avatar_url'] ?? 'kinz.png';
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
        'mmr_change': mmrChange,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Update daily challenges progress
      if (result == 'win') {
        await incrementChallengeProgressByType(myUid, 'win_duel', 1);
      }
      
      int correctAnswersCount = 0;
      final myPlayerKey = isP1 ? 'p1' : 'p2';
      final answers = data['answers'] as Map<String, dynamic>? ?? {};
      answers.forEach((qKey, qData) {
        if (qData is Map && qData.containsKey(myPlayerKey)) {
          final ansInfo = qData[myPlayerKey];
          if (ansInfo is Map && ansInfo['correct'] == true) {
            correctAnswersCount++;
          }
        }
      });

      if (correctAnswersCount > 0) {
        await incrementChallengeProgressByType(myUid, 'correct_answer', correctAnswersCount);
      }

      if (p2 != 'bot_id' && p2.isNotEmpty) {
        await incrementChallengeProgressByType(myUid, 'duel_friend', 1);
      } else if (p2 == 'bot_id' || p1 == 'bot_id') {
        await incrementChallengeProgressByType(myUid, 'play_offline', 1);
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

  Map<String, dynamic> _shuffleQuestionOptions(Map<String, dynamic> q) {
    final copy = Map<String, dynamic>.from(q);
    final optionsKey = copy.containsKey('options') ? 'options' : 'opts';
    final originalOpts = copy[optionsKey];
    if (originalOpts is List && originalOpts.isNotEmpty) {
      final opts = List<String>.from(originalOpts);
      
      String correctText = '';
      if (copy.containsKey('correct_answer')) {
        correctText = copy['correct_answer'].toString();
      } else if (copy.containsKey('ans')) {
        final ansIndex = copy['ans'] as int? ?? 0;
        if (ansIndex >= 0 && ansIndex < opts.length) {
          correctText = opts[ansIndex];
        }
      }
      
      opts.shuffle();
      copy[optionsKey] = opts;
      
      if (correctText.isNotEmpty) {
        final newAnsIndex = opts.indexOf(correctText);
        if (newAnsIndex != -1) {
          copy['ans'] = newAnsIndex;
        }
        copy['correct_answer'] = correctText;
      }
    }
    return copy;
  }

  // Load questions for the duel
  Future<List<Map<String, dynamic>>> getQuestionsForDuel(String subject, String difficulty) async {
    final query = await _db
        .collection('questions')
        .where('subject', isEqualTo: subject.toLowerCase())
        .where('difficulty', isEqualTo: difficulty.toLowerCase())
        .limit(20)
        .get();

    List<Map<String, dynamic>> questionsList = [];

    if (query.docs.isNotEmpty) {
      final list = query.docs.map((d) => d.data()).toList();
      list.shuffle();
      questionsList = list.take(10).toList();
    } else {
      // Return fallback sample questions if database is empty (filtered by difficulty)
      final allFallback = _getFallbackQuestions(subject);
      final filtered = allFallback.where((q) => q['difficulty'] == difficulty.toLowerCase()).toList();
      if (filtered.isNotEmpty) {
        filtered.shuffle();
        questionsList = filtered.take(10).toList();
      } else {
        allFallback.shuffle();
        questionsList = allFallback.take(10).toList();
      }
    }

    return questionsList.map((q) => _shuffleQuestionOptions(q)).toList();
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
    int ticketCost = 0,
    required int pullCount, // 1 or 10
  }) async {
    final myUid = currentUser!.uid;
    final userDocRef = _db.collection('users').doc(myUid);
    final userDoc = await userDocRef.get();
    
    if (!userDoc.exists) throw Exception('Pengguna tidak ditemukan!');
    final userData = userDoc.data()!;
    final currentGems = userData['gems'] as int;
    final currentTickets = userData['tickets'] as int? ?? 0;
    int epicPity = userData['gacha_pity_epic'] as int? ?? 0;
    int legendaryPity = userData['gacha_pity_legendary'] as int? ?? 0;

    if (currentTickets < ticketCost) {
      throw Exception('Tiket tidak cukup!');
    }

    if (currentGems < cost) {
      throw Exception('Gems tidak cukup!');
    }

    // Roll gacha items based on rates (cached to make subsequent pulls fast)
    List<Map<String, dynamic>> pool = [];
    if (_cachedItemPools.containsKey(bannerId)) {
      pool = _cachedItemPools[bannerId]!;
    } else {
      final poolQuery = await _db
          .collection('gacha_banners')
          .doc(bannerId)
          .collection('item_pool')
          .get();

      if (poolQuery.docs.isNotEmpty) {
        final rawPool = poolQuery.docs.map((d) => d.data()).toList();
        // Filter out non-cosmetics: keep only avatar, background, effect
        pool = rawPool.where((item) {
          final type = (item['item_type'] ?? '').toString().toLowerCase();
          return type == 'avatar' || type == 'background' || type == 'effect';
        }).toList();

        if (pool.isEmpty) {
          pool = _getFallbackItemPool();
        }
        _cachedItemPools[bannerId] = pool;
      } else {
        pool = _getFallbackItemPool();
      }
    }

    final rand = Random();
    List<Map<String, dynamic>> results = [];
    final batch = _db.batch();
    int totalEarnedGems = 0;

    for (int i = 0; i < pullCount; i++) {
      Map<String, dynamic> selectedItem;
      if (legendaryPity + 1 >= 50) {
        selectedItem = _pickGuaranteedItem(pool, ['legendary', 'mythical']);
      } else if (epicPity + 1 >= 10) {
        selectedItem = _pickGuaranteedItem(pool, ['epic', 'legendary', 'mythical']);
      } else {
        selectedItem = _pickWeightedItem(pool, rand);
      }

      final rarity = (selectedItem['rarity'] ?? 'common').toString().toLowerCase();
      final isEpicOrBetter = rarity == 'epic' || rarity == 'legendary' || rarity == 'mythical';
      final isLegendaryOrBetter = rarity == 'legendary' || rarity == 'mythical';
      epicPity = isEpicOrBetter ? 0 : epicPity + 1;
      legendaryPity = isLegendaryOrBetter ? 0 : legendaryPity + 1;

      results.add(selectedItem);

      // Save to user inventories collection
      final itemId = selectedItem['item_id'];
      final invRef = userDocRef.collection('inventories').doc(itemId);
      batch.set(invRef, {
        'item_id': itemId,
        'item_name': selectedItem['item_name'],
        'item_type': selectedItem['item_type'] ?? 'avatar',
        'item_image': selectedItem['item_image'] ?? 'avatar',
        'rarity': selectedItem['rarity'] ?? 'common',
        'is_equipped': false,
        'quantity': FieldValue.increment(1),
        'last_obtained_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Record gacha pull log
      final pullLogRef = _db.collection('gacha_pulls').doc();
      batch.set(pullLogRef, {
        'pull_id': pullLogRef.id,
        'user_id': myUid,
        'banner_id': bannerId,
        'item_id': itemId,
        'rarity': rarity,
        'pulled_at': FieldValue.serverTimestamp(),
      });
    }

    batch.update(userDocRef, {
      'gems': currentGems - cost + totalEarnedGems,
      'tickets': currentTickets - ticketCost,
      'gacha_pity_epic': epicPity,
      'gacha_pity_legendary': legendaryPity,
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (cost > 0) {
      final walletLogRef = _db.collection('wallet_logs').doc();
      batch.set(walletLogRef, {
        'log_id': walletLogRef.id,
        'user_id': myUid,
        'amount': -cost,
        'type': 'spend',
        'source': 'gacha_pull',
        'reference_id': bannerId,
        'balance_after': currentGems - cost,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // Trigger daily challenge progress
    try {
      await incrementChallengeProgressByType(myUid, 'do_gacha', pullCount);
    } catch (e) {
      print('[Challenge] Failed to increment do_gacha challenge: $e');
    }

    return results;
  }

  Map<String, dynamic> _pickWeightedItem(List<Map<String, dynamic>> pool, Random rand) {
    final totalRate = pool.fold<double>(
      0,
      (sum, item) => sum + ((item['drop_rate'] as num?)?.toDouble() ?? 0.1),
    );
    final roll = rand.nextDouble() * totalRate;
    double cumulative = 0.0;
    for (var item in pool) {
      cumulative += ((item['drop_rate'] as num?)?.toDouble() ?? 0.1);
      if (roll <= cumulative) return item;
    }
    return pool.last;
  }

  Map<String, dynamic> _pickGuaranteedItem(List<Map<String, dynamic>> pool, List<String> rarities) {
    final candidates = pool
        .where((item) => rarities.contains((item['rarity'] ?? 'common').toString().toLowerCase()))
        .toList();
    if (candidates.isEmpty) return pool.last;
    candidates.shuffle();
    return candidates.first;
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
          'avatar_url': itemDoc.data()!['item_image'] ?? 'kinz.png',
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

  Future<void> unequipItem(String itemId, String itemType) async {
    final myUid = currentUser!.uid;
    final invRef = _db.collection('users').doc(myUid).collection('inventories');

    // 1. Mark the item as unequipped in inventory
    await invRef.doc(itemId).update({'is_equipped': false});

    // 2. Update user document based on type
    if (itemType == 'avatar') {
      await _db.collection('users').doc(myUid).update({
        'avatar_url': 'kinz.png',
      });
    } else if (itemType == 'background') {
      await _db.collection('users').doc(myUid).update({
        'theme_id': FieldValue.delete(),
      });
    } else if (itemType == 'effect') {
      await _db.collection('users').doc(myUid).update({
        'effect_id': FieldValue.delete(),
      });
    }
  }

  // ---------------------------------------------------------------------------
  // BADGES
  // ---------------------------------------------------------------------------

  // Get all badge definitions
  List<Map<String, dynamic>> getAllBadgeDefinitions() {
    return [
      {'badge_id': 'pioneer', 'badge_name': 'Pejuang Pertama', 'badge_icon': 'emoji_events_rounded', 'description': 'Berhasil bergabung dengan StudyDuel!'},
      {'badge_id': 'first_duel', 'badge_name': 'Petarung Baru', 'badge_icon': 'military_tech_rounded', 'description': 'Menyelesaikan duel pertamamu!'},
      {'badge_id': 'top10', 'badge_name': 'Top 10 Global', 'badge_icon': 'leaderboard_rounded', 'description': 'Meraih peringkat 10 besar di leaderboard global'},
      {'badge_id': 'win100', 'badge_name': '100 Winstreak', 'badge_icon': 'workspace_premium_rounded', 'description': 'Memenangkan 100 pertandingan berturut-turut'},
      {'badge_id': 'ipa_expert', 'badge_name': 'IPA Expert', 'badge_icon': 'science_rounded', 'description': 'Memenangkan 100 duel mata pelajaran IPA'},
      {'badge_id': 'math_master', 'badge_name': 'Math Master', 'badge_icon': 'calculate_rounded', 'description': 'Memenangkan 100 duel Matematika'},
      {'badge_id': 'social_star', 'badge_name': 'Social Star', 'badge_icon': 'public_rounded', 'description': 'Memenangkan 100 duel IPS'},
      {'badge_id': 'bahasa_boss', 'badge_name': 'Bahasa Boss', 'badge_icon': 'import_contacts_rounded', 'description': 'Memenangkan 100 duel Bahasa'},
      {'badge_id': 'first_gacha', 'badge_name': 'Lucky Pull', 'badge_icon': 'casino_rounded', 'description': 'Melakukan gacha pertamamu!'},
      {'badge_id': 'collector', 'badge_name': 'Kolektor', 'badge_icon': 'inventory_2_rounded', 'description': 'Mengumpulkan 10 item dari gacha'},
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

  // Toggle badge pin state
  Future<void> toggleBadgePin(String uid, String badgeId, bool pin) async {
    final ref = _db.collection('users').doc(uid).collection('badges').doc(badgeId);
    
    if (pin) {
      final pinned = await _db.collection('users').doc(uid).collection('badges').where('is_pinned', isEqualTo: true).get();
      if (pinned.docs.length >= 3) {
        throw Exception('Maksimal 3 badge yang dapat disematkan!');
      }
    }
    
    await ref.update({'is_pinned': pin});
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
          'banner_image': 'auto_awesome_rounded',
          'created_at': FieldValue.serverTimestamp(),
        });

        // Populate item pool using batch
        final pool = _getFallbackItemPool();
        final batch = _db.batch();
        for (var item in pool) {
          batch.set(bannerRef.collection('item_pool').doc(item['item_id']), item);
        }
        await batch.commit();
      } else {
        // Always populate/update item pool using batch
        final bannerRef = _db.collection('gacha_banners').doc('default_banner');
        final pool = _getFallbackItemPool();
        final batch = _db.batch();
        for (var item in pool) {
          batch.set(bannerRef.collection('item_pool').doc(item['item_id']), item);
        }
        await batch.commit();
      }

      // Check if we need to seed questions
      final questionsQuery = await _db.collection('questions').limit(150).get();
      if (questionsQuery.docs.length < 120) {
        // Seed 150+ questions using batches
        final subjects = ['matematika', 'ipa', 'ips', 'bahasa indonesia', 'bahasa'];
        final batch = _db.batch();
        for (var subj in subjects) {
          final list = _getFallbackQuestions(subj);
          for (var i = 0; i < list.length; i++) {
            final q = list[i];
            String diff = q['difficulty'] ?? 'mudah';
            
            final qId = 'q_${subj}_${diff}_$i';
            batch.set(_db.collection('questions').doc(qId), {
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
        await batch.commit();
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
        // Mudah
        {'q': 'Hasil dari 12² - 5³ adalah...', 'opts': ['19', '21', '24', '14'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'Jika 3x + 12 = 27, nilai dari x adalah...', 'opts': ['3', '4', '5', '6'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Nilai dari kelipatan persekutuan terkecil (KPK) dari 14 dan 21 adalah...', 'opts': ['28', '42', '56', '84'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Luas sebuah segitiga dengan alas 15 cm dan tinggi 8 cm adalah...', 'opts': ['30 cm²', '60 cm²', '120 cm²', '90 cm²'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Berapakah jumlah rusuk pada limas segiempat?', 'opts': ['6', '8', '10', '12'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Nilai dari 2⁵ ÷ 2² + 3² adalah...', 'opts': ['14', '15', '17', '18'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Gradien dari garis yang sejajar dengan persamaan y = -3x + 8 adalah...', 'opts': ['3', '-3', '1/3', '-1/3'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Hasil dari 25% dari 160 adalah...', 'opts': ['40', '50', '35', '45'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'Nilai x yang memenuhi persamaan 2x - 5 = 11 adalah...', 'opts': ['6', '7', '8', '9'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Sebuah persegi memiliki keliling 36 cm. Luas persegi tersebut adalah...', 'opts': ['64 cm²', '81 cm²', '36 cm²', '100 cm²'], 'ans': 1, 'difficulty': 'mudah'},
        // Sedang
        {'q': 'Sebuah tabung memiliki jari-jari 7 cm dan tinggi 10 cm. Volume tabung tersebut adalah... (π = 22/7)', 'opts': ['1540 cm³', '154 cm³', '770 cm³', '3080 cm³'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Hasil penyederhanaan dari persamaan kuadrat x² - 5x + 6 = 0 memiliki himpunan penyelesaian...', 'opts': ['{1, 5}', '{2, 3}', '{-2, -3}', '{1, 6}'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Jika matriks A = [[2, 3], [1, 4]], berapakah nilai determinan dari matriks A?', 'opts': ['5', '8', '3', '11'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Jika fungsi f(x) = ax + b, dengan f(2) = 7 dan f(-1) = 1, nilai a dan b berturut-turut adalah...', 'opts': ['a=2, b=3', 'a=3, b=1', 'a=2, b=5', 'a=3, b=2'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Sebuah dadu dilempar sekali. Peluang munculnya mata dadu faktor dari 6 adalah...', 'opts': ['1/2', '2/3', '1/3', '5/6'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Nilai dari ³log 27 + ²log 16 adalah...', 'opts': ['5', '7', '9', '12'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Panjang hipotenusa segitiga siku-siku adalah 13 cm. Jika panjang salah satu sisi tegaknya 5 cm, berapakah luas segitiga tersebut?', 'opts': ['30 cm²', '60 cm²', '15 cm²', '65 cm²'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Suku ke-15 dari barisan aritmetika 3, 7, 11, 15, ... adalah...', 'opts': ['55', '57', '59', '61'], 'ans': 2, 'difficulty': 'sedang'},
        {'q': 'Dalam sebuah kotak terdapat 5 bola merah dan 3 bola biru. Jika diambil 2 bola sekaligus secara acak, peluang terambilnya semua bola merah adalah...', 'opts': ['5/28', '5/14', '3/14', '15/28'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Persamaan garis yang melalui titik (2, 3) dengan gradien 2 adalah...', 'opts': ['y = 2x - 1', 'y = 2x + 1', 'y = 2x - 3', 'y = 2x + 3'], 'ans': 0, 'difficulty': 'sedang'},
        // Sulit
        {'q': 'Jika f(x) = (2x + 3)/(x - 1) untuk x ≠ 1, fungsi invers f⁻¹(x) adalah...', 'opts': ['(x - 3)/(x - 2)', '(x + 3)/(x - 2)', '(2x - 3)/(x + 1)', '(x - 2)/(2x + 3)'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Suku ke-5 dan ke-10 dari barisan aritmetika adalah 18 dan 38. Berapakah jumlah 15 suku pertama barisan tersebut?', 'opts': ['450', '480', '510', '540'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Himpunan penyelesaian dari sin x = 1/2 untuk interval 0° ≤ x ≤ 360° adalah...', 'opts': ['{30°, 150°}', '{30°, 210°}', '{60°, 120°}', '{150°, 330°}'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Dalam suatu kepanitiaan yang terdiri dari 8 orang, akan dipilih 3 orang sebagai pengurus inti. Banyaknya cara pemilihan pengurus tersebut adalah...', 'opts': ['336', '168', '56', '28'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Persamaan lingkaran yang berpusat di titik (2, -3) dan memiliki jari-jari 5 adalah...', 'opts': ['(x-2)² + (y+3)² = 5', '(x+2)² + (y-3)² = 25', '(x-2)² + (y+3)² = 25', 'x² + y² - 4x + 6y = 0'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Jika nilai lim_{x→3} (x² - 9) / (2x - 6) disederhanakan, hasilnya adalah...', 'opts': ['3', '6', '1.5', '2'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Hasil dari integral ∫ (3x² - 4x + 5) dx adalah...', 'opts': ['x³ - 2x² + 5', 'x³ - 2x² + 5x + C', '3x³ - 2x² + 5x + C', 'x³ - 4x² + 5x + C'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Nilai maksimum dari fungsi f(x) = -x² + 6x - 5 adalah...', 'opts': ['2', '3', '4', '5'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Diketahui kubus ABCD.EFGH dengan panjang rusuk 6 cm. Jarak titik A ke garis CF adalah...', 'opts': ['3√2 cm', '3√6 cm', '6√2 cm', '3√3 cm'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Banyaknya bilangan genap terdiri dari 3 angka berbeda yang dapat disusun dari angka 1, 2, 3, 4, 5, 6 adalah...', 'opts': ['48', '60', '72', '80'], 'ans': 1, 'difficulty': 'sulit'},
      ];
    } else if (s == 'ipa' || s == 'science' || s == 'sains') {
      return [
        // Mudah
        {'q': 'Organel sel tumbuhan yang berfungsi sebagai tempat berlangsungnya fotosintesis adalah...', 'opts': ['Mitokondria', 'Kloroplas', 'Ribosom', 'Vakuola'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Hukum I Newton menjelaskan tentang sifat kelembaman suatu benda, yang berarti...', 'opts': ['Benda selalu bergerak', 'F = m.a', 'Benda mempertahankan keadaannya', 'Aksi = Reaksi'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Gas yang paling dominan di atmosfer bumi adalah...', 'opts': ['Oksigen', 'Karbondioksida', 'Nitrogen', 'Argon'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Simbiosis antara jamur dan akar tumbuhan tingkat tinggi membentuk...', 'opts': ['Liken', 'Mikoriza', 'Nodus akar', 'Parasitisme'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Proses perubahan wujud zat dari padat langsung menjadi gas dinamakan...', 'opts': ['Menguap', 'Mencair', 'Menyublim', 'Mengkristal'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Pembuluh darah yang membawa darah kaya oksigen dari paru-paru kembali ke jantung adalah...', 'opts': ['Vena pulmonalis', 'Arteri pulmonalis', 'Aorta', 'Vena cava'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'Satuan suhu dalam Sistem Internasional (SI) adalah...', 'opts': ['Celcius', 'Fahrenheit', 'Reamur', 'Kelvin'], 'ans': 3, 'difficulty': 'mudah'},
        {'q': 'Bagian mata yang berfungsi mengatur jumlah cahaya yang masuk ke mata adalah...', 'opts': ['Iris', 'Pupil', 'Kornea', 'Retina'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Zat makanan yang berfungsi sebagai pembangun dan pengganti sel-sel tubuh yang rusak adalah...', 'opts': ['Karbohidrat', 'Lemak', 'Protein', 'Vitamin'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Planet yang dikenal sebagai planet merah dalam tata surya kita adalah...', 'opts': ['Merkurius', 'Mars', 'Jupiter', 'Saturnus'], 'ans': 1, 'difficulty': 'mudah'},
        // Sedang
        {'q': 'Sebuah kawat penghantar memiliki hambatan 15 Ohm dan dialiri arus listrik sebesar 2 Ampere. Beda potensial pada kawat tersebut adalah...', 'opts': ['7.5 Volt', '13 Volt', '30 Volt', '17 Volt'], 'ans': 2, 'difficulty': 'sedang'},
        {'q': 'Pencernaan protein secara kimiawi dalam lambung manusia dibantu oleh enzim...', 'opts': ['Amilase dan Lipase', 'Pepsin dan Asam Klorida', 'Tripsin dan Erepsin', 'Ptialin'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Persilangan monohibrid dominan penuh antara tanaman tinggi (TT) dengan tanaman pendek (tt) menghasilkan keturunan F2 dengan perbandingan fenotip...', 'opts': ['1 : 2 : 1', '3 : 1', '9 : 3 : 3 : 1', '1 : 1'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Unsur dengan nomor atom 11 (Natrium) berada pada golongan dan periode...', 'opts': ['Golongan IA, Periode 3', 'Golongan IIA, Periode 2', 'Golongan VIIA, Periode 3', 'Golongan IA, Periode 4'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Perpindahan kalor tanpa melalui zat perantara sama sekali disebut...', 'opts': ['Konduksi', 'Konveksi', 'Radiasi', 'Evaporasi'], 'ans': 2, 'difficulty': 'sedang'},
        {'q': 'Tekanan hidrostatis dipengaruhi oleh faktor-faktor berikut, kecuali...', 'opts': ['Massa jenis zat cair', 'Percepatan gravitasi', 'Kedalaman benda', 'Luas penampang wadah'], 'ans': 3, 'difficulty': 'sedang'},
        {'q': 'Bagian ginjal yang berfungsi untuk melakukan filtrasi darah menghasilkan urine primer adalah...', 'opts': ['Glomerulus', 'Tubulus Kontortus Proksimal', 'Lengkung Henle', 'Tubulus Kolektivus'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Larutan asam dapat mengubah warna kertas lakmus biru menjadi...', 'opts': ['Biru', 'Merah', 'Kuning', 'Hijau'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Organisme yang mampu membuat makanannya sendiri melalui proses fotosintesis disebut...', 'opts': ['Produsen', 'Konsumen I', 'Konsumen II', 'Dekomposer'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Hubungan antara kerbau dengan burung jalak merupakan contoh simbiosis...', 'opts': ['Komensalisme', 'Parasitisme', 'Mutualisme', 'Amensalisme'], 'ans': 2, 'difficulty': 'sedang'},
        // Sulit
        {'q': 'Sebuah benda bermassa 2 kg jatuh bebas dari ketinggian 20 m. Jika g = 10 m/s², energi kinetik benda saat berada pada ketinggian 5 m dari tanah adalah...', 'opts': ['100 J', '300 J', '400 J', '150 J'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Organel sel yang berperan sebagai pusat pemrosesan protein, modifikasi makromolekul, dan pensortiran zat sekresi adalah...', 'opts': ['Retikulum Endoplasma Kasar', 'Badan Golgi', 'Lisosom', 'Peroksisom'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Larutan asam kuat H2SO4 memiliki konsentrasi 0.05 M. pH larutan tersebut adalah...', 'opts': ['1', '2', '1.3', '7'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Hormon pada tumbuhan yang memicu pematangan buah secara cepat dan pengguguran daun adalah...', 'opts': ['Auksin', 'Giberelin', 'Gas Etilen', 'Sitokinin'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Pada transformator ideal, lilitan primer 500 dan sekunder 1000. Jika tegangan input 220V dan arus output 1A, berapakah kuat arus pada kumparan primer?', 'opts': ['0.5 A', '2 A', '4 A', '1.5 A'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Komponen penyusun rantai DNA terdiri atas gula deoksiribosa, gugus fosfat, dan basa nitrogen. Pasangan basa nitrogen yang benar adalah...', 'opts': ['Adenin-Urasil', 'Sitosin-Timin', 'Adenin-Timin', 'Guanin-Adenin'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Sebuah lensa cembung memiliki kekuatan 5 dioptri. Jarak fokus lensa tersebut adalah...', 'opts': ['20 cm', '50 cm', '10 cm', '5 cm'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Dalam siklus krebs, setiap satu molekul Asetil Ko-A yang masuk akan menghasilkan ATP sebanyak...', 'opts': ['3 ATP', '2 ATP', '4 ATP', '1 ATP'], 'ans': 3, 'difficulty': 'sulit'},
        {'q': 'Zat psikotropika golongan I yang sangat berbahaya karena menyebabkan ketergantungan kuat dan tidak digunakan untuk terapi adalah...', 'opts': ['Diazepam', 'Ekstasi', 'Morfin', 'Kokain'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Sebuah kapal selam memancarkan bunyi sonar ke dasar laut dan menerima pantulannya dalam waktu 4 detik. Jika cepat rambat bunyi di air 1500 m/s, kedalaman laut adalah...', 'opts': ['1500 m', '2000 m', '3000 m', '6000 m'], 'ans': 2, 'difficulty': 'sulit'},
      ];
    } else if (s == 'ips' || s == 'social' || s == 'sosial') {
      return [
        // Mudah
        {'q': 'Garis khayal yang melingkari bumi secara mendatar dan membagi bumi menjadi belahan Utara dan Selatan adalah...', 'opts': ['Garis Bujur', 'Garis Lintang (Khatulistiwa)', 'Garis Meridian', 'Garis Astronomis'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Negara di Asia Tenggara yang tidak memiliki wilayah laut dan dijuluki "Landlocked Country" adalah...', 'opts': ['Kamboja', 'Laos', 'Myanmar', 'Vietnam'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Mata uang resmi dari negara Thailand adalah...', 'opts': ['Baht', 'Ringgit', 'Dong', 'Peso'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'Candi Borobudur yang megah di Jawa Tengah merupakan candi peninggalan dari kerajaan bercorak...', 'opts': ['Hindu Siwa', 'Buddha Mahayana', 'Hindu Wisnu', 'Buddha Theravada'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Peristiwa Rengasdengklok terjadi karena adanya perbedaan pendapat antara golongan muda dan golongan tua mengenai...', 'opts': ['Teks proklamasi', 'Lokasi proklamasi', 'Waktu pelaksanaan proklamasi', 'Struktur pemerintahan baru'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Benua terkecil di dunia berdasarkan luas daratannya adalah benua...', 'opts': ['Eropa', 'Australia', 'Antartika', 'Amerika Selatan'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Kebutuhan manusia yang mutlak harus dipenuhi demi kelangsungan hidupnya disebut kebutuhan...', 'opts': ['Primer', 'Sekunder', 'Tersier', 'Jasmani'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'Siapakah tokoh penjelajah dari Italia yang terkenal menemukan benua Amerika?', 'opts': ['Vasco da Gama', 'Marco Polo', 'Christopher Columbus', 'Ferdinand Magellan'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Gunung tertinggi di pulau Jawa adalah gunung...', 'opts': ['Semeru', 'Merapi', 'Slamet', 'Bromo'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'Kerajaan Hindu pertama di Indonesia adalah kerajaan...', 'opts': ['Tarumanegara', 'Kutai', 'Majapahit', 'Sriwijaya'], 'ans': 1, 'difficulty': 'mudah'},
        // Sedang
        {'q': 'Perang Dunia I dipicu oleh peristiwa pembunuhan putra mahkota Austria-Hongaria yang bernama...', 'opts': ['Franz Ferdinand', 'Adolf Hitler', 'Winston Churchill', 'Wilhelm II'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Garis Wallace merupakan garis khayal yang membatasi sebaran fauna tipe...', 'opts': ['Asiatis dan Peralihan', 'Peralihan dan Australis', 'Asiatis dan Australis', 'Endemis dan Migrasi'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Kerajaan Islam tertua di Indonesia yang terletak di ujung utara Pulau Sumatera adalah...', 'opts': ['Demak', 'Samudera Pasai', 'Aceh Darussalam', 'Perlak'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Dalam ekonomi, kurva yang menggambarkan hubungan antara harga dengan jumlah barang yang diminta memiliki gradien...', 'opts': ['Positif', 'Negatif', 'Nol', 'Tak terhingga'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Organisasi kerjasama negara-negara pengekspor minyak bumi didirikan dengan nama...', 'opts': ['APEC', 'OPEC', 'WTO', 'IMF'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Salah satu dampak negatif kolonialisasi Belanda di bidang ekonomi bagi rakyat Indonesia adalah...', 'opts': ['Monopoli perdagangan VOC', 'Pengenalan tanaman baru', 'Pembangunan jalan raya Daendels', 'Urbanisasi pesat'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Benua yang dilalui oleh garis khatulistiwa, garis balik utara, dan garis balik selatan sekaligus adalah benua...', 'opts': ['Asia', 'Amerika', 'Afrika', 'Australia'], 'ans': 2, 'difficulty': 'sedang'},
        {'q': 'Tokoh perwakilan Indonesia dalam penandatanganan Deklarasi Bangkok tahun 1967 adalah...', 'opts': ['Adam Malik', 'Tun Abdul Razak', 'Narciso Ramos', 'S. Rajaratnam'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Danau terdalam di Indonesia yang terletak di pulau Sulawesi adalah danau...', 'opts': ['Toba', 'Poso', 'Singkarak', 'Matano'], 'ans': 3, 'difficulty': 'sedang'},
        {'q': 'Alat pemuas kebutuhan yang jumlahnya terbatas dan untuk memperolehnya memerlukan pengorbanan disebut barang...', 'opts': ['Bebas', 'Ekonomi', 'Substitusi', 'Komplementer'], 'ans': 1, 'difficulty': 'sedang'},
        // Sulit
        {'q': 'Perjanjian Tordesillas pada tahun 1494 membagi wilayah pelayaran dunia luar Eropa antara kerajaan...', 'opts': ['Inggris dan Prancis', 'Spanyol dan Portugis', 'Belanda dan Spanyol', 'Portugis dan Belanda'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Konferensi Asia-Afrika (KAA) tahun 1955 di Bandung menghasilkan kesepakatan prinsip perdamaian dunia yang dikenal dengan istilah...', 'opts': ['Dasasila Bandung', 'Deklarasi Bandung', 'Piagam Bandung', 'Prinsip Asia-Afrika'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Teori masuknya Hindu-Buddha ke Indonesia yang menyatakan bahwa kebudayaan tersebut dibawa oleh para ksatria yang kalah perang disebut teori...', 'opts': ['Brahmana', 'Ksatria', 'Waisya', 'Arus Balik'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Kebijakan ekonomi merkantilisme yang diterapkan oleh negara-negara Eropa pada abad ke-16 bertujuan untuk...', 'opts': ['Meningkatkan kesejahteraan koloni', 'Mengumpulkan logam mulia sebanyak-banyaknya', 'Membangun pasar bebas internasional', 'Mendorong industrialisasi mandiri'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Kondisi di mana kenaikan harga barang secara umum terjadi terus menerus yang disebabkan oleh kelebihan jumlah uang beredar disebut...', 'opts': ['Deflasi', 'Inflasi', 'Devaluasi', 'Revaluasi'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Kerajaan Majapahit mencapai puncak kejayaannya di bawah pimpinan Raja Hayam Wuruk dengan Mahapatih Gajah Mada yang terkenal dengan sumpah...', 'opts': ['Sumpah Palapa', 'Sumpah Amukti Palapa', 'Sumpah Majapahit', 'Sumpah Pemuda'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Perundingan antara Indonesia dan Belanda yang ditandatangani pada tanggal 25 Maret 1947 adalah perundingan...', 'opts': ['Linggajati', 'Renville', 'Roem-Royen', 'KMB'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Faktor utama yang menyebabkan runtuhnya VOC pada tanggal 31 Desember 1799 adalah...', 'opts': ['Serangan kerajaan lokal', 'Korupsi internal pegawai', 'Kalah bersaing dengan EIC Inggris', 'Krisis keuangan di Belanda'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Sistem sewa tanah (Landrent System) di Indonesia pada masa penjajahan Inggris diperkenalkan oleh...', 'opts': ['Daendels', 'Van den Bosch', 'Thomas Stamford Raffles', 'Janssens'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Suatu keadaan di mana kurva penawaran bergeser ke kanan dapat disebabkan oleh...', 'opts': ['Peningkatan teknologi produksi', 'Kenaikan biaya bahan baku', 'Kenaikan tarif pajak', 'Penurunan jumlah produsen'], 'ans': 0, 'difficulty': 'sulit'},
      ];
    } else if (s == 'bahasa indonesia' || s == 'b. indonesia' || s == 'indonesian') {
      return [
        // Mudah
        {'q': 'Gaya bahasa yang membandingkan benda mati seolah-olah memiliki sifat seperti manusia disebut majas...', 'opts': ['Metafora', 'Hiperbola', 'Personifikasi', 'Asosiasi'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Manakah penulisan kata depan yang benar di bawah ini?', 'opts': ['di sekolah', 'disekolah', 'ditulis', 'ke sampingkan'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'Kata dasar dari kata berimbuhan "menyampaikan" adalah...', 'opts': ['Sampaikan', 'Menyampai', 'Sampai', 'Tampak'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Kalimat yang subjeknya dikenai suatu perbuatan atau tindakan disebut kalimat...', 'opts': ['Aktif transitif', 'Aktif intransitif', 'Pasif', 'Majemuk'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Lawan kata (antonim) yang tepat untuk kata "khas" adalah...', 'opts': ['Spesial', 'Umum', 'Unik', 'Terbatas'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Paragraf yang memiliki kalimat utama di akhir paragraf disebut paragraf...', 'opts': ['Deduktif', 'Induktif', 'Campuran', 'Naratif'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Cerita fiksi pendek yang menceritakan tentang asal-usul suatu daerah disebut...', 'opts': ['Fabel', 'Legenda', 'Mitos', 'Sage'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'Tanda baca yang digunakan untuk memisahkan unsur-unsur dalam suatu pemerincian atau pembilangan adalah...', 'opts': ['Koma (,)', 'Titik koma (;)', 'Titik dua (:)', 'Hubung (-)'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'Kata bercetak miring pada kalimat "Adik makan *apel* dengan lahap" menduduki jabatan sebagai...', 'opts': ['Subjek', 'Predikat', 'Objek', 'Keterangan'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Manakah kata di bawah ini yang tergolong kata sifat (adjektiva)?', 'opts': ['Membaca', 'Rumah', 'Sangat', 'Indah'], 'ans': 3, 'difficulty': 'mudah'},
        // Sedang
        {'q': 'Manakah deretan kata berikut yang semuanya merupakan kata baku?', 'opts': ['Apotik, Izin, Analisa', 'Apotek, Izin, Analisis', 'Apotek, Ijin, Analisa', 'Apotik, Ijin, Analisis'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Peribahasa "Bagai pinang dibelah dua" memiliki makna...', 'opts': ['Dua orang yang bermusuhan', 'Sangat mirip satu sama lain', 'Tidak adil dalam membagi sesuatu', 'Nasib yang buruk'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Kalimat berikut yang mengandung kata bersinonim adalah...', 'opts': ['Ia naik tangga lalu turun lagi.', 'Ayah membeli buku, sedangkan ibu membeli buah.', 'Kakak sangat gemar membaca dan menyukai menulis.', 'Anak itu sangat cerdas dan pintar di kelasnya.'], 'ans': 3, 'difficulty': 'sedang'},
        {'q': 'Latar tempat, waktu, dan suasana dalam sebuah karya sastra fiksi disebut...', 'opts': ['Alur', 'Setting (Latar)', 'Amanat', 'Tema'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Konjungsi yang digunakan untuk menyatakan hubungan pertentangan pada kalimat majemuk adalah...', 'opts': ['Dan, Serta', 'Sehingga, Maka', 'Tetapi, Melainkan', 'Karena, Sebab'], 'ans': 2, 'difficulty': 'sedang'},
        {'q': 'Kata bercetak miring yang bermakna konotatif terdapat pada kalimat...', 'opts': ['Ibu membeli *kambing hitam* di pasar hewan.', 'Ia dituduh menjadi *kambing hitam* dalam kasus itu.', 'Adik gemar memelihara *kambing hitam* di kandang.', 'Kambing hitam itu melompati pagar kebun.'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Unsur dalam surat resmi yang berisi identitas pengirim surat secara lengkap adalah...', 'opts': ['Salam pembuka', 'Kepala surat (Kop surat)', 'Lampiran', 'Perihal'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Ide pokok atau gagasan utama yang melandasi sebuah cerita disebut...', 'opts': ['Tema', 'Amanat', 'Alur', 'Tokoh'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Imbuhan "ter-" yang bermakna "paling" terdapat pada kalimat...', 'opts': ['Buku itu *terbawa* oleh ayah.', 'Kakak adalah anak *tertua* di keluarga kami.', 'Pencuri itu *tertangkap* polisi.', 'Gelas itu *terjatuh* dari meja.'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Teks yang bertujuan untuk memaparkan proses terjadinya suatu fenomena alam atau sosial disebut...', 'opts': ['Deskripsi', 'Eksposisi', 'Eksplanasi', 'Narasi'], 'ans': 2, 'difficulty': 'sedang'},
        // Sulit
        {'q': 'Manakah kalimat berikut yang menggunakan ejaan dan tanda baca secara tepat?', 'opts': ['Ayah membeli: apel, jeruk, dan mangga.', 'Ayah membeli apel, jeruk, dan mangga.', 'Ayah membeli apel; jeruk; dan mangga.', 'Ayah membeli: apel, jeruk dan mangga.'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Kalimat majemuk bertingkat hubungan konsesif ditunjukkan oleh kalimat...', 'opts': ['Walaupun hujan lebat, ia tetap pergi bekerja.', 'Ia segera pulang setelah pekerjaan selesai.', 'Adik menangis karena mainannya rusak.', 'Ibu sedang memasak ketika ayah datang.'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Kata serapan yang berasal dari bahasa Sanskerta terdapat pada kata...', 'opts': ['Pihak', 'Kamera', 'Bahagia', 'Kertas'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Frasa "meja hijau" pada kalimat "Kasus korupsi itu akhirnya dibawa ke meja hijau" berkedudukan sebagai...', 'opts': ['Frasa nominal idiomatis', 'Frasa verbal kiasan', 'Frasa adjektival', 'Frasa preposisional'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Bagian teks ulasan yang berisi penilaian mengenai kelebihan dan kelemahan suatu karya sastra adalah...', 'opts': ['Orientasi', 'Tafsiran', 'Evaluasi', 'Rangkuman'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Kalimat berikut yang merupakan kalimat pasif intransitif adalah...', 'opts': ['Buku dibeli oleh adik kemarin.', 'Adik menangis tersedu-sedu.', 'Pencuri itu tertangkap tadi malam.', 'Baju itu dicuci ibu tadi pagi.'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Kata "mengaburkan" dalam kalimat "Asap tebal mengaburkan pandangan sopir" terbentuk dari proses afiksasi yang menyatakan...', 'opts': ['Melakukan tindakan', 'Menyebabkan jadi', 'Mencari sesuatu', 'Membuat alat'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Majas yang menggunakan kata kiasan untuk menyindir secara halus dengan perkataan sebaliknya disebut...', 'opts': ['Ironi', 'Sarkasme', 'Sinisme', 'Litotes'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'Penulisan pustaka dari buku "Laskar Pelangi" karya Andrea Hirata tahun 2005 diterbitkan Bentang Pustaka Yogyakarta yang benar adalah...', 'opts': ['Andrea Hirata. 2005. Laskar Pelangi. Yogyakarta: Bentang Pustaka.', 'Hirata, Andrea. 2005. Laskar Pelangi. Yogyakarta: Bentang Pustaka.', 'Hirata, Andrea. 2005. Laskar Pelangi: Bentang Pustaka. Yogyakarta.', 'Andrea, Hirata. 2005. Laskar Pelangi. Bentang Pustaka: Yogyakarta.'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Kalimat "Karena sakit, ia tidak hadir di sekolah" jika diubah menjadi kalimat efektif yang benar adalah...', 'opts': ['Karena dia sakit, dia tidak hadir di sekolah.', 'Sakit membuat dia tidak hadir di sekolah.', 'Sakit, ia tidak hadir di sekolah.', 'Ia tidak hadir di sekolah karena sakit.'], 'ans': 2, 'difficulty': 'sulit'},
      ];
    } else {
      return [
        // Mudah
        {'q': 'What is the past tense form of the verb "sing"?', 'opts': ['singed', 'sang', 'sung', 'singing'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'They ... studying English at school right now.', 'opts': ['is', 'am', 'are', 'was'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'Choose the correct preposition: "The keys are ... the table."', 'opts': ['in', 'at', 'on', 'under'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'She ... a beautiful song in the concert yesterday.', 'opts': ['sings', 'sang', 'sung', 'singed'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'What is the opposite of the word "brave"?', 'opts': ['cowardly', 'fearless', 'strong', 'happy'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'Choose the correct word: "I bought a ... of new shoes."', 'opts': ['pair', 'pear', 'pare', 'pearce'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'Yesterday was Friday. Tomorrow will be...', 'opts': ['Saturday', 'Sunday', 'Monday', 'Thursday'], 'ans': 1, 'difficulty': 'mudah'},
        {'q': 'What is the plural form of the word "child"?', 'opts': ['children', 'childs', 'childrens', 'childes'], 'ans': 0, 'difficulty': 'mudah'},
        {'q': 'I have a cat. ... fur is very soft.', 'opts': ['His', 'Her', 'Its', 'It\'s'], 'ans': 2, 'difficulty': 'mudah'},
        {'q': 'He ... soccer with his friends every weekend.', 'opts': ['plays', 'play', 'playing', 'played'], 'ans': 0, 'difficulty': 'mudah'},
        // Sedang
        {'q': '"If it rains tomorrow, we ... the football match."', 'opts': ['will cancel', 'would cancel', 'canceled', 'cancel'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Which sentence is in the Present Perfect Tense?', 'opts': ['She writes a book.', 'She is writing a book.', 'She has written a book.', 'She wrote a book.'], 'ans': 2, 'difficulty': 'sedang'},
        {'q': 'The synonym of the word "huge" is...', 'opts': ['tiny', 'gigantic', 'heavy', 'broad'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'Identify the adverb in the sentence: "He ran very quickly to catch the bus."', 'opts': ['ran', 'very', 'quickly', 'bus'], 'ans': 2, 'difficulty': 'sedang'},
        {'q': '"The book was written ... J.K. Rowling in 1997."', 'opts': ['by', 'from', 'with', 'of'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'Which word means "a person who designs buildings"?', 'opts': ['Engineer', 'Architect', 'Builder', 'Carpenter'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': '"Neither of the students ... finished the homework yet."', 'opts': ['has', 'have', 'are', 'were'], 'ans': 0, 'difficulty': 'sedang'},
        {'q': 'By the time we arrived, the movie ... already started.', 'opts': ['has', 'had', 'was', 'is'], 'ans': 1, 'difficulty': 'sedang'},
        {'q': 'I look forward to ... you at the graduation ceremony.', 'opts': ['meet', 'met', 'meeting', 'to meet'], 'ans': 2, 'difficulty': 'sedang'},
        {'q': 'Which sentence uses comparison correctly?', 'opts': ['She is taller than her sister.', 'She is more tall than her sister.', 'She is more taller than her sister.', 'She is tallest than her sister.'], 'ans': 0, 'difficulty': 'sedang'},
        // Sulit
        {'q': '"If I ... you, I would accept the job offer immediately."', 'opts': ['am', 'was', 'were', 'had been'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Which sentence represents the passive voice form of "The manager has approved the budget"?', 'opts': ['The budget was approved by the manager.', 'The budget has been approved by the manager.', 'The budget is approved by the manager.', 'The manager has been approved the budget.'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': '"By the time the train arrives, we ... for two hours."', 'opts': ['will wait', 'will have been waiting', 'would wait', 'have waited'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': '"Despite ... tired, she stayed up late to complete the report."', 'opts': ['she was', 'being', 'having', 'she has been'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'What is the meaning of the idiom "break a leg"?', 'opts': ['fail a test', 'get injured', 'good luck', 'run fast'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'Choose the correct sentence:', 'opts': ['Whom did you invite to the party?', 'Who did you invite to the party?', 'Whose did you invite to the party?', 'Which did you invite to the party?'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'I would rather ... at home than go out tonight.', 'opts': ['stay', 'stayed', 'to stay', 'staying'], 'ans': 0, 'difficulty': 'sulit'},
        {'q': 'No sooner had he left the house ... it started to rain.', 'opts': ['when', 'than', 'then', 'that'], 'ans': 1, 'difficulty': 'sulit'},
        {'q': 'Hardly ... closed his eyes when the telephone rang.', 'opts': ['he had', 'did he', 'had he', 'has he'], 'ans': 2, 'difficulty': 'sulit'},
        {'q': 'The term "mitigate" most nearly means...', 'opts': ['increase', 'lessen', 'explain', 'predict'], 'ans': 1, 'difficulty': 'sulit'},
      ];
    }
  }

  List<Map<String, dynamic>> _getFallbackItemPool() {
    return [
      {'item_id': 'einstein', 'item_name': 'Albert Einstein', 'item_type': 'avatar', 'item_image': 'account_circle', 'rarity': 'legendary', 'drop_rate': 0.03},
      {'item_id': 'astronaut', 'item_name': 'Astronot', 'item_type': 'avatar', 'item_image': 'rocket_launch', 'rarity': 'epic', 'drop_rate': 0.06},
      {'item_id': 'wizard', 'item_name': 'Penyihir Kinz', 'item_type': 'avatar', 'item_image': 'auto_awesome', 'rarity': 'epic', 'drop_rate': 0.08},
      {'item_id': 'owl', 'item_name': 'Burung Hantu Bijak', 'item_type': 'avatar', 'item_image': 'psychology', 'rarity': 'rare', 'drop_rate': 0.12},
      {'item_id': 'ninja', 'item_name': 'Ninja Master', 'item_type': 'avatar', 'item_image': 'shutter_speed', 'rarity': 'rare', 'drop_rate': 0.12},
      
      {'item_id': 'crimson_spark', 'item_name': 'Crimson Spark', 'item_type': 'background', 'item_image': 'wallpaper', 'rarity': 'legendary', 'drop_rate': 0.03},
      {'item_id': 'galaxy_requiem', 'item_name': 'Galaxy Requiem', 'item_type': 'background', 'item_image': 'temp_sky', 'rarity': 'mythical', 'drop_rate': 0.01},
      {'item_id': 'neon_cyberpunk', 'item_name': 'Neon Cyberpunk', 'item_type': 'background', 'item_image': 'nightlife', 'rarity': 'legendary', 'drop_rate': 0.03},
      {'item_id': 'forest_serenade', 'item_name': 'Forest Serenade', 'item_type': 'background', 'item_image': 'forest', 'rarity': 'rare', 'drop_rate': 0.08},
      {'item_id': 'sunset_breeze', 'item_name': 'Sunset Breeze', 'item_type': 'background', 'item_image': 'wb_sunny', 'rarity': 'rare', 'drop_rate': 0.08},
      
      {'item_id': 'sun_blaster', 'item_name': 'Sun Blaster', 'item_type': 'effect', 'item_image': 'light_mode', 'rarity': 'legendary', 'drop_rate': 0.03},
      {'item_id': 'thunder_blade', 'item_name': 'Thunder Blade', 'item_type': 'effect', 'item_image': 'bolt', 'rarity': 'epic', 'drop_rate': 0.06},
      {'item_id': 'star_spark', 'item_name': 'Star Spark', 'item_type': 'effect', 'item_image': 'stars', 'rarity': 'common', 'drop_rate': 0.16},
      {'item_id': 'sakura_breeze', 'item_name': 'Sakura Breeze', 'item_type': 'effect', 'item_image': 'filter_vintage', 'rarity': 'epic', 'drop_rate': 0.06},
      {'item_id': 'matrix_digital', 'item_name': 'Matrix Digital', 'item_type': 'effect', 'item_image': 'terminal', 'rarity': 'mythical', 'drop_rate': 0.01},
      {'item_id': 'aqua_bubbles', 'item_name': 'Aqua Bubbles', 'item_type': 'effect', 'item_image': 'bubble_chart', 'rarity': 'common', 'drop_rate': 0.14},
    ];
  }

  // ---------------------------------------------------------------------------
  // NEW USER SYNC & CHALLENGE METHODS
  // ---------------------------------------------------------------------------

  Future<void> checkAndSyncUserData(String uid, Map<String, dynamic> userData) async {
    final Map<String, dynamic> updates = {};

    final avatarUrl = userData['avatar_url'] as String?;
    if (avatarUrl == null || avatarUrl == 'kinz.pngnz.png') {
      updates['avatar_url'] = 'kinz.png';
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

    // Proactive streak reset check: Jika sudah lewat 1 hari tanpa main, reset streak ke 0
    final streakLastDate = userData['streak_last_date'] as Timestamp?;
    if (streakLastDate != null) {
      final lastDate = streakLastDate.toDate();
      final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      final dayDiff = nowDateOnly.difference(lastDateOnly).inDays;
      
      if (dayDiff > 1 && (userData['streak'] ?? 0) > 0) {
        updates['streak'] = 0;
      }
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
