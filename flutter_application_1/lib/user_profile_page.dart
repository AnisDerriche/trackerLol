import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'gradient_scaffold.dart';
import 'user_session.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<List<String>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<String>> _fetchHistory() async {
    final email = UserSession.email;
    if (email == null) return [];
    try {
      final response = await http
          .get(Uri.parse('http://163.5.143.64:8080/history?email=$email'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = (data['history'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        return list;
      }
    } catch (_) {
      // ignore errors and return empty list
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email : ${UserSession.email ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 20),
            const Text(
              'Historique des Riot IDs:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Text('Erreur lors du chargement',
                        style: TextStyle(color: Colors.red));
                  } else {
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) {
                      return const Text('Aucun historique',
                          style: TextStyle(color: Colors.white));
                    }
                    return ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final id = history[index];
                        return ListTile(
                          title: Text(id,
                              style:
                                  const TextStyle(color: Colors.white)),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                UserSession.logout();
                Navigator.pop(context);
              },
              child: const Text('Déconnexion'),
            ),
          ],
        ),
      ),
    );
  }
}
