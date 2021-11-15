import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

const primaryColor = Color(0xFF742092);
const buttonColor = Color(0xFF73A794);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => ApplicationState(),
        builder: (context, _) => Consumer<ApplicationState>(
            builder: (ctx, auth, _) => MaterialApp(
                home: auth.credentials != null ? HomePage() : LoginPage())));
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _current = 0;
  var _itemController = TextEditingController();
  void _onChangePage(page) {
    setState(() {
      _current = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text('Sign in Form'),
        actions: [
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                Provider.of<ApplicationState>(context, listen: false).logout();
              })
        ],
      ),
      body: Text(
        'You are inside the system',
        style: TextStyle(color: Color(0xFF742092), fontSize: 20),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text('Sign in Form'),
      ),
      body: Container(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Form(
                    key: _formkey,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 30),
                          child: TextFormField(
                            controller: _emailController,
                            autofocus: true,
                            decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder()),
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please enter email';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextFormField(
                            controller: _passwordController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder()),
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please enter password';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    )),
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: ElevatedButton(
                    onPressed: () {
                      final email = _emailController.text;
                      final password = _passwordController.text;
                      Provider.of<ApplicationState>(context, listen: false)
                          .login(email, password, context);
                    },
                    child: Text('Sign In'),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

class ApplicationState extends ChangeNotifier {
  String credentials;
  ApplicationState() {
    init();
  }
  Future<void> init() async {
    await Firebase.initializeApp();
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        credentials = user.email;
      } else {
        credentials = null;
      }
      notifyListeners();
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  Future<void> login(
      String email, String password, BuildContext context) async {
    UserInfo userInfo = UserInfo(email: email, password: password);
    try {
      var status = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(userInfo.email);
      if (!status.contains('password')) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: userInfo.email, password: userInfo.password);
      } else {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: userInfo.email, password: userInfo.password);
        } on FirebaseAuthException catch (_) {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                    title: Text("Email is already used with others password"),
                  ));
        }
      }
    } on FirebaseAuthException catch (_) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text("Email is Invalid Format"),
              ));
    }
    notifyListeners();
  }
}

class UserInfo {
  String email;
  String password;
  UserInfo({this.email, this.password});
}
