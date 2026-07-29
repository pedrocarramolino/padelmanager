import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> register({
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String level,
    required String position,
    required String password,
  }) async {
    // Crear usuario en Firebase Authentication
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user!;
    // Documento en users: solo datos de cuenta (rol). El perfil
    // (nombre, foto, nivel...) vive únicamente en players/{uid}.
    await _firestore.collection('users').doc(user.uid).set({
      'id': user.uid,
      'email': email,
      'role': 'user',
      'createdAt': Timestamp.now(),
    });

    // Documento en players con el mismo UID
    await _firestore.collection('players').doc(user.uid).set({
      'userId': user.uid,
      'name': name,
      'surname': surname,
      'email': email,
      'phone': phone,
      'level': double.parse(level),
      'position': position,
      'photoUrl': '',
      'createdAt': Timestamp.now(),
    });

    return result;
  }

  Future<UserCredential> signInWithGoogle() async {
    UserCredential userCredential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      userCredential = await _auth.signInWithPopup(provider);
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Inicio de sesión cancelado');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }
    final user = userCredential.user!;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      final names = (user.displayName ?? '').split(' ');
      final name = names.isNotEmpty ? names.first : '';
      final surname = names.length > 1 ? names.sublist(1).join(' ') : '';
      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'email': user.email,
        'role': 'user',
        'createdAt': Timestamp.now(),
      });
      await _firestore.collection('players').doc(user.uid).set({
        'userId': user.uid,
        'name': name,
        'surname': surname,
        'email': user.email,
        'phone': '',
        'level': 3.0,
        'position': 'Indiferente',
        'photoUrl': user.photoURL ?? '',
        'createdAt': Timestamp.now(),
      });
    } else {
      if ((user.photoURL ?? '').isNotEmpty) {
        await updatePhoto(user.photoURL!);
      }
    }
    return userCredential;
  }

  Future<void> updateFirebaseAuthPhoto(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updatePhotoURL(photoUrl);
    await user.reload();
  }

  Future<String> uploadProfileImage(Uint8List bytes) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/ejqldgov/image/upload',
    );
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = 'padel_manager';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: '${user.uid}.jpg'),
    );
    final response = await request.send();
    final body = await response.stream.bytesToString();
    debugPrint('Status: ${response.statusCode}');
    debugPrint(body);
    if (response.statusCode != 200) {
      throw Exception(body);
    }
    final json = jsonDecode(body);
    final photoUrl = json['secure_url'];
    await updatePhoto(photoUrl);
    await updateFirebaseAuthPhoto(photoUrl);
    return photoUrl;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  /// Datos de cuenta (rol, email). No incluye nombre, foto ni nivel:
  /// eso vive en players/{uid}, ver [getCurrentPlayerData].
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  /// Perfil del usuario (nombre, foto, nivel, posición...), fuente
  /// única en players/{uid}.
  Future<Map<String, dynamic>?> getCurrentPlayerData() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final doc = await _firestore.collection('players').doc(user.uid).get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  Future<void> updateProfile({
    required String name,
    required String surname,
    required String phone,
    required double level,
    required String position,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No hay ningún usuario autenticado');
    }

    await _firestore.collection('players').doc(user.uid).update({
      'name': name,
      'surname': surname,
      'phone': phone,
      'level': level,
      'position': position,
    });
  }

  Future<void> updatePhoto(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('players').doc(user.uid).update({
      'photoUrl': photoUrl,
    });
  }

  Future<bool> isAdmin() async {
    final data = await getCurrentUserData();

    if (data == null) {
      return false;
    }

    return data['role'] == 'admin';
  }
}
