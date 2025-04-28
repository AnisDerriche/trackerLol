import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    // Navigation directe vers la page d'accueil sans vÃ©rification
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage(title: 'LoL Stats Tracker')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Connexion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nom d\'utilisateur',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1D1F33),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1D1F33),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Se connecter', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ProfilePage extends StatefulWidget {
  final String summonerName;
  const ProfilePage({Key? key, required this.summonerName}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<SummonerStats> _futureStats;

  @override
  void initState() {
    super.initState();
    _futureStats = ApiService.fetchStats(widget.summonerName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: FutureBuilder<SummonerStats>(
        future: _futureStats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          } else {
            final stats = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- En-tête profil ---
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/test.png',
                          height: 64, width: 64, fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats.summonerName,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stats.tier} ${stats.rank}',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Victoires: ${stats.wins}   Défaites: ${stats.losses}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  // --- Boutons Résumé / Champions / Maîtrise / …
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: const [
                        _ProfileTab(label: 'Résumé', icon: Icons.favorite_border),
                        SizedBox(width: 12),
                        _ProfileTab(label: 'Champions', icon: Icons.access_time),
                        SizedBox(width: 12),
                        _ProfileTab(label: 'Maîtrise', icon: Icons.show_chart),
                        SizedBox(width: 12),
                        _ProfileTab(label: '', icon: Icons.more_horiz),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- Onglets Tout / SoloQ / Flex / ARAM ---
                  DefaultTabController(
                    length: 4,
                    child: TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.white,
                      tabs: const [
                        Tab(text: 'Tout'),
                        Tab(text: 'Solo/Q'),
                        Tab(text: 'Flex'),
                        Tab(text: 'ARAM'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // TODO: insérer ici des widgets détaillant les stats par queue
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ProfileTab({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ],
      ),
    );
  }
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
  static const _apiKey = 'RGAPI-fe38694a-ea66-4b15-a350-cd8b12abc707';
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
  int _bottomIndex = 0;
  final List<IconData> _bottomIcons = [
    Icons.home,
    Icons.explore,
    Icons.shopping_cart,
    Icons.notifications_none,
    Icons.person_outline,
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCategory(String label, IconData icon, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: selected ? Colors.white : Colors.grey),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.grey, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBanner(String imageAsset, String title) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.asset(imageAsset, height: 140, width: double.infinity, fit: BoxFit.cover),
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChampionCard(String imageAsset, String name, String subtitle) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(imageAsset, height: 120, width: 120, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1D1F33),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              hintText: 'Rechercher un summoner',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage(summonerName: value)),
                );
                _searchController.clear();
              }
            },
          ),
        ),
      ),
      body: _bottomIndex == 0
          // Home content
          ? SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategory('Accueil', Icons.favorite_border, true),
                          const SizedBox(width: 8),
                          _buildCategory('Statistiques', Icons.access_time, false),
                          const SizedBox(width: 8),
                          _buildCategory('Tier List', Icons.show_chart, false),
                          const SizedBox(width: 8),
                          _buildCategory('Plus', Icons.list, false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Banners
                    _buildBanner('assets/images/test.png', 'Statistiques'),
                    const SizedBox(height: 12),
                    _buildBanner('assets/images/test.png', 'Tier List'),
                    const SizedBox(height: 24),
                    // Popular builds header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Builds les plus populaires',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Horizontal champion list
                    SizedBox(
                      height: 190,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildChampionCard('assets/images/test.png', 'Mel', 'Découvrez le nouveau champion'),
                          _buildChampionCard('assets/images/test.png', 'Ambessa', 'Découvrez le nouveau champion'),
                          _buildChampionCard('assets/images/test.png', 'Aurora', 'Découvrez le nouveau champion'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _bottomIndex == 1
              // Login page
              ? const LoginPage()
              : _bottomIndex == 4
                  // Profile page
                  ? ProfilePage(summonerName: "Summoner") // You may want to prompt for a name or store last searched
                  // Fallback
                  : const SizedBox(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _bottomIndex,
        onTap: (i) => setState(() => _bottomIndex = i),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: _bottomIcons.map((icon) => BottomNavigationBarItem(icon: Icon(icon), label: '')).toList(),
      ),
    );
  }
}
