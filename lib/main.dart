// PreguntadosFutbol - main.dart
// Versión limpia: carga preguntas desde assets/questions.json (JSON), categorías, dificultades, temporizador, animaciones y sonidos.
// Instrucciones:
// 1) Crea un nuevo proyecto Flutter.
// 2) Añade estas dependencias en pubspec.yaml:
//    audioplayers: ^2.1.6
// 3) Añade estos assets en pubspec.yaml:
//    assets:
//      - assets/questions.json
//      - assets/sounds/gol.mp3
//      - assets/sounds/fallo.mp3
// 4) Coloca los archivos correspondientes en la carpeta assets/.
// 5) Reemplaza lib/main.dart por este archivo y ejecuta `flutter pub get` y `flutter run`.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
  // Cargamos el JSON de preguntas antes de arrancar la app
  final String raw = await rootBundle.loadString('assets/questions.json');
  final List<dynamic> parsed = json.decode(raw);
  final List<Question> questions = parsed.map((m) => Question.fromJson(m)).toList();

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
    // Espera campos: id (opcional), pregunta, opciones, respuestaCorrecta (index), categoria, dificultad
    final catStr = (json['categoria'] ?? 'Historia').toString();
    final diffStr = (json['dificultad'] ?? 'Facil').toString();
    Category cat = Category.Historia;
    Difficulty diff = Difficulty.Facil;
    try {
      cat = Category.values.firstWhere((e) => categoryToString(e).toLowerCase() == catStr.toLowerCase());
    } catch (_) {}
    try {
      diff = Difficulty.values.firstWhere((e) => difficultyToString(e).toLowerCase() == diffStr.toLowerCase());
    } catch (_) {}

    return Question(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      text: json['pregunta'] ?? json['text'] ?? '',
      options: List<String>.from(json['opciones'] ?? json['options'] ?? []),
      correctIndex: json['respuestaCorrecta'] ?? json['correctIndex'] ?? 0,
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
                const Icon(Icons.sports_soccer, size: 120, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  '¡Bienvenido a Preguntas sobre Fútbol!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pon a prueba tus conocimientos. Elige categoría y dificultad para comenzar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Comenzar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryDifficultySelection(questions: questions)));
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  child: const Text('Ver instrucciones'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Instrucciones'),
                      content: const Text('Responde las preguntas seleccionando una de las opciones. Cada respuesta correcta suma 1 punto. Hay un temporizador según la dificultad.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
                    ),
                  ),
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
  State<CategoryDifficultySelection> createState() => _CategoryDifficultySelectionState();
}

class _CategoryDifficultySelectionState extends State<CategoryDifficultySelection> {
  Category _selectedCategory = Category.Historia;
  Difficulty _selectedDifficulty = Difficulty.Facil;

  List<Question> _filterQuestions() {
    return widget.questions.where((q) => q.category == _selectedCategory && q.difficulty == _selectedDifficulty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final available = _filterQuestions();
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir categoría y dificultad'), backgroundColor: Colors.green.shade700),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Categoría', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Category.values.map((c) {
                final selected = c == _selectedCategory;
                return ChoiceChip(
                  label: Text(categoryToString(c)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Dificultad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Difficulty.values.map((d) {
                final selected = d == _selectedDifficulty;
                return ChoiceChip(
                  label: Text(difficultyToString(d)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedDifficulty = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final filtered = _filterQuestions();
                if (filtered.isEmpty) {
                  // Si no hay preguntas para la combinacion exacta, mostrar aviso y ofrecer regresar
                  showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text('Sin preguntas'),
                    content: const Text('No hay preguntas para la combinación seleccionada. Intenta otra combinación.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
                  ));
                } else {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizPage(questions: filtered, category: _selectedCategory, difficulty: _selectedDifficulty)));
                }
              },
              child: const Text('Jugar'),
            ),
            const SizedBox(height: 12),
            Text('Preguntas disponibles: ${available.length}', textAlign: TextAlign.center),
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

  const QuizPage({super.key, required this.questions, required this.category, required this.difficulty});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  late List<Question> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;
  late int _timeLeft;
  Timer? _timer;
  late AnimationController _animController;
  bool _showCorrectAnim = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);
    _questions.shuffle();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
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
          _answered = true;
          _selectedIndex = null;
          _playSound(false);
          _animController.forward(from: 0);
          t.cancel();
        }
      });
    });
  }

  Future<void> _playSound(bool correct) async {
    try {
      if (correct) {
        reproducirGol();
      } else {
        reproducirFallo();
      }
    } catch (e) {
      // ignore
    }
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      final isCorrect = index == _questions[_currentIndex].correctIndex;
      if (isCorrect) _score += 1;
      _playSound(isCorrect);
      _showCorrectAnim = isCorrect;
      _animController.forward(from: 0);
      _timer?.cancel();
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      _selectedIndex = null;
      _answered = false;
      _showCorrectAnim = false;
    });
    if (_currentIndex >= _questions.length) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultPage(score: _score, total: _questions.length, category: widget.category, difficulty: widget.difficulty)));
    } else {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(body: Center(child: Text('No hay preguntas disponibles')));
    }
    final q = _questions[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text('${categoryToString(widget.category)} · ${difficultyToString(widget.difficulty)}'), backgroundColor: Colors.green.shade700),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pregunta ${_currentIndex + 1} / ${_questions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(children: [
                  const Icon(Icons.timer, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text('$_timeLeft s', style: const TextStyle(fontWeight: FontWeight.bold)),
                ])
              ],
            ),
            const SizedBox(height: 12),
            AnimatedScale(
              scale: _showCorrectAnim ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(q.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(q.options.length, (i) {
              final isCorrect = i == q.correctIndex;
              final isSelected = i == _selectedIndex;
              Color? color;
              if (_answered) {
                if (isSelected) color = isCorrect ? Colors.green : Colors.red;
                if (!isSelected && isCorrect) color = Colors.green.shade200;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color ?? Colors.white,
                    foregroundColor: color != null ? Colors.black : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  onPressed: () => _selectOption(i),
                  child: Align(alignment: Alignment.centerLeft, child: Text(q.options[i], style: const TextStyle(fontSize: 16))),
                ),
              );
            }),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Puntuación: $_score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ElevatedButton(
                  onPressed: _answered ? _nextQuestion : null,
                  child: Text(_currentIndex + 1 < _questions.length ? 'Siguiente' : 'Finalizar'),
                ),
              ],
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

  const ResultPage({super.key, required this.score, required this.total, required this.category, required this.difficulty});

  String _message() {
    final ratio = score / total;
    if (ratio == 1.0) return '¡Perfecto! Eres un verdadero experto.';
    if (ratio >= 0.7) return '¡Muy bien! Tienes muy buenos conocimientos.';
    if (ratio >= 0.4) return 'No está mal, sigue practicando.';
    return 'Sigue estudiando y practicando. ¡Mejorará!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado'), backgroundColor: Colors.green.shade700),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 96, color: Colors.amber),
                const SizedBox(height: 16),
                Text('$score / $total', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(_message(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                Text('Categoría: ${categoryToString(category)}  •  Dificultad: ${difficultyToString(difficulty)}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 24),
                ElevatedButton(
                      onPressed: () {
                      // Regresa por la pila de navegación hasta la primera ruta (WelcomeScreen).
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('Volver al inicio'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- END OF FILE ----------
