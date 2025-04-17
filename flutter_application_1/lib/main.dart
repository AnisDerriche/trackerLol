import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoL Stats Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const HomePage(title: 'LoL Stats Tracker'),
    );
  }
}

class SummonerStats {
  final String summonerName;
  final String tier;
  final String rank;
  final int wins;
  final int losses;

  SummonerStats({
    required this.summonerName,
    required this.tier,
    required this.rank,
    required this.wins,
    required this.losses,
  });

  factory SummonerStats.fromJson(Map<String, dynamic> json) {
    return SummonerStats(
      summonerName: json['summonerName'],
      tier: json['tier'],
      rank: json['rank'],
      wins: json['wins'],
      losses: json['losses'],
    );
  }
}

class ApiService {
  static const _apiKey = 'notre api key riot';
  static const _baseUrl = 'https://euw1.api.riotgames.com';
  
  static Future<SummonerStats> fetchStats(String summonerName) async {
    final summonerResponse = await http.get(
      Uri.parse('$_baseUrl/lol/summoner/v4/summoners/by-name/$summonerName?api_key=$_apiKey'),
    );
    if (summonerResponse.statusCode != 200) {
      throw Exception('Summoner not found');
    }
    final summonerData = json.decode(summonerResponse.body);
    final id = summonerData['id'];

    final leagueResponse = await http.get(
      Uri.parse('$_baseUrl/lol/league/v4/entries/by-summoner/$id?api_key=$_apiKey'),
    );
    if (leagueResponse.statusCode != 200) {
      throw Exception('League data not available');
    }
    final list = json.decode(leagueResponse.body) as List;
    final soloQueue = list.firstWhere(
      (entry) => entry['queueType'] == 'RANKED_SOLO_5x5',
      orElse: () => null,
    );
    if (soloQueue == null) {
      throw Exception('No solo queue data');
    }

    return SummonerStats(
      summonerName: summonerData['name'],
      tier: soloQueue['tier'],
      rank: soloQueue['rank'],
      wins: soloQueue['wins'],
      losses: soloQueue['losses'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  SummonerStats? _stats;
  String? _error;

  Future<void> _getStats() async {
    setState(() {
      _loading = true;
      _error = null;
      _stats = null;
    });
    try {
      final stats = await ApiService.fetchStats(_controller.text.trim());
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildStatsCard(SummonerStats stats) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              stats.summonerName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('${stats.tier} ${stats.rank}'),
            const SizedBox(height: 8),
            Text('Wins: ${stats.wins}'),
            Text('Losses: ${stats.losses}'),
            const SizedBox(height: 8),
            Text('Win Rate: ${((stats.wins / (stats.wins + stats.losses)) * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Summoner Name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _getStats(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _getStats,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Get Stats'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (_stats != null) _buildStatsCard(_stats!),
          ],
        ),
      ),
    );
  }
}
