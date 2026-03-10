import 'package:flutter/material.dart';
import 'data_model.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});
  @override State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  final _nameController = TextEditingController();
  double _startingCash = 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create League"), backgroundColor: const Color(0xFF2A0D55), foregroundColor: Colors.white),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("League Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: "e.g. Wall Street Wolves", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            const Text("Starting Cash", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(children: [
              Text("€ ${_startingCash.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2A0D55))),
              Expanded(child: Slider(value: _startingCash, min: 1000, max: 10000, divisions: 9, activeColor: const Color(0xFF2A0D55), onChanged: (v) => setState(() => _startingCash = v))),
            ]),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty) {
                    await AppData().createNewLeague(_nameController.text, _startingCash);
                    if (context.mounted) Navigator.pop(context); 
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A0D55), foregroundColor: Colors.white),
                child: const Text("CREATE"),
              ),
            )
          ]),
        ),
      ),
    );
  }
}