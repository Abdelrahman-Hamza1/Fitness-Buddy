# Bundled fonts

Both are SIL Open Font License 1.1 (texts alongside). Downloaded from
`github.com/google/fonts` at a pinned commit (A02 D1):

    https://raw.githubusercontent.com/google/fonts/47d54ca1ebb14fd864695f1d39dc734f39017c33/ofl/<family>/<file>

| File here | Upstream file | sha256 |
|---|---|---|
| `InterVariable.ttf` | `ofl/inter/Inter[opsz,wght].ttf` | `29160a80ff49ddcab2c97711247e08b1fab27a484a329ce8b813d820dc559031` |
| `NotoSansArabicVariable.ttf` | `ofl/notosansarabic/NotoSansArabic[wdth,wght].ttf` | `63111b5b2e074dd48cc67692e0a2726d86ee94c1c37fe8598257b7b4e87e869e` |
| `OFL-Inter.txt` | `ofl/inter/OFL.txt` | `5b9321a4298cfeb6b34354164a1c3afc3db114569984c502b9b35d988fd58c57` |
| `OFL-NotoSansArabic.txt` | `ofl/notosansarabic/OFL.txt` | `07fc70bfeb985cc1a87a8587d0a0c80bab11c86c9dc3fd95b6f0cb332f983e96` |

The upstream names contain `[`, `,` and `]`; they are renamed here so asset
paths stay plain. Verify with `sha256sum` against the table. Both fonts are
variable: Flutter drives the `wght` axis from `fontWeight` (Flutter 3.41+).
