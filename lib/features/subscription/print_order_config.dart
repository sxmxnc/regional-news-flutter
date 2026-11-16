import '../../core/app_language.dart';

abstract final class PrintOrderSlugs {
  static String page(AppLanguage language) => switch (language) {
    AppLanguage.de => 'zeitung',
    AppLanguage.pl => 'miesiecznik',
  };
}
