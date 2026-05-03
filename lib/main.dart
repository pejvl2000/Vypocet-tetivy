import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const ArcCalculatorApp());
}

// Definujeme, co všechno umíme vypočítat
enum CalculationMode { L, h, r }

class ArcCalculatorApp extends StatelessWidget {
  const ArcCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const ArcCalculatorScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('cs', 'CZ'), // Nastavení češtiny
      ],
    );
  }
}

class ArcCalculatorScreen extends StatefulWidget {
  const ArcCalculatorScreen({super.key});

  @override
  State<ArcCalculatorScreen> createState() => _ArcCalculatorScreenState();
}

class _ArcCalculatorScreenState extends State<ArcCalculatorScreen> {
  final TextEditingController _lController = TextEditingController();
  final TextEditingController _hController = TextEditingController();
  final TextEditingController _rController = TextEditingController();

  // Výchozí režim: počítáme poloměr (r)
  CalculationMode _mode = CalculationMode.r;

  double _arcLength = 0.0;
  double _arcAngle = 0.0;

  void _calculate() {
    double l = double.tryParse(_lController.text.replaceFirst(',', '.')) ?? 0;
    double h = double.tryParse(_hController.text.replaceFirst(',', '.')) ?? 0;
    double r = double.tryParse(_rController.text.replaceFirst(',', '.')) ?? 0;

    setState(() {
      switch (_mode) {
        case CalculationMode.r:
          // Validace: L musí být větší než h (praktické omezení pro smysluplný oblouk)
          if (h > 0 && l > h) {
            r = (pow(l, 2) / (8 * h)) + (h / 2);
            _rController.text = r.toStringAsFixed(2).replaceFirst('.', ',');
          } else {
            _rController.text = "Error"; // Nebo nechat prázdné
            r = 0;
          }
          break;

        case CalculationMode.h:
          // Validace: L nesmí být větší než 2*r (tětiva nemůže být delší než průměr)
          if (r > 0 && l <= 2 * r && l > 0) {
            h = r - sqrt(pow(r, 2) - pow(l / 2, 2));
            _hController.text = h.toStringAsFixed(2).replaceFirst('.', ',');
          } else {
            _hController.text = "Error"; 
            h = 0;
          }
          break;

        case CalculationMode.L:
          // Validace: h nesmí být větší než r
          if (r > 0 && h > 0 && h <= r) {
            l = 2 * sqrt(2 * r * h - pow(h, 2));
            _lController.text = l.toStringAsFixed(2).replaceFirst('.', ',');
          } else {
            _lController.text = "Error";
            l = 0;
          }
          break;
      }

      // 2. Doplňkové výpočty (Délka oblouku a Úhel)
      // Proběhnou jen pokud máme platné R a L
      if (r > 0 && l > 0 && l <= 2 * r) {
        // Kontrola pro asin: hodnota musí být v rozsahu -1 až 1
        double ratio = l / (2 * r);
        if (ratio > 1.0) ratio = 1.0; 
        
        double angleRad = 2 * asin(ratio);
        _arcAngle = angleRad * (180 / pi);
        _arcLength = angleRad * r;
      } else {
        _arcAngle = 0.0;
        _arcLength = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Výpočet oblouku", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildRow("Délka tětivy (L)", _lController, CalculationMode.L),
                const Divider(),
                _buildRow("Výška vzepětí (h)", _hController, CalculationMode.h),
                const Divider(),
                _buildRow("Poloměr (R)", _rController, CalculationMode.r),
                
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      _lController.clear();
                      _hController.clear();
                      _rController.clear();
                      setState(() {
                        _arcLength = 0.0;
                        _arcAngle = 0.0;
                      });
                    },
                    child: const Text("Smazat"),
                  ),
                ),
                const Divider(thickness: 2), // Silnější čára pro oddělení
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text("Doplňkové údaje:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                _buildReadOnlyRow("Délka oblouku (S)", _arcLength.toStringAsFixed(2).replaceFirst('.', ','), "mm"),
                _buildReadOnlyRow("Středový úhel (φ)", _arcAngle.toStringAsFixed(1).replaceFirst('.', ','), "°"),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            height: 400,
            child: Image.asset('assets/Nakres.png', errorBuilder: (context, error, stackTrace) => const Placeholder()),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, TextEditingController controller, CalculationMode rowMode) {
    bool isResult = _mode == rowMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Oranžové políčko - kliknutím změníš režim výpočtu
          GestureDetector(
            onTap: () => setState(() {
              _mode = rowMode;
              _calculate();
            }),
            child: Icon(
              isResult ? Icons.check_box : Icons.check_box_outline_blank,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isResult ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              enabled: !isResult, // Pokud je to výsledek, nepustíme tam klávesnici
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isResult ? FontWeight.bold : FontWeight.normal, 
                color: (isResult && controller.text.contains(RegExp(r'[a-zA-Z]'))) 
                    ? Colors.red      // Pokud text obsahuje písmena (chybu), bude červený
                    : (isResult ? Colors.green : Colors.black)
              ),
              decoration: const InputDecoration(border: InputBorder.none, hintText: "0"),
              onChanged: (_) => _calculate(),
            ),
          ),
          const SizedBox(width: 5),
          const Text("mm", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
  Widget _buildReadOnlyRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 34), // Odsazení, aby text lícoval s řádky výše (šířka ikony + mezera)
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(width: 10),
          Text(unit, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}