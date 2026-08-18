import 'package:fhv_dashboard/services/mensa_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _sampleGermanPage = '''
LEGENDE DER ALLERGENE
A Glutenhaltiges Getreide und daraus gewonnene Erzeugnisse H Schalenfrüchte und daraus gewonnene Erzeugnisse
B Krebstiere und daraus gewonnene Erzeugnisse L Sellerie und daraus gewonnene Erzeugnisse
HERKUNFTSANGABE
Rind: 100% AT / Schwein: 100% AT
MENÜPLAN KW34
17. August 2026 – 21. August 2026
MONTAG MENÜ 1 KICHERERBSEN- GEMÜSE CHILI ALLERGENE
Sauerrahm- Dip + Dessert GLO
MENÜ 2 LÄNDLE KALBSBRATWURST ALLERGENE
 Zwiebel- Senf- Sauce + Pommes frites + Salat GLO
DIENSTAG MENÜ 1 GEBACKENE RÖSTITASCHEN (KRÄUTER- GERVAIS) ALLERGENE
Topfen Dip + Salatgarnitur ACGLO
MENÜ 2 OFENFRISCHE HÜHNERKEULE ALLERGENE
 Thymian- Jus + Reis + Zucchini- Gemüse GLO
VEGAN VEGANES TAGESANGEBOT
MITTWOCH MENÜ 1 SCHARF MARINIERTER TOFU ALLERGENE
Gurken- Relish + Pommes frites + gem. Salat FGLNO
MENÜ 2 PULLET BEEF IM BURGER BUN (LÄNDLE BIO RIND) ALLERGENE
 BBQ- Sauce + Pommes frites + Coleslaw Salat ACGLO
DONNERSTAG MENÜ 1 ORIENTALISCHE LINSEN PFANNE ALLERGENE
Curry- Dip + Dörrobst + Minze + gem. Salat AFGLNO
MENÜ 2 GESCHNETZELTES VOM LÄNDLE SCHWEIN ALLERGENE
 Teigwaren + Ländle Bohnen ACGLOP
VEGAN VEGANES TAGESANGEBOT
FREITAG MENÜ 1 OFENFRISCHE BUCHTELN ALLERGENE
Vanillesauce + Rhabarber Kompott ACG
MENÜ 2 HAUSSPIESS VOM LÄNDLE SCHWEIN ALLERGENE

 (Paprika & Zwiebel & Speck) + Teufelsauce + Pommes frites + gem. Salat GLO
MENÜ 1 + 1 STK. OBST: EUR 10,50/FHV EUR 7,90 | MENÜ 2 + SUPPE: EUR 11,50/FHV EUR 8,50
VEGAN + 1 STK OBST: EUR 10,50/FHV EUR 7,90
TAGESHIT: EUR 12,90
MENÜPLAN KW34
August 17th 2026 – August 21st, 2026
MONDAY MENU 1 CHICKPEA VEGETABLE CHILI ALLERGENS
sour cream + dessert GLO
''';

void main() {
  test('isoWeekNumber matches the real Aug 17-21 2026 menu (KW34)', () {
    expect(MensaService.isoWeekNumber(DateTime(2026, 8, 17)), 34);
    expect(MensaService.isoWeekNumber(DateTime(2026, 8, 21)), 34);
  });

  test('urlForWeek builds the expected Ländle Gastronomie URL', () {
    expect(
      MensaService.urlForWeek(34),
      'https://laendlegastronomie.at/menue.html?file=files/Laendlegastronomie/Menuekarten/KW34_FHMensa.pdf',
    );
  });

  test('parseRawText extracts all 5 days with correct dishes and allergens', () {
    final menu = MensaService().parseRawText(
      week: 34,
      rawText: _sampleGermanPage,
    );

    expect(menu.isEmpty, isFalse);
    expect(menu.dateRangeLabel, '17. August 2026 – 21. August 2026');
    expect(menu.days.map((d) => d.day), [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
    ]);

    final montag = menu.days[0];
    expect(montag.items, hasLength(2));
    expect(montag.items[0].category, 'Menü 1');
    expect(montag.items[0].title, 'KICHERERBSEN- GEMÜSE CHILI');
    expect(montag.items[0].description, 'Sauerrahm- Dip + Dessert');
    expect(montag.items[0].allergens, ['G', 'L', 'O']);
    expect(montag.items[1].category, 'Menü 2');
    expect(montag.items[1].title, 'LÄNDLE KALBSBRATWURST');

    final dienstag = menu.days[1];
    expect(dienstag.items, hasLength(3));
    expect(dienstag.items[2].category, 'Vegan');
    expect(dienstag.items[2].title, 'VEGANES TAGESANGEBOT');
    expect(dienstag.items[2].description, isEmpty);

    final freitag = menu.days[4];
    expect(freitag.items, hasLength(2));
    expect(
      freitag.items[1].description,
      '(Paprika & Zwiebel & Speck) + Teufelsauce + Pommes frites + gem. Salat',
    );
    expect(freitag.items[1].allergens, ['G', 'L', 'O']);

    for (final day in menu.days) {
      for (final item in day.items) {
        expect(item.title, isNot(contains('EUR')));
        expect(item.title, isNot(contains('MONDAY')));
      }
    }
  });
}
