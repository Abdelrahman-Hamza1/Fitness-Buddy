#!/usr/bin/env python3
"""Writes names/meats.tsv: regex concept lines (re:...) for meat cuts by raw /
cooked / lean-only, from the compact tables below. Names only; the numbers
come from USDA through the importer. Run: python3 -I gen_meats.py > names/meats.tsv
"""
import sys

# (usda cut regex after "<animal>, ", EN cut, AR cut, arabizi, methods)
# methods: regexes for the cooked state, best first
STEAK = r'(?:broiled|grilled|pan-fried)'
ROAST = r'(?:roasted)'
BRAISE = r'(?:braised)'
BEEF = [
    (r'chuck eye steak', 'chuck eye steak', 'ستيك تشك آي', 'chuck eye steak', STEAK),
    (r'chuck eye roast', 'chuck eye roast', 'روست تشك آي', 'chuck eye roast', BRAISE),
    (r'chuck, arm pot roast', 'arm pot roast', 'روست الكتف', 'arm pot roast', BRAISE),
    (r'chuck, blade roast', 'chuck blade roast', 'روست شفرة الكتف', 'blade roast', BRAISE),
    (r'chuck, clod roast', 'chuck clod roast', 'روست كلود', 'clod roast', BRAISE),
    (r'chuck, mock tender steak', 'mock tender steak', 'ستيك موك تندر', 'mock tender steak', BRAISE),
    (r'chuck, short ribs', 'short ribs', 'ضلوع قصيرة', 'short ribs, dala3', BRAISE),
    (r'chuck, under blade steak', 'under blade steak', 'ستيك تحت الشفرة', 'under blade steak', BRAISE),
    (r'chuck, top blade', 'top blade steak', 'ستيك الشفرة العلوية', 'top blade steak', STEAK),
    (r'chuck for stew', 'chuck for stew', 'لحم مكعبات للطبخ', 'lahm mkaabat, stew meat', BRAISE),
    (r'brisket, flat half', 'brisket, flat half', 'صدر بقر مسطح', 'brisket, sader', BRAISE),
    (r'brisket, point half', 'brisket, point half', 'صدر بقر (النصف الدهني)', 'brisket point', BRAISE),
    (r'brisket, whole', 'brisket', 'صدر بقر', 'brisket, sader baqar', BRAISE),
    (r'flank, steak', 'flank steak', 'ستيك فلانك', 'flank steak', STEAK),
    (r'plate steak', 'plate steak', 'ستيك الصدر', 'plate steak', STEAK),
    (r'plate, inside skirt steak', 'inside skirt steak', 'ستيك سكيرت داخلي', 'skirt steak', STEAK),
    (r'plate, outside skirt steak', 'outside skirt steak', 'ستيك سكيرت خارجي', 'outside skirt steak', STEAK),
    (r'loin, tenderloin roast', 'tenderloin roast', 'روست فيليه', 'tenderloin roast', ROAST),
    (r'loin, tenderloin steak', 'tenderloin steak', 'ستيك فيليه', 'fillet steak, filet mignon', STEAK),
    (r'loin, top loin steak', 'top loin steak (strip)', 'ستيك ستريب', 'strip steak, new york', STEAK),
    (r'loin, top sirloin cap steak', 'top sirloin cap steak', 'ستيك سيرلوين كاب', 'sirloin cap steak', STEAK),
    (r'rib eye roast', 'rib eye roast', 'روست ريب آي', 'rib eye roast', ROAST),
    (r'rib eye steak', 'rib eye steak', 'ستيك ريب آي', 'ribeye steak, entrecote', STEAK),
    (r'rib, back ribs', 'back ribs', 'ضلوع خلفية', 'back ribs', BRAISE),
    (r'rib, small end', 'rib roast, small end', 'روست الضلع (الطرف الصغير)', 'rib roast small end', ROAST),
    (r'rib, large end', 'rib roast, large end', 'روست الضلع (الطرف الكبير)', 'rib roast large end', ROAST),
    (r'rib, whole', 'rib roast, whole', 'روست الضلع كامل', 'rib roast', ROAST),
    (r'round, eye of round roast', 'eye of round roast', 'روست عين الفخذ', 'eye of round roast', ROAST),
    (r'round, eye of round steak', 'eye of round steak', 'ستيك عين الفخذ', 'eye of round steak', STEAK),
    (r'round, top round roast', 'top round roast', 'روست الفخذ العلوي', 'top round roast', ROAST),
    (r'round, top round,? steak', 'top round steak', 'ستيك الفخذ العلوي', 'top round steak, london broil', STEAK),
    (r'round, tip round, roast', 'tip round roast', 'روست رأس الفخذ', 'tip round roast', ROAST),
    (r'round, knuckle, tip center', 'knuckle tip center steak', 'ستيك مفصل الفخذ', 'knuckle steak', STEAK),
    (r'round, outside round', 'bottom round (outside round)', 'فخذ خارجي', 'bottom round', BRAISE),
    (r'round, full cut', 'round, full cut', 'فخذ بقر كامل', 'round full cut', ROAST),
    (r'short loin, porterhouse steak', 'porterhouse steak', 'ستيك بورتر هاوس', 'porterhouse steak', STEAK),
    (r'short loin, t-bone steak', 'T-bone steak', 'ستيك تي بون', 't-bone steak', STEAK),
    (r'shank crosscuts', 'shank crosscuts', 'موزات مقطعة', 'shank crosscuts, mozat', BRAISE),
    (r'shoulder pot roast or steak', 'shoulder pot roast', 'روست الكتف', 'shoulder pot roast', BRAISE),
    (r'shoulder steak', 'shoulder steak', 'ستيك الكتف', 'shoulder steak', STEAK),
    (r'tenderloin, (?:roast|steak)', 'tenderloin', 'فيليه بقر', 'tenderloin, fillet', ROAST),
    (r'top sirloin, steak', 'top sirloin steak', 'ستيك سيرلوين', 'sirloin steak', STEAK),
]

LAMB = [
    (r'foreshank', 'foreshank', 'موزة أمامية', 'foreshank, mouza', BRAISE),
    (r'leg, shank half', 'leg, shank half', 'فخذ ضأن (نصف الموزة)', 'leg shank half', ROAST),
    (r'leg, sirloin half', 'leg, sirloin half', 'فخذ ضأن (نصف السيرلوين)', 'leg sirloin half', ROAST),
    (r'leg, whole', 'leg, whole', 'فخذ ضأن كامل', 'leg of lamb, fakhdh', ROAST),
    (r'loin', 'loin chops', 'ريش ضأن', 'lamb loin, loin chops', r'(?:broiled|grilled|roasted)'),
    (r'rib', 'rib chops', 'ريش ضأن بالضلع', 'lamb rib chops, rishat', r'(?:broiled|grilled|roasted)'),
    (r'shoulder, arm', 'shoulder, arm', 'كتف ضأن (الذراع)', 'lamb shoulder arm', BRAISE),
    (r'shoulder, blade', 'shoulder, blade', 'كتف ضأن (الشفرة)', 'lamb shoulder blade', BRAISE),
    (r'shoulder, whole', 'shoulder, whole', 'كتف ضأن كامل', 'lamb shoulder, katef', r'(?:braised|roasted)'),
    (r'cubed for stew or kabob', 'cubed for stew or skewers', 'مكعبات ضأن للطبخ والشوي', 'cubed lamb skewers', r'(?:braised|broiled)'),
]
VEAL = [
    (r'leg', 'leg', 'فخذ عجل', 'veal leg', r'(?:roasted|braised|pan-fried)'),
    (r'loin', 'loin', 'خاصرة عجل', 'veal loin', r'(?:roasted|braised)'),
    (r'rib', 'rib', 'ضلع عجل', 'veal rib', r'(?:roasted|braised)'),
    (r'shoulder, whole', 'shoulder', 'كتف عجل', 'veal shoulder', r'(?:roasted|braised)'),
    (r'shank', 'shank', 'موزة عجل', 'veal shank, osso buco', BRAISE),
    (r'sirloin', 'sirloin', 'سيرلوين عجل', 'veal sirloin', r'(?:roasted|braised)'),
    (r'breast, whole', 'breast', 'صدر عجل', 'veal breast', BRAISE),
    (r'cubed for stew', 'cubed for stew', 'مكعبات عجل للطبخ', 'veal cubes', BRAISE),
]
PORK = [
    (r'fresh, loin, tenderloin', 'tenderloin', 'فيليه خنزير', 'pork tenderloin', ROAST),
    (r'fresh, loin, center loin', 'center loin chops', 'ريش خنزير', 'pork chops', r'(?:broiled|grilled|pan-fried)'),
    (r'fresh, loin, top loin', 'top loin chops', 'ريش خنزير علوية', 'pork top loin', r'(?:broiled|grilled|pan-fried)'),
    (r'fresh, loin, sirloin', 'sirloin roast', 'سيرلوين خنزير', 'pork sirloin', ROAST),
    (r'fresh, loin, whole', 'loin, whole', 'خاصرة خنزير كاملة', 'pork loin', ROAST),
    (r'fresh, shoulder, blade, boston', 'shoulder, Boston blade', 'كتف خنزير', 'pork shoulder, boston butt', BRAISE),
    (r'fresh, leg, whole', 'leg (fresh ham)', 'فخذ خنزير طازج', 'fresh ham', ROAST),
    (r'fresh, spareribs', 'spareribs', 'ضلوع خنزير', 'spareribs, pork ribs', BRAISE),
    (r'fresh, ground', 'ground', 'لحم خنزير مفروم', 'ground pork', r'(?:cooked)'),
]
GROUND_BEEF = [
    ('70% lean meat / 30% fat', '70/30'), ('75% lean meat / 25% fat', '75/25'),
    ('93% lean meat / 7% fat', '93/7'), ('97% lean meat / 3% fat', '97/3'),
]


def q(s):
    return s


def line(rx, en, ar, zi, st):
    print(f're:{rx} | {en} | {ar} | {zi} | st={st}')


def meat(animal, an_en, an_ar, an_zi, cuts):
    for rx, en, ar, zi, meth in cuts:
        base = f'^{animal}, {rx}[^,]*,'
        lf = r'(?:[^,]*, )*?separable lean and fat'
        lo = r'(?:[^,]*, )*?separable lean only'
        for fat, fe, fa in ((lf, '', ''), (lo, ', lean only', ' بدون دهن')):
            if fe == '':
                line(f'^{animal}, {rx}(?:, [^,]*)*?, separable lean and fat(?:, [^,]*)*?, raw$',
                     f'{an_en} {en}, raw', f'{an_ar} {ar} نيء', f'{an_zi} {zi} nay', 'raw')
            line(f'^{animal}, {rx}(?:, [^,]*)*?, separable lean {"and fat" if fe == "" else "only"}(?:, [^,]*)*?, cooked, {meth}$',
                 f'{an_en} {en}{fe}, cooked', f'{an_ar} {ar}{fa} مطبوخ', f'{an_zi} {zi}{fe.replace(", lean only", " lean")} matbookh', 'cooked')


print('# Meat cuts (A54 batch 3), generated by gen_meats.py. regex on the full lowercase USDA description | EN | AR | arabizi | st=state')
meat('beef', 'Beef', 'لحم بقري', 'lahm baqar', BEEF)
meat('lamb', 'Lamb', 'لحم ضأن', 'lahm kharouf', LAMB)
meat('veal', 'Veal', 'لحم عجل', 'lahm 3ijl', VEAL)
meat('pork', 'Pork', 'لحم خنزير', 'lahm khanzir', [c for c in PORK if 'fresh' in c[0] or True])


# Poultry (regex on the cleaned description).
CHICKEN_PARTS = [
    ('breast', 'breast', 'صدر', 'sader'), ('drumstick', 'drumstick', 'دبوس', 'dabbous'),
    ('thigh', 'thigh', 'ورك', 'werek'), ('wing', 'wing', 'جناح', 'janah'),
    ('leg', 'leg (thigh and drumstick)', 'فخذ كامل', 'fakhd'), ('back', 'back', 'ظهر', 'dahr'),
]
for k, en, ar, zi in CHICKEN_PARTS:
    base = f'^chicken, broilers or fryers, {k}'
    for skin, se, sa in (('meat only', 'meat only', 'بدون جلد'), ('meat and skin', 'with skin', 'بجلدها')):
        for state, st, sen, sar, szi in (('raw', 'raw', 'raw', 'نيء', 'nay'),
                                         ('cooked, roasted', 'cooked', 'roasted', 'مشوي بالفرن', 'mashwi bil forn'),
                                         ('cooked, stewed', 'cooked', 'stewed', 'مسلوق', 'maslouq')):
            line(f'{base}, {skin}, {state}$', f'Chicken {en}, {se}, {sen}',
                 f'دجاج {ar} {sa} {sar}', f'djaj {zi} {szi}', st)
        if skin == 'meat and skin':
            line(f'{base}, {skin}, cooked, fried(?:, flour)?$', f'Chicken {en}, {se}, fried',
                 f'دجاج {ar} {sa} مقلي', f'djaj {zi} maqli', 'fried')
for rx, en, ar, zi, st in [
    (r'^chicken, broilers or fryers, light meat, meat only, raw$', 'Chicken, light meat, raw', 'دجاج لحم أبيض نيء', 'djaj lahm abyad nay', 'raw'),
    (r'^chicken, broilers or fryers, light meat, meat only, cooked, roasted$', 'Chicken, light meat, roasted', 'دجاج لحم أبيض مشوي بالفرن', 'djaj lahm abyad mashwi', 'cooked'),
    (r'^chicken, broilers or fryers, dark meat, meat only, raw$', 'Chicken, dark meat, raw', 'دجاج لحم غامق نيء', 'djaj lahm ghamiq nay', 'raw'),
    (r'^chicken, broilers or fryers, dark meat, meat only, cooked, roasted$', 'Chicken, dark meat, roasted', 'دجاج لحم غامق مشوي بالفرن', 'djaj lahm ghamiq mashwi', 'cooked'),
    (r'^chicken, capons, meat and skin, raw$', 'Capon, raw', 'ديك مخصي نيء', 'capon nay', 'raw'),
    (r'^chicken, capons, meat and skin, cooked, roasted$', 'Capon, roasted', 'ديك مخصي مشوي', 'capon mashwi', 'cooked'),
    (r'^chicken, cornish game hens, meat and skin, raw$', 'Cornish game hen, raw', 'دجاج كورنيش نيء', 'cornish hen nay', 'raw'),
    (r'^chicken, cornish game hens, meat and skin, cooked, roasted$', 'Cornish game hen, roasted', 'دجاج كورنيش مشوي', 'cornish hen mashwi', 'cooked'),
    (r'^chicken, roasting, meat and skin, raw$', 'Chicken, roasting, raw', 'دجاج للشوي نيء', 'djaj lil shawi nay', 'raw'),
    (r'^chicken, roasting, meat and skin, cooked, roasted$', 'Chicken, roasting, roasted', 'دجاج للشوي مشوي', 'djaj lil shawi mashwi', 'cooked'),
    (r'^chicken, stewing, meat and skin, raw$', 'Hen (stewing chicken), raw', 'دجاجة بلدية نيئة', 'djaja baladi nay, hen', 'raw'),
    (r'^chicken, stewing, meat and skin, cooked, stewed$', 'Hen (stewing chicken), stewed', 'دجاجة بلدية مسلوقة', 'djaja baladi maslouqa', 'cooked'),
    (r'^chicken, feet, raw$', 'Chicken feet, raw', 'أرجل دجاج نيئة', 'arjul djaj', 'raw'),
    (r'^chicken, broilers or fryers, giblets, raw$', 'Chicken giblets, raw', 'مصارين دجاج نيئة', 'giblets nay', 'raw'),
    (r'^chicken, broilers or fryers, giblets, cooked, simmered$', 'Chicken giblets, simmered', 'مصارين دجاج مسلوقة', 'giblets maslouq', 'cooked'),
    (r'^chicken, broilers or fryers, heart, raw$', 'Chicken heart, raw (broiler)', 'قلب دجاج فروج نيء', 'qalb djaj froj', 'raw'),
    (r'^chicken, broilers or fryers, neck, meat only, raw$', 'Chicken neck, raw', 'رقبة دجاج نيئة', 'raqabet djaj', 'raw'),
    (r'^turkey, all classes, breast, meat only, raw$', 'Turkey breast, raw', 'صدر ديك رومي نيء', 'sader dik roumi nay', 'raw'),
    (r'^turkey, all classes, breast, meat only, cooked, roasted$', 'Turkey breast, roasted', 'صدر ديك رومي مشوي', 'sader dik roumi mashwi', 'cooked'),
    (r'^turkey, all classes, leg, meat only, raw$', 'Turkey leg, raw', 'فخذ ديك رومي نيء', 'fakhd dik roumi nay', 'raw'),
    (r'^turkey, all classes, leg, meat only, cooked, roasted$', 'Turkey leg, roasted', 'فخذ ديك رومي مشوي', 'fakhd dik roumi mashwi', 'cooked'),
    (r'^turkey, all classes, wing, meat and skin, raw$', 'Turkey wing, raw', 'جناح ديك رومي نيء', 'janah dik roumi nay', 'raw'),
    (r'^turkey, all classes, wing, meat and skin, cooked, roasted$', 'Turkey wing, roasted', 'جناح ديك رومي مشوي', 'janah dik roumi mashwi', 'cooked'),
    (r'^turkey, whole, meat only, raw$', 'Turkey, whole, meat only, raw', 'ديك رومي كامل نيء', 'dik roumi nay', 'raw'),
    (r'^turkey, whole, meat only, cooked, roasted$', 'Turkey, whole, meat only, roasted', 'ديك رومي كامل مشوي', 'dik roumi mashwi', 'cooked'),
    (r'^turkey, whole, meat and skin, cooked, roasted$', 'Turkey, whole, with skin, roasted', 'ديك رومي بجلده مشوي', 'dik roumi bi jild mashwi', 'cooked'),
    (r'^turkey, dark meat, meat only, cooked, roasted$', 'Turkey, dark meat, roasted', 'ديك رومي لحم غامق مشوي', 'dik roumi lahm ghamiq', 'cooked'),
    (r'^turkey, ground, 93% lean, 7% fat, pan-broiled crumbles$', 'Turkey, ground, 93% lean, cooked', 'ديك رومي مفروم 93% مطبوخ', 'ground turkey 93 matbookh', 'cooked'),
    (r'^turkey, ground, 85% lean, 15% fat, pan-broiled crumbles$', 'Turkey, ground, 85% lean, cooked', 'ديك رومي مفروم 85% مطبوخ', 'ground turkey 85 matbookh', 'cooked'),
    (r'^turkey, ground, fat free, pan-broiled crumbles$', 'Turkey, ground, fat free, cooked', 'ديك رومي مفروم خالي الدسم مطبوخ', 'ground turkey fat free', 'cooked'),
    (r'^turkey, ground, raw$', 'Turkey, ground, raw (regular)', 'ديك رومي مفروم نيء عادي', 'ground turkey regular', 'raw'),
    (r'^duck, domesticated, meat only, raw$', 'Duck, meat only, raw', 'بط لحم بدون جلد نيء', 'batt nay', 'raw'),
    (r'^duck, domesticated, meat only, cooked, roasted$', 'Duck, meat only, roasted', 'بط لحم بدون جلد مشوي', 'batt mashwi', 'cooked'),
    (r'^duck, domesticated, meat and skin, raw$', 'Duck, with skin, raw', 'بط بجلده نيء', 'batt bi jild nay', 'raw'),
    (r'^duck, wild, breast, meat only, raw$', 'Duck, wild, breast, raw', 'صدر بط بري نيء', 'batt barri', 'raw'),
    (r'^goose, domesticated, meat only, raw$', 'Goose, meat only, raw', 'إوز لحم بدون جلد نيء', 'iwazz nay', 'raw'),
    (r'^goose, domesticated, meat only, cooked, roasted$', 'Goose, meat only, roasted', 'إوز لحم بدون جلد مشوي', 'iwazz mashwi', 'cooked'),
    (r'^goose, domesticated, meat and skin, cooked, roasted$', 'Goose, with skin, roasted', 'إوز بجلده مشوي', 'iwazz bi jild mashwi', 'cooked'),
    (r'^pheasant, (?:cooked, )?(?:meat and skin, )?(?:raw|cooked, roasted)$', 'Pheasant', 'دراج', 'durraj, pheasant', 'raw'),
    (r'^quail, meat and skin, raw$', 'Quail, raw', 'سمان نيء', 'sammaan nay', 'raw'),
    (r'^quail, breast, meat only, raw$', 'Quail breast, raw', 'صدر سمان نيء', 'sader sammaan', 'raw'),
    (r'^guinea hen, meat and skin, raw$', 'Guinea hen, raw', 'دجاج غينيا نيء', 'guinea hen', 'raw'),
    (r'^squab, \(pigeon\), meat and skin, raw$', 'Squab (pigeon), raw', 'حمام صغير نيء', 'hamam nay', 'raw'),
    (r'^squab, meat and skin, raw$', 'Squab (young pigeon), raw', 'فراخ حمام نيئة', 'frakh hamam nay', 'raw'),
    (r'^squab, meat and skin, cooked, roasted$', 'Squab (young pigeon), roasted', 'فراخ حمام مشوية', 'frakh hamam mashwi', 'cooked'),
    (r'^ostrich, ground, raw$', 'Ostrich, ground, raw', 'نعام مفروم نيء', 'naam mafroum', 'raw'),
    (r'^ostrich, ground, cooked, pan-broiled$', 'Ostrich, ground, cooked', 'نعام مفروم مطبوخ', 'naam mafroum matbookh', 'cooked'),
    (r'^pate de foie gras, canned', 'Foie gras pate, canned', 'كبد الإوز المعلب', 'foie gras', 'as_sold'),
]:
    line(rx, en, ar, zi, st)


# Variety meats (organs) for beef, lamb, veal.
ORGANS = [('heart', 'heart', 'قلب', 'qalb'), ('kidneys', 'kidneys', 'كلاوي', 'kalawi'),
          ('liver', 'liver', 'كبدة', 'kebde'), ('lungs', 'lungs', 'رئة', 'ri2a, fshe'),
          ('brain', 'brain', 'مخ', 'mokh'), ('spleen', 'spleen', 'طحال', 'tehal'),
          ('tongue', 'tongue', 'لسان', 'lisan'), ('pancreas', 'pancreas', 'بنكرياس', 'pancreas'),
          ('thymus', 'thymus (sweetbread)', 'غدة التيموس', 'sweetbread')]
for animal, an_en, an_ar, an_zi in (('beef', 'Beef', 'بقر', 'baqar'), ('lamb', 'Lamb', 'ضأن', 'kharouf'),
                                     ('veal', 'Veal', 'عجل', '3ijl')):
    for k, en, ar, zi in ORGANS:
        line(f'^{animal}, variety meats and by-products, {k}, raw$', f'{an_en} {en}, raw',
             f'{ar} {an_ar} نيئة' if k not in ('brain',) else f'مخ {an_ar} نيء', f'{zi} {an_zi} nay', 'raw')
        line(f'^{animal}, variety meats and by-products, {k}, cooked, (?:braised|simmered|pan-fried)$',
             f'{an_en} {en}, cooked', f'{ar} {an_ar} مطبوخة' if k != 'brain' else f'مخ {an_ar} مطبوخ',
             f'{zi} {an_zi} matbookh', 'cooked')

# Pork products and a few game meats.
for rx, en, ar, zi, st in [
    (r'^pork, cured, bacon, cooked, microwaved$', 'Bacon, cooked, microwaved', 'لحم خنزير مقدد مطبوخ بالميكروويف', 'bacon microwave', 'cooked'),
    (r'^pork, cured, bacon, pre-sliced, cooked, pan-fried$', 'Bacon, pre-sliced, pan-fried', 'لحم خنزير مقدد مقلي', 'bacon fried', 'fried'),
    (r'^pork, cured, bacon, cooked, baked$', 'Bacon, baked', 'لحم خنزير مقدد مخبوز', 'bacon baked', 'cooked'),
    (r'^pork, cured, bacon, unprepared$', 'Bacon, raw (unprepared)', 'لحم خنزير مقدد نيء', 'bacon raw', 'raw'),
    (r'^canadian bacon, cooked, pan-fried$', 'Canadian bacon, pan-fried', 'بيكون كندي مقلي', 'canadian bacon', 'fried'),
    (r'^pork, cured, ham, slice, boneless, separable lean and fat, regular$', 'Ham, cured, boneless slice', 'جامبون شريحة', 'ham slice', 'as_sold'),
    (r'^pork, cured, ham, whole, separable lean and fat, roasted$', 'Ham, cured, whole, roasted', 'جامبون كامل مشوي', 'ham roasted', 'cooked'),
    (r'^pork, cured, salt pork, raw$', 'Salt pork', 'لحم خنزير مملح', 'salt pork', 'raw'),
    (r'^game meat, deer, raw$', 'Deer (venison), raw', 'لحم غزال نيء', 'lahm ghazal nay, venison', 'raw'),
    (r'^game meat, deer, cooked, roasted$', 'Deer (venison), roasted', 'لحم غزال مشوي', 'lahm ghazal mashwi', 'cooked'),
    (r'^game meat, deer, ground, raw$', 'Deer (venison), ground, raw', 'لحم غزال مفروم نيء', 'ground venison', 'raw'),
    (r'^game meat, boar, wild, raw$', 'Wild boar, raw', 'خنزير بري نيء', 'wild boar nay', 'raw'),
    (r'^game meat, boar, wild, cooked, roasted$', 'Wild boar, roasted', 'خنزير بري مشوي', 'wild boar mashwi', 'cooked'),
    (r'^game meat, rabbit, wild, raw$', 'Rabbit, wild, raw', 'أرنب بري نيء', 'arnab barri nay', 'raw'),
    (r'^game meat, rabbit, wild, cooked, stewed$', 'Rabbit, wild, stewed', 'أرنب بري مطبوخ', 'arnab barri matbookh', 'cooked'),
    (r'^game meat, rabbit, domesticated, composite of cuts, cooked, roasted$', 'Rabbit, roasted', 'أرنب مشوي', 'arnab mashwi', 'cooked'),
    (r'^game meat, rabbit, domesticated, composite of cuts, cooked, stewed$', 'Rabbit, stewed', 'أرنب مطبوخ', 'arnab matbookh', 'cooked'),
    (r'^game meat, bison, ground, cooked, pan-broiled$', 'Bison, ground, cooked', 'جاموس أمريكي مفروم مطبوخ', 'bison ground cooked', 'cooked'),
    (r'^bison, ground, raw$', 'Bison, ground, raw', 'جاموس أمريكي مفروم نيء', 'bison ground', 'raw'),
    (r'^game meat, buffalo, water, raw$', 'Water buffalo, raw', 'لحم جاموس نيء', 'lahm jamous nay', 'raw'),
    (r'^game meat, buffalo, water, cooked, roasted$', 'Water buffalo, roasted', 'لحم جاموس مشوي', 'lahm jamous mashwi', 'cooked'),
    (r'^game meat, horse, raw$', 'Horse meat, raw', 'لحم حصان نيء', 'horse meat', 'raw'),
    (r'^game meat, antelope, raw$', 'Antelope, raw', 'لحم ظبي نيء', 'antelope', 'raw'),
]:
    line(rx, en, ar, zi, st)
for pct, tag in (('70% lean meat / 30% fat', '70'), ('75% lean meat / 25% fat', '75'), ('93% lean meat / 7% fat', '93'), ('97% lean meat / 3% fat', '97')):
    line(rf'^beef, ground, {pct}, raw$'.replace('/', '/ ?'), f'Beef, ground, {tag}% lean, raw', f'لحم بقري مفروم {tag}% نيء', f'lahm baqar mafroum {tag} nay', 'raw')
    line(rf'^beef, ground, {pct}, patty, cooked, pan-broiled$'.replace('/', '/ ?'), f'Beef, ground, {tag}% lean, patty, cooked', f'لحم بقري مفروم {tag}% مطبوخ', f'lahm baqar mafroum {tag} matbookh', 'cooked')
