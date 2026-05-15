-- =============================================================================
-- SEED DML: The Build Depot (TBD) — Full Demo Database Population
-- =============================================================================
-- This file populates ALL foundational reference tables for the
-- Snowflake Summit 2026 HOL demo database. It is designed to be run AFTER
-- the DDL (schema creation) and BEFORE the scenario-specific incremental DML.
--
-- Theme: "The Build Depot (TBD)" — a multi-location hardware store chain
-- selling products from brands that sound *almost* real.
--
-- Run order:
--   1. DDL (create tables & constraints)
--   2. THIS FILE (seed foundational data)
--   3. Incremental scenario DML (scenario A/B/C specific data)
--
-- All rows are tagged with DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS' for rollback
-- where the column exists. Tables without DEMO_BATCH_ID use CTID_FIVETRAN_ID
-- prefix 'TBD_' for identification and rollback.
-- =============================================================================

USE DATABASE SNOWFLAKE_SUMMIT_2026_HOL_DB;
USE SCHEMA SF_HOL_2026_RETAIL;

-- #############################################################################
-- 1. RET_WAREHOUSES — 5 TBD Store Locations
-- #############################################################################

INSERT INTO RET_WAREHOUSES (CTID_FIVETRAN_ID, ID, NAME, ADDRESS, CITY, STATE, ZIP, CAPACITY_SQFT, IS_ACTIVE, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED)
VALUES
  ('TBD_WH_000001', 1, 'TBD Edison',        '100 Tool Plaza',        'Edison',        'NJ', '08817', 32000, TRUE, '2022-03-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_WH_000002', 2, 'TBD Atlanta',       '250 Builder Blvd',      'Atlanta',       'GA', '30301', 35000, TRUE, '2022-06-15 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_WH_000003', 3, 'TBD Indianapolis',  '789 Hammer Lane',       'Indianapolis',  'IN', '46201', 28000, TRUE, '2023-01-10 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_WH_000004', 4, 'TBD Denver',        '455 Summit Dr',         'Denver',        'CO', '80201', 24000, TRUE, '2023-04-20 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_WH_000005', 5, 'TBD Dallas',        '1200 Lone Star Pkwy',   'Dallas',        'TX', '75201', 30000, TRUE, '2023-08-05 00:00:00', FALSE, CURRENT_TIMESTAMP());


-- #############################################################################
-- 2. RET_PRODUCT_CATEGORIES — 12 Store Departments
-- #############################################################################

INSERT INTO RET_PRODUCT_CATEGORIES (CTID_FIVETRAN_ID, ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED)
VALUES
  ('TBD_CA_000001',  1, 'Power Tools',                'Cordless and corded power tools for pros and DIYers',           '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000002',  2, 'Hand Tools',                 'Wrenches, pliers, screwdrivers, and manual tools',              '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000003',  3, 'Plumbing',                   'Pipes, fittings, faucets, and water management',                '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000004',  4, 'Electrical',                 'Wiring, outlets, switches, and lighting',                       '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000005',  5, 'Paint & Stain',              'Interior and exterior paint, stains, and coatings',             '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000006',  6, 'Hardware & Fasteners',       'Screws, bolts, nails, anchors, and cabinet hardware',           '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000007',  7, 'Lumber & Building Materials','Dimensional lumber, plywood, insulation, and drywall',          '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000008',  8, 'Heating & Cooling',          'HVAC, space heaters, fans, and thermostats',                    '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000009',  9, 'Outdoor & Garden',           'Lawn care, garden tools, outdoor lighting, and fencing',        '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000010', 10, 'Safety & Security',          'Smoke detectors, locks, work gloves, and safety gear',          '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000011', 11, 'Flooring & Tile',            'Vinyl, laminate, ceramic tile, and flooring supplies',           '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CA_000012', 12, 'Kitchen & Bath',             'Vanities, sinks, fixtures, and bath accessories',               '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP());


-- #############################################################################
-- 3. RET_PRODUCT_SUBCATEGORIES — 46 Subcategories
-- #############################################################################

INSERT INTO RET_PRODUCT_SUBCATEGORIES (CTID_FIVETRAN_ID, ID, CATEGORY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED)
VALUES
  -- Category 1: Power Tools
  ('TBD_SC_000001',  1,  1, 'Cordless Drills',         'Battery-powered drills and driver kits',               '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000002',  2,  1, 'Circular Saws',           'Corded and cordless circular saws',                    '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000003',  3,  1, 'Sanders & Polishers',     'Orbital, belt, and detail sanders',                    '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000004',  4,  1, 'Angle Grinders',          'Corded and cordless grinders and cut-off tools',       '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 2: Hand Tools
  ('TBD_SC_000005',  5,  2, 'Wrenches & Sockets',      'Ratchets, socket sets, and combination wrenches',      '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000006',  6,  2, 'Pliers & Cutters',        'Needle-nose, slip-joint, and locking pliers',          '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000007',  7,  2, 'Screwdrivers',            'Phillips, flathead, and precision screwdriver sets',    '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000008',  8,  2, 'Hammers & Mallets',       'Claw hammers, ball-peen, and rubber mallets',          '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 3: Plumbing
  ('TBD_SC_000009',  9,  3, 'Pipes & Fittings',        'PVC, copper, and PEX pipes and connectors',            '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000010', 10,  3, 'Faucets',                 'Kitchen, bathroom, and utility faucets',                '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000011', 11,  3, 'Valves & Regulators',     'Ball valves, gate valves, and pressure regulators',    '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000012', 12,  3, 'Water Heaters',           'Tank and tankless water heaters',                      '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 4: Electrical
  ('TBD_SC_000013', 13,  4, 'Wire & Cable',            'Romex, THHN, and extension cords',                     '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000014', 14,  4, 'Outlets & Switches',      'GFCI outlets, dimmers, and smart switches',            '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000015', 15,  4, 'Breakers & Panels',       'Circuit breakers and electrical panels',                '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000016', 16,  4, 'Lighting',                'LED bulbs, fixtures, and recessed lighting',            '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 5: Paint & Stain
  ('TBD_SC_000017', 17,  5, 'Interior Paint',          'Wall and ceiling paints in all finishes',               '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000018', 18,  5, 'Exterior Paint',          'Weather-resistant exterior coatings',                   '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000019', 19,  5, 'Wood Stain & Finishes',   'Deck stain, polyurethane, and sealants',               '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000020', 20,  5, 'Primers & Sealants',      'Primer, caulk, and surface prep',                      '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 6: Hardware & Fasteners
  ('TBD_SC_000021', 21,  6, 'Screws & Bolts',          'Wood screws, machine bolts, and lag bolts',             '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000022', 22,  6, 'Nails & Brads',           'Framing nails, finish nails, and brad nails',           '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000023', 23,  6, 'Anchors & Wall Fasteners','Drywall anchors, toggle bolts, and masonry anchors',   '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000024', 24,  6, 'Hinges & Latches',        'Door hinges, gate latches, and cabinet hardware',       '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 7: Lumber & Building Materials
  ('TBD_SC_000025', 25,  7, 'Dimensional Lumber',      '2x4, 2x6, 4x4, and framing lumber',                   '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000026', 26,  7, 'Plywood & Panels',        'Construction plywood, OSB, and MDF panels',             '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000027', 27,  7, 'Insulation',              'Fiberglass batts, spray foam, and rigid board',         '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000028', 28,  7, 'Drywall & Accessories',   'Drywall sheets, joint compound, and tape',              '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 8: Heating & Cooling
  ('TBD_SC_000029', 29,  8, 'Space Heaters',           'Ceramic, infrared, and oil-filled heaters',             '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000030', 30,  8, 'Fans & Ventilation',      'Box fans, ceiling fans, and exhaust fans',              '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000031', 31,  8, 'Thermostats',             'Programmable and smart thermostats',                    '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000032', 32,  8, 'HVAC Filters',            'Furnace filters and air purifiers',                     '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 9: Outdoor & Garden
  ('TBD_SC_000033', 33,  9, 'Lawn Mowers',             'Push, self-propelled, and riding mowers',               '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000034', 34,  9, 'Garden Hand Tools',       'Shovels, rakes, pruners, and garden gloves',            '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000035', 35,  9, 'Outdoor Lighting',        'Path lights, spotlights, and solar lights',             '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000036', 36,  9, 'Fencing & Edging',        'Privacy fence, garden edging, and gates',               '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 10: Safety & Security
  ('TBD_SC_000037', 37, 10, 'Smoke & CO Detectors',    'Smoke alarms, carbon monoxide detectors',               '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000038', 38, 10, 'Padlocks & Deadbolts',    'Combination, keyed, and smart locks',                   '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000039', 39, 10, 'Work Gloves',             'Leather, nitrile, and cut-resistant gloves',            '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000040', 40, 10, 'Safety Glasses & Ear Pro','Impact-rated glasses and earplugs',                     '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 11: Flooring & Tile
  ('TBD_SC_000041', 41, 11, 'Vinyl Plank',             'Luxury vinyl plank and peel-and-stick',                 '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000042', 42, 11, 'Ceramic Tile',            'Floor and wall ceramic and porcelain tile',             '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000043', 43, 11, 'Laminate Flooring',       'Click-lock and glue-down laminate planks',              '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  -- Category 12: Kitchen & Bath
  ('TBD_SC_000044', 44, 12, 'Vanities & Cabinets',     'Bathroom vanities and storage cabinets',                '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000045', 45, 12, 'Sinks',                   'Undermount, drop-in, and vessel sinks',                 '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_SC_000046', 46, 12, 'Bath Faucets & Fixtures', 'Bathroom faucets, showerheads, and accessories',        '2022-01-01 00:00:00', '2022-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP());


-- #############################################################################
-- 4. RET_PRODUCTS — ~500 Products (The Build Depot Catalog)
--
-- Critical IDs that MUST exist with correct subcategory mapping:
--   ID 10  → subcategory 1  (Cordless Drills)   → category 1 (Power Tools)
--   ID 42  → subcategory 2  (Circular Saws)     → category 1 (Power Tools)
--   ID 50  → subcategory 5  (Wrenches & Sockets)→ category 2 (Hand Tools)
--   ID 101 → subcategory 10 (Faucets)           → category 3 (Plumbing)
--   ID 102 → subcategory 10 (Faucets)           → category 3 (Plumbing)
--   ID 103 → subcategory 11 (Valves)            → category 3 (Plumbing)
--   ID 104 → subcategory 14 (Outlets & Switches)→ category 4 (Electrical)
--   ID 105 → subcategory 14 (Outlets & Switches)→ category 4 (Electrical)
--   ID 106 → subcategory 1  (Cordless Drills)   → category 1 (Power Tools)
--   ID 107 → subcategory 3  (Sanders)           → category 1 (Power Tools)
--   ID 108 → subcategory 34 (Garden Hand Tools) → category 9 (Outdoor & Garden)
--   ID 210 → subcategory 17 (Interior Paint)    → category 5 (Paint & Stain)
--   ID 410 → subcategory 33 (Lawn Mowers)       → category 9 (Outdoor & Garden)
-- #############################################################################

-- 4a: Scenario-critical products (hand-crafted for exact subcategory mapping)
INSERT INTO RET_PRODUCTS (CTID_FIVETRAN_ID, ID, SKU, NAME, DESCRIPTION, SUBCATEGORY_ID, BRAND, UNIT_PRICE, WEIGHT_LBS, IS_ACTIVE, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID, VENDOR_ID)
VALUES
  -- Power Tools (subcat 1 = Cordless Drills)
  ('TBD_PR_000010',  10, 'PWR-DRL-010', 'DeWalter 20V MAX Cordless Drill/Driver Kit',      'Compact drill with 2 speed settings and LED work light',          1, 'DeWalter',         129.99,  3.50, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', NULL),
  ('TBD_PR_000106', 106, 'PWR-DRL-106', 'Wyobi ONE+ 18V Cordless Drill/Driver Kit',        'Lightweight 18V drill with magnetic tray and 2 batteries',        1, 'Wyobi',             89.99,  3.20, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', 1),
  -- Power Tools (subcat 2 = Circular Saws)
  ('TBD_PR_000042',  42, 'PWR-SAW-042', 'Milwonky M18 FUEL 7-1/4 in. Circular Saw',        'Brushless motor with 5800 RPM and magnesium shoe',                2, 'Milwonky',         199.99,  6.80, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', NULL),
  -- Power Tools (subcat 3 = Sanders)
  ('TBD_PR_000107', 107, 'PWR-SND-107', 'Bozch 5 in. Random Orbit Sander',                 'Variable speed pad sander with dust collection',                  3, 'Bozch',             69.99,  2.90, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', 2),
  -- Hand Tools (subcat 5 = Wrenches & Sockets)
  ('TBD_PR_000050',  50, 'HND-WRN-050', 'Kraftsman 24-Piece Mechanics Tool Set',            'SAE and Metric socket set with quick-release ratchet',            5, 'Kraftsman',         49.99,  4.10, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', NULL),
  -- Plumbing (subcat 10 = Faucets)
  ('TBD_PR_000101', 101, 'PLB-FAU-101', 'Dolta Foundations Single-Handle Kitchen Faucet',   'Chrome finish with integral spray and diamond seal valve',        10, 'Dolta Faucets',    189.99,  5.20, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', 1),
  ('TBD_PR_000102', 102, 'PLB-FAU-102', 'Dolta Leland Pull-Down Sprayer Kitchen Faucet',    'Stainless steel with MagnaTite docking and Touch2O',              10, 'Dolta Faucets',    229.99,  6.10, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', 1),
  -- Plumbing (subcat 11 = Valves & Regulators)
  ('TBD_PR_000103', 103, 'PLB-VLV-103', 'Dolta ShieldFlow 3/4 in. Brass Ball Valve',        'Full-port brass ball valve with quarter-turn handle',             11, 'Dolta Faucets',     34.99,  0.80, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', 2),
  -- Electrical (subcat 14 = Outlets & Switches)
  ('TBD_PR_000104', 104, 'ELC-OUT-104', 'Levitan Decora Smart Wi-Fi Dimmer Switch',         'Voice-compatible dimmer with scheduling and away mode',           14, 'Levitan',           44.99,  0.35, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', 2),
  ('TBD_PR_000105', 105, 'ELC-OUT-105', 'Levitan 20A Self-Test GFCI Outlet (3-Pack)',       'Tamper-resistant GFCI receptacles with LED indicator',            14, 'Levitan',           24.99,  0.60, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', 3),
  -- Outdoor & Garden (subcat 34 = Garden Hand Tools)
  ('TBD_PR_000108', 108, 'OTD-TRM-108', 'STEELE 56V Battery-Powered String Trimmer',        'Lightweight trimmer with variable speed and bump feed',           34, 'STEELE',           159.99,  8.50, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', 3),
  -- Paint & Stain (subcat 17 = Interior Paint)
  ('TBD_PR_000210', 210, 'PNT-INT-210', 'Sherman-Willams ProClassic Interior Satin (1 gal)','Self-leveling alkyd-modified latex with excellent flow',          17, 'Sherman-Willams',   42.99,  9.50, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', NULL),
  -- Outdoor & Garden (subcat 33 = Lawn Mowers)
  ('TBD_PR_000410', 410, 'OTD-LWN-410', 'Skotts 21 in. Self-Propelled Gas Lawn Mower',      '163cc engine with 3-in-1 cutting: mulch, bag, side discharge',   33, 'Skotts',           349.99, 72.00, TRUE, '2022-06-01 00:00:00', '2022-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS', NULL);

-- 4b: Bulk product catalog (~487 additional products filling out all subcategories)
INSERT INTO RET_PRODUCTS (CTID_FIVETRAN_ID, ID, SKU, NAME, DESCRIPTION, SUBCATEGORY_ID, BRAND, UNIT_PRICE, WEIGHT_LBS, IS_ACTIVE, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID, VENDOR_ID)
WITH id_sequence AS (
    SELECT seq4() + 1 AS product_id
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
    WHERE seq4() + 1 NOT IN (10, 42, 50, 101, 102, 103, 104, 105, 106, 107, 108, 210, 410)
)
SELECT
    'TBD_PR_' || LPAD(product_id::VARCHAR, 6, '0'),
    product_id,
    -- SKU: department prefix + zero-padded ID
    CASE
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 1  AND 4  THEN 'PWR-'
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 5  AND 8  THEN 'HND-'
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 9  AND 12 THEN 'PLB-'
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 13 AND 16 THEN 'ELC-'
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 17 AND 20 THEN 'PNT-'
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 21 AND 24 THEN 'HDW-'
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 25 AND 28 THEN 'LBR-'
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 29 AND 32 THEN 'HVC-'
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 33 AND 36 THEN 'OTD-'
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 37 AND 40 THEN 'SAF-'
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 41 AND 43 THEN 'FLR-'
        ELSE 'KTB-'
    END || LPAD(product_id::VARCHAR, 3, '0'),
    -- Product name: brand + item type
    CASE MOD(product_id, 21)
        WHEN 0  THEN 'DeWalter'
        WHEN 1  THEN 'Milwonky'
        WHEN 2  THEN 'Wyobi'
        WHEN 3  THEN 'Makuta'
        WHEN 4  THEN 'Bozch'
        WHEN 5  THEN 'Stanly'
        WHEN 6  THEN '4M'
        WHEN 7  THEN 'Rust-O-Liam'
        WHEN 8  THEN 'Sherman-Willams'
        WHEN 9  THEN 'Behr-ly'
        WHEN 10 THEN 'Dromel'
        WHEN 11 THEN 'BLOCK+DEKKER'
        WHEN 12 THEN 'Kraftsman'
        WHEN 13 THEN 'Huskie'
        WHEN 14 THEN 'Klien Toolz'
        WHEN 15 THEN 'Levitan'
        WHEN 16 THEN 'Dolta Faucets'
        WHEN 17 THEN 'Webber'
        WHEN 18 THEN 'Skotts'
        WHEN 19 THEN 'STEELE'
        WHEN 20 THEN 'Owens Korning'
    END || ' ' ||
    CASE MOD(product_id - 1, 46) + 1
        WHEN 1  THEN 'Cordless Drill '
        WHEN 2  THEN '7-1/4" Circular Saw '
        WHEN 3  THEN 'Orbital Sander '
        WHEN 4  THEN '4-1/2" Angle Grinder '
        WHEN 5  THEN 'Combination Wrench Set '
        WHEN 6  THEN 'Needle-Nose Pliers '
        WHEN 7  THEN '10-Piece Screwdriver Set '
        WHEN 8  THEN '16 oz. Claw Hammer '
        WHEN 9  THEN '1/2" PVC Pipe 10ft '
        WHEN 10 THEN 'Pull-Down Kitchen Faucet '
        WHEN 11 THEN '3/4" Ball Valve '
        WHEN 12 THEN '40-Gal Gas Water Heater '
        WHEN 13 THEN '14/2 Romex Wire 250ft '
        WHEN 14 THEN 'Decora 15A Outlet '
        WHEN 15 THEN '20A Circuit Breaker '
        WHEN 16 THEN 'LED A19 Bulb 4-Pack '
        WHEN 17 THEN 'Interior Flat Paint 1-Gal '
        WHEN 18 THEN 'Exterior Semi-Gloss 1-Gal '
        WHEN 19 THEN 'Deck Stain Transparent 1-Gal '
        WHEN 20 THEN 'Multi-Surface Primer 1-Qt '
        WHEN 21 THEN '#8 x 2" Wood Screws 100-Pk '
        WHEN 22 THEN '3" Framing Nails 1-Lb '
        WHEN 23 THEN 'Drywall Anchor Kit 50-Pk '
        WHEN 24 THEN '3.5" Door Hinge 3-Pack '
        WHEN 25 THEN '2x4x8 Kiln-Dried SPF '
        WHEN 26 THEN '4x8 1/2" Plywood Panel '
        WHEN 27 THEN 'R-13 Fiberglass Batt 15" '
        WHEN 28 THEN '4x8 1/2" Drywall Sheet '
        WHEN 29 THEN '1500W Ceramic Space Heater '
        WHEN 30 THEN '52" Ceiling Fan w/ Light '
        WHEN 31 THEN 'Smart Thermostat '
        WHEN 32 THEN '20x25x1 HVAC Filter 4-Pk '
        WHEN 33 THEN '21" Self-Propelled Mower '
        WHEN 34 THEN 'Bypass Pruner '
        WHEN 35 THEN 'Solar Path Light 6-Pack '
        WHEN 36 THEN '6ft Privacy Fence Panel '
        WHEN 37 THEN 'Smoke/CO Combo Detector '
        WHEN 38 THEN 'Combination Padlock '
        WHEN 39 THEN 'Leather Work Gloves (L) '
        WHEN 40 THEN 'Impact Safety Glasses '
        WHEN 41 THEN 'Luxury Vinyl Plank 20sqft '
        WHEN 42 THEN '12x12 Ceramic Floor Tile '
        WHEN 43 THEN 'Click-Lock Laminate 25sqft '
        WHEN 44 THEN '36" Bathroom Vanity '
        WHEN 45 THEN 'Undermount Kitchen Sink '
        WHEN 46 THEN 'Widespread Bath Faucet '
    END || 'No. ' || product_id,
    'Quality hardware from The Build Depot (TBD)',
    -- Subcategory ID (evenly distributed across 46 subcategories)
    MOD(product_id - 1, 46) + 1,
    -- Brand
    CASE MOD(product_id, 21)
        WHEN 0  THEN 'DeWalter'
        WHEN 1  THEN 'Milwonky'
        WHEN 2  THEN 'Wyobi'
        WHEN 3  THEN 'Makuta'
        WHEN 4  THEN 'Bozch'
        WHEN 5  THEN 'Stanly'
        WHEN 6  THEN '4M'
        WHEN 7  THEN 'Rust-O-Liam'
        WHEN 8  THEN 'Sherman-Willams'
        WHEN 9  THEN 'Behr-ly'
        WHEN 10 THEN 'Dromel'
        WHEN 11 THEN 'BLOCK+DEKKER'
        WHEN 12 THEN 'Kraftsman'
        WHEN 13 THEN 'Huskie'
        WHEN 14 THEN 'Klien Toolz'
        WHEN 15 THEN 'Levitan'
        WHEN 16 THEN 'Dolta Faucets'
        WHEN 17 THEN 'Webber'
        WHEN 18 THEN 'Skotts'
        WHEN 19 THEN 'STEELE'
        WHEN 20 THEN 'Owens Korning'
    END,
    -- Price: varies by subcategory family
    CASE
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 1  AND 4  THEN ROUND(59.99 + MOD(product_id * 7, 200), 2)
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 5  AND 8  THEN ROUND(14.99 + MOD(product_id * 3, 80), 2)
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 9  AND 12 THEN ROUND(9.99  + MOD(product_id * 11, 300), 2)
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 13 AND 16 THEN ROUND(4.99  + MOD(product_id * 5, 100), 2)
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 17 AND 20 THEN ROUND(12.99 + MOD(product_id * 2, 60), 2)
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 21 AND 24 THEN ROUND(3.99  + MOD(product_id * 1, 30), 2)
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 25 AND 28 THEN ROUND(5.99  + MOD(product_id * 4, 50), 2)
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 29 AND 32 THEN ROUND(19.99 + MOD(product_id * 6, 150), 2)
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 33 AND 36 THEN ROUND(19.99 + MOD(product_id * 8, 350), 2)
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 37 AND 40 THEN ROUND(9.99  + MOD(product_id * 2, 40), 2)
        WHEN MOD(product_id - 1, 46) + 1 BETWEEN 41 AND 43 THEN ROUND(1.99  + MOD(product_id * 3, 80), 2)
        ELSE ROUND(49.99 + MOD(product_id * 9, 400), 2)
    END,
    -- Weight (lbs)
    ROUND(0.5 + MOD(product_id * 3, 50)::FLOAT / 10, 2),
    TRUE,
    DATEADD('day', -MOD(product_id, 500), '2025-01-01')::TIMESTAMP_NTZ,
    DATEADD('day', -MOD(product_id, 500), '2025-01-01')::TIMESTAMP_NTZ,
    FALSE,
    CURRENT_TIMESTAMP(),
    'DEMO_2026_SCENARIOS',
    NULL
FROM id_sequence;


-- #############################################################################
-- 5. RET_CUSTOMERS — 470 Customers
-- #############################################################################

-- 5a: Scenario C specific customers (hand-crafted with matching addresses)
INSERT INTO RET_CUSTOMERS (CTID_FIVETRAN_ID, ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, ADDRESS, CITY, STATE, ZIP, REGION, CUSTOMER_TYPE, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED)
VALUES
  ('TBD_CU_000401', 401, 'Mike',    'Thornton',   'mike.thornton@example.com',     '908-555-0101', '1 VIP St',        'Edison',        'NJ', '08817', 'Northeast', 'contractor',  '2023-03-15 00:00:00', '2023-03-15 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000402', 402, 'Sarah',   'Chen',       'sarah.chen@example.com',        '908-555-0102', '2 VIP St',        'Edison',        'NJ', '08817', 'Northeast', 'residential', '2023-04-20 00:00:00', '2023-04-20 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000403', 403, 'David',   'Rodriguez',  'david.rodriguez@example.com',   '404-555-0103', '3 VIP Ave',       'Atlanta',       'GA', '30301', 'Southeast', 'contractor',  '2023-05-10 00:00:00', '2023-05-10 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000404', 404, 'James',   'Whitmore',   'james.whitmore@example.com',    '404-555-0104', '4 Spend Ln',      'Atlanta',       'GA', '30301', 'Southeast', 'business',    '2023-06-01 00:00:00', '2023-06-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000405', 405, 'Karen',   'Patel',      'karen.patel@example.com',       '317-555-0105', '5 Spend Dr',      'Indianapolis',  'IN', '46201', 'Midwest',   'business',    '2023-07-15 00:00:00', '2023-07-15 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000406', 406, 'Tom',     'Brewer',     'tom.brewer@example.com',        '908-555-0106', '6 Loyal St',      'Edison',        'NJ', '08817', 'Northeast', 'residential', '2023-01-10 00:00:00', '2023-01-10 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000407', 407, 'Lisa',    'Nakamura',   'lisa.nakamura@example.com',     '404-555-0107', '7 Loyal Ave',     'Atlanta',       'GA', '30301', 'Southeast', 'residential', '2023-02-25 00:00:00', '2023-02-25 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000408', 408, 'Greg',    'Foster',     'greg.foster@example.com',       '317-555-0108', '8 Loyal Dr',      'Indianapolis',  'IN', '46201', 'Midwest',   'residential', '2023-03-30 00:00:00', '2023-03-30 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000409', 409, 'Rachel',  'Kim',        'rachel.kim@example.com',        '908-555-0109', '9 Multi St',      'Edison',        'NJ', '08817', 'Northeast', 'contractor',  '2023-04-15 00:00:00', '2023-04-15 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000410', 410, 'Marcus',  'Webb',       'marcus.webb@example.com',       '404-555-0110', '10 Multi Ave',    'Atlanta',       'GA', '30301', 'Southeast', 'contractor',  '2023-05-20 00:00:00', '2023-05-20 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000411', 411, 'Diane',   'Murphy',     'diane.murphy@example.com',      '317-555-0111', '11 Low St',       'Indianapolis',  'IN', '46201', 'Midwest',   'residential', '2023-06-10 00:00:00', '2023-06-10 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000412', 412, 'Brian',   'Taylor',     'brian.taylor@example.com',      '908-555-0112', '12 Low Ave',      'Edison',        'NJ', '08817', 'Northeast', 'residential', '2023-07-01 00:00:00', '2023-07-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000413', 413, 'Amy',     'Gonzalez',   'amy.gonzalez@example.com',      '404-555-0113', '13 Scatter Dr',   'Atlanta',       'GA', '30301', 'Southeast', 'residential', '2023-08-15 00:00:00', '2023-08-15 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000414', 414, 'Robert',  'Singh',      'robert.singh@example.com',      '317-555-0114', '14 Old Rd',       'Indianapolis',  'IN', '46201', 'Midwest',   'contractor',  '2023-09-01 00:00:00', '2023-09-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_CU_000415', 415, 'Cathy',   'Liu',        'cathy.liu@example.com',         '908-555-0115', '15 Edge St',      'Edison',        'NJ', '08817', 'Northeast', 'residential', '2023-10-10 00:00:00', '2023-10-10 00:00:00', FALSE, CURRENT_TIMESTAMP());

-- 5b: Bulk customers (IDs 1-400, 416-470) — general TBD shoppers
INSERT INTO RET_CUSTOMERS (CTID_FIVETRAN_ID, ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, ADDRESS, CITY, STATE, ZIP, REGION, CUSTOMER_TYPE, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED)
WITH first_names AS (
    SELECT column1 AS fn, ROW_NUMBER() OVER (ORDER BY column1) AS rn FROM VALUES
      ('John'),('Jane'),('Alex'),('Chris'),('Pat'),('Sam'),('Morgan'),('Taylor'),('Jordan'),('Casey'),
      ('Drew'),('Dylan'),('Avery'),('Riley'),('Quinn'),('Blake'),('Reese'),('Skyler'),('Emery'),('Rowan'),
      ('Logan'),('Parker'),('Harper'),('Sawyer'),('Finley'),('Charlie'),('Hayden'),('Peyton'),('Dakota'),('Sage')
),
last_names AS (
    SELECT column1 AS ln, ROW_NUMBER() OVER (ORDER BY column1) AS rn FROM VALUES
      ('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),('Miller'),('Davis'),('Martinez'),('Anderson'),
      ('Thomas'),('Jackson'),('White'),('Harris'),('Martin'),('Thompson'),('Moore'),('Allen'),('Young'),('King'),
      ('Wright'),('Scott'),('Hill'),('Green'),('Adams'),('Baker'),('Nelson'),('Carter'),('Mitchell'),('Perez')
),
locations AS (
    SELECT column1 AS city, column2 AS state_code, column3 AS zip, column4 AS region, ROW_NUMBER() OVER (ORDER BY column1) AS rn FROM VALUES
      ('Edison',       'NJ', '08817', 'Northeast'),
      ('Atlanta',      'GA', '30301', 'Southeast'),
      ('Indianapolis', 'IN', '46201', 'Midwest'),
      ('Denver',       'CO', '80201', 'West'),
      ('Dallas',       'TX', '75201', 'South'),
      ('San Jose',     'CA', '95101', 'West'),
      ('Chicago',      'IL', '60601', 'Midwest'),
      ('Orlando',      'FL', '32801', 'Southeast'),
      ('Philadelphia', 'PA', '19101', 'Northeast'),
      ('Columbus',     'OH', '43201', 'Midwest')
),
customer_ids AS (
    SELECT seq4() + 1 AS cid
    FROM TABLE(GENERATOR(ROWCOUNT => 470))
    WHERE seq4() + 1 NOT BETWEEN 401 AND 415
)
SELECT
    'TBD_CU_' || LPAD(c.cid::VARCHAR, 6, '0'),
    c.cid,
    fn.fn,
    ln.ln,
    LOWER(fn.fn) || '.' || LOWER(ln.ln) || '.' || c.cid || '@example.com',
    '555-' || LPAD(MOD(c.cid * 7, 9000 + 1000)::VARCHAR, 4, '0'),
    c.cid || ' Hardware Way',
    loc.city,
    loc.state_code,
    loc.zip,
    loc.region,
    CASE
        WHEN MOD(c.cid, 10) < 6 THEN 'residential'
        WHEN MOD(c.cid, 10) < 9 THEN 'contractor'
        ELSE 'business'
    END,
    DATEADD('day', -MOD(c.cid * 3, 800), '2025-06-01')::TIMESTAMP_NTZ,
    DATEADD('day', -MOD(c.cid * 3, 800), '2025-06-01')::TIMESTAMP_NTZ,
    FALSE,
    CURRENT_TIMESTAMP()
FROM customer_ids c
JOIN first_names fn ON fn.rn = MOD(c.cid - 1, 30) + 1
JOIN last_names ln  ON ln.rn = MOD(FLOOR((c.cid - 1) / 30), 30) + 1
JOIN locations loc  ON loc.rn = MOD(c.cid - 1, 10) + 1;


-- #############################################################################
-- 6. RET_PROMOTIONS — 12 TBD Sales Events
-- #############################################################################

INSERT INTO RET_PROMOTIONS (CTID_FIVETRAN_ID, ID, NAME, DESCRIPTION, DISCOUNT_TYPE, DISCOUNT_VALUE, MIN_ORDER_AMOUNT, APPLICABLE_CATEGORY_ID, START_DATE, END_DATE, IS_ACTIVE, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED)
VALUES
  ('TBD_PM_000001',  1, 'Spring Tool Blowout',       'Save big on power tools for spring projects',         'percent',  15.00,   50.00,  1, '2026-03-01', '2026-04-30', TRUE,  '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000002',  2, 'Wrench Fest',               'Hand tool deals for the home mechanic',               'percent',  10.00,   25.00,  2, '2026-01-15', '2026-02-28', FALSE, '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000003',  3, 'Plumber''s Weekend',        'Save on faucets, valves, and pipe fittings',          'fixed',    25.00,  100.00,  3, '2026-02-01', '2026-02-28', FALSE, '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000004',  4, 'Light It Up Sale',          'Electrical essentials at knockout prices',            'percent',  12.00,   30.00,  4, '2026-04-01', '2026-04-30', TRUE,  '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000005',  5, 'Paint Month Madness',       'All interior and exterior paint on sale',             'percent',  20.00,   40.00,  5, '2026-05-01', '2026-05-31', TRUE,  '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000006',  6, 'Bolt Bonanza',              'Stock up on fasteners and hardware',                  'percent',  10.00,   15.00,  6, '2026-01-01', '2026-01-31', FALSE, '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000007',  7, 'Build Season Kickoff',      'Lumber and building materials for your next project', 'fixed',    50.00,  200.00,  7, '2026-03-15', '2026-05-15', TRUE,  '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000008',  8, 'Beat the Heat',             'Fans and cooling gear before summer hits',            'percent',  18.00,   40.00,  8, '2026-05-15', '2026-06-30', TRUE,  '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000009',  9, 'Summer Lawn & Garden',      'Get your yard ready for summer',                      'fixed',    30.00,  150.00,  9, '2026-04-15', '2026-06-15', TRUE,  '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000010', 10, 'Safe Home Month',           'Detectors, locks, and safety gear deals',             'percent',  15.00,   20.00, 10, '2026-03-01', '2026-03-31', FALSE, '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000011', 11, 'Floor & More Sale',         'Vinyl, tile, and laminate at clearance prices',       'percent',  25.00,   75.00, 11, '2026-02-15', '2026-03-15', FALSE, '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP()),
  ('TBD_PM_000012', 12, 'Bath Remodel Bonanza',      'Vanities, sinks, and fixtures for your remodel',     'fixed',    75.00,  300.00, 12, '2026-04-01', '2026-05-31', TRUE,  '2025-12-01 00:00:00', FALSE, CURRENT_TIMESTAMP());


-- #############################################################################
-- 7. RET_INVENTORY (additional) — Stock levels for popular products
--    The 5 existing rows for product 42 remain untouched.
-- #############################################################################

INSERT INTO RET_INVENTORY (CTID_FIVETRAN_ID, ID, PRODUCT_ID, WAREHOUSE_ID, QUANTITY_ON_HAND, REORDER_POINT, REORDER_QUANTITY, LAST_RESTOCKED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID)
WITH popular_products AS (
    SELECT column1 AS product_id, column2 AS base_qty
    FROM VALUES
      (10, 150), (50, 200), (101, 80), (102, 60), (103, 300), (104, 250),
      (105, 400), (106, 120), (107, 90), (108, 70), (210, 180), (410, 40),
      (1, 100), (2, 85), (3, 95), (5, 120), (11, 110), (15, 130),
      (20, 200), (25, 75), (30, 60), (35, 90), (40, 150), (45, 80),
      (55, 175), (60, 140), (65, 95), (70, 110), (75, 130), (80, 85)
),
warehouses AS (
    SELECT column1 AS warehouse_id FROM VALUES (1),(2),(3),(4),(5)
)
SELECT
    'TBD_IV_' || LPAD(ROW_NUMBER() OVER (ORDER BY p.product_id, w.warehouse_id)::VARCHAR, 6, '0'),
    1000 + ROW_NUMBER() OVER (ORDER BY p.product_id, w.warehouse_id),
    p.product_id,
    w.warehouse_id,
    GREATEST(5, p.base_qty + MOD(p.product_id * w.warehouse_id * 7, 50) - 25),
    GREATEST(10, ROUND(p.base_qty * 0.2, 0)),
    GREATEST(25, ROUND(p.base_qty * 0.5, 0)),
    DATEADD('day', -MOD(p.product_id + w.warehouse_id, 60), '2026-05-01')::TIMESTAMP_NTZ,
    '2026-05-01 00:00:00'::TIMESTAMP_NTZ,
    FALSE,
    CURRENT_TIMESTAMP(),
    'DEMO_2026_SCENARIOS'
FROM popular_products p
CROSS JOIN warehouses w
WHERE p.product_id != 42;  -- product 42 inventory already exists from scenario A


-- #############################################################################
-- 8. RET_INVENTORY_TRANSACTIONS — 150 Movement logs
-- #############################################################################

INSERT INTO RET_INVENTORY_TRANSACTIONS (CTID_FIVETRAN_ID, ID, PRODUCT_ID, WAREHOUSE_ID, TRANSACTION_TYPE, QUANTITY, REFERENCE_ID, NOTES, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED)
WITH txn_data AS (
    SELECT
        seq4() AS rn,
        CASE MOD(seq4(), 15)
            WHEN 0 THEN 10 WHEN 1 THEN 42 WHEN 2 THEN 50 WHEN 3 THEN 101
            WHEN 4 THEN 102 WHEN 5 THEN 103 WHEN 6 THEN 104 WHEN 7 THEN 105
            WHEN 8 THEN 106 WHEN 9 THEN 107 WHEN 10 THEN 108 WHEN 11 THEN 210
            WHEN 12 THEN 410 WHEN 13 THEN 1 WHEN 14 THEN 5
        END AS product_id,
        MOD(seq4(), 5) + 1 AS warehouse_id,
        CASE MOD(seq4(), 4)
            WHEN 0 THEN 'receipt'
            WHEN 1 THEN 'sale'
            WHEN 2 THEN 'adjustment'
            WHEN 3 THEN 'return'
        END AS txn_type,
        CASE MOD(seq4(), 4)
            WHEN 0 THEN 50 + MOD(seq4() * 7, 150)
            WHEN 1 THEN -(1 + MOD(seq4() * 3, 10))
            WHEN 2 THEN MOD(seq4() * 2, 20) - 10
            WHEN 3 THEN 1 + MOD(seq4(), 3)
        END AS qty,
        DATEADD('day', -MOD(seq4() * 3, 365), '2026-05-15')::TIMESTAMP_NTZ AS txn_date
    FROM TABLE(GENERATOR(ROWCOUNT => 150))
)
SELECT
    'TBD_IT_' || LPAD(rn::VARCHAR, 6, '0'),
    2000 + rn,
    product_id,
    warehouse_id,
    txn_type,
    qty,
    NULL,
    CASE txn_type
        WHEN 'receipt'    THEN 'Vendor delivery to TBD store'
        WHEN 'sale'       THEN 'Customer purchase'
        WHEN 'adjustment' THEN 'Cycle count correction'
        WHEN 'return'     THEN 'Customer return processed'
    END,
    txn_date,
    FALSE,
    CURRENT_TIMESTAMP()
FROM txn_data;


-- #############################################################################
-- 9. RET_TICKETS — 50 Support Tickets
-- #############################################################################

INSERT INTO RET_TICKETS (CTID_FIVETRAN_ID, ID, CUSTOMER_ID, ORDER_ID, ISSUE_TYPE, PRIORITY, STATUS, DESCRIPTION, CREATED_AT, RESOLVED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED)
WITH ticket_data AS (
    SELECT
        seq4() AS rn,
        MOD(seq4(), 50) + 1 AS customer_id,
        CASE MOD(seq4(), 4)
            WHEN 0 THEN 'shipping_delay'
            WHEN 1 THEN 'product_defect'
            WHEN 2 THEN 'billing_error'
            WHEN 3 THEN 'return_request'
        END AS issue_type,
        CASE MOD(seq4(), 4)
            WHEN 0 THEN 'medium'
            WHEN 1 THEN 'high'
            WHEN 2 THEN 'low'
            WHEN 3 THEN 'medium'
        END AS priority,
        CASE MOD(seq4(), 4)
            WHEN 0 THEN 'resolved'
            WHEN 1 THEN 'open'
            WHEN 2 THEN 'closed'
            WHEN 3 THEN 'in_progress'
        END AS status,
        DATEADD('day', -MOD(seq4() * 5, 180), '2026-05-15')::TIMESTAMP_NTZ AS created
    FROM TABLE(GENERATOR(ROWCOUNT => 50))
)
SELECT
    'TBD_TK_' || LPAD(rn::VARCHAR, 6, '0'),
    3000 + rn,
    customer_id,
    NULL,
    issue_type,
    priority,
    status,
    CASE issue_type
        WHEN 'shipping_delay'  THEN 'Order has not arrived within expected delivery window. Customer requesting tracking update from TBD.'
        WHEN 'product_defect'  THEN 'Product received with manufacturing defect. Customer requesting replacement or refund from TBD.'
        WHEN 'billing_error'   THEN 'Customer charged incorrect amount on TBD purchase. Requesting price adjustment.'
        WHEN 'return_request'  THEN 'Customer wants to return item purchased at TBD. Requesting return shipping label.'
    END,
    created,
    CASE WHEN status IN ('resolved', 'closed') THEN DATEADD('day', MOD(rn, 7) + 1, created) ELSE NULL END,
    FALSE,
    CURRENT_TIMESTAMP()
FROM ticket_data;


-- #############################################################################
-- 10. RET_PRODUCT_REVIEWS — 150 Reviews
--     Products 101-103 (high defect) get lower ratings (1-3 stars).
--     Products 106-108 (clean) get higher ratings (4-5 stars).
-- #############################################################################

INSERT INTO RET_PRODUCT_REVIEWS (CTID_FIVETRAN_ID, ID, PRODUCT_ID, CUSTOMER_ID, RATING, REVIEW_TITLE, REVIEW_TEXT, IS_VERIFIED_PURCHASE, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED)
WITH review_data AS (
    SELECT
        seq4() AS rn,
        CASE
            WHEN seq4() < 20  THEN 101
            WHEN seq4() < 40  THEN 102
            WHEN seq4() < 55  THEN 103
            WHEN seq4() < 70  THEN 104
            WHEN seq4() < 85  THEN 105
            WHEN seq4() < 100 THEN 106
            WHEN seq4() < 115 THEN 107
            WHEN seq4() < 130 THEN 108
            WHEN seq4() < 140 THEN 10
            ELSE 42
        END AS product_id,
        MOD(seq4() * 7, 200) + 1 AS customer_id,
        DATEADD('day', -MOD(seq4() * 11, 365), '2026-05-15')::TIMESTAMP_NTZ AS review_date
    FROM TABLE(GENERATOR(ROWCOUNT => 150))
)
SELECT
    'TBD_RV_' || LPAD(rn::VARCHAR, 6, '0'),
    4000 + rn,
    product_id,
    customer_id,
    CASE
        WHEN product_id IN (101, 102, 103) THEN 1 + MOD(rn, 3)          -- 1-3 stars (defective products)
        WHEN product_id IN (104, 105)      THEN 2 + MOD(rn, 3)          -- 2-4 stars (near-miss products)
        WHEN product_id IN (106, 107, 108) THEN 4 + MOD(rn, 2)          -- 4-5 stars (clean products)
        ELSE 3 + MOD(rn, 3)                                              -- 3-5 stars (popular items)
    END,
    CASE
        WHEN product_id IN (101, 102, 103) AND MOD(rn, 3) = 0 THEN 'Started leaking after a week'
        WHEN product_id IN (101, 102, 103) AND MOD(rn, 3) = 1 THEN 'Poor quality control from Dolta'
        WHEN product_id IN (101, 102, 103) AND MOD(rn, 3) = 2 THEN 'Returned - defective out of the box'
        WHEN product_id IN (104, 105) AND MOD(rn, 2) = 0       THEN 'Works fine but feels cheap'
        WHEN product_id IN (104, 105) AND MOD(rn, 2) = 1       THEN 'Decent Levitan product for the price'
        WHEN product_id IN (106, 107, 108) AND MOD(rn, 2) = 0  THEN 'Excellent quality, very reliable'
        WHEN product_id IN (106, 107, 108) AND MOD(rn, 2) = 1  THEN 'Great value, would buy again from TBD'
        WHEN product_id = 10 THEN 'Solid DeWalter drill for DIY projects'
        WHEN product_id = 42 THEN 'Milwonky saw cuts straight and true'
        ELSE 'Good product from The Build Depot'
    END,
    CASE
        WHEN product_id IN (101, 102, 103) AND MOD(rn, 3) = 0 THEN 'Installed this Dolta faucet and within days it started dripping. Very disappointed. Had to call a plumber to remove it. Will not buy Dolta again from TBD.'
        WHEN product_id IN (101, 102, 103) AND MOD(rn, 3) = 1 THEN 'The finish was scratched out of the box and the valve cartridge was already worn. Clearly a manufacturing issue from Dolta. Returning to The Build Depot.'
        WHEN product_id IN (101, 102, 103) AND MOD(rn, 3) = 2 THEN 'DOA. Would not connect properly. Threads were cross-cut. Waste of money. Going with a different brand next time I visit TBD.'
        WHEN product_id IN (104, 105) AND MOD(rn, 2) = 0       THEN 'The Levitan dimmer works but the plastic feels flimsy. WiFi connection drops occasionally. Not terrible but not great either.'
        WHEN product_id IN (104, 105) AND MOD(rn, 2) = 1       THEN 'Easy install and works as advertised. The LED indicator is a nice touch. Solid mid-range Levitan option from TBD.'
        WHEN product_id IN (106, 107, 108) AND MOD(rn, 2) = 0  THEN 'Been using this for 6 months now with zero issues. Battery life is impressive and the build quality is top-notch. TBD recommended.'
        WHEN product_id IN (106, 107, 108) AND MOD(rn, 2) = 1  THEN 'Compared to the big brands this is just as good at a fraction of the price. Highly recommend for weekend warriors shopping at TBD.'
        WHEN product_id = 10 THEN 'The DeWalter 20V drill has solid torque for its class. Great for hanging shelves and assembling furniture. Battery lasts a full day of light use. Got it at TBD Edison.'
        WHEN product_id = 42 THEN 'This Milwonky circular saw cuts through 2x4s like butter. Brushless motor is quiet and the blade guard works smoothly. Professional quality from The Build Depot.'
        ELSE 'Picked this up at TBD and it does exactly what I need. Fair price for a solid product. Would recommend to other DIYers.'
    END,
    TRUE,
    review_date,
    FALSE,
    CURRENT_TIMESTAMP()
FROM review_data;


-- #############################################################################
-- VALIDATION: Quick row count check (uncomment to run)
-- #############################################################################
/*
SELECT 'RET_WAREHOUSES'             AS tbl, COUNT(*) AS cnt FROM RET_WAREHOUSES
UNION ALL SELECT 'RET_PRODUCT_CATEGORIES',   COUNT(*) FROM RET_PRODUCT_CATEGORIES
UNION ALL SELECT 'RET_PRODUCT_SUBCATEGORIES',COUNT(*) FROM RET_PRODUCT_SUBCATEGORIES
UNION ALL SELECT 'RET_PRODUCTS',             COUNT(*) FROM RET_PRODUCTS
UNION ALL SELECT 'RET_CUSTOMERS',            COUNT(*) FROM RET_CUSTOMERS
UNION ALL SELECT 'RET_PROMOTIONS',           COUNT(*) FROM RET_PROMOTIONS
UNION ALL SELECT 'RET_INVENTORY',            COUNT(*) FROM RET_INVENTORY
UNION ALL SELECT 'RET_INVENTORY_TRANSACTIONS', COUNT(*) FROM RET_INVENTORY_TRANSACTIONS
UNION ALL SELECT 'RET_TICKETS',              COUNT(*) FROM RET_TICKETS
UNION ALL SELECT 'RET_PRODUCT_REVIEWS',      COUNT(*) FROM RET_PRODUCT_REVIEWS
UNION ALL SELECT 'RET_ORDERS',               COUNT(*) FROM RET_ORDERS
UNION ALL SELECT 'RET_ORDER_ITEMS',          COUNT(*) FROM RET_ORDER_ITEMS
UNION ALL SELECT 'RET_RETURNS',              COUNT(*) FROM RET_RETURNS
UNION ALL SELECT 'RET_VENDORS',              COUNT(*) FROM RET_VENDORS
UNION ALL SELECT 'RET_SHIPMENTS',            COUNT(*) FROM RET_SHIPMENTS
UNION ALL SELECT 'RET_SHIPMENT_LINES',       COUNT(*) FROM RET_SHIPMENT_LINES
ORDER BY 1;
*/


-- #############################################################################
-- ROLLBACK: Remove all seed data (run in reverse dependency order)
-- #############################################################################
/*
-- Remove seed data (identified by TBD_ prefix on CTID_FIVETRAN_ID)
DELETE FROM RET_PRODUCT_REVIEWS        WHERE CTID_FIVETRAN_ID LIKE 'TBD_RV_%';
DELETE FROM RET_TICKETS                WHERE CTID_FIVETRAN_ID LIKE 'TBD_TK_%';
DELETE FROM RET_INVENTORY_TRANSACTIONS WHERE CTID_FIVETRAN_ID LIKE 'TBD_IT_%';
DELETE FROM RET_INVENTORY              WHERE CTID_FIVETRAN_ID LIKE 'TBD_IV_%';
DELETE FROM RET_PROMOTIONS             WHERE CTID_FIVETRAN_ID LIKE 'TBD_PM_%';
DELETE FROM RET_CUSTOMERS              WHERE CTID_FIVETRAN_ID LIKE 'TBD_CU_%';
DELETE FROM RET_PRODUCTS               WHERE CTID_FIVETRAN_ID LIKE 'TBD_PR_%';
DELETE FROM RET_PRODUCT_SUBCATEGORIES  WHERE CTID_FIVETRAN_ID LIKE 'TBD_SC_%';
DELETE FROM RET_PRODUCT_CATEGORIES     WHERE CTID_FIVETRAN_ID LIKE 'TBD_CA_%';
DELETE FROM RET_WAREHOUSES             WHERE CTID_FIVETRAN_ID LIKE 'TBD_WH_%';
*/
