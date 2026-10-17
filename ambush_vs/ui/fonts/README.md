# Web Chinese font

`NotoSansCJKsc-Regular.woff2` contains the complete Noto Sans CJK SC Regular face (source archive for regeneration). It is losslessly repackaged from face 2 of Debian's `NotoSansCJK-Regular.ttc` using FontTools. The cmap and glyph order remain intact. The original face outlines and naming belong to the Noto project.

**Web greybox uses** `NotoSansCJKsc-GreyboxSubset.woff2` (via `web_ui_font.tres`): a FontTools subset of glyphs referenced by greybox UI strings + `weapons.csv`. Regenerate with `python3 ui/fonts/subset_cjk_for_greybox.py`. The full face is excluded from the Web export preset to cut download size.

Source: https://github.com/notofonts/noto-cjk
License: SIL Open Font License 1.1, included as `OFL.txt`.

The Web platform cannot load the system Chinese fonts used by the native UI. NightOps uses this bundled face as a Web fallback, and the default Web GUI font uses it for controls outside that theme. Native font selection stays in the existing system-font path. The export evidence records the source, face, transformation, version and file hashes.

`DejaVuSans.ttf` is the complete, unchanged DejaVu Sans 2.37 face (Bitstream Vera license; DejaVu changes in public domain), with its notice in `DejaVu-LICENSE.txt`. It covers UI symbols such as ↺/↻/☷/✕ absent from the CJK face. `web_ui_font.tres` provides the same symbol fallback for default controls.
