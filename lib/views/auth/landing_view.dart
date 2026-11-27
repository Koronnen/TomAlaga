import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_view.dart';
import 'sign_up_view.dart';

class LandingPage extends StatefulWidget {
  const   LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {

  // Text Outline
  Widget _outlineText(String text){
    return Stack(
      children: [
        Text(text, style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.bold, 
          foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = Colors.black)
        ),
        Text(text, style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text("TomAlaga", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: const Color(0xFFFEC00F),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          children: [
                            Container(
                              width: 198,
                              height: 218,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(43), 
                              image: const DecorationImage(image: AssetImage('assets/images/home.jpg'), 
                              fit: BoxFit.cover)),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Image.asset('assets/images/catpaw.png', 
                                  height: 66, width: 71, 
                                  fit: BoxFit.contain)
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _outlineText("Welcome to"),
                                    _outlineText("TomAlaga"),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Image.asset('assets/images/dogpaw.png', 
                                  height: 66, width: 71, 
                                  fit: BoxFit.contain)
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("The Official Campus Pet Tracker", style: GoogleFonts.inter(fontSize: 14, color: Colors.black)),
                                Text("of University of Santo Tomas", style: GoogleFonts.inter(fontSize: 14, color: Colors.black)),
                              ],
                            ),
                            const SizedBox(height: 35),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 55),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Hello Thomasians!", style: GoogleFonts.inter(fontSize: 20, color: Colors.black)),
                              Text("Ready to take care of our", style: GoogleFonts.inter(fontSize: 20, color: Colors.black)),
                              Text("campus pets?", style: GoogleFonts.inter(fontSize: 20, color: Colors.black)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(width: 30),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LoginView())
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEC00F), 
                                  padding: const EdgeInsets.symmetric(vertical: 14), 
                                  side: const BorderSide(color: Colors.black, width: 1)
                                ),
                                child: Text("Log-in", style: GoogleFonts.inter(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SignUpView())
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEC00F), 
                                  padding: const EdgeInsets.symmetric(vertical: 14), 
                                  side: const BorderSide(color: Colors.black, width: 1)),
                                child: Text("Sign up", style: GoogleFonts.inter(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            SizedBox(width: 30),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFEC00F),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: SafeArea(
                      top: false,
                      child:
                      Text.rich(
                        TextSpan(text: "Contact us at our Facebook Page: TomAlaga and E-mail: ", style: GoogleFonts.inter(fontSize: 15, color: Colors.black),
                        children: [
                          TextSpan(text: "alagang.tomasino@ust.edu.ph", style: GoogleFonts.inter(fontSize: 15, 
                              color: Colors.blue, decoration: TextDecoration.underline, decorationColor: Colors.blue),
                            ),
                          ],
                        ), 
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}