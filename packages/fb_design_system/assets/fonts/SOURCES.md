# Bundled fonts

All three are SIL Open Font License 1.1 (texts alongside). Downloaded from
`github.com/google/fonts` at a pinned commit (A02 D1):

    https://raw.githubusercontent.com/google/fonts/47d54ca1ebb14fd864695f1d39dc734f39017c33/ofl/<family>/<file>

| File here | Upstream file | sha256 |
|---|---|---|
| `InterVariable.ttf` | `ofl/inter/Inter[opsz,wght].ttf` | `29160a80ff49ddcab2c97711247e08b1fab27a484a329ce8b813d820dc559031` |
| `NunitoVariable.ttf` | `ofl/nunito/Nunito[wght].ttf` | `bb55a5ca5c2042335b3991af27c4d0705d0ef41cac6164ac737fd8f2a1e85207` |
| `NotoSansArabicVariable.ttf` | `ofl/notosansarabic/NotoSansArabic[wdth,wght].ttf` | `63111b5b2e074dd48cc67692e0a2726d86ee94c1c37fe8598257b7b4e87e869e` |
| `OFL-Inter.txt` | `ofl/inter/OFL.txt` | `5b9321a4298cfeb6b34354164a1c3afc3db114569984c502b9b35d988fd58c57` |
| `OFL-Nunito.txt` | `ofl/nunito/OFL.txt` | `580df76c95a1ec5ab878ceb25bb3d85c6a076804e9c970c8c6972aea775fdf65` |
| `OFL-NotoSansArabic.txt` | `ofl/notosansarabic/OFL.txt` | `07fc70bfeb985cc1a87a8587d0a0c80bab11c86c9dc3fd95b6f0cb332f983e96` |

The upstream names contain `[`, `,` and `]`; they are renamed here so asset
paths stay plain. Verify with `sha256sum` against the table. All fonts are
variable: Flutter drives the `wght` axis from `fontWeight` (Flutter 3.41+).
Nunito (added by A44, TD-098) is at the same pinned commit; its default
instance is ExtraLight (200), so `test/fonts_test.dart` proves the weight
axis moves. It has no `tnum` feature, but its default digits are tabular.
