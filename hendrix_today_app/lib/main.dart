import 'package:flutter/material.dart';
import 'package:hendrix_today_app/home_screen.dart';
import 'package:hendrix_today_app/calendar_screen.dart';
import 'package:hendrix_today_app/search_screen.dart';
import 'package:hendrix_today_app/firebase_options.dart';
import 'dart:async';                                     // new
import 'package:firebase_auth/firebase_auth.dart'        // new
    hide EmailAuthProvider, PhoneAuthProvider;           // new
import 'package:firebase_core/firebase_core.dart';       // new
import 'package:firebase_ui_auth/firebase_ui_auth.dart'; // new
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';                 // new

//import 'src/authentication.dart';                        // new
//import 'src/widgets.dart';

//Teddy is our savior for firebase

void main() {
  // Modify from here...
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    builder: ((context, child) => const rootApp()),
  ));
  // ...to here.
}


class ScreenContainer extends StatefulWidget {
  const ScreenContainer({super.key});

  @override
  State<ScreenContainer> createState() => _ScreenContainerState();
}

class _ScreenContainerState extends State<ScreenContainer> {
  Color webOrange = const Color.fromARGB(255, 202, 81, 39);
  int selectedIndex = 0;
  List<Widget> pages = []; //contains each page
  List<String> titles = []; //contains the title of each page
  final List<String> dropdownItems = ["EVENTS", "ANNOUNCEMENTS", "MEETINGS"];
  String dropdownValue = "EVENTS";

  @override
  void initState() {
    super.initState();
    pages = [
      const MyHomeScreen(),
      const CalendarScreen(),
      const SearchScreen()
    ]; //Stores Pages for BottomNav
    titles = [
      "Hendrix Today",
      "HDX Calendar",
      "Search"
    ];}
    @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
            backgroundColor: webOrange, title: Text(titles[selectedIndex]),
            leading: IconButton(onPressed: (){
              Navigator.pushNamed(context, "/sign-in");
            }, icon: Icon(Icons.account_circle))), 
        bottomSheet: DropdownButton(
                //isExpanded: true,
                value: dropdownValue,
                items: dropdownItems.map((itemone) {
                  return DropdownMenuItem(value: itemone, child: Text(itemone));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    dropdownValue = newValue.toString();
                  });
                }),
        body: Center(child: pages[selectedIndex]),
        bottomNavigationBar:
            BottomNavigationBar(items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                color: webOrange,
              ),
              label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.calendar_month_outlined,
                color: webOrange,
              ),
              label: "Calendar"),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.search,
                color: webOrange,
              ),
              label: "Search")
        ], currentIndex: selectedIndex, onTap: onItemTapped));
  }
  
     //Stores Page Titles for AppBar
    

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }
}
class rootApp extends StatelessWidget{
  
  const rootApp({super.key});
  final Color webOrange = const Color.fromARGB(255, 202, 81, 39);


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      theme: ThemeData(backgroundColor: webOrange),
      //Start adding here

      initialRoute: '/home',
      routes: {
        '/home': (context) {
          return Consumer<ApplicationState>(builder: (context, appState, _)=> const ScreenContainer());
        },
        '/sign-in': ((context) {
          return SignInScreen(
            actions: [
              ForgotPasswordAction(((context, email) {
                Navigator.of(context)
                    .pushNamed('/forgot-password', arguments: {'email': email});
              })),
              AuthStateChangeAction(((context, state) {
                if (state is SignedIn || state is UserCreated) {
                  var user = (state is SignedIn)
                      ? state.user
                      : (state as UserCreated).credential.user;
                  if (user == null) {
                    return;
                  }
                  if (state is UserCreated) {
                    user.updateDisplayName(user.email!.split('@')[0]);
                  }
                  if (!user.emailVerified) {
                    user.sendEmailVerification();
                    const snackBar = SnackBar(
                        content: Text(
                            'Please check your email to verify your email address'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              })),
            ],
          );
        }),
        '/forgot-password': ((context) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return ForgotPasswordScreen(
            email: arguments?['email'] as String,
            headerMaxExtent: 200,
          );
        }),
        '/profile': ((context) {
          return ProfileScreen(
            providers: [],
            actions: [
              SignedOutAction(
                ((context) {
                  //Navigator.of(context).pushNamedAndRemoveUntil("/home", (r) => false)
                  //to get rid of all previous pathing and return to the original route
                  Navigator.of(context).pushReplacementNamed('/home');
                }),
              ),
            ],
          );
        })
      },
  );
  }
  }
class Router{
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => ScreenContainer());
      case '/signin':
        return MaterialPageRoute(builder: (_) => SignInScreen());
      default:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
                  body: Center(
                      child: Text('No route defined for ${settings.name}')),
                ));
    }
  }
}

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
      } else {
        _loggedIn = false;
      }
      notifyListeners();
    });
  }
}
