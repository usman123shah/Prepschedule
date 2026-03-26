import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Convert Firebase User to App User
  app_user.User? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return app_user.User(
      id: user.uid,
      username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
      email: user.email ?? '',
      password: '', // Password is not stored or needed after login
    );
  }

  // Auth State Stream
  Stream<app_user.User?> get user {
    return _auth.authStateChanges().map(_mapFirebaseUser);
  }

  app_user.User? get currentUser => _mapFirebaseUser(_auth.currentUser);

  // Check if username unique
  Future<bool> isUsernameUnique(String username) async {
    final query = await _db.collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  // Sign Up
  Future<app_user.User?> signUp(String email, String password, String username) async {
    try {
      // 1. Check if username exists in Firestore
      bool unique = await isUsernameUnique(username);
      if (!unique) {
        throw Exception("Username is already taken.");
      }

      // 2. Create Auth User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      
      // 3. Create User Profile in Firestore
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'username': username,
          'email': email,
          'uid': user.uid,
          'created_at': FieldValue.serverTimestamp(),
        });

        // 4. Update display name
        await user.updateDisplayName(username);
        await user.reload();
      }
      
      return _mapFirebaseUser(_auth.currentUser);
    } catch (e) {
      print('Firebase Auth Error (SignUp): $e');
      rethrow;
    }
  }

  // Login by Username or Email
  Future<app_user.User?> login(String identifier, String password) async {
    try {
      String email = identifier;

      // 1. If identifier doesn't look like an email, assume it's a username
      if (!identifier.contains('@')) {
        final query = await _db.collection('users')
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();
        
        if (query.docs.isEmpty) {
          throw Exception("No user found with this username.");
        }
        email = query.docs.first.data()['email'];
      }

      // 2. Perform Firebase Login
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Map result for profile
      final fbUser = result.user;
      if (fbUser != null) {
        // Fetch full profile (including username) from Firestore if not in displayName
        final doc = await _db.collection('users').doc(fbUser.uid).get();
        String username = identifier;
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          username = data?['username'] ?? identifier;
        }
        
        return app_user.User(
          id: fbUser.uid,
          username: username,
          email: email,
          password: '',
        );
      }
      return null;
    } catch (e) {
      print('Firebase Auth Error (Login): $e');
      rethrow;
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Firebase Auth Error (Reset): $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
