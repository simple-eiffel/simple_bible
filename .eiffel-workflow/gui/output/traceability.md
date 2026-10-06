# Traceability Matrix

**Document:** simple_bible GUI
**Version:** 0.1.0

## States -> Screens

| State | Screen | Requirements |
|-------|--------|--------------|
| S-01 (starting) | SCR-24 (Startup) | - |
| S-02 (checking_databases) | SCR-24 (Startup) | - |
| S-03 (database_error) | SCR-23 (D08 Database problem) | - |
| S-04 (restoring_session) | SCR-24 (Startup) | - |
| S-05 (ready) | SCR-01 (Main window - Simple layout) | - |
| S-06 (navigating) | SCR-03 (P01 Bible Text) | - |
| S-07 (choosing_reference) | SCR-16 (D01 Go to Reference / D10 candidates) | - |
| S-08 (searching) | SCR-09 (P07 Search Results) | - |
| S-09 (building_guide) | SCR-10 (P08 Guides) | - |
| S-10 (census_defining) | SCR-18 (D03 Census Builder) | - |
| S-11 (census_running) | SCR-11 (P09 Census and Checks) | - |
| S-12 (claim_checking) | SCR-19 (D04 Claim Check (v1.5)) | - |
| S-13 (settings_open) | SCR-20 (D05 Settings) | - |
| S-14 (exporting) | SCR-21 (D06 Export / Copy) | - |
| S-15 (error_recoverable) | SCR-01 (Main window - Simple layout) | - |
| S-16 (exiting) | - | - |
| S-17 (mode_simple) | SCR-01 (Main window - Simple layout) | - |
| S-18 (mode_study) | SCR-02 (Main window - Study layout) | - |
| S-19 (layout_applying) | SCR-22 (D07 Layouts) | - |
| S-20 (layout_saving) | SCR-22 (D07 Layouts) | - |
| S-21 (panel_current) | SCR-03 (P01 Bible Text) | - |
| S-22 (panel_stale) | - | - |
| S-23 (panel_refreshing) | SCR-03 (P01 Bible Text) | - |
| S-24 (panel_unlinked) | - | - |

## Requirements -> States

| Requirement | States Covered | Transitions |
|-------------|----------------|-------------|
| FR-002 | S-02 | T-02 |
| FR-020 | S-06, S-07 | T-09, T-11 |
| FR-022 | S-06 | T-10 |
| FR-025 | S-10, S-11 | T-25, T-26 |
| FR-026 | S-11 | T-28 |
| FR-027 | S-11 | T-28 |
| FR-030 | S-09 | T-20 |
| FR-032 | S-05 | - |
| NFR-001 | S-06 | T-10 |
| NFR-002 | S-08, S-11 | T-17 |
| NFR-013 | S-13 | T-35 |
| A01 | S-05, S-06 | T-09 |
| A02 | S-21, S-23 | T-55 |
| A08 | S-17, S-18 | T-44, T-55 |
| A09 | S-19, S-20 | T-49 |
| A10 | S-13 | T-35 |
| B01 | S-08 | T-15 |
| B03 | S-08 | T-15 |
| B05 | S-08 | T-15 |
| D09 | S-09 | T-20 |
| C06 | S-09 | T-20 |
| E10 | S-14 | T-37 |
| I-P01 | S-12 | T-31 |
| I-P02 | S-10, S-11 | T-25 |
| I-P03 | S-11 | T-28 |
| I-P05 | S-14 | T-37 |
| I-P06 | S-09 | T-20 |
| I-P07 | S-09 | T-20 |
| D-019 | S-05 | - |

## Coverage Summary

- **States:** 0/24 (0% covered by requirements)
- **Screen Mappings:** 21 states mapped to screens
- **Total Screens:** 25
- **Total Transitions:** 62
- **Requirements Tracked:** 29
