import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback toggleView;
  const LoginScreen({super.key, required this.toggleView});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0000FF),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 48.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/TychaLogo.png',
                    width: 110,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12.0),
                const Text(
                  'Start Spending\nWisely.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const SizedBox(height: 28.0),
                const Text('Email', style: TextStyle(color: Colors.white)),
                TextFormField(
                  style: const TextStyle(color: Colors.black),
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    hintText: 'ex. yourname@email.com',
                    hintStyle: TextStyle(color: Colors.black54, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? 'Enter an email' : null,
                  onChanged: (val) {
                    setState(() => email = val);
                  },
                ),
                const SizedBox(height: 16.0),
                const Text('Password', style: TextStyle(color: Colors.white)),
                TextFormField(
                  obscureText: true,
                  style: const TextStyle(color: Colors.black),
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    hintText: 'ex. 282@sas00L!!',
                    hintStyle: TextStyle(color: Colors.black54, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (val) => (val == null || val.length < 6)
                      ? 'Enter a password 6+ chars long'
                      : null,
                  onChanged: (val) {
                    setState(() => password = val);
                  },
                ),
                const SizedBox(height: 24.0),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() => loading = true);
                          final result = await _auth.signInWithEmailAndPassword(
                              email, password);
                          if (result == null) {
                            setState(() {
                              error = 'Could not sign in with those credentials';
                              loading = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0000FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0)),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF0000FF),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Continue',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 36.0),
                Center(
                  child: Column(
                    children: [
                      const Text("Don't have an account?",
                          style: TextStyle(color: Colors.white)),
                      GestureDetector(
                        onTap: () => widget.toggleView(),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                if (error.isNotEmpty)
                  Center(
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red, fontSize: 14.0),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
