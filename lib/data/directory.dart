import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/content_store.dart';
import 'apps_data.dart';

enum LinkKind { web, app, phone }

/// عنصر في الدليل.
///
/// كل رابط هنا تم التحقق منه من صفحة رسمية أو من نتائج بحث حقيقية.
/// أي تطبيق بلا [package] موثّق يفتح بحثاً في متجر جوجل بلاي بدل رابط
/// قد لا يعمل. للتحقق الدوري شغّل: python3 tools/check_links.py
class DirItem {
  final String title;
  final String desc;
  final LinkKind kind;
  final String? url;
  final String? package;
  final String? phone;
  final String? searchName;

  const DirItem.web(this.title, this.desc, String this.url)
      : kind = LinkKind.web,
        package = null,
        phone = null,
        searchName = null;

  const DirItem.app(this.title, this.desc, {this.package, this.searchName})
      : kind = LinkKind.app,
        url = null,
        phone = null;

  const DirItem.phone(this.title, this.desc, String this.phone)
      : kind = LinkKind.phone,
        url = null,
        package = null,
        searchName = null;

  /// مفتاح فريد يُستخدم للمفضلة.
  String get key => '${kind.name}|$title';

  Uri get uri {
    switch (kind) {
      case LinkKind.web:
        return Uri.parse(url!);
      case LinkKind.phone:
        return Uri.parse('tel:$phone');
      case LinkKind.app:
        if (package != null) {
          return Uri.parse(
              'https://play.google.com/store/apps/details?id=$package');
        }
        return Uri.parse(
            'https://play.google.com/store/search?q=${Uri.encodeComponent(searchName ?? title)}&c=apps');
    }
  }

  IconData get icon {
    switch (kind) {
      case LinkKind.web:
        return Icons.open_in_new;
      case LinkKind.phone:
        return Icons.call;
      case LinkKind.app:
        return Icons.download;
    }
  }
}

class DirGroup {
  final String title;
  final List<DirItem> items;
  const DirGroup(this.title, this.items);
}

class DirSection {
  final String id;
  final IconData icon;
  final Color color;
  final List<DirGroup> groups;

  /// عنوان وعنوان فرعي للأقسام القادمة من المحتوى البعيد (التي ليس لها ترجمة).
  final String? title;
  final String? subtitle;
  const DirSection(this.id, this.icon, this.color, this.groups,
      {this.title, this.subtitle});

  int get count => groups.fold(0, (a, g) => a + g.items.length);
}

/// الأقسام المضمّنة في التطبيق. المحتوى البعيد (content.json) يمكنه تعديلها أو إضافة أقسام.
const List<DirSection> defaultSections = [
  appsSection,
  DirSection('gov', Icons.account_balance, Color(0xFF1565C0), [
    DirGroup('خدمات المواطن', [
      DirItem.web('الرقم الوطني', 'المشروع الوطني للرقم الوطني وخدماته.',
          'https://www.nid.gov.ly/'),
      DirItem.web('مصلحة الجوازات والجنسية',
          'الموقع الرسمي: الفروع والنماذج والقرارات.', 'https://lpa.gov.ly/'),
      DirItem.web('وزارة الخدمة المدنية',
          'قرارات التنسيب والإفراجات المالية.', 'https://civil-service.gov.ly/'),
      DirItem.web('خدمة لي باي', 'بوابة الدفع الحكومي الإلكتروني.',
          'https://lypay.gov.ly/'),
    ]),
  ]),
  DirSection('banks', Icons.account_balance_wallet, Color(0xFF00796B), [
    DirGroup('المصرف المركزي', [
      DirItem.web('مصرف ليبيا المركزي', 'الموقع الرسمي.', 'https://cbl.gov.ly/'),
      DirItem.web('أسعار الصرف الرسمية', 'الأسعار اليومية المعتمدة.',
          'https://cbl.gov.ly/currency-exchange-rates/'),
      DirItem.web('دليل المصارف التجارية', 'قائمة المصارف المرخصة.',
          'https://cbl.gov.ly/banks/'),
      DirItem.web('بوابة المطورين', 'واجهات المصرف المركزي البرمجية.',
          'https://central-bank-of-libya.gitbook.io/devportal'),
    ]),
    DirGroup('مصارف تجارية', [
      DirItem.web('مصرف الجمهورية', 'الموقع الرسمي.', 'https://www.jbank.ly/'),
      DirItem.web('مصرفي بلس (شرح الخدمة)', 'طريقة الاشتراك والتفعيل.',
          'https://www.jbank.ly/ar/e-service/electronic-services/masrifi-plus/'),
      DirItem.web('المصرف التجاري الوطني', 'الموقع الرسمي.', 'https://www.ncb.ly/'),
      DirItem.web('موبي مال (شرح الخدمة)', 'خدمة المصرف التجاري الوطني.',
          'https://www.ncb.ly/ar/personal/mobi-mal/'),
      DirItem.web('مسارات للخدمات المالية',
          'مصرفي بلس وصحارى موبايل وموبي ناب.', 'https://masarat.ly/'),
      DirItem.web('صحارى موبايل (شرح الخدمة)', 'طريقة تفعيل الخدمة.',
          'https://masarat.ly/sahara-mobile/'),
    ]),
  ]),
  DirSection('telecom', Icons.cell_tower, Color(0xFF3949AB), [
    DirGroup('الشركات', [
      DirItem.web('المدار الجديد', 'الموقع الرسمي.', 'https://almadar.ly/'),
      DirItem.web('الشركة القابضة للاتصالات', 'الشركة الأم لشركات الاتصالات.',
          'https://lptic.ly/'),
      DirItem.web('العنكبوت الليبي', 'استضافة ودومينات وخدمات سحابية.',
          'https://libyanspider.com/'),
    ]),
  ]),
  DirSection('stores', Icons.storefront, Color(0xFFEF6C00), [
    DirGroup('متاجر إلكترونية', [
      DirItem.web('باهي', 'أول وأكبر متجر إلكتروني محلي.', 'https://baahy.com/'),
      DirItem.web('النورس', 'سوق إلكتروني لمتاجر ليبيا.', 'https://nawris.net/'),
      DirItem.web('المستودع', 'متجر إلكتروني ليبي داخل وخارج ليبيا.',
          'https://big.ly/'),
      DirItem.web('تسوق ليبيا', 'دفع عند الاستلام وتوصيل لكل المدن.',
          'https://www.shoppinglibya.com/'),
      DirItem.web('يوباي ليبيا', 'منتجات دولية تصل إلى ليبيا.',
          'https://www.ubuy.com.ly/ar/'),
    ]),
    DirGroup('دلائل تجارية', [
      DirItem.web('دليل الأعمال الليبي', 'شركات وخدمات حسب المدينة.',
          'https://www.businessdirectorylists.com/libya/category/emergency-numbers'),
    ]),
  ]),
  DirSection('jobs', Icons.work, Color(0xFF303F9F), [
    DirGroup('وظائف', [
      DirItem.web('مصرف ليبيا المركزي - الوظائف', 'إعلانات التوظيف الرسمية.',
          'https://cbl.gov.ly/career/'),
      DirItem.web('المؤسسة الوطنية للنفط', 'قسم الوظائف في الموقع الرسمي.',
          'https://noc.ly/'),
      DirItem.web('بحث وظائف ليبيا', 'نتائج بحث جوجل عن وظائف ليبيا.',
          'https://www.google.com/search?q=%D9%88%D8%B8%D8%A7%D8%A6%D9%81+%D9%84%D9%8A%D8%A8%D9%8A%D8%A7'),
      DirItem.web('لينكدإن - وظائف ليبيا', 'وظائف للشركات والمنظمات.',
          'https://www.linkedin.com/jobs/search/?location=Libya'),
      DirItem.web('ReliefWeb - وظائف ليبيا', 'وظائف المنظمات الدولية.',
          'https://reliefweb.int/jobs?search=libya'),
    ]),
  ]),
  DirSection('travel', Icons.flight, Color(0xFF0288D1), [
    DirGroup('طيران', [
      DirItem.web('الخطوط الجوية الأفريقية', 'الحجز والرحلات.',
          'https://afriqiyah.aero/'),
      DirItem.web('الخطوط الجوية الليبية', 'الناقل الوطني.',
          'https://libyanairlines.aero/'),
    ]),
  ]),
  DirSection('edu', Icons.school, Color(0xFF6A1B9A), [
    DirGroup('التعليم', [
      DirItem.web('وزارة التربية والتعليم', 'الامتحانات والنتائج والتسجيل.',
          'https://moe.gov.ly/'),
      DirItem.web('نتائج المركز الوطني للامتحانات',
          'الاستعلام عن النتيجة برقم القيد.', 'https://finalresults.nec.gov.ly/'),
    ]),
  ]),
  DirSection('energy', Icons.bolt, Color(0xFFF9A825), [
    DirGroup('كهرباء ونفط', [
      DirItem.web('الشركة العامة للكهرباء', 'الموقع الرسمي للشركة.',
          'https://www.gecol.ly/'),
      DirItem.web('الاستعلام عن فاتورة الكهرباء', 'الاستعلام عن الرصيد والفاتورة.',
          'https://www.gecol.ly/Home/BalanceInquiry'),
      DirItem.web('المؤسسة الوطنية للنفط', 'الأخبار والعطاءات والشركات التابعة.',
          'https://noc.ly/'),
      DirItem.web('عطاءات المؤسسة الوطنية للنفط', 'فرص التوريد والعقود.',
          'https://noc.ly/tenders/'),
    ]),
  ]),
  DirSection('health', Icons.local_hospital, Color(0xFFC62828), [
    DirGroup('صحة', [
      DirItem.web('وزارة الصحة - جهاز الإسعاف', 'المراكز والمكاتب.',
          'https://moh.gov.ly/pages/centers-offices/ambulance-services'),
      DirItem.web('دليل ليبيا الطبي', 'دليل الأطباء والمرافق الصحية.',
          'https://lmd.ly/'),
    ]),
  ]),
  DirSection('news', Icons.newspaper, Color(0xFFD84315), [
    DirGroup('مصادر إخبارية', [
      DirItem.web('بوابة الوسط', 'أخبار ليبيا لحظة بلحظة.', 'https://alwasat.ly/'),
      DirItem.web('عين ليبيا', 'أخبار وأسعار العملات.', 'https://www.eanlibya.com/'),
      DirItem.web('ليبيا هيرالد', 'أخبار ليبيا بالإنجليزية.',
          'https://libyaherald.com/'),
      DirItem.web('ليبيا أوبزرفر', 'أخبار ليبيا.', 'https://www.libyaobserver.ly/'),
      DirItem.web('وكالة الأنباء الليبية', 'الوكالة الرسمية.',
          'https://www.lana-news.ly/ara'),
    ]),
  ]),
];

/// الأقسام الحالية (المضمّنة + أي تحديث من المحتوى البعيد).
List<DirSection> get directorySections => ContentStore.instance.sections;

/// عنوان القسم: من ملف الترجمة إن وُجد، وإلا العنوان القادم من المحتوى البعيد.
String sectionTitle(DirSection s) {
  final key = 'sec_${s.id}';
  final t = key.tr();
  return t == key ? (s.title ?? s.id) : t;
}

String sectionSubtitle(DirSection s) {
  final key = 'sub_${s.id}';
  final t = key.tr();
  return t == key ? (s.subtitle ?? '') : t;
}

/// كل العناصر (للبحث والمفضلة).
List<DirItem> allDirectoryItems() => [
      for (final s in directorySections)
        for (final g in s.groups) ...g.items,
    ];

DirSection? sectionById(String id) {
  for (final s in directorySections) {
    if (s.id == id) return s;
  }
  return null;
}

/// أرقام الطوارئ المتداولة (الشرطة 1515، الإسعاف 193).
const List<DirItem> emergencyNumbers = [
  DirItem.phone('الشرطة', 'رقم الشرطة.', '1515'),
  DirItem.phone('الإسعاف', 'جهاز خدمات الإسعاف.', '193'),
];

/// أنواع البحث على خرائط جوجل داخل مدينة.
class NearbyKind {
  final String id;
  final String query;
  final IconData icon;
  final Color color;
  const NearbyKind(this.id, this.query, this.icon, this.color);
}

const List<NearbyKind> nearbyKinds = [
  NearbyKind('pharmacy', 'صيدلية', Icons.local_pharmacy, Colors.teal),
  NearbyKind('hospital', 'مستشفى', Icons.local_hospital, Colors.red),
  NearbyKind('bank', 'مصرف', Icons.account_balance, Colors.blue),
  NearbyKind('atm', 'صراف آلي', Icons.atm, Colors.indigo),
  NearbyKind('market', 'سوبرماركت', Icons.storefront, Colors.orange),
  NearbyKind('fuel', 'محطة وقود', Icons.local_gas_station, Colors.brown),
  NearbyKind('restaurant', 'مطعم', Icons.restaurant, Colors.deepOrange),
  NearbyKind('hotel', 'فندق', Icons.hotel, Colors.purple),
  NearbyKind('police', 'شرطة', Icons.local_police, Colors.blueGrey),
];

Uri mapsSearchUri(String query, String city) => Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$query $city ليبيا')}');
