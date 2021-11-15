import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => ApplicationState(),
        builder: (context, _) => Consumer<ApplicationState>(
            builder: (ctx, auth, _) => MaterialApp(
                home: auth.credentials != null ? SecondPage() : LoginPage())));
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formkey = GlobalKey<FormState>();
  FocusNode myFocusNode;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final password = true;

  @override
  void initState() {
    super.initState();
    myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFC858BA),
        title: Text(
          'LOGIN',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),
      ),
      body: Column(
        children: [
          LoginContent(),
          Form(
              key: _formkey,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 38, vertical: 30),
                    child: TextFormField(
                      focusNode: myFocusNode,
                      controller: _emailController,
                      autofocus: true,
                      decoration: InputDecoration(
                          labelText: 'Email', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter email';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 38),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: password,
                      decoration: InputDecoration(
                          labelText: 'Password', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter password';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: ElevatedButton(
                      onPressed: () {
                        final email = _emailController.text;
                        final password = _passwordController.text;
                        Provider.of<ApplicationState>(context, listen: false)
                            .login(email, password, context);
                        myFocusNode.requestFocus();
                        if (_formkey.currentState.validate()) {
                          ApplicationState().login(email, password, context);
                        }
                      },
                      child: Text('SUBMIT'),
                    ),
                  ),
                ],
              )),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(13.0),
        child: FloatingActionButton(
          backgroundColor: Color(0xFFC858BA),
          child: Icon(Icons.chevron_right),
          tooltip: 'next',
          onPressed: () {
            print(_emailController.text);
            print(_passwordController.text);
          },
        ),
      ),
    );
  }
}

class LoginContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'PLEASE LOGIN BELOW',
                style: TextStyle(color: Color(0xFF742092), fontSize: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  var _current = 0;
  void _onChangePage(page) {
    setState(() {
      _current = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFC858BA),
        title: Text(
          // 'PAGE 2',
          _current == 0 ? "Page2" : "Page3",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),
        actions: [
          IconButton(
              onPressed: () {
                Provider.of<ApplicationState>(context).logout();
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body: Center(
        child: _current == 0
            ? Column(
                children: [Text('This is page 2')],
              )
            : Column(
                children: [
                  Text('This is page 3'),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _current,
        backgroundColor: Color(0xFFC858BA),
        selectedItemColor: Color(0xFFFFC973),
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.chevron_left), label: 'left'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chevron_right), label: 'right'),
        ],
        onTap: _onChangePage,
      ),
      floatingActionButton: _current == 0
          ? FloatingActionButton(
              onPressed: () {},
              child: Icon(Icons.add),
              backgroundColor: Color(0xFF742092),
            )
          : null,
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

