# A03 evidence: Open Food Facts coverage (WP5, D11/D12)

Aggregates only. No OFF rows, names or barcodes are stored in the repo (ODbL, C-5). Produced on 2026-10-17 by `make off-coverage` (`tools/scripts/off-coverage.sh` + `off_coverage.py`, stdlib, streamed; the 1.2 GB gz was deleted afterwards).

## Export

- Export URL: https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz
- Last-Modified: Fri, 16 Oct 2026 12:36:15 GMT
- Downloaded: 2026-10-17T09:59Z
- Size (gz): 1275171186 bytes
- sha256: f72687ee8bc6522054fe69dbfda6b91902c16af1ec2e043cde27bc6c29ad8176

### Rows in export

4535553

### Discovered country tags

| tag | products |
|---|---:|
| `en:israel` | 7472 |
| `en:jordan` | 1133 |
| `en:palestinian-territories` | 719 |
| `en:state-of-palestine` | 19 |

### Products and completeness

| group | products | complete-4 | % | complete-5 | % |
|---|---:|---:|---:|---:|---:|
| `ALL` | 9339 | 1254 | 13.4% | 507 | 5.4% |
| `PS_or_JO` | 1869 | 144 | 7.7% | 84 | 4.5% |
| `en:israel` | 7472 | 1111 | 14.9% | 423 | 5.7% |
| `en:jordan` | 1133 | 108 | 9.5% | 75 | 6.6% |
| `en:palestinian-territories` | 719 | 36 | 5.0% | 9 | 1.3% |
| `en:state-of-palestine` | 19 | 0 | 0.0% | 0 | 0.0% |

complete-4 = kcal (or kJ/4.184), protein, carbs, fat; complete-5 adds fiber.

### GS1 prefix split (`PS_or_JO`, top 10 of 1869)

| prefix | products | share |
|---|---:|---:|
| 625 | 674 | 36.1% |
| 729 | 162 | 8.7% |
| 622 | 90 | 4.8% |
| 628 | 89 | 4.8% |
| 869 | 55 | 2.9% |
| 629 | 45 | 2.4% |
| 590 | 31 | 1.7% |
| 062 | 30 | 1.6% |
| 868 | 30 | 1.6% |
| 479 | 22 | 1.2% |

### GS1 prefix split (`ALL`, top 10 of 9339)

| prefix | products | share |
|---|---:|---:|
| 729 | 6211 | 66.5% |
| 625 | 694 | 7.4% |
| 622 | 97 | 1.0% |
| 628 | 90 | 1.0% |
| 869 | 75 | 0.8% |
| 590 | 74 | 0.8% |
| 800 | 66 | 0.7% |
| 629 | 51 | 0.5% |
| 400 | 43 | 0.5% |
| 482 | 43 | 0.5% |

### Local sample (matched anywhere in OFF)

| product | region | found | complete-4 | complete-5 |
|---|---|---:|---:|---:|
| Al-Juneidi halawa 250 g | JO | 0 | 0 | 0 |
| Al-Juneidi halawa with pistachio 250 g | JO | 0 | 0 | 0 |
| Hammoudeh halloumi cheese 250 g | JO | 0 | 0 | 0 |
| Almarai processed cheese triangles | JO | 53 | 13 | 6 |
| Almarai spreadable cream cheese 500 g | JO | 49 | 13 | 6 |
| Almarai fresh full-fat milk | JO | 64 | 22 | 13 |
| Al Arz tahini (sesame paste) | PS | 5 | 2 | 1 |
| Siniora beef mortadella | PS | 1 | 0 | 0 |
| Siniora frankfurters / hot dogs | PS | 2 | 1 | 1 |
| Palestine Gardens (Sinokrot) Medjool dates | PS | 3 | 0 | 0 |
| Sinokrot chocolate / candy | PS | 0 | 0 | 0 |
| Nabulsi cheese | PS | 0 | 0 | 0 |
| Al-Wadi Al-Akhdar canned chickpeas / foul | PS | 9 | 5 | 2 |
| Tnuva milk 3% | PS | 3 | 1 | 0 |
| Tara milk | PS | 8 | 1 | 0 |
| Osem Bamba peanut snack | PS | 13 | 6 | 5 |
| Elite Turkish coffee | PS | 6 | 4 | 3 |
| Nescafe 3 in 1 instant coffee | INT | 311 | 151 | 110 |
| Nestle Cerelac infant cereal | INT | 161 | 75 | 46 |
| Pepsi cola can | INT | 1470 | 749 | 245 |
| Coca-Cola classic | INT | 2073 | 1180 | 383 |
| Tang orange drink powder | INT | 214 | 116 | 44 |
| Rani fruit juice | JO | 269 | 149 | 44 |
| Indomie instant noodles | INT | 135 | 75 | 52 |
| Ulker biscuits | TR | 100 | 54 | 27 |
| Eti Petit Beurre biscuits | TR | 522 | 432 | 284 |
| Kellogg's Corn Flakes | INT | 446 | 298 | 244 |
| Lipton Yellow Label tea | INT | 1596 | 891 | 355 |
| Nutella hazelnut spread | INT | 479 | 298 | 83 |
| Lay's potato chips | INT | 2327 | 1109 | 836 |
| Pringles original | INT | 661 | 424 | 287 |

### D12 verdict

Sample products found with complete-4 data: 24 of 31 (77.4%); threshold 40%.

**Verdict: barcode first, label scan as the fallback.**

## Reading the numbers (orchestrator, please weigh these before the verdict is used)

- Tag spellings found: `en:israel`, `en:jordan`, `en:palestinian-territories` (not `en:palestine`), `en:state-of-palestine`. No `west-bank` / `gaza` tags exist. PS = `palestinian-territories` + `state-of-palestine`: 738 products, 36 complete-4 (4.9%).
- Region data is thin: PS ∪ JO = 1,869 products, only 7.7% complete-4 and 4.5% complete-5. Israel-tagged: 7,472 (14.9% complete-4).
- Palestine has no prefix of its own in practice: Palestine-tagged products carry mostly 625 (Jordan), 729 (Israel) and 628/622/869 imports. Jordan's 625 is the biggest prefix in PS ∪ JO (36%).
- **The rule outcome is "barcode first" (77% of the 31-item sample found with complete-4), but the sample is a weak test of the owner's shop.** Matching is by brand tag + name word and counted anywhere in OFF, not only region-tagged. International lines (Pepsi, Lay's, Lipton, Nutella, Kellogg's, Eti...) carry the score. The Palestinian/Jordanian-specific items are mostly missing: Al-Juneidi (2), Hammoudeh halloumi, Sinokrot chocolate, Nabulsi cheese: 0 found; Siniora mortadella and Palestine Gardens dates found but incomplete. Of the 18 PS/JO-region items, 11 have a complete-4 match, and 5 of those are Almarai/Rani/Israeli lines. For purely local brands it is about 2 of 9.
- Recommendation: treat the 40% rule as satisfied on paper, but keep the label scan equally prominent in A28 and let the on-device counter decide. Barcode hits for international and Israeli-supplied products will be good; local dairy, halawa, mortadella, bread will often miss and need the label scan or manual entry.
- Limits: brand slugs and name words are heuristics (variants such as `hamoudeh` may be spelled otherwise); products with `energy-kcal_100g` empty and no kJ are counted incomplete; sample `verified: false` sources were not opened.
