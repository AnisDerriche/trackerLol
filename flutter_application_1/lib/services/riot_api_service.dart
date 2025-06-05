import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service utilitaire pour communiquer avec l'API Riot.
///
/// Le token d'API doit être placé dans [_apiKey]. Pour un vrai
/// projet il est recommandé de charger cette valeur depuis un
/// stockage sécurisé ou un fichier de configuration ignoré par git.
class RiotApiService {
  static const _apiKey = 'RGAPI-fe38694a-ea66-4b15-a350-cd8b12abc707';
  static const _baseUrl = 'https://euw1.api.riotgames.com';
  static const _ddragonVersion = '14.7.1';
  static const _dataDragonUrl =
      'https://ddragon.leagueoflegends.com/cdn/$_ddragonVersion/data/en_US/champion.json';

  /// Récupère les statistiques d'un invocateur à partir d'un nom ou d'un Riot ID
  /// sous la forme `Nom#TAG`.
  static Future<SummonerStats> fetchStats(String query) async {
    Map<String, dynamic> summonerData;
    Map<String, dynamic>? accountData;

    // Si un tag est présent, on utilise l'API Riot ID pour obtenir le PUUID
    late String puuid;
    if (query.contains('#')) {
      final parts = query.split('#');
      final gameName = parts.first;
      final tagLine = parts.last;
      final accountResponse = await http.get(
        Uri.parse(
            'https://europe.api.riotgames.com/riot/account/v1/accounts/by-riot-id/$gameName/$tagLine?api_key=$_apiKey'),
      );
      if (accountResponse.statusCode != 200) {
        throw Exception('Account not found');
      }
      accountData = json.decode(accountResponse.body);
      puuid = accountData?['puuid'];
      final response = await http.get(
        Uri.parse('$_baseUrl/lol/summoner/v4/summoners/by-puuid/$puuid?api_key=$_apiKey'),
      );
      if (response.statusCode != 200) {
        throw Exception('Summoner not found');
      }
      summonerData = json.decode(response.body);
    } else {
      final summonerResponse = await http.get(
        Uri.parse('$_baseUrl/lol/summoner/v4/summoners/by-name/$query?api_key=$_apiKey'),
      );
      if (summonerResponse.statusCode != 200) {
        throw Exception('Summoner not found');
      }
      summonerData = json.decode(summonerResponse.body);
      puuid = summonerData['puuid'];
      final accountResponse = await http.get(Uri.parse(
          'https://europe.api.riotgames.com/riot/account/v1/accounts/by-puuid/$puuid?api_key=$_apiKey'));
      if (accountResponse.statusCode == 200) {
        accountData = json.decode(accountResponse.body);
      }
    }

    final id = summonerData['id'];

    final leagueResponse = await http.get(
      Uri.parse('$_baseUrl/lol/league/v4/entries/by-summoner/$id?api_key=$_apiKey'),
    );
    if (leagueResponse.statusCode != 200) {
      throw Exception('League data not available');
    }
    final list = json.decode(leagueResponse.body) as List<dynamic>;
    final soloQueue = list.firstWhere(
      (entry) => entry['queueType'] == 'RANKED_SOLO_5x5',
      orElse: () => null,
    );

    String tier = 'Unranked';
    String rank = '';
    int wins = 0;
    int losses = 0;
    if (soloQueue != null) {
      tier = (soloQueue['tier'] as String?) ?? 'Unranked';
      rank = (soloQueue['rank'] as String?) ?? '';
      wins = (soloQueue['wins'] as int?) ?? 0;
      losses = (soloQueue['losses'] as int?) ?? 0;
    }

    // Utilisé pour récupérer les matchs récents et associer le Riot ID
    final puuidForMatches = puuid;

    final matchesResponse = await http.get(
      Uri.parse(
          'https://europe.api.riotgames.com/lol/match/v5/matches/by-puuid/$puuidForMatches/ids?start=0&count=5&api_key=$_apiKey'),
    );

    List<dynamic> matchIds = [];
    if (matchesResponse.statusCode == 200) {
      matchIds = json.decode(matchesResponse.body) as List<dynamic>;
    }

    final List<MatchStats> matches = [];
    for (final mId in matchIds) {
      final matchDetailResponse = await http.get(
        Uri.parse(
            'https://europe.api.riotgames.com/lol/match/v5/matches/$mId?api_key=$_apiKey'),
      );
      if (matchDetailResponse.statusCode == 200) {
        final data = json.decode(matchDetailResponse.body);
        final participants = data['info']['participants'] as List<dynamic>;
        final participant = participants.firstWhere(
          (p) => p['puuid'] == puuid,
          orElse: () => null,
        );
        if (participant != null) {
          final championName = participant['championName'] as String?;
          final kills = participant['kills'] as int?;
          final deaths = participant['deaths'] as int?;
          final assists = participant['assists'] as int?;
          final win = participant['win'] as bool?;
          final queueId = data['info']['queueId'] as int?;

          if (championName != null &&
              kills != null &&
              deaths != null &&
              assists != null &&
              win != null) {
            matches.add(MatchStats(
              matchId: mId as String,
              champion: championName,
              kills: kills,
              deaths: deaths,
              assists: assists,
              win: win,
              queueId: queueId ?? 0,
            ));
          }
        }
      }
    }

    final String summonerName = accountData != null
        ? '${accountData['gameName']}#${accountData['tagLine']}'
        : (summonerData['name'] as String?) ?? 'Unknown';

    return SummonerStats(
      summonerName: summonerName,
      profileIconId: (summonerData['profileIconId'] as int?) ?? 0,
      summonerLevel: (summonerData['summonerLevel'] as int?) ?? 0,
      tier: tier,
      rank: rank,
      wins: wins,
      losses: losses,
      recentMatches: matches,
    );
  }

  /// Renvoie l'URL du splash art d'un champion.
  static Future<String> fetchChampionSplashUrl(String championName) async {
    final championsResponse = await http.get(Uri.parse(_dataDragonUrl));
    if (championsResponse.statusCode != 200) {
      throw Exception('Failed to load champion data');
    }

    final championsData =
        json.decode(championsResponse.body)['data'] as Map<String, dynamic>;

    String? dataKey;
    for (var entry in championsData.entries) {
      if ((entry.value['name'] as String).toLowerCase() == championName.toLowerCase()) {
        dataKey = entry.key;
        break;
      }
    }
    if (dataKey == null) {
      throw Exception('Champion not found');
    }

    final championId = championsData[dataKey]['id'];
    return 'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${championId}_0.jpg';
  }

  /// Renvoie l'URL de l'icône d'un champion.
  static Future<String> fetchChampionIconUrl(String championName) async {
    final championsResponse = await http.get(Uri.parse(_dataDragonUrl));
    if (championsResponse.statusCode != 200) {
      throw Exception('Failed to load champion data');
    }

    final championsData =
        json.decode(championsResponse.body)['data'] as Map<String, dynamic>;

    String? dataKey;
    for (var entry in championsData.entries) {
      if ((entry.value['name'] as String).toLowerCase() ==
          championName.toLowerCase()) {
        dataKey = entry.key;
        break;
      }
    }
    if (dataKey == null) {
      throw Exception('Champion not found');
    }

    final championId = championsData[dataKey]['id'];
    return 'https://ddragon.leagueoflegends.com/cdn/$_ddragonVersion/img/champion/${championId}.png';
  }

  /// Construit l'URL de l'icone de profil d'un invocateur.
  static String profileIconUrl(int iconId) {
    return 'https://ddragon.leagueoflegends.com/cdn/$_ddragonVersion/img/profileicon/$iconId.png';
  }

  /// Construit l'URL de l'icone d'un item.
  static String itemIconUrl(int itemId) {
    if (itemId == 0) {
      return 'https://ddragon.leagueoflegends.com/cdn/$_ddragonVersion/img/item/0.png';
    }
    return 'https://ddragon.leagueoflegends.com/cdn/$_ddragonVersion/img/item/$itemId.png';
  }

  /// Récupère le détail complet d'un match pour afficher les deux équipes.
  static Future<MatchDetail> fetchMatchDetail(String matchId) async {
    final response = await http.get(Uri.parse(
        'https://europe.api.riotgames.com/lol/match/v5/matches/$matchId?api_key=$_apiKey'));
    if (response.statusCode != 200) {
      throw Exception('Match not found');
    }
    final data = json.decode(response.body);
    final participants = data['info']['participants'] as List<dynamic>;
    final List<MatchParticipant> blueTeam = [];
    final List<MatchParticipant> redTeam = [];
    for (final p in participants) {
      String name = (p['summonerName'] as String?) ?? 'Unknown';
      final riotGameName = p['gameName'] ?? p['riotIdGameName'];
      final riotTag = p['tagLine'] ?? p['riotIdTagline'];
      if (riotGameName != null && riotTag != null) {
        name = '$riotGameName#$riotTag';
      } else if (p['puuid'] != null) {
        final accResp = await http.get(Uri.parse(
            'https://europe.api.riotgames.com/riot/account/v1/accounts/by-puuid/${p['puuid']}?api_key=$_apiKey'));
        if (accResp.statusCode == 200) {
          final accData = json.decode(accResp.body);
          final gn = accData['gameName'];
          final tl = accData['tagLine'];
          if (gn != null && tl != null) {
            name = '$gn#$tl';
          }
        }
      }

      final participant = MatchParticipant(
        summonerName: name,
        champion: (p['championName'] as String?) ?? 'Unknown',
        kills: (p['kills'] as int?) ?? 0,
        deaths: (p['deaths'] as int?) ?? 0,
        assists: (p['assists'] as int?) ?? 0,
        win: (p['win'] as bool?) ?? false,
        items: [
          for (var i = 0; i <= 6; i++) (p['item$i'] as int?) ?? 0,
        ],
      );
      if ((p['teamId'] as int?) == 100) {
        blueTeam.add(participant);
      } else {
        redTeam.add(participant);
      }
    }
    return MatchDetail(blueTeam: blueTeam, redTeam: redTeam);
  }
}

/// Modèle simple pour représenter les statistiques d'un invocateur.
class SummonerStats {
  final String summonerName;
  final int profileIconId;
  final int summonerLevel;
  final String tier;
  final String rank;
  final int wins;
  final int losses;
  final List<MatchStats> recentMatches;

  SummonerStats({
    required this.summonerName,
    required this.profileIconId,
    required this.summonerLevel,
    required this.tier,
    required this.rank,
    required this.wins,
    required this.losses,
    required this.recentMatches,
  });

  factory SummonerStats.fromJson(Map<String, dynamic> json) {
    return SummonerStats(
      summonerName: (json['summonerName'] as String?) ?? 'Unknown',
      profileIconId: (json['profileIconId'] as int?) ?? 0,
      summonerLevel: (json['summonerLevel'] as int?) ?? 0,
      tier: (json['tier'] as String?) ?? 'Unranked',
      rank: (json['rank'] as String?) ?? '',
      wins: (json['wins'] as int?) ?? 0,
      losses: (json['losses'] as int?) ?? 0,
      recentMatches: (json['recentMatches'] as List<dynamic>?)
              ?.map((e) => MatchStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

}

class MatchStats {
  final String matchId;
  final String champion;
  final int kills;
  final int deaths;
  final int assists;
  final bool win;
  final int queueId;

  MatchStats({
    required this.matchId,
    required this.champion,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.win,
    required this.queueId,
  });

  factory MatchStats.fromJson(Map<String, dynamic> json) {
    return MatchStats(
      matchId: (json['matchId'] as String?) ?? '',
      champion: (json['champion'] as String?) ?? 'Unknown',
      kills: (json['kills'] as int?) ?? 0,
      deaths: (json['deaths'] as int?) ?? 0,
      assists: (json['assists'] as int?) ?? 0,
      win: (json['win'] as bool?) ?? false,
      queueId: (json['queueId'] as int?) ?? 0,
    );
  }
}

class MatchParticipant {
  final String summonerName;
  final String champion;
  final int kills;
  final int deaths;
  final int assists;
  final bool win;
  final List<int> items;

  MatchParticipant({
    required this.summonerName,
    required this.champion,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.win,
    required this.items,
  });
}

class MatchDetail {
  final List<MatchParticipant> blueTeam;
  final List<MatchParticipant> redTeam;

  MatchDetail({required this.blueTeam, required this.redTeam});
}
