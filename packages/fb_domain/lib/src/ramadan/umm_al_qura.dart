import 'package:fb_domain/src/time/local_date.dart';

/// The Umm al-Qura calendar's Ramadan (LC-030, A41a D1): the first day of
/// Ramadan and of Shawwal (Eid al-Fitr) for each Hijri year 1440–1499
/// (2019–2076).
///
/// Only these two month starts are needed (Ramadan's dates and its day
/// number, LC-020), so this is a table of two dates per year instead of a
/// Hijri conversion package: `fb_domain` has no runtime dependencies.
///
/// Source: the Umm al-Qura month-start series of `hijri-converter` 2.3.2
/// (MIT licence, (c) Mohammed Alshehri; the same series as R.H. van Gent's
/// Umm al-Qura tables and the `hijri` Dart package), read with the epoch
/// 1858-11-16 so that 1447–1450 match van Gent's published list
/// (webspace.science.uu.nl/~gent0113/islam/ummalqura_principal.htm). The
/// country's own moon sighting can differ by a day: the user's ±1-day
/// shift covers that (LC-030). Outside the table, Ramadan isn't detected
/// (the app says so; no Ramadan mode).
abstract final class UmmAlQura {
  /// The package the table was derived from, for the licence page.
  static const String sourcePackage =
      'hijri-converter 2.3.2 (Umm al-Qura table)';

  /// The source's licence, kept with the derived data as it requires: the
  /// copyright and permission notices of `hijri-converter` 2.3.2
  /// (https://pypi.org/project/hijri-converter/2.3.2.post1/, LICENSE).
  /// The app shows it on About › Licences; the repo copy is
  /// `packages/fb_domain/THIRD_PARTY_NOTICES.md`.
  static const String sourceLicence = '''
MIT License

Copyright (c) 2018 Mohammed Alshehri (https://www.dralshehri.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';

  /// (1 Ramadan, 1 Shawwal) by Hijri year.
  static final Map<int, (LocalDate, LocalDate)> ramadan = Map.unmodifiable({
    1440: (LocalDate(2019, 5, 6), LocalDate(2019, 6, 4)),
    1441: (LocalDate(2020, 4, 24), LocalDate(2020, 5, 24)),
    1442: (LocalDate(2021, 4, 13), LocalDate(2021, 5, 13)),
    1443: (LocalDate(2022, 4, 2), LocalDate(2022, 5, 2)),
    1444: (LocalDate(2023, 3, 23), LocalDate(2023, 4, 21)),
    1445: (LocalDate(2024, 3, 11), LocalDate(2024, 4, 10)),
    1446: (LocalDate(2025, 3, 1), LocalDate(2025, 3, 30)),
    1447: (LocalDate(2026, 2, 18), LocalDate(2026, 3, 20)),
    1448: (LocalDate(2027, 2, 8), LocalDate(2027, 3, 9)),
    1449: (LocalDate(2028, 1, 28), LocalDate(2028, 2, 26)),
    1450: (LocalDate(2029, 1, 16), LocalDate(2029, 2, 14)),
    1451: (LocalDate(2030, 1, 5), LocalDate(2030, 2, 4)),
    1452: (LocalDate(2030, 12, 26), LocalDate(2031, 1, 24)),
    1453: (LocalDate(2031, 12, 15), LocalDate(2032, 1, 14)),
    1454: (LocalDate(2032, 12, 4), LocalDate(2033, 1, 2)),
    1455: (LocalDate(2033, 11, 23), LocalDate(2033, 12, 23)),
    1456: (LocalDate(2034, 11, 12), LocalDate(2034, 12, 12)),
    1457: (LocalDate(2035, 11, 1), LocalDate(2035, 12, 1)),
    1458: (LocalDate(2036, 10, 20), LocalDate(2036, 11, 19)),
    1459: (LocalDate(2037, 10, 10), LocalDate(2037, 11, 8)),
    1460: (LocalDate(2038, 9, 30), LocalDate(2038, 10, 29)),
    1461: (LocalDate(2039, 9, 19), LocalDate(2039, 10, 19)),
    1462: (LocalDate(2040, 9, 7), LocalDate(2040, 10, 7)),
    1463: (LocalDate(2041, 8, 28), LocalDate(2041, 9, 26)),
    1464: (LocalDate(2042, 8, 17), LocalDate(2042, 9, 15)),
    1465: (LocalDate(2043, 8, 6), LocalDate(2043, 9, 4)),
    1466: (LocalDate(2044, 7, 26), LocalDate(2044, 8, 24)),
    1467: (LocalDate(2045, 7, 15), LocalDate(2045, 8, 14)),
    1468: (LocalDate(2046, 7, 5), LocalDate(2046, 8, 3)),
    1469: (LocalDate(2047, 6, 24), LocalDate(2047, 7, 24)),
    1470: (LocalDate(2048, 6, 12), LocalDate(2048, 7, 12)),
    1471: (LocalDate(2049, 6, 2), LocalDate(2049, 7, 1)),
    1472: (LocalDate(2050, 5, 22), LocalDate(2050, 6, 20)),
    1473: (LocalDate(2051, 5, 11), LocalDate(2051, 6, 10)),
    1474: (LocalDate(2052, 4, 30), LocalDate(2052, 5, 29)),
    1475: (LocalDate(2053, 4, 20), LocalDate(2053, 5, 19)),
    1476: (LocalDate(2054, 4, 9), LocalDate(2054, 5, 9)),
    1477: (LocalDate(2055, 3, 29), LocalDate(2055, 4, 28)),
    1478: (LocalDate(2056, 3, 17), LocalDate(2056, 4, 16)),
    1479: (LocalDate(2057, 3, 6), LocalDate(2057, 4, 5)),
    1480: (LocalDate(2058, 2, 24), LocalDate(2058, 3, 25)),
    1481: (LocalDate(2059, 2, 14), LocalDate(2059, 3, 15)),
    1482: (LocalDate(2060, 2, 3), LocalDate(2060, 3, 4)),
    1483: (LocalDate(2061, 1, 23), LocalDate(2061, 2, 21)),
    1484: (LocalDate(2062, 1, 12), LocalDate(2062, 2, 10)),
    1485: (LocalDate(2063, 1, 1), LocalDate(2063, 1, 30)),
    1486: (LocalDate(2063, 12, 21), LocalDate(2064, 1, 20)),
    1487: (LocalDate(2064, 12, 9), LocalDate(2065, 1, 8)),
    1488: (LocalDate(2065, 11, 29), LocalDate(2065, 12, 28)),
    1489: (LocalDate(2066, 11, 19), LocalDate(2066, 12, 18)),
    1490: (LocalDate(2067, 11, 8), LocalDate(2067, 12, 8)),
    1491: (LocalDate(2068, 10, 27), LocalDate(2068, 11, 26)),
    1492: (LocalDate(2069, 10, 16), LocalDate(2069, 11, 15)),
    1493: (LocalDate(2070, 10, 5), LocalDate(2070, 11, 4)),
    1494: (LocalDate(2071, 9, 25), LocalDate(2071, 10, 24)),
    1495: (LocalDate(2072, 9, 13), LocalDate(2072, 10, 13)),
    1496: (LocalDate(2073, 9, 3), LocalDate(2073, 10, 2)),
    1497: (LocalDate(2074, 8, 23), LocalDate(2074, 9, 22)),
    1498: (LocalDate(2075, 8, 13), LocalDate(2075, 9, 11)),
    1499: (LocalDate(2076, 8, 1), LocalDate(2076, 8, 30)),
  });
}
