// PreguntadosFutbol - main.dart
// Incluye: Confirmar respuesta, resaltado visual antes de confirmar, sonidos.

import 'dart:async';
import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();

Future<void> reproducirGol() async {
  await player.play(AssetSource('sounds/gol.mp3'));
}

Future<void> reproducirFallo() async {
  await player.play(AssetSource('sounds/fallo.mp3'));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String raw = await rootBundle.loadString('assets/questions.json');
  final List<dynamic> parsed = json.decode(raw);
  final List<Question> questions =
      parsed.map((m) => Question.fromJson(m)).toList();

  runApp(PreguntadosFutbolApp(questions: questions));
}

class PreguntadosFutbolApp extends StatelessWidget {
  final List<Question> questions;
  const PreguntadosFutbolApp({super.key, required this.questions});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preguntados Fútbol',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: WelcomeScreen(questions: questions),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Enums
// ignore: constant_identifier_names
enum Category { Historia, Jugadores, Copas }
// ignore: constant_identifier_names
enum Difficulty { Facil, Medio, Dificil }

String categoryToString(Category c) => c.toString().split('.').last;
String difficultyToString(Difficulty d) => d.toString().split('.').last;

// Modelo pregunta
class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final Category category;
  final Difficulty difficulty;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.category,
    required this.difficulty,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final catStr = (json['categoria'] ?? 'Historia').toString();
    final diffStr = (json['dificultad'] ?? 'Facil').toString();
    Category cat = Category.Historia;
    Difficulty diff = Difficulty.Facil;
    try {
      cat = Category.values.firstWhere((e) =>
          categoryToString(e).toLowerCase() == catStr.toLowerCase());
    } catch (_) {}
    try {
      diff = Difficulty.values.firstWhere((e) =>
          difficultyToString(e).toLowerCase() == diffStr.toLowerCase());
    } catch (_) {}

    return Question(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      text: json['pregunta'] ?? json['text'] ?? '',
      options:
          List<String>.from(json['opciones'] ?? json['options'] ?? []),
      correctIndex:
          json['respuestaCorrecta'] ?? json['correctIndex'] ?? 0,
      category: cat,
      difficulty: diff,
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  final List<Question> questions;
  const WelcomeScreen({super.key, required this.questions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_soccer,
                    size: 120, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  '¡Bienvenido a Preguntas sobre Fútbol!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Comenzar'),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CategoryDifficultySelection(
                            questions: questions)));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryDifficultySelection extends StatefulWidget {
  final List<Question> questions;
  const CategoryDifficultySelection({super.key, required this.questions});

  @override
  State<CategoryDifficultySelection> createState() =>
      _CategoryDifficultySelectionState();
}

class _CategoryDifficultySelectionState
    extends State<CategoryDifficultySelection> {
  Category _selectedCategory = Category.Historia;
  Difficulty _selectedDifficulty = Difficulty.Facil;

  List<Question> _filterQuestions() {
    return widget.questions
        .where((q) =>
            q.category == _selectedCategory &&
            q.difficulty == _selectedDifficulty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final available = _filterQuestions();
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir categoría y dificultad')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: Category.values.map((c) {
                return ChoiceChip(
                  label: Text(categoryToString(c)),
                  selected: c == _selectedCategory,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: Difficulty.values.map((d) {
                return ChoiceChip(
                  label: Text(difficultyToString(d)),
                  selected: d == _selectedDifficulty,
                  onSelected: (_) => setState(() => _selectedDifficulty = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final filtered = _filterQuestions();
                if (filtered.isEmpty) {
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: const Text('Sin preguntas'),
                            content: const Text(
                                'No hay preguntas para la combinación seleccionada.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cerrar'))
                            ],
                          ));
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => QuizPage(
                          questions: filtered,
                          category: _selectedCategory,
                          difficulty: _selectedDifficulty)));
                }
              },
              child: const Text('Jugar'),
            ),
            Text('Preguntas disponibles: ${available.length}'),
          ],
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final List<Question> questions;
  final Category category;
  final Difficulty difficulty;

  const QuizPage(
      {super.key,
      required this.questions,
      required this.category,
      required this.difficulty});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<Question> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;
  late int _timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions)..shuffle();
    _startTimer();
  }

  int _baseTimeForDifficulty() {
    switch (widget.difficulty) {
      case Difficulty.Facil:
        return 15;
      case Difficulty.Medio:
        return 12;
      case Difficulty.Dificil:
        return 8;
    }
  }

  void _startTimer() {
    _timeLeft = _baseTimeForDifficulty();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _confirmAnswer();
        }
      });
    });
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() => _selectedIndex = index);
  }

  void _confirmAnswer() {
    if (_answered || _selectedIndex == null) return;
    setState(() {
      _answered = true;
      final isCorrect =
          _selectedIndex == _questions[_currentIndex].correctIndex;
      if (isCorrect) _score++;
      _playSound(isCorrect);
      _timer?.cancel();
    });
  }

  Future<void> _playSound(bool correct) async {
    if (correct) {
      reproducirGol();
    } else {
      reproducirFallo();
    }
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _questions.length) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ResultPage(
                score: _score,
                total: _questions.length,
                category: widget.category,
                difficulty: widget.difficulty,
              )));
    } else {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _answered = false;
      });
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${categoryToString(widget.category)} · ${difficultyToString(widget.difficulty)}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Pregunta ${_currentIndex + 1} / ${_questions.length}'),
            Text('$_timeLeft s'),
            const SizedBox(height: 18),


            // LÍNEA AÑADIDA: Aquí mostramos la pregunta
            Text(
              q.text, // Muestra el texto de la pregunta actual
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 18), // Un poco de espacio extra
            ...List.generate(q.options.length, (i) {
              final isCorrect = i == q.correctIndex;
              final isSelected = i == _selectedIndex;

              Color? bgColor;
              BorderSide borderSide = BorderSide.none;

              if (_answered) {
                if (isSelected) {
                  bgColor = isCorrect ? Colors.green : Colors.red;
                }
                if (!isSelected && isCorrect) {
                  bgColor = Colors.green.shade200;
                }
              } else if (isSelected) {
                bgColor = Colors.blue.shade100;
                borderSide =
                    const BorderSide(color: Colors.blue, width: 2);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor ?? Colors.white,
                    foregroundColor: Colors.black87,
                    side: borderSide,
                  ),
                  onPressed: () => _selectOption(i),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(q.options[i])),
                ),
              );
            }),
            const Spacer(),
            if (!_answered)
              ElevatedButton(
                onPressed: _confirmAnswer,
                child: const Text('Confirmar'),
              )
            else
              ElevatedButton(
                onPressed: _nextQuestion,
                child: Text(_currentIndex + 1 < _questions.length
                    ? 'Siguiente'
                    : 'Finalizar'),
              )
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final int score;
  final int total;
  final Category category;
  final Difficulty difficulty;

  const ResultPage(
      {super.key,
      required this.score,
      required this.total,
      required this.category,
      required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$score / $total',
                style: const TextStyle(fontSize: 42)),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .popUntil((route) => route.isFirst);
              },
              child: const Text('Volver al inicio'),
            )
          ],
        ),
      ),
    );
  }
}
