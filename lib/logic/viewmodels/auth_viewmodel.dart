import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:email_otp/email_otp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _user != null && _user!.isAnonymous;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _otpSent = false;
  bool get otpSent => _otpSent;

  String _userRole = 'OJT Trainee';
  String get userRole => _userRole;

  String? _profileImageBase64;
  String? get profileImageBase64 => _profileImageBase64;

  AuthViewModel() {
    _initEmailOTP();
    _initGoogleSignIn();
    
    _auth.authStateChanges().listen((User? newUser) async {
      _user = newUser;
      if (newUser != null) {
        await _fetchUserRole(newUser.uid);
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        _userRole = doc.data()?['role'] ?? 'OJT Trainee';
        _profileImageBase64 = doc.data()?['profileImageBase64'];
      } else {
        _userRole = 'OJT Trainee';
        _profileImageBase64 = null;
      }
    } catch (e) {
      debugPrint("Error fetching role: $e");
    }
  }

  Future<void> updateProfile({String? name, String? role, String? profileImageBase64}) async {
    try {
      _setLoading(true);
      if (name != null && _user != null) {
        await _user!.updateDisplayName(name);
      }
      
      Map<String, dynamic> updateData = {};
      if (role != null) updateData['role'] = role;
      if (profileImageBase64 != null) updateData['profileImageBase64'] = profileImageBase64;
      
      if (updateData.isNotEmpty && _user != null) {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set(
          updateData, 
          SetOptions(merge: true)
        );
        if (role != null) _userRole = role;
        if (profileImageBase64 != null) _profileImageBase64 = profileImageBase64;
      }
      
      // Force reload user to get updated displayName
      await _user?.reload();
      _user = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating profile: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (e) {
      debugPrint("Error initializing GoogleSignIn: $e");
    }
  }

  void _initEmailOTP() {
    EmailOTP.config(
      appName: "WorkFlow OJT",
      otpType: OTPType.numeric,
      otpLength: 6,
    );
    EmailOTP.setSMTP(
      host: 'smtp.gmail.com',
      emailPort: EmailPort.port587,
      secureType: SecureType.tls,
      username: 'akcatabay26@gmail.com',
      password: 'jtov lcnu lebh dviq',
    );
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      final googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        _setLoading(false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final authClient = googleUser.authorizationClient;
      final scopes = ['email', 'openid'];
      var authorization = await authClient.authorizationForScopes(scopes);
      
      if (authorization == null) {
        authorization = await authClient.authorizeScopes(scopes);
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      _setLoading(true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint("Error signing in with Email: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInAnonymously() async {
    try {
      _setLoading(true);
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint("Error signing in as Guest: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendOTP(String email) async {
    try {
      _setLoading(true);
      final success = await EmailOTP.sendOTP(email: email);
      if (success) {
        _otpSent = true;
        notifyListeners();
      } else {
        throw Exception("Failed to send OTP. Please check your SMTP configuration.");
      }
    } catch (e) {
      debugPrint("Error sending OTP: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerWithEmailVerified(String email, String password, String otp) async {
    try {
      _setLoading(true);
      if (!EmailOTP.verifyOTP(otp: otp)) {
        throw Exception("Invalid OTP. Please check your email.");
      }
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _otpSent = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error registering with Email/OTP: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void resetOTP() {
    _otpSent = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
    _setLoading(false);
  }
}
