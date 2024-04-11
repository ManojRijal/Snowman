import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(HangmanApp());

class HangmanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hangman Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/': (context) => SignupScreen(),
        '/login': (context) => LoginScreen(),
        '/hangman': (context) => HangmanScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/snow5.jpeg'),
      ),
    );
  }
}

class UserCredentials {
  final String username;
  final String password;

  UserCredentials(this.username, this.password);
}

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String username = _usernameController.text;
                String password = _passwordController.text;

                // Save the user credentials
                await saveUserCredentials(username, password);

                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveUserCredentials(String username, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String username = _usernameController.text;
                String password = _passwordController.text;

                // Retrieve the saved user credentials
                UserCredentials? savedCredentials = await getUserCredentials();

                // Check if the entered credentials match the saved ones
                if (savedCredentials != null &&
                    savedCredentials.username == username &&
                    savedCredentials.password == password) {
                  Navigator.pushReplacementNamed(context, '/hangman');
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Invalid Data'),
                        content: Text('Please enter valid username and password.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<UserCredentials?> getUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');

    if (username != null && password != null) {
      return UserCredentials(username, password);
    } else {
      return null;
    }
  }
}

class HangmanScreen extends StatefulWidget {
  @override
  _HangmanScreenState createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  List<String> words = ["hangman", "chill", "banana", "computer", "python"];
  late String secretWord;
  late List<String> guessedLetters;
  int remainingChances = 5;
  int mistakes = 0;
  int score = 0;
  int consecutiveWins = 0;
  int previousScore = 0;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    Random random = Random();
    words.shuffle(); // Shuffle the words list
    secretWord = words.first; // Select the first word after shuffling
    guessedLetters = List.filled(secretWord.length, "_");
    remainingChances = 5;
    mistakes = 0;
    // Update score based on consecutive wins
    if (consecutiveWins == 2) {
      score += previousScore;
      previousScore = 0;
      consecutiveWins = 0;
    }
    score += previousScore;
    previousScore = 0;
  }

  void guessLetter(String letter) {
    setState(() {
      if (secretWord.contains(letter)) {
        for (int i = 0; i < secretWord.length; i++) {
          if (secretWord[i] == letter) {
            guessedLetters[i] = letter;
          }
        }
        // Update score if the guess is correct
        score += 10;
      } else {
        remainingChances--;
        mistakes++;
        // Deduct score if the guess is wrong
        if (score > 0) {
          score -= 5;
        }
      }
      if (remainingChances == 0 || !guessedLetters.contains("_")) {
        // Game over, reset the game
        showResetDialog();
      }
    });
  }

  String getHint() {
    Map<String, String> hints = {
      "hangman": "Popular game played with a rope and a stick figure.",
      "chill": "Relaxing or cooling off, often used to describe a relaxed atmosphere.",
      "banana": "Yellow fruit with a peel.",
      "computer": "Electronic device used for processing data.",
      "python": "A type of snake, but also a popular programming language."
    };

    return hints[secretWord] ?? "No hint available.";
  }

  void showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Text(remainingChances == 0
              ? 'You ran out of chances. The word was: $secretWord\nYour Score: $score'
              : 'Congratulations! You guessed the word: $secretWord\nYour Score: $score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  consecutiveWins++;
                  previousScore = score;
                  startGame(); // Start a new game
                });
              },
              child: Text('New Game'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hangman Game'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remaining Chances: $remainingChances',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 20),
                    if (mistakes > 0)
                      Image.asset(
                        'assets/snow$mistakes.jpeg',
                        height: 300,
                      ),
                    SizedBox(height: 20),
                    Text(
                      guessedLetters.join(" "),
                      style: TextStyle(fontSize: 40),
                    ),
                    SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: remainingChances > 0 && guessedLetters.contains("_")
                          ? () {
                        setState(() {
                          String hint = getHint();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hint: $hint'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        });
                      }
                          : null,
                      child: Text(
                        'Hint',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Score: $score',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 20),
                    // Display letters in a keyboard-like layout
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildKeyboardRow(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P']),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildKeyboardRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L']),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildKeyboardRow(['Z', 'X', 'C', 'V', 'B', 'N', 'M']),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildKeyboardRow(List<String> letters) {
    return Row(
      children: letters.map((letter) {
        return Padding(
          padding: const EdgeInsets.all(5.0),
          child: ElevatedButton(
            onPressed: remainingChances > 0 && guessedLetters.contains("_") ? () => guessLetter(letter.toLowerCase()) : null,
            child: Text(letter),
          ),
        );
      }).toList(),
    );
  }
}
