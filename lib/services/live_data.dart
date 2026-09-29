import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/cities.dart';
import 'parsers.dart';

class CityWeather {
  final String city;
  final double temp;
  final int code;
  final double wind;
  final double? humidity;
  const CityWeather(this.city, this.temp, this.code, this.wind, this.humidity);

  Map<String, dynamic> toJson() =>
      {'city': city, 'temp': temp, 'code': code, 'wind': wind, 'hum': humidity};
  factory CityWeather.fromJson(Map<String, dynamic> j) => CityWeather(
        j['city'] as String,
        (j['temp'] as num).toDouble(),
        (j['code'] as num).toInt(),
        (j['wind'] as num).toDouble(),
        (j['hum'] as num?)?.toDouble(),
      );
}

class NewsSource {
  final String name;
  final String site;
  final List<String> feeds;
  const NewsSource(this.name, this.site, this.feeds);
}

/// مصادر الأخبار. لكل مصدر أكثر من رابط تغذية محتمل، يُجرَّب بالترتيب
/// ويُعتمد أول رابط يرجع أخباراً. المصدر الذي لا يستجيب يظهر في الشاشة
/// مع زر لفتح موقعه مباشرة.
const List<NewsSource> newsSources = [
  NewsSource('عين ليبيا', 'https://www.eanlibya.com/',
      ['https://www.eanlibya.com/feed/']),
  NewsSource('ليبيا هيرالد', 'https://libyaherald.com/',
      ['https://libyaherald.com/feed']),
  NewsSource('بوابة الوسط', 'https://alwasat.ly/',
      ['https://alwasat.ly/rss', 'https://alwasat.ly/feed']),
  NewsSource('ليبيا أوبزرفر', 'https://www.libyaobserver.ly/',
      ['https://www.libyaobserver.ly/rss.xml', 'https://www.libyaobserver.ly/feed']),
  NewsSource('مصرف ليبيا المركزي', 'https://cbl.gov.ly/blog/',
      ['https://cbl.gov.ly/feed/']),
];

/// حالة تحميل جزء من البيانات.
enum LoadState { idle, loading, ok, failed }

class LiveData extends ChangeNotifier {
  LiveData._();
  static final LiveData instance = LiveData._();

  static const _cblUrl = 'https://cbl.gov.ly/currency-exchange-rates/';
  static const _parallelUrl = 'https://www.eanlibya.com/exchangerate/';
  static const _goldUrl = 'https://api.gold-api.com/price/XAU';
  static const _oilUrl =
      'https://api.oilpriceapi.com/v1/prices/latest?by_code=BRENT_CRUDE_USD';
  static const _cacheKey = 'live_cache_v1';
  static const double _gramsPerOunce = 31.1034768;

  List<CblRate> cbl = const [];
  List<ParallelRate> parallel = const [];
  String? parallelUpdated;
  double? goldUsdPerOunce;
  double? brentUsd;
  Map<String, CityWeather> weather = const {};
  List<NewsItem> news = const [];
  Set<String> failedNewsSources = {};
  DateTime? lastUpdated;

  LoadState currency = LoadState.idle;
  LoadState gold = LoadState.idle;
  LoadState oil = LoadState.idle;
  LoadState weatherState = LoadState.idle;
  LoadState newsState = LoadState.idle;

  bool get oilConfigured => AppConfig.oilApiKey.isNotEmpty;

  Timer? _timer;
  bool _refreshing = false;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _loadCache();
    unawaited(refresh());
    _timer = Timer.periodic(
        const Duration(minutes: AppConfig.refreshMinutes), (_) => refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------- مساعدات ----------

  Future<String?> _get(String url, {Map<String, String>? headers}) async {
    try {
      final r = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'LibyaHub/1.0 (Android)',
        'Accept-Language': 'ar,en;q=0.8',
        ...?headers,
      }).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return utf8.decode(r.bodyBytes, allowMalformed: true);
    } catch (_) {}
    return null;
  }

  // ---------- القيم المشتقة ----------

  CblRate? cblRate(String arabicNameContains) {
    for (final r in cbl) {
      if (r.name.contains(arabicNameContains)) return r;
    }
    return null;
  }

  double? parallelRate(String arabicNameContains) {
    for (final r in parallel) {
      if (r.name.contains(arabicNameContains)) return r.price;
    }
    return null;
  }

  double? get usdOfficial => cblRate('الدولار الأمريكي')?.average;
  double? get usdParallel => parallelRate('الدولار');

  /// سعر غرام الذهب الخام بالدينار (تقدير: السعر العالمي × سعر الدولار).
  /// لا يشمل المصنعية ولا هامش الصاغة.
  double? goldPerGramLyd(int karat) {
    final usd = goldUsdPerOunce;
    final rate = usdParallel ?? usdOfficial;
    if (usd == null || rate == null) return null;
    return usd / _gramsPerOunce * (karat / 24) * rate;
  }

  // ---------- التحديث ----------

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    currency = gold = oil = weatherState = newsState = LoadState.loading;
    notifyListeners();
    try {
      await Future.wait([
        _refreshCurrency(),
        _refreshGold(),
        _refreshOil(),
        _refreshWeather(),
        _refreshNews(),
      ]);
      lastUpdated = DateTime.now();
      await _saveCache();
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCurrency() async {
    final results = await Future.wait([_get(_cblUrl), _get(_parallelUrl)]);
    var ok = false;
    if (results[0] != null) {
      final parsed = parseCblRates(results[0]!);
      if (parsed.isNotEmpty) {
        cbl = parsed;
        ok = true;
      }
    }
    if (results[1] != null) {
      final parsed = parseParallelRates(results[1]!);
      if (parsed.isNotEmpty) {
        parallel = parsed;
        parallelUpdated = parseParallelUpdated(results[1]!);
        ok = true;
      }
    }
    currency = ok ? LoadState.ok : LoadState.failed;
    notifyListeners();
  }

  Future<void> _refreshGold() async {
    final body = await _get(_goldUrl);
    try {
      if (body != null) {
        final j = jsonDecode(body) as Map<String, dynamic>;
        final p = (j['price'] as num?)?.toDouble();
        if (p != null && p > 0) {
          goldUsdPerOunce = p;
          gold = LoadState.ok;
          notifyListeners();
          return;
        }
      }
    } catch (_) {}
    gold = LoadState.failed;
    notifyListeners();
  }

  Future<void> _refreshOil() async {
    if (!oilConfigured) {
      oil = LoadState.idle;
      return;
    }
    final body = await _get(_oilUrl,
        headers: {'Authorization': 'Token ${AppConfig.oilApiKey}'});
    try {
      if (body != null) {
        final j = jsonDecode(body) as Map<String, dynamic>;
        final p = ((j['data'] as Map<String, dynamic>)['price'] as num?)?.toDouble();
        if (p != null && p > 0) {
          brentUsd = p;
          oil = LoadState.ok;
          notifyListeners();
          return;
        }
      }
    } catch (_) {}
    oil = LoadState.failed;
    notifyListeners();
  }

  Future<void> _refreshWeather() async {
    final lats = libyaCities.map((c) => c.lat).join(',');
    final lngs = libyaCities.map((c) => c.lng).join(',');
    final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lats&longitude=$lngs'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
        '&timezone=auto';
    final body = await _get(url);
    try {
      if (body != null) {
        final decoded = jsonDecode(body);
        final list = decoded is List ? decoded : [decoded];
        final map = <String, CityWeather>{};
        for (var i = 0; i < list.length && i < libyaCities.length; i++) {
          final cur = (list[i] as Map<String, dynamic>)['current'] as Map<String, dynamic>?;
          if (cur == null) continue;
          final t = (cur['temperature_2m'] as num?)?.toDouble();
          final code = (cur['weather_code'] as num?)?.toInt();
          if (t == null || code == null) continue;
          map[libyaCities[i].name] = CityWeather(
            libyaCities[i].name,
            t,
            code,
            (cur['wind_speed_10m'] as num?)?.toDouble() ?? 0,
            (cur['relative_humidity_2m'] as num?)?.toDouble(),
          );
        }
        if (map.isNotEmpty) {
          weather = map;
          weatherState = LoadState.ok;
          notifyListeners();
          return;
        }
      }
    } catch (_) {}
    weatherState = LoadState.failed;
    notifyListeners();
  }

  Future<void> _refreshNews() async {
    final failed = <String>{};
    final all = <NewsItem>[];
    await Future.wait(newsSources.map((s) async {
      for (final feed in s.feeds) {
        final body = await _get(feed);
        if (body == null) continue;
        final items = parseFeed(body, s.name);
        if (items.isNotEmpty) {
          all.addAll(items);
          return;
        }
      }
      failed.add(s.name);
    }));
    all.sort((a, b) {
      final da = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    failedNewsSources = failed;
    if (all.isNotEmpty) {
      news = all;
      newsState = LoadState.ok;
    } else {
      newsState = LoadState.failed;
    }
    notifyListeners();
  }

  // ---------- التخزين المؤقت (للعمل بدون إنترنت) ----------

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'cbl': cbl.map((e) => e.toJson()).toList(),
          'parallel': parallel.map((e) => e.toJson()).toList(),
          'parallelUpdated': parallelUpdated,
          'gold': goldUsdPerOunce,
          'oil': brentUsd,
          'weather': weather.values.map((e) => e.toJson()).toList(),
          'news': news.take(40).map((e) => e.toJson()).toList(),
          'at': lastUpdated?.toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      cbl = [for (final e in (j['cbl'] as List? ?? [])) CblRate.fromJson(e as Map<String, dynamic>)];
      parallel = [for (final e in (j['parallel'] as List? ?? [])) ParallelRate.fromJson(e as Map<String, dynamic>)];
      parallelUpdated = j['parallelUpdated'] as String?;
      goldUsdPerOunce = (j['gold'] as num?)?.toDouble();
      brentUsd = (j['oil'] as num?)?.toDouble();
      weather = {
        for (final e in (j['weather'] as List? ?? []))
          (e as Map<String, dynamic>)['city'] as String: CityWeather.fromJson(e)
      };
      news = [for (final e in (j['news'] as List? ?? [])) NewsItem.fromJson(e as Map<String, dynamic>)];
      lastUpdated = j['at'] == null ? null : DateTime.tryParse(j['at'] as String);
      notifyListeners();
    } catch (_) {}
  }
}
