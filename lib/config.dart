/// إعدادات وقت البناء. تُمرَّر عبر --dart-define أو أسرار GitHub Actions.
///
/// مثال:
///   flutter build apk --release \
///     --dart-define=OIL_API_KEY=xxxx \
///     --dart-define=CONTACT_EMAIL=you@example.com
class AppConfig {
  /// مفتاح مجاني من oilpriceapi.com لجلب سعر برنت. بدونه تظهر بطاقة النفط
  /// مع رابط للمصدر بدل رقم.
  static const String oilApiKey = String.fromEnvironment('OIL_API_KEY');

  /// بريد استقبال طلبات إضافة المتاجر (شاشة أضف متجرك).
  static const String contactEmail = String.fromEnvironment('CONTACT_EMAIL');

  /// كم دقيقة بين كل تحديث تلقائي للبيانات المباشرة.
  static const int refreshMinutes = 5;
}
