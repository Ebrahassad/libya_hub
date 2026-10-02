import 'package:flutter/material.dart';

import '../data/directory.dart';
import '../data/hotels.dart';
import '../data/news_sources.dart';

/// تحليل المحتوى البعيد (content.json). كل الدوال نقية وتتجاهل أي عنصر غير صالح
/// بدل أن تُسقط التطبيق، وتقبل فقط روابط https/http وأرقام هواتف ومعرّفات حزم سليمة.

final RegExp _urlRe = RegExp(r'^https?://[^\s]+$');
final RegExp _pkgRe = RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$');
final RegExp _phoneRe = RegExp(r'^\+?[0-9]{3,15}$');

const Map<String, IconData> remoteIcons = {
  'apps': Icons.apps,
  'bank': Icons.account_balance,
  'wallet': Icons.account_balance_wallet,
  'phone': Icons.phone_android,
  'telecom': Icons.cell_tower,
  'store': Icons.storefront,
  'shopping': Icons.shopping_cart,
  'work': Icons.work,
  'flight': Icons.flight,
  'school': Icons.school,
  'bolt': Icons.bolt,
  'hospital': Icons.local_hospital,
  'news': Icons.newspaper,
  'hotel': Icons.hotel,
  'map': Icons.map,
  'car': Icons.directions_car,
  'food': Icons.restaurant,
  'home': Icons.home_work,
  'mosque': Icons.mosque,
  'gov': Icons.account_balance,
  'tv': Icons.tv,
  'build': Icons.construction,
  'info': Icons.info,
  'sport': Icons.sports_soccer,
  'category': Icons.category,
};

String _s(Object? v) => v == null ? '' : v.toString().trim();

DirItem? parseDirItem(Object? raw) {
  if (raw is! Map) return null;
  final title = _s(raw['title']);
  if (title.isEmpty) return null;
  final desc = _s(raw['desc']);
  switch (_s(raw['type']).isEmpty ? 'web' : _s(raw['type'])) {
    case 'web':
      final u = _s(raw['url']);
      return _urlRe.hasMatch(u) ? DirItem.web(title, desc, u) : null;
    case 'app':
      final pkg = _s(raw['package']);
      if (pkg.isNotEmpty) {
        return _pkgRe.hasMatch(pkg) ? DirItem.app(title, desc, package: pkg) : null;
      }
      final q = _s(raw['search']);
      return DirItem.app(title, desc, searchName: q.isEmpty ? null : q);
    case 'phone':
      final p = _s(raw['phone']).replaceAll(' ', '');
      return _phoneRe.hasMatch(p) ? DirItem.phone(title, desc, p) : null;
  }
  return null;
}

Color _color(Object? v, Color fallback) {
  final h = _s(v).replaceFirst('#', '');
  if (h.length != 6) return fallback;
  final n = int.tryParse(h, radix: 16);
  return n == null ? fallback : Color(0xFF000000 | n);
}

List<DirSection> parseSections(Object? raw) {
  final out = <DirSection>[];
  if (raw is! List) return out;
  for (final e in raw) {
    if (e is! Map) continue;
    final id = _s(e['id']);
    if (id.isEmpty) continue;
    final groups = <DirGroup>[];
    final rawGroups = e['groups'];
    if (rawGroups is List) {
      for (final g in rawGroups) {
        if (g is! Map) continue;
        final items = <DirItem>[];
        final rawItems = g['items'];
        if (rawItems is List) {
          for (final i in rawItems) {
            final item = parseDirItem(i);
            if (item != null) items.add(item);
          }
        }
        if (items.isNotEmpty) groups.add(DirGroup(_s(g['title']), items));
      }
    }
    if (groups.isEmpty) continue;
    out.add(DirSection(
      id,
      remoteIcons[_s(e['icon'])] ?? Icons.category,
      _color(e['color'], const Color(0xFF455A64)),
      groups,
      title: _s(e['title']).isEmpty ? null : _s(e['title']),
      subtitle: _s(e['subtitle']).isEmpty ? null : _s(e['subtitle']),
    ));
  }
  return out;
}

/// يدمج الأقسام البعيدة مع المضمّنة: نفس المعرّف يستبدل، المعرّف الجديد يُضاف
/// في النهاية، و[remove] يحذف أقساماً بمعرّفاتها.
List<DirSection> mergeSections(
    List<DirSection> base, List<DirSection> remote, Iterable<String> remove) {
  final removed = remove.toSet();
  final byId = {for (final r in remote) r.id: r};
  final result = <DirSection>[];
  for (final s in base) {
    if (removed.contains(s.id)) continue;
    result.add(byId.remove(s.id) ?? s);
  }
  for (final r in remote) {
    if (byId.containsKey(r.id) && !removed.contains(r.id)) result.add(r);
  }
  return result;
}

List<Hotel> parseHotels(Object? raw) {
  final out = <Hotel>[];
  if (raw is! List) return out;
  for (final e in raw) {
    if (e is! Map) continue;
    final name = _s(e['name']);
    final city = _s(e['city']);
    if (name.isEmpty || city.isEmpty) continue;
    final phone = _s(e['phone']).replaceAll(' ', '');
    final web = _s(e['web']);
    out.add(Hotel(
      name,
      city,
      stars: int.tryParse(_s(e['stars'])) ?? 0,
      note: _s(e['note']),
      phone: _phoneRe.hasMatch(phone) ? phone : null,
      phoneLabel: _phoneRe.hasMatch(phone) ? (_s(e['phoneLabel']).isEmpty ? phone : _s(e['phoneLabel'])) : null,
      web: _urlRe.hasMatch(web) ? web : null,
    ));
  }
  return out;
}

List<NewsSource> parseNewsSources(Object? raw) {
  final out = <NewsSource>[];
  if (raw is! List) return out;
  for (final e in raw) {
    if (e is! Map) continue;
    final name = _s(e['name']);
    final feeds = <String>[
      if (e['feeds'] is List)
        for (final f in e['feeds'] as List)
          if (_urlRe.hasMatch(_s(f))) _s(f),
    ];
    if (name.isEmpty || feeds.isEmpty) continue;
    final site = _s(e['site']);
    out.add(NewsSource(
      name,
      feeds,
      site: _urlRe.hasMatch(site) ? site : null,
      limit: (int.tryParse(_s(e['limit'])) ?? 10).clamp(1, 40).toInt(),
    ));
  }
  return out;
}
