import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'services/riot_api_service.dart';
import 'app_theme.dart';
import 'gradient_scaffold.dart';
import 'user_session.dart';
import 'user_profile_page.dart';

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

  void _login() async {
    String email = _usernameController.text;
    String mdp = _passwordController.text;
    if (mdp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le mot de passe ne peut pas être vide")),
      );
      return;
    }


  Map<String, dynamic> loginData = {
    'email': email,
    'mdp': mdp,
  };


    try {
      final response = await http.post(
        Uri.parse('http://163.5.143.64:8080/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'Login successful') {
          UserSession.email = email;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage(title: 'LoL Stats Tracker')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la connexion : ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion : $e')),
      );
    }
  }

  void _register() async {
    String email = _usernameController.text;
    String mdp = _passwordController.text;
    if (mdp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le mot de passe ne peut pas être vide")),
      );
      return;
    }

    Map<String, dynamic> registerData = {
      'email': email,
      'mdp': mdp,
    };


    try {
      final response = await http.post(
        Uri.parse('http://163.5.143.64:8080/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registerData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inscription réussie !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'inscription : ${response.body}')),
        );
      }
    } catch (e) {
    print('Erreur réseau : $e');
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Erreur lors de l\'inscription : $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Connexion'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Connexion',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person, color: Colors.grey),
                  hintText: 'Email',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.grey),
                  hintText: 'Mot de passe',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  child: Text('Se connecter'),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _register,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  child: Text("S'inscrire"),
                ),
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
  final TextEditingController _searchController = TextEditingController();
  int _selectedQueue = 0;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.summonerName;
    _futureStats = RiotApiService.fetchStats(widget.summonerName);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _futureStats = RiotApiService.fetchStats(query);
      });
    }
  }

  List<MatchStats> _filteredMatches(List<MatchStats> matches) {
    switch (_selectedQueue) {
      case 1:
        return matches.where((m) => m.queueId == 420).toList();
      case 2:
        return matches.where((m) => m.queueId == 440).toList();
      case 3:
        return matches.where((m) => m.queueId == 450).toList();
      default:
        return matches;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
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
              hintText: 'Rechercher un Riot ID',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
      ),
      body: FutureBuilder<SummonerStats>(
        future: _futureStats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Aucune donnée', style: TextStyle(color: Colors.white)));
          } else {
            final stats = snapshot.data!;
            _searchController.text = stats.summonerName;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- En-tête profil ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1F33),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(
                            RiotApiService.profileIconUrl(stats.profileIconId),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats.summonerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats.tier} ${stats.rank}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              'Niveau ${stats.summonerLevel}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Winrate: '
                    '${stats.wins + stats.losses == 0 ? '0' : ((stats.wins / (stats.wins + stats.losses)) * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: stats.wins + stats.losses == 0
                        ? 0
                        : stats.wins / (stats.wins + stats.losses),
                    backgroundColor: Colors.white24,
                    color: Theme.of(context).colorScheme.secondary,
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
                      onTap: (i) => setState(() => _selectedQueue = i),
                      tabs: const [
                        Tab(text: 'Tout'),
                        Tab(text: 'Solo/Q'),
                        Tab(text: 'Flex'),
                        Tab(text: 'ARAM'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._filteredMatches(stats.recentMatches).map(
                    (m) => FutureBuilder<String>(
                      future: RiotApiService.fetchChampionIconUrl(m.champion),
                      builder: (context, snapshot) {
                        final iconWidget =
                            snapshot.connectionState == ConnectionState.done && snapshot.hasData
                                ? CircleAvatar(
                                    radius: 24,
                                    backgroundImage: NetworkImage(snapshot.data!),
                                  )
                                : const SizedBox(width: 48, height: 48);
                        return GestureDetector(
                          onTap: () async {
                            final detail =
                                await RiotApiService.fetchMatchDetail(m.matchId);
                            // ignore: use_build_context_synchronously
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => MatchDetailPage(detail: detail)),
                            );
                          },
                          child: Card(
                            color: const Color(0xFF1D1F33),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: iconWidget,
                              title: Text(
                                m.champion,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${m.kills}/${m.deaths}/${m.assists}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Icon(
                                m.win ? Icons.check_circle : Icons.cancel,
                                color: m.win ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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

class MatchDetailPage extends StatelessWidget {
  final MatchDetail detail;
  const MatchDetailPage({super.key, required this.detail});

  Widget _buildTeam(String label, List<MatchParticipant> team) {
    return Card(
      color: const Color(0xFF1D1F33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...team.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: FutureBuilder<String>(
                        future: RiotApiService.fetchChampionIconUrl(p.champion),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done ||
                              snapshot.data == null) {
                            return const SizedBox(width: 40, height: 40);
                          }
                          return CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(snapshot.data!),
                          );
                        },
                      ),
                      title: Text(
                        p.summonerName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${p.kills}/${p.deaths}/${p.assists}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    SizedBox(
                      height: 24,
                      child: Row(
                        children: [
                          for (final id in p.items)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Image.network(
                                RiotApiService.itemIconUrl(id),
                                width: 24,
                                height: 24,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF22245A), Color(0xFF090979)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Détail du match'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeam('Equipe 1', detail.blueTeam),
            const SizedBox(height: 16),
            _buildTeam('Equipe 2', detail.redTeam),
          ],
        ),
      ),
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
      theme: AppTheme.darkTheme,
      home: const HomePage(title: 'LoL Stats Tracker'),
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

  Widget _buildChampionCard(FutureOr<String> imageSource, String name, String subtitle) {
    final Future<String> imageFuture = imageSource is String
        ? Future.value(imageSource)
        : imageSource as Future<String>;
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<String>(
              future: imageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError || snapshot.data == null) {
                  return Image.asset(
                    'assets/images/test.png',
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  );
                } else {
                  return Image.network(
                    snapshot.data!,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  );
                }
              },
            ),
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
    return GradientScaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          if (UserSession.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfilePage()),
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
        ],
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
      body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bienvenue sur LoL Stats',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recherchez un invocateur pour afficher ses statistiques.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
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
                          _buildChampionCard(RiotApiService.fetchChampionSplashUrl("Ahri"), 'Ahri', 'Découvrez le champion populaire'),
                          _buildChampionCard(RiotApiService.fetchChampionSplashUrl("Garen"), 'Garen', 'Découvrez le champion populaire'),
                          _buildChampionCard(RiotApiService.fetchChampionSplashUrl("Lux"), 'Lux', 'Découvrez le champion populaire'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
