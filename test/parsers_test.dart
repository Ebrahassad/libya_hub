import 'package:flutter_test/flutter_test.dart';
import 'package:libya_hub/services/parsers.dart';

void main() {
  test('parseCblRates reads rows with or without labels', () {
    const html = '''
<table>
<tr><th>التاريخ</th><th>العملة</th><th>الوحدة</th><th>المتوسط</th><th>بيع</th><th>شراء</th></tr>
<tr><td>التاريخ: 2026-09-29</td><td>العملة: الدولار الأمريكي</td><td>الوحدة: دولار واحد</td>
<td>المتوسط: 6.3967 د.ل</td><td>بيع: 6.4127 د.ل</td><td>شراء: 6.3808 د.ل</td></tr>
<tr><td>2026-09-29</td><td>اليورو</td><td>يورو واحد</td><td>7.2693 د.ل</td><td>7.2874 د.ل</td><td>7.2511 د.ل</td></tr>
</table>''';
    final rates = parseCblRates(html);
    expect(rates.length, 2);
    expect(rates[0].name, 'الدولار الأمريكي');
    expect(rates[0].average, closeTo(6.3967, 0.00001));
    expect(rates[0].sell, closeTo(6.4127, 0.00001));
    expect(rates[0].buy, closeTo(6.3808, 0.00001));
    expect(rates[1].name, 'اليورو');
    expect(rates[1].date, '2026-09-29');
  });

  test('parseParallelRates skips empty image cells', () {
    const html = '''
<table>
<tr><th></th><th>العملة</th><th>السعر</th><th></th></tr>
<tr><td><img src="a.png"></td><td>الدولار</td><td>9.53</td><td></td></tr>
<tr><td><img src="b.png"></td><td>اليورو</td><td>10.80</td><td></td></tr>
</table>''';
    final rates = parseParallelRates(html);
    expect(rates.length, 2);
    expect(rates[0].name, 'الدولار');
    expect(rates[0].price, 9.53);
    expect(rates[1].price, 10.8);
  });

  test('parseFeed reads RSS items with CDATA and entities', () {
    const xml = '''
<rss><channel><title>x</title>
<item><title><![CDATA[خبر عاجل &amp; مهم]]></title><link>https://example.ly/a</link>
<pubDate>Tue, 29 Sep 2026 10:20:00 +0000</pubDate></item>
<item><title>Second</title><link>https://example.ly/b</link></item>
</channel></rss>''';
    final items = parseFeed(xml, 'مصدر');
    expect(items.length, 2);
    expect(items[0].title, contains('خبر عاجل'));
    expect(items[0].link, 'https://example.ly/a');
    expect(items[0].source, 'مصدر');
    expect(items[0].date, isNotNull);
    expect(items[1].date, isNull);
  });

  test('weatherKey maps WMO codes', () {
    expect(weatherKey(0), 'w_clear');
    expect(weatherKey(3), 'w_cloudy');
    expect(weatherKey(63), 'w_rain');
    expect(weatherKey(95), 'w_storm');
  });
}
