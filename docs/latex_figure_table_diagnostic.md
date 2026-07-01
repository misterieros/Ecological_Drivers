# Diagnostic of figure and table coherence corrections

The following locations in the original uploaded `1Main.tex` required correction.

## Figure order and argument flow
- Line 167: beta-diversity NMDS was cited as Fig. 5, but after reordering it corresponds to Fig. 3.
- Line 173: decadal richness was cited as Fig. 3, but after reordering it corresponds to Fig. 4.
- Line 179: seasonal and inter-decadal environmental variability was cited as Fig. 4, but after reordering it corresponds to Fig. 5.
- Line 204: Discussion repeated the beta-diversity mismatch, citing Fig. 5 instead of Fig. 3.
- Line 210: Discussion repeated the decadal richness mismatch, citing Fig. 3 instead of Fig. 4.
- Line 212: the environmental-trend reference should be Fig. 5, and the recent richness-decline reference should be Fig. 4.
- Line 222: the western-island decline should cite Fig. 4, not Fig. 3. The expression `Fig. \ref{tab:7}` was internally inconsistent and was corrected to Tables 6 and 7.

## Table order and formatting
- Line 165: malformed expression `Fig.\Tables` was corrected to Tables 1 and 3.
- Lines 108, 112, and 146: early table citations were added in Methods to establish the correct order of Tables 1, 2, 3, and 4 before the Results.
- Lines 187 and 216: extended GAM tables were identified as Supplementary Tables, so they no longer interrupt the main table sequence.
- Line 285: caption typo `Satial` was corrected to `Spatial`.
- Line 538: supplementary tables now restart as S1, S2, etc.
- Tables 12 and 13: vertical rules and repeated hlines were replaced with booktabs-style formatting.

## Additional visible correction
- `thethao_mean` was marked as deleted and corrected to `thetao_mean` in the visible table entries.
