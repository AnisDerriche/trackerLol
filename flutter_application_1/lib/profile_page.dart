import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
          child: const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              hintText: 'Rechercher',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                    'assets/images/avatar.jpg', 
                    height: 64, width: 64, fit: BoxFit.cover
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '#Nom du Joueur#Id',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'dernière mise à jour',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // --- Boutons Résumé / Champions / Maîtrise / …
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _ProfileTab(label: 'Résumé', icon: Icons.favorite_border),
                _ProfileTab(label: 'Champions', icon: Icons.access_time),
                _ProfileTab(label: 'Maîtrise', icon: Icons.show_chart),
                _ProfileTab(label: '', icon: Icons.more_horiz),
              ],
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
            // TODO: ici tu peux mettre tes cartes de rang, tes stats, etc.
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Ici ton résumé de stats',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // TODO: liste des dernières parties
            const Center(
              child: Text(
                'Liste des dernières parties…',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
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