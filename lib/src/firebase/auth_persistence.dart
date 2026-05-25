import 'package:firebase_auth/firebase_auth.dart';

enum AuthPersistenceType {
  local,
  session,
  none,
}

class AuthPersistence {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  Future<void> signInWithEmail(
      String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool get isSignedIn => _auth.currentUser != null;

  Future<void> setPersistence(
      AuthPersistenceType type) async {
    Persistence persistence;
    switch (type) {
      case AuthPersistenceType.local:
        persistence = Persistence.LOCAL;
        break;
      case AuthPersistenceType.session:
        persistence = Persistence.SESSION;
        break;
      case AuthPersistenceType.none:
        persistence = Persistence.NONE;
        break;
    }
    await _auth.setPersistence(persistence);
  }
}
