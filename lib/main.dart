import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/pet_registration_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://smnxfxynyvxrtfldahxa.supabase.co',
    publishableKey: 'sb_publishable_W38-MyHzMDL-C4xBeu3MWw_ZM4rOgcn',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PetRegistrationView(),
    );
  }
}