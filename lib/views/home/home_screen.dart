import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/directory.dart';
import '../../data/hotels.dart';
import '../../services/app_state.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/dir_item_tile.dart';
import '../../widgets/open_link.dart';
import '../../widgets/ticker.dart';
import '../emergency/emergency_screen.dart';
import '../favorites/favorites_screen.dart';
import '../hotels/hotels_screen.dart';
import '../map/map_screen.dart';
import '../merchant/merchant_screen.dart';
import '../news/news_screen.dart';
import '../rates/rates_screen.dart';
import '../section/section_screen.dart';

class _Tile {
  final String titleKey;
  final String? subtitleKey;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  final String? count;
  const _Tile(this.titleKey, this.subtitleKey, this.icon, this.color, this.builder, {this.count});
}

String _norm(String s) => s
    .replaceAll(RegExp('[\u064B-\u065F]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .toLowerCase()
    .trim();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Tile> _tiles() {
    return [
      _Tile('tile_rates', null, Icons.currency_exchange, const Color(0xFFF9A825),
          (_) => const RatesScreen()),
      _Tile('tile_news', null, Icons.newspaper, const Color(0xFFD84315),
          (_) => const NewsScreen()),
      _Tile('tile_hotels', null, Icons.hotel, const Color(0xFF6A1B9A),
          (_) => const HotelsScreen()),
      _Tile('tile_map', null, Icons.map, const Color(0xFF2E7D32), (_) => const MapScreen()),
      _Tile('tile_emergency', null, Icons.emergency, const Color(0xFFC62828),
          (_) => const EmergencyScreen()),
      for (final s in directorySections)
        _Tile('sec_${s.id}', 'sub_${s.id}', s.icon, s.color,
            (_) => SectionScreen(section: s),
            count: 'items_count'.tr(args: ['${s.count}'])),
    ];
  }

  void _push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  List<DirItem> _results() {
    final q = _norm(_query);
    if (q.isEmpty) return const [];
    return allSearchableItems()
        .where((i) => _norm(i.title).contains(q) || _norm(i.desc).contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final searching = _query.trim().isNotEmpty;
    // قراءة اللغة هنا تجعل الشاشة تُعاد رسمها فور تغييرها.
    final localeCode = context.locale.languageCode;
    final tiles = _tiles();

    return Scaffold(
      key: ValueKey(localeCode),
      appBar: AppBar(
        title: Text('app_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active, color: scheme.error),
            tooltip: 'news_tooltip'.tr(),
            onPressed: () => _push(const NewsScreen()),
          ),
          ListenableBuilder(
            listenable: AppState.instance,
            builder: (context, _) => IconButton(
              icon: Icon(AppState.instance.dark ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'theme_tooltip'.tr(),
              onPressed: () => AppState.instance.setDark(!AppState.instance.dark),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'lang_tooltip'.tr(),
            onPressed: () {
              context.setLocale(context.locale.languageCode == 'ar'
                  ? const Locale('en')
                  : const Locale('ar'));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  NewsTicker(onTap: () => _push(const NewsScreen())),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'search_hint'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searching
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListenableBuilder(
                    listenable: AppState.instance,
                    builder: (context, _) {
                      final s = AppState.instance;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.location_city),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(s.hasCity ? s.city : 'choose_city'.tr()),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                            onPressed: () => showCityPicker(context),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            s.hasCity
                                ? 'nearby_in'.tr(args: [s.city])
                                : 'nearby_pick_city'.tr(),
                            style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (final k in nearbyKinds)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(end: 8),
                                    child: ActionChip(
                                      avatar: Icon(k.icon, size: 18, color: k.color),
                                      label: Text('near_${k.id}'.tr()),
                                      onPressed: () {
                                        if (!s.hasCity) {
                                          showCityPicker(context);
                                          return;
                                        }
                                        openUri(context, mapsSearchUri(k.query, s.city));
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (!searching) ...[
                    Text('all_sections'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                  ],
                ]),
              ),
            ),
            if (searching)
              _searchResults(scheme)
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: tiles.length,
                  itemBuilder: (context, index) => _tileCard(tiles[index]),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = 0);
          if (i == 1) _push(const FavoritesScreen());
          if (i == 2) _push(const MerchantScreen());
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home), label: 'nav_home'.tr()),
          NavigationDestination(icon: const Icon(Icons.bookmark), label: 'nav_favorites'.tr()),
          NavigationDestination(icon: const Icon(Icons.storefront), label: 'nav_add_store'.tr()),
        ],
      ),
    );
  }

  Widget _searchResults(ColorScheme scheme) {
    final results = _results();
    if (results.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text('no_results'.tr())),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList.builder(
        itemCount: results.length,
        itemBuilder: (context, i) => DirItemTile(item: results[i], accent: scheme.primary),
      ),
    );
  }

  Widget _tileCard(_Tile t) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: t.builder)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: t.color.withValues(alpha: 0.15),
                child: Icon(t.icon, size: 26, color: t.color),
              ),
              const SizedBox(height: 8),
              Text(t.titleKey.tr(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              if (t.count != null) ...[
                const SizedBox(height: 2),
                Text(t.count!,
                    style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
