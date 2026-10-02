// ignore_for_file: prefer_const_constructors
import '../services/content_store.dart';

/// مصدر أخبار. لكل مصدر أكثر من رابط تغذية (RSS) محتمل، يُجرَّب بالترتيب
/// ويُعتمد أول رابط يرجع أخباراً. المصدر الذي لا يستجيب يُتجاوَز بصمت.
class NewsSource {
  final String name;
  final String? site; // يظهر كزر «فتح الموقع» إن وُجد
  final List<String> feeds;
  final int limit;
  const NewsSource(this.name, this.feeds, {this.site, this.limit = 10});
}

String _gnews(String query, {String lang = 'ar', String country = 'LY'}) =>
    'https://news.google.com/rss/search?q=${Uri.encodeComponent(query)}'
    '&hl=$lang&gl=$country&ceid=$country:$lang';

/// مصادر الأخبار المضمّنة. تغذيات أخبار جوجل تجمع عناوين عشرات المواقع الليبية
/// (الوسط، ليبيا أوبزرفر، المرصد، العين وغيرها) وتُظهر اسم الموقع الأصلي لكل خبر.
final List<NewsSource> defaultNewsSources = [
  NewsSource('أخبار ليبيا', [_gnews('ليبيا when:1d')], limit: 25),
  NewsSource('عاجل', [_gnews('ليبيا عاجل when:1d')], limit: 15),
  NewsSource('طرابلس وبنغازي', [_gnews('طرابلس OR بنغازي OR مصراتة OR سبها when:2d')], limit: 15),
  NewsSource('اقتصاد', [_gnews('الدينار الليبي OR مصرف ليبيا المركزي OR المؤسسة الوطنية للنفط when:3d')],
      limit: 15),
  NewsSource('Libya News', [_gnews('Libya when:1d', lang: 'en', country: 'US')], limit: 12),
  NewsSource('عين ليبيا', ['https://www.eanlibya.com/feed/'], site: 'https://www.eanlibya.com/'),
  NewsSource('ليبيا هيرالد', ['https://libyaherald.com/feed'], site: 'https://libyaherald.com/'),
  NewsSource('بوابة الوسط', ['https://alwasat.ly/rss', 'https://alwasat.ly/feed'],
      site: 'https://alwasat.ly/'),
  NewsSource('ليبيا أوبزرفر',
      ['https://www.libyaobserver.ly/rss.xml', 'https://www.libyaobserver.ly/feed'],
      site: 'https://www.libyaobserver.ly/'),
  NewsSource('مصرف ليبيا المركزي', ['https://cbl.gov.ly/feed/'], site: 'https://cbl.gov.ly/blog/'),
  NewsSource('ليبيا ريفيو', ['https://libyareview.com/feed/']),
  NewsSource('المرصد', ['https://almarsad.co/feed/']),
  NewsSource('ليبيا الأحرار', ['https://libyaalahrar.net/feed/']),
  NewsSource('ليبيا أخبار', ['https://libyaakhbar.com/feed/']),
];

/// المصادر الحالية (المضمّنة أو ما حدّده المحتوى البعيد).
List<NewsSource> get newsSources => ContentStore.instance.newsSources;

/// مصادر لها موقع يُعرض زر لفتحه.
List<NewsSource> get newsSourcesWithSite =>
    newsSources.where((s) => s.site != null).toList();
