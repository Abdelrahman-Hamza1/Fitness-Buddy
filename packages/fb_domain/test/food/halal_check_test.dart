import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

Set<HalalFlag> _check(String ingredients, {List<String> tags = const []}) =>
    HalalCheck.check(ingredients: ingredients, tags: tags);

void main() {
  group('HalalCheck (FD-081)', () {
    test('pork, in English and Arabic, as whole words only', () {
      expect(_check('Wheat flour, pork fat, salt'), {HalalFlag.pork});
      expect(HalalCheck.check(name: 'Smoked Ham'), {HalalFlag.pork});
      expect(_check('دقيق، شحم الخنزير، ملح'), {HalalFlag.pork});
      expect(HalalCheck.check(nameAr: 'لحم خنزير مدخن'), {HalalFlag.pork});
      expect(
        HalalCheck.check(name: 'Hamburger buns, graham crackers'),
        isEmpty,
      );
      expect(HalalCheck.check(name: 'Turkey ham slices'), isEmpty);
    });

    test('alcohol, except sugar alcohols, alcohol-free and wine vinegar', () {
      expect(_check('Sugar, cocoa, rum (2%)'), {HalalFlag.alcohol});
      expect(_check('ماء، كحول إيثيلي'), {HalalFlag.alcohol});
      expect(_check('سكر، والكحول'), {HalalFlag.alcohol});
      expect(_check('Sweeteners (sugar alcohols), maltitol'), isEmpty);
      expect(_check('Alcohol-free malt drink'), isEmpty);
      expect(_check('Red wine vinegar, mustard'), isEmpty);
      expect(_check('شراب شعير خالي من الكحول'), isEmpty);
      expect(_check('Ginger, root beer flavour'), isEmpty);
    });

    test('gelatin and emulsifiers of unknown source are "unknown"', () {
      expect(_check('Sugar, glucose syrup, gelatine, citric acid'), {
        HalalFlag.unknownSource,
      });
      expect(_check('Emulsifier (E471), salt'), {HalalFlag.unknownSource});
      expect(_check('emulsifier: e-472e'), {HalalFlag.unknownSource});
      expect(_check('سكر، جيلاتين بقري؟'), {HalalFlag.unknownSource});
      expect(_check('سكر، الجيلاتين'), {HalalFlag.unknownSource});
      expect(_check('Emulsifier (soy lecithin), E322'), isEmpty);
    });

    test('halal, vegan and vegetarian tags drop only the unknown flag', () {
      expect(_check('gelatin', tags: ['en:halal']), isEmpty);
      expect(_check('E471', tags: ['en:vegan']), isEmpty);
      expect(_check('gelatin, pork, wine', tags: ['en:halal']), {
        HalalFlag.pork,
        HalalFlag.alcohol,
      });
    });

    test('nothing to check gives no flags', () {
      expect(HalalCheck.check(), isEmpty);
      expect(
        HalalCheck.check(name: 'Rice, cooked', nameAr: 'أرز مطبوخ'),
        isEmpty,
      );
    });
  });
}
