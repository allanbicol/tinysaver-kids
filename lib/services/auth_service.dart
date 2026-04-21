import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp(String email, String password, String name,
      {String pigName = 'Buddy'}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document in Firestore with defaults
    await _db.collection('users').doc(credential.user!.uid).set({
      'name': name,
      'pig_name': pigName,
      'coin_balance': 0,
      'pin_code': '1234',
      'currency_code': 'PHP',
      'currency_symbol': '₱',
      'coin_value': 1.0,
      'current_streak': 0,
      'longest_streak': 0,
      'last_check_in_date': null,
      'mission_date': null,
      'mission_target': 3,
      'mission_progress': 0,
      'mission_bonus': 5,
      'mission_claimed': false,
      'owned_accessories': <String>[],
      'worn_accessory': null,
      'mascot_kind': 'pig',
      'is_premium': false,
      'premium_since': null,
      'last_activity': FieldValue.serverTimestamp(),
    });

    // Seed default tasks for new user
    await _seedDefaultData(credential.user!.uid);

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _seedDefaultData(String uid) async {
    final batch = _db.batch();

    // Default tasks
    final tasks = [
      {'title': 'Make my bed', 'coin_reward': 2, 'icon_name': 'bed', 'is_active': true, 'created_at': FieldValue.serverTimestamp()},
      {'title': 'Brush teeth', 'coin_reward': 1, 'icon_name': 'sentiment_very_satisfied', 'is_active': true, 'created_at': FieldValue.serverTimestamp()},
      {'title': 'Eat vegetables', 'coin_reward': 3, 'icon_name': 'eco', 'is_active': true, 'created_at': FieldValue.serverTimestamp()},
      {'title': 'Read a book', 'coin_reward': 5, 'icon_name': 'menu_book', 'is_active': true, 'created_at': FieldValue.serverTimestamp()},
      {'title': 'Clean up toys', 'coin_reward': 2, 'icon_name': 'toys', 'is_active': true, 'created_at': FieldValue.serverTimestamp()},
    ];

    for (final task in tasks) {
      final ref = _db.collection('users').doc(uid).collection('tasks').doc();
      batch.set(ref, task);
    }

    // Default reward goal
    final rewardRef = _db.collection('users').doc(uid).collection('rewards').doc();
    batch.set(rewardRef, {
      'title': 'Toy Car',
      'target_coins': 20,
      'emoji': '🚗',
      'is_active': true,
      'is_redeemed': false,
    });

    await batch.commit();
  }
}
