import 'package:flutter/material.dart';
import 'package:tomalaga/views/user_profile_view.dart';
import '../controllers/auth_controller.dart';
import '../views/home_view.dart';
import '../views/pet_registration_view.dart';

class MainNavigation extends StatefulWidget{
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>{
  int _currentIndex = 0;
  final AuthController _authController = AuthController();

  late final List<Widget> _pages = [
    HomeView(controller: _authController),
    //Quests
    //Map
    const PetRegistrationView(),
    UserProfile(controller: _authController),
  ];

  Widget _navBubble(IconData icon, {required bool isActive}){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFEC00F) : Colors.transparent,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(icon, color: isActive ? Colors.black : Colors.black54),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.black, width: 1.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFFEC00F),
          unselectedItemColor: Colors.black54,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: _navBubble(Icons.home_outlined, isActive: false),
              activeIcon: _navBubble(Icons.home, isActive: true),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _navBubble(Icons.pets_outlined, isActive: false),
              activeIcon: _navBubble(Icons.pets, isActive: true),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _navBubble(Icons.person_outlined, isActive: false),
              activeIcon: _navBubble(Icons.person, isActive: true),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
