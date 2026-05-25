import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSync {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  static bool _persistenceEnabled = false;

  Future<void> enableOfflinePersistence() async {
    if (_persistenceEnabled) return;

    try {
      _firestore.settings =
          const Settings(persistenceEnabled: true);
      _persistenceEnabled = true;
      print('Firestore offline persistence enabled');
    } catch (e) {
      print('Failed to enable Firestore persistence: $e');
      print(
          'Note: Set settings BEFORE calling any Firestore methods');
    }
  }

  Future<void> setOfflineData(String collection,
      String docId, Map<String, dynamic> data) async {
    await _firestore
        .collection(collection)
        .doc(docId)
        .set(data);
  }

  Future<Map<String, dynamic>?> getOfflineData(
      String collection, String docId) async {
    final doc = await _firestore
        .collection(collection)
        .doc(docId)
        .get();
    return doc.data();
  }

  Stream<Map<String, dynamic>?> listenToDocument(
      String collection, String docId) {
    return _firestore
        .collection(collection)
        .doc(docId)
        .snapshots()
        .map((doc) => doc.data());
  }
}

/// IMPORTANT: Call this BEFORE any Firestore operations
/// Example:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   await FirestoreSync().enableOfflinePersistence(); // CALL THIS FIRST
///   runApp(MyApp());
/// }
/// ```
