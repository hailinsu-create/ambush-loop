# Web Chinese font

`NotoSansCJKsc-Regular.woff2` contains the complete Noto Sans CJK SC Regular face, not a game-text subset. It is losslessly repackaged from face 2 of Debian's `NotoSansCJK-Regular.ttc` using FontTools. The cmap and glyph order remain intact. The original face outlines and naming belong to the Noto project.

Source: https://github.com/notofonts/noto-cjk
License: SIL Open Font License 1.1, included as `OFL.txt`.

The Web platform cannot load the system Chinese fonts used by the native UI. NightOps uses this bundled face as a Web fallback, and the default Web GUI font uses it for controls outside that theme. Native font selection stays in the existing system-font path. The export evidence records the source, face, transformation, version and file hashes.
