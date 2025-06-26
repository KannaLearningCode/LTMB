import 'package:flutter/material.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:kfc_seller/Screens/Cart/cart_provider.dart';
import 'package:kfc_seller/Screens/Home/splash_screen.dart';
import 'package:kfc_seller/Screens/admin/admin_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MongoDatabase.connect().then((value) {
    print("Connected to MongoDB");
  }).catchError((error) {
    print("Error connecting to MongoDB: $error");
  });
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()), // 👈 thêm dòng này
        ],
        child: const MyApp(),
      ),
    );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:  const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
 const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}
  class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context){
    return Scaffold(body: SafeArea(child: Text("hello")));
  }
  }