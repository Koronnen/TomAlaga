import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _authController = AuthController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authController.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authController.mapAuthError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //Outline Text
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
        title: Text('TomAlaga Sign-up', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
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
                          Text("Sign-up", style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black)),
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
                            validator: _authController.validatePassword,
                          ),
                          const SizedBox(height: 12),
                          Text("Confirm Password:", style: GoogleFonts.inter(fontSize: 18, color: Colors.black)),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(255, 223, 223, 223),
                              labelText: 'Confirm your Password',
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color.fromARGB(255, 113, 3, 3))),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color.fromARGB(255, 113, 3, 3))),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (val) => _authController.validateConfirmPassword(val, _passwordController.text),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEC00F),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)) 
                              ),
                              child: _isLoading ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2))
                                : Text('Sign Up', style: GoogleFonts.inter(fontSize: 18, color: Colors.black)),
                            ),
                          ),
                          const SizedBox(height: 35),
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