import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tomalaga/views/auth/sign_up_view.dart';
import 'package:tomalaga/views/main_navigation_view.dart';
import '../../controllers/auth_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'verify_email_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _authController = AuthController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authController.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (!mounted || user == null) return;

      if (!user.emailVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyEmailView(controller: _authController),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNavigation(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authController.mapAuthError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onForgotPassword() async {
    final emailError = _authController.validateUstEmail(_emailController.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your valid @ust.edu.ph email first.'),
        ),
      );
      return;
    }

    try {
      await _authController.sendPasswordReset(_emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your UST inbox.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authController.mapAuthError(e))),
      );
    }
  }

  //Text Outline 
  Widget _outlineText(String text){
    return Stack(
      children: [
        Text(text, style: GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.bold, 
          foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = Colors.black)
        ),
        Text(text, style: GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.white))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text('TomAlaga Log-in', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints){
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:[
                  Container(
                    color: const Color(0xFFFEC00F),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _outlineText("TomAlaga"),
                                    SizedBox(height: 1),
                                    Text("The Official Campus Pet Tracker", style: GoogleFonts.inter(fontSize: 14, color: Colors.black)),
                                    Text("of University of Santo Tomas", style: GoogleFonts.inter(fontSize: 14, color: Colors.black)),
                                  ],
                                ),
                                SizedBox(width: 5),
                                Column(children: [
                                  Image.asset('assets/images/catpaw.png', height: 63, width: 62, fit: BoxFit.contain),
                                  Image.asset('assets/images/dogpaw.png', height: 69, width: 59, fit: BoxFit.contain),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 70),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Log-in", style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black)),
                          SizedBox(height: 25),
                          Text("E-mail Address:", style: GoogleFonts.inter(fontSize: 18, color: Colors.black)),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(255, 223, 223, 223),
                              labelText: 'Enter your UST Email',
                              hintText: 'name.college@ust.edu.ph',
                              
                              labelStyle: GoogleFonts.inter(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500,),
                              hintStyle: GoogleFonts.inter(color: Colors.black54, fontSize: 12),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color.fromARGB(255, 113, 3, 3))),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color.fromARGB(255, 113, 3, 3))),
                            ),
                            validator: _authController.validateUstEmail,
                          ),
                          const SizedBox(height: 12),
                          Text("Password:", style: GoogleFonts.inter(fontSize: 18, color: Colors.black)),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(255, 223, 223, 223),
                              labelText: 'Enter your Password',
                              labelStyle: GoogleFonts.inter(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color.fromARGB(255, 113, 3, 3))),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color.fromARGB(255, 113, 3, 3))),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? 'Enter your password' : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _onForgotPassword,
                              child: Text('Forgot Password?', style: GoogleFonts.inter(color: Colors.black)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEC00F),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)) 
                              ),
                              child: _isLoading ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFEC00F)))
                                : Text('Log In', style: GoogleFonts.inter(fontSize: 18, color: Colors.black)),
                            ),
                          ),
                          const SizedBox(height: 35),
                          Center(
                            child: TextButton(
                              onPressed: _isLoading ? null : () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpView(),
                                    ),
                                  );
                                },
                              child: Text("New to TomAlaga? [Create an Account]", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),          
          );
        }
      ),
    );
  }
}