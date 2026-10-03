-- Importing data
CREATE EXTENSION postgis;
SELECT PostGIS_Version();
CREATE SCHEMA raw;
CREATE SCHEMA model;
CREATE SCHEMA results;
SELECT postGIS_Version();

SELECT * FROM raw.os_buildings LIMIT 10;
SELECT COUNT (*) FROM raw.os_buildings
SELECT id, featcode FROM raw.os_buildings LIMIT 10;
SELECT ST_SRID(geom) FROM raw.os_buildings LIMIT 1;

SELECT * FROM raw.flood_hazard_1in30 LIMIT 10;
SELECT * FROM raw.london_boroughs LIMIT 10;

CREATE TABLE raw.os_uprn (uprn BIGINT,x_coordinate DOUBLE PRECISION, y_coordinate DOUBLE PRECISION,latitude DOUBLE PRECISION,longitude DOUBLE PRECISION);
COPY raw.os_uprn (uprn,x_coordinate,y_coordinate,latitude,longitude) FROM 'C:\Users\tobyj\OneDrive\Documents\Project 2\uprn\osopenuprn_202608.csv' WITH (FORMAT csv,HEADER true);
SELECT * FROM raw.os_uprn LIMIT 10;

CREATE TABLE raw.epc_domestic (certificate_number TEXT, address1 TEXT, address2 TEXT, address3 TEXT, postcode TEXT, posttown TEXT, address TEXT, constituency TEXT, constituency_label TEXT, local_authority TEXT, local_authority_label TEXT, built_form TEXT, co2_emiss_curr_per_floor_area TEXT, co2_emissions_current TEXT, co2_emissions_potential TEXT, construction_age_band TEXT, current_energy_efficiency TEXT, current_energy_rating TEXT, energy_consumption_current TEXT, energy_consumption_potential TEXT, energy_tariff TEXT, environment_impact_current TEXT, environment_impact_potential TEXT, extension_count TEXT, fixed_lighting_outlets_count TEXT, flat_storey_count TEXT, flat_top_storey TEXT, floor_description TEXT, floor_energy_eff TEXT, floor_height TEXT, floor_level TEXT, glazed_area TEXT, glazed_type TEXT, heat_loss_corridor TEXT, heating_cost_current TEXT, heating_cost_potential TEXT, hot_water_cost_current TEXT, hot_water_cost_potential TEXT, hot_water_energy_eff TEXT, hot_water_env_eff TEXT, hotwater_description TEXT, inspection_date TEXT, lighting_cost_current TEXT, lighting_cost_potential TEXT, lighting_description TEXT, lighting_energy_eff TEXT, lighting_env_eff TEXT, lodgement_date TEXT, lodgement_datetime TEXT, low_energy_lighting TEXT, low_energy_fixed_lighting_outlets_count TEXT, main_fuel TEXT, mainheat_description TEXT, mainheat_energy_eff TEXT, mainheat_env_eff TEXT, mainheatc_energy_eff TEXT, mainheatc_env_eff TEXT, mainheatcont_description TEXT, main_heating_controls TEXT, mains_gas_flag TEXT, mechanical_ventilation TEXT, multi_glaze_proportion TEXT, number_habitable_rooms TEXT, number_heated_rooms TEXT, number_open_fireplaces TEXT, photo_supply TEXT, potential_energy_efficiency TEXT, potential_energy_rating TEXT, property_type TEXT, report_type TEXT, roof_description TEXT, roof_energy_eff TEXT, roof_env_eff TEXT, secondheat_description TEXT, sheating_energy_eff TEXT, sheating_env_eff TEXT, solar_water_heating_flag TEXT, tenure TEXT, total_floor_area TEXT, transaction_type TEXT, unheated_corridor_length TEXT, walls_description TEXT, walls_energy_eff TEXT, walls_env_eff TEXT, wind_turbine_count TEXT, windows_description TEXT, windows_energy_eff TEXT, windows_env_eff TEXT, floor_env_eff TEXT, region TEXT, country TEXT, uprn TEXT, uprn_source TEXT);SELECT COUNT(*) FROM raw.epc_domestic;
SELECT uprn, property_type, built_form, total_floor_area, postcode, construction_age_band FROM raw.epc_domestic LIMIT 10;

CREATE TABLE raw.ons_london_property_values (region_country_code TEXT,region_country_name TEXT,local_authority_code TEXT,local_authority_name TEXT,property_type TEXT,period TEXT,median_price NUMERIC);
SELECT * FROM raw.ons_london_property_values LIMIT 10;

SELECT * FROM raw.flood_hazard_rivers_1in100_sea_1in200_defended LIMIT 10;

-- Validate database

-- Check all data tables are present
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'raw'
ORDER BY table_name;

--Check how much data is in each table
SELECT 'epc_domestic' AS table_name, COUNT(*) AS rows FROM raw.epc_domestic
UNION ALL
SELECT 'flood_hazard_1in30_defended', COUNT(*) FROM raw.flood_hazard_1in30_defended
UNION ALL
SELECT 'flood_hazard_rivers_1in100_sea_1in200_defended', COUNT(*) FROM raw.flood_hazard_rivers_1in100_sea_1in200_defended
UNION ALL
SELECT 'london_boroughs', COUNT(*) FROM raw.london_boroughs
UNION ALL
SELECT 'ons_london_property_values', COUNT(*) FROM raw.ons_london_property_values
UNION ALL
SELECT 'os_buildings', COUNT(*) FROM raw.os_buildings
UNION ALL
SELECT 'os_uprn', COUNT(*) FROM raw.os_uprn;

-- Check columns were interpreted correctely
SELECT table_name, column_name,data_type FROM information_schema.columns WHERE table_schema = 'raw' ORDER BY table_name, ordinal_position;

-- Check spatial data
SELECT f_table_schema, f_table_name, f_geometry_column, srid, type FROM geometry_columns WHERE f_table_schema = 'raw' ORDER BY f_table_name;

SELECT
    'os_buildings' AS table_name,
    COUNT(*) AS invalid_geometries

-- Check for a link
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT uprn) AS unique_uprns FROM raw.os_uprn;

-- Check for missing values
SELECT COUNT(*) AS missing_uprns FROM raw.os_uprn WHERE uprn IS NULL;

--
SELECT COUNT(*) AS total_epc, COUNT(uprn) AS epc_with_uprn, COUNT(*) - COUNT(uprn) AS epc_without_uprn FROM raw.epc_domestic;

-- Check for duplicates
SELECT COUNT(*) AS uprns_with_multiple_certificates FROM (SELECT uprn FROM raw.epc_domestic WHERE uprn IS NOT NULLGROUP BY uprnHAVING COUNT(*) > 1) AS duplicates;

-- Check for distinct
SELECT COUNT(DISTINCT uprn) AS unique_epc_uprns FROM raw.epc_domestic WHERE uprn IS NOT NULL;

--Check for links
SELECT COUNT(DISTINCT e.uprn) AS epc_uprns_found_in_os FROM raw.epc_domestic e INNER JOIN raw.os_uprn u ON e.uprn::BIGINT = u.uprn WHERE e.uprn IS NOT NULL;

--
SELECT COUNT(DISTINCT local_authority_code) AS unique_london_authorities, COUNT(DISTINCT local_authority_name) AS unique_authority_names FROM raw.ons_london_property_values;

-- Check for missing data
SELECT COUNT(*) AS total_values, COUNT(median_price) AS non_null_values, COUNT(*) - COUNT(median_price) AS missing_values, COUNT(*) FILTER (WHERE median_price <= 0) AS zero_or_negative_values FROM raw.ons_london_property_values;

-- Check where missing data is concentrated
SELECT property_type, COUNT(*) AS missing_values FROM raw.ons_london_property_values WHERE median_price IS NULL GROUP BY property_type ORDER BY missing_values DESC;

--
SELECT depth_band, COUNT(*) AS records FROM raw.flood_hazard_1in30_defended GROUP BY depth_band ORDER BY depth_band;
SELECT depth_band, COUNT(*) AS records FROM raw.flood_hazard_rivers_1in100_sea_1in200_defended GROUP BY depth_band ORDER BY depth_band;
SELECT flood_sour, COUNT(*) AS records FROM raw.flood_hazard_1in30_defended GROUP BY flood_sour ORDER BY flood_sour;
SELECT flood_sour, COUNT(*) AS records FROM raw.flood_hazard_rivers_1in100_sea_1in200_defended GROUP BY flood_sour ORDER BY flood_sour;

--END OF DATA CLEANING/VALDIDATION

-- Create first model dataset from the original raw one
CREATE TABLE model.buildings AS SELECT id AS building_id, geom, featcode FROM raw.os_buildings;
-- Create spatial index for the table, so we can do spatial operations
CREATE INDEX buildings_geom_idx ON model.buildings USING GIST (geom);

--
CREATE TABLE model.uprn AS SELECT uprn, x_coordinate, y_coordinate, latitude, longitude, ST_SetSRID (ST_MakePoint(x_coordinate, y_coordinate), 27700) AS geom FROM raw.os_uprn;

--Create an index
CREATE INDEX uprn_geom_idx ON model.uprn USING GIST (geom);

-- Create the model table for epc
CREATE TABLE model.epc AS SELECT certificate_number, uprn::BIGINT AS uprn, property_type, built_form, construction_age_band, total_floor_area::NUMERIC AS total_floor_area, postcode, local_authority, current_energy_rating FROM raw.epc_domestic WHERE uprn IS NOT NULL;

-- Create the model table for property values
CREATE TABLE model.property_values AS SELECT local_authority_code, local_authority_name, property_type, period, median_price FROM raw.ons_london_property_values;

-- Create the model table for london boroughs
CREATE TABLE model.boroughs AS SELECT id, name, gss_code, geom FROM raw.london_boroughs;

-- Create the model tables for the low and high retrun period floods
CREATE TABLE model.flood_hazard_1in30_defended AS SELECT id, geom, depth_band, flood_sour FROM raw.flood_hazard_1in30_defended;
CREATE TABLE model.flood_hazard_rivers_1in100_sea_1in200_defended AS SELECT id, geom, depth_band, flood_sour FROM raw.flood_hazard_rivers_1in100_sea_1in200_defended;

-- Create the spatial index's for the two new tables
CREATE INDEX flood_1in30_geom_idx ON model.flood_hazard_1in30_defended USING GIST (geom);
CREATE INDEX flood_1in100_200_geom_idx ON model.flood_hazard_rivers_1in100_sea_1in200_defended USING GIST (geom);

-- Test before begining joins
SELECT b.building_id, COUNT(u.uprn) AS uprns_inside FROM (SELECT * FROM model.buildings LIMIT 100) AS b LEFT JOIN model.uprn AS u ON ST_Within(u.geom, b.geom) GROUP BY b.building_id ORDER BY uprns_inside DESC;


EXPLAIN ANALYZE SELECT b.building_id, COUNT(u.uprn) AS uprns_inside FROM (SELECT * FROM model.buildings LIMIT 100) AS b LEFT JOIN model.uprn AS u ON u.geom && b.geom AND ST_Within(u.geom, b.geom) GROUP BY b.building_id ORDER BY uprns_inside DESC;

-- Build the building UPRN linkage table
CREATE TABLE model.building_uprn AS SELECT b.building_id, u.uprn FROM model.buildings AS b JOIN model.uprn AS u ON u.geom && b.geom AND ST_Within(u.geom, b.geom);

-- Check results from the table
SELECT COUNT(*) AS building_uprn_matches, COUNT(DISTINCT building_id) AS buildings_with_uprn, COUNT(DISTINCT uprn) AS unique_uprns FROM model.building_uprn;

-- Check before adding the EPC link
SELECT COUNT(*) AS building_uprn_matches, COUNT(e.uprn) AS matches_with_epc, COUNT(DISTINCT e.uprn) AS unique_epc_uprns FROM model.building_uprn AS bu LEFT JOIN model.epc AS e ON bu.uprn = e.uprn;

-- Column check
SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'raw' AND table_name = 'epc_domestic' AND (column_name ILIKE '%date%' OR column_name ILIKE '%lodged%' OR column_name ILIKE '%inspection%' OR column_name ILIKE '%transaction%') ORDER BY ordinal_position;

-- Data check
SELECT uprn, certificate_number, inspection_date, lodgement_date, lodgement_datetime, transaction_typeFROM model.epc LIMIT 10;

-- Add columns to table
ALTER TABLE model.epc ADD COLUMN inspection_date TEXT, ADD COLUMN lodgement_date TEXT, ADD COLUMN lodgement_datetime TEXT;

-- Populate the new columns
UPDATE model.epc AS e SET inspection_date = r.inspection_date, lodgement_date = r.lodgement_date, lodgement_datetime = r.lodgement_datetime FROM raw.epc_domestic AS r WHERE e.certificate_number = r.certificate_number;

-- Check if adding the columns was successful
SELECT uprn, certificate_number, inspection_date, lodgement_date, lodgement_datetime FROM model.epc LIMIT 10;

-- For each UPRN, retain the most recently lodged EPC certificate
SELECT uprn, certificate_number, lodgement_datetime, ROW_NUMBER() OVER (PARTITION BY uprn ORDER BY lodgement_datetime DESC) AS epc_rank FROM model.epc WHERE uprn IN ( SELECT uprn FROM model.epc GROUP BY uprn HAVING COUNT(*) > 1) LIMIT 20;

-- Create a temporary table before altering the epc table
CREATE TABLE model.epc_clean AS SELECT certificate_number, uprn, property_type, built_form, construction_age_band, total_floor_area, postcode, local_authority, current_energy_rating, inspection_date, lodgement_date, lodgement_datetime FROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY uprn ORDER BY lodgement_datetime DESC) AS epc_rank FROM model.epc) AS ranked_epc WHERE epc_rank = 1;

-- Check there is now one epc per UPRN
SELECT COUNT(*) AS total_records, COUNT(DISTINCT uprn) AS unique_uprns FROM model.epc_clean;

-- Replace the epc table
ALTER TABLE model.epc RENAME TO epc_old;

-- Get rid of old epc table
DROP TABLE model.epc_old;

-- Rename the cleaned table to the new general one
ALTER TABLE model.epc_clean RENAME TO epc;

-- Final verification of the epc data table
SELECT COUNT(*) AS building_uprn_matches, COUNT(e.uprn) AS matches_with_epc, COUNT(DISTINCT e.uprn) AS unique_epc_uprns FROM model.building_uprn AS bu LEFT JOIN model.epc AS e ON bu.uprn = e.uprn;




ALTER TABLE model.epc ADD COLUMN local_authority_label TEXT;
UPDATE model.epc AS e SET local_authority_label = r.local_authority_label FROM raw.epc_domestic AS r WHERE e.certificate_number = r.certificate_number;

-- Create model.building_properties, this will bring the EPC characteristics onto each building–UPRN relationship.
CREATE TABLE model.building_properties AS SELECT bu.building_id, bu.uprn, e.property_type, e.built_form, e.construction_age_band, e.total_floor_area, e.postcode, e.local_authority, e.local_authority_label FROM model.building_uprn AS bu LEFT JOIN model.epc AS e ON bu.uprn = e.uprn;

-- Check the building_properties table
SELECT COUNT(*) AS total_records, COUNT(DISTINCT building_id) AS unique_buildings, COUNT(DISTINCT uprn) AS unique_uprns, COUNT(property_type) AS records_with_epc FROM model.building_properties;
SELECT * FROM model.building_properties LIMIT 10;
SELECT * FROM model.building_properties WHERE property_type IS NOT NULL LIMIT 10;

-- Create another table which pins the building_properties table to our boroughs dataset
CREATE TABLE model.london_building_properties AS SELECT bp.building_id, bp.uprn, bp.property_type, bp.built_form, bp.construction_age_band, bp.total_floor_area, bp.postcode, bp.local_authority, bp.local_authority_label, b.name AS borough_name, b.gss_code AS borough_gss_code FROM model.building_properties AS bp JOIN model.buildings AS buildings ON bp.building_id = buildings.building_id JOIN model.boroughs AS b ON ST_Intersects(buildings.geom, b.geom);

-- Check the new table
SELECT COUNT(*) AS total_records, COUNT(DISTINCT building_id) AS unique_buildings, COUNT(DISTINCT uprn) AS unique_uprns, COUNT(property_type) AS records_with_epc FROM model.london_building_properties;
SELECT borough_name, COUNT(*) AS records FROM model.london_building_properties GROUP BY borough_name ORDER BY borough_name;

-- Drop old table
DROP TABLE model.building_properties;

-- Create the 1-in-30-year defended flood exposure table, spatially intersect the London building footprints with the EA flood polygons
CREATE TABLE model.flood_exposure_1in30 AS SELECT lbp.building_id, lbp.uprn, fh.id AS flood_id, fh.depth_band, fh.flood_sour FROM model.london_building_properties AS lbp JOIN model.buildings AS b ON lbp.building_id = b.building_id JOIN model.flood_hazard_1in30_defended AS fh ON ST_Intersects(b.geom, fh.geom);

-- 1-in-30 year exposure table checks
SELECT COUNT(*) AS total_records, COUNT(DISTINCT building_id) AS unique_buildings, COUNT(DISTINCT uprn) AS unique_uprns, COUNT(depth_band) AS records_with_depth, COUNT(flood_sour) AS records_with_source FROM model.flood_exposure_1in30;
SELECT depth_band, COUNT(*) AS records FROM model.flood_exposure_1in30 GROUP BY depth_band ORDER BY depth_band;
SELECT flood_sour, depth_band, COUNT(*) AS records FROM model.flood_exposure_1in30 GROUP BY flood_sour, depth_band ORDER BY flood_sour, depth_band;

-- Create the 1-in-100/200 year defended flood exposure table, spatially interscet the london building footprints with the EA flood polygons
CREATE TABLE model.flood_exposure_1in100_200 AS SELECT lbp.building_id, lbp.uprn, fh.id AS flood_id, fh.depth_band, fh.flood_sour FROM model.london_building_properties AS lbp JOIN model.buildings AS b ON lbp.building_id = b.building_id JOIN model.flood_hazard_rivers_1in100_sea_1in200_defended AS fh ON ST_Intersects(b.geom, fh.geom);

-- 1-in-100/200 year exposure table checks
SELECT COUNT(*) AS total_records, COUNT(DISTINCT building_id) AS unique_buildings, COUNT(DISTINCT uprn) AS unique_uprns, COUNT(depth_band) AS records_with_depth, COUNT(flood_sour) AS records_with_source FROM model.flood_exposure_1in100_200;
SELECT depth_band, COUNT(*) AS records FROM model.flood_exposure_1in100_200 GROUP BY depth_band ORDER BY depth_band;

-- Create a table that joins our flood exposure records back to the EPC-linked London properties, while only retaining records with a usable depth band. Thus establishing the actual modelling popultion for each scenario
CREATE TABLE model.loss_population_1in30 AS SELECT fe.building_id, fe.uprn, fe.flood_id, fe.depth_band, fe.flood_sour, lbp.property_type, lbp.built_form, lbp.construction_age_band, lbp.total_floor_area, lbp.postcode, lbp.borough_name, lbp.borough_gss_code FROM model.flood_exposure_1in30 AS fe JOIN model.london_building_properties AS lbp ON fe.building_id = lbp.building_id AND fe.uprn = lbp.uprn WHERE fe.depth_band <> 'unavailable' AND lbp.property_type IS NOT NULL;

-- How many properties made it through the filter
SELECT COUNT(*) AS total_records, COUNT(DISTINCT building_id) AS unique_buildings, COUNT(DISTINCT uprn) AS unique_uprns, COUNT(property_type) AS records_with_property_type, COUNT(total_floor_area) AS records_with_floor_area FROM model.loss_population_1in30;
SELECT COUNT(*) AS records, COUNT(DISTINCT uprn) AS unique_uprns, MAX(records_per_uprn) AS max_records_per_uprn FROM (SELECT uprn, COUNT(*) AS records_per_uprn FROM model.loss_population_1in30 GROUP BY uprn) AS x;
SELECT depth_band, COUNT(DISTINCT uprn) AS unique_properties FROM model.loss_population_1in30 GROUP BY depth_band ORDER BY depth_band;

-- How many properties fall into each depth band when we force each property to have one representative flood depth
SELECT uprn, COUNT(*) AS flood_records, STRING_AGG(DISTINCT depth_band, ', ' ORDER BY depth_band) AS depth_bands FROM model.loss_population_1in30 GROUP BY uprn HAVING COUNT(*) > 1 ORDER BY flood_records DESC;
SELECT
    CASE
        WHEN depth_band = '<150mm' THEN 1
        WHEN depth_band = '150-300mm' THEN 2
        WHEN depth_band = '300-600mm' THEN 3
        WHEN depth_band = '600-900mm' THEN 4
        WHEN depth_band = '900-1200mm' THEN 5
        WHEN depth_band = '1200-2300mm' THEN 6
        WHEN depth_band = '>2300mm' THEN 7
    END AS depth_rank,
    depth_band,
    COUNT(*) AS properties
FROM (
    SELECT
        uprn,
        depth_band,
        CASE
            WHEN depth_band = '<150mm' THEN 1
            WHEN depth_band = '150-300mm' THEN 2
            WHEN depth_band = '300-600mm' THEN 3
            WHEN depth_band = '600-900mm' THEN 4
            WHEN depth_band = '900-1200mm' THEN 5
            WHEN depth_band = '1200-2300mm' THEN 6
            WHEN depth_band = '>2300mm' THEN 7
        END AS rank
    FROM model.loss_population_1in30
) AS x
WHERE rank = (
    SELECT MAX(
        CASE
            WHEN depth_band = '<150mm' THEN 1
            WHEN depth_band = '150-300mm' THEN 2
            WHEN depth_band = '300-600mm' THEN 3
            WHEN depth_band = '600-900mm' THEN 4
            WHEN depth_band = '900-1200mm' THEN 5
            WHEN depth_band = '1200-2300mm' THEN 6
            WHEN depth_band = '>2300mm' THEN 7
        END
    )
    FROM model.loss_population_1in30 y
    WHERE y.uprn = x.uprn
)
GROUP BY depth_rank, depth_band
ORDER BY depth_rank;


SELECT
    depth_band,
    COUNT(*) AS properties
FROM (
    SELECT
        uprn,
        depth_band,
        ROW_NUMBER() OVER (
            PARTITION BY uprn
            ORDER BY
                CASE
                    WHEN depth_band = '<150mm' THEN 1
                    WHEN depth_band = '150-300mm' THEN 2
                    WHEN depth_band = '300-600mm' THEN 3
                    WHEN depth_band = '600-900mm' THEN 4
                    WHEN depth_band = '900-1200mm' THEN 5
                    WHEN depth_band = '1200-2300mm' THEN 6
                    WHEN depth_band = '>2300mm' THEN 7
                END DESC
        ) AS rn
    FROM model.loss_population_1in30
) AS ranked
WHERE rn = 1
GROUP BY depth_band
ORDER BY
    CASE
        WHEN depth_band = '<150mm' THEN 1
        WHEN depth_band = '150-300mm' THEN 2
        WHEN depth_band = '300-600mm' THEN 3
        WHEN depth_band = '600-900mm' THEN 4
        WHEN depth_band = '900-1200mm' THEN 5
        WHEN depth_band = '1200-2300mm' THEN 6
        WHEN depth_band = '>2300mm' THEN 7
    END;

-- Drop old table
DROP TABLE model.loss_population_1in30;

-- Create new table
CREATE TABLE model.loss_population_1in30 AS
SELECT
    building_id,
    uprn,
    flood_id,
    depth_band,
    flood_sour,
    property_type,
    built_form,
    construction_age_band,
    total_floor_area,
    postcode,
    borough_name,
    borough_gss_code
FROM (
    SELECT
        fe.building_id,
        fe.uprn,
        fe.flood_id,
        fe.depth_band,
        fe.flood_sour,
        lbp.property_type,
        lbp.built_form,
        lbp.construction_age_band,
        lbp.total_floor_area,
        lbp.postcode,
        lbp.borough_name,
        lbp.borough_gss_code,
        ROW_NUMBER() OVER (
            PARTITION BY fe.uprn
            ORDER BY
                CASE
                    WHEN fe.depth_band = '<150mm' THEN 1
                    WHEN fe.depth_band = '150-300mm' THEN 2
                    WHEN fe.depth_band = '300-600mm' THEN 3
                    WHEN fe.depth_band = '600-900mm' THEN 4
                    WHEN fe.depth_band = '900-1200mm' THEN 5
                    WHEN fe.depth_band = '1200-2300mm' THEN 6
                    WHEN fe.depth_band = '>2300mm' THEN 7
                END DESC
        ) AS rn
    FROM model.flood_exposure_1in30 AS fe
    JOIN model.london_building_properties AS lbp
        ON fe.building_id = lbp.building_id
        AND fe.uprn = lbp.uprn
    WHERE fe.depth_band <> 'unavailable'
      AND lbp.property_type IS NOT NULL
) AS ranked
WHERE rn = 1;

-- Validate new table
SELECT COUNT(*) AS total_records, COUNT(DISTINCT uprn) AS unique_uprns, COUNT(DISTINCT building_id) AS unique_buildings, COUNT(*) FILTER (WHERE depth_band IS NOT NULL) AS records_with_depth, COUNT(*) FILTER (WHERE property_type IS NOT NULL) AS records_with_property_type, COUNT(*) FILTER (WHERE total_floor_area IS NOT NULL) AS records_with_floor_area FROM model.loss_population_1in30;

-- Build the same for the higher return period table
CREATE TABLE model.loss_population_1in100_200 AS
SELECT
    building_id,
    uprn,
    flood_id,
    depth_band,
    flood_sour,
    property_type,
    built_form,
    construction_age_band,
    total_floor_area,
    postcode,
    borough_name,
    borough_gss_code
FROM (
    SELECT
        fe.building_id,
        fe.uprn,
        fe.flood_id,
        fe.depth_band,
        fe.flood_sour,
        lbp.property_type,
        lbp.built_form,
        lbp.construction_age_band,
        lbp.total_floor_area,
        lbp.postcode,
        lbp.borough_name,
        lbp.borough_gss_code,
        ROW_NUMBER() OVER (
            PARTITION BY fe.uprn
            ORDER BY
                CASE
                    WHEN fe.depth_band = '<150mm' THEN 1
                    WHEN fe.depth_band = '150-300mm' THEN 2
                    WHEN fe.depth_band = '300-600mm' THEN 3
                    WHEN fe.depth_band = '600-900mm' THEN 4
                    WHEN fe.depth_band = '900-1200mm' THEN 5
                    WHEN fe.depth_band = '1200-2300mm' THEN 6
                    WHEN fe.depth_band = '>2300mm' THEN 7
                END DESC
        ) AS rn
    FROM model.flood_exposure_1in100_200 AS fe
    JOIN model.london_building_properties AS lbp
        ON fe.building_id = lbp.building_id
        AND fe.uprn = lbp.uprn
    WHERE fe.depth_band <> 'unavailable'
      AND lbp.property_type IS NOT NULL
) AS ranked
WHERE rn = 1;

-- Validate table in the same way
SELECT COUNT(*) AS total_records, COUNT(DISTINCT uprn) AS unique_uprns, COUNT(DISTINCT building_id) AS unique_buildings, COUNT(*) FILTER (WHERE depth_band IS NOT NULL) AS records_with_depth, COUNT(*) FILTER (WHERE property_type IS NOT NULL) AS records_with_property_type, COUNT(*) FILTER (WHERE total_floor_area IS NOT NULL) AS records_with_floor_area FROM model.loss_population_1in100_200;
SELECT depth_band, COUNT(*) AS properties FROM model.loss_population_1in100_200 GROUP BY depth_band ORDER BY CASE WHEN depth_band = '<150mm' THEN 1 WHEN depth_band = '150-300mm' THEN 2 WHEN depth_band = '300-600mm' THEN 3 WHEN depth_band = '600-900mm' THEN 4 WHEN depth_band = '900-1200mm' THEN 5 WHEN depth_band = '1200-2300mm' THEN 6 WHEN depth_band = '>2300mm' THEN 7 END;

-- Create homemade table
CREATE TABLE model.vulnerability (depth_band TEXT, damage_25yr_2013 NUMERIC, damage_25yr_2026 NUMERIC, damage_100yr_2013 NUMERIC, damage_100yr_2026 NUMERIC)
-- Populate vulnerability table
INSERT INTO model.vulnerability (
    depth_band,
    damage_25yr_2013,
    damage_25yr_2026,
    damage_100yr_2013,
    damage_100yr_2026
)
VALUES
    ('<150mm', 11975, 17458, 17666, 25755),
    ('150-300mm', 22545, 32868, 27392, 39934),
    ('300-600mm', 29588, 43135, 24133, 35183),
    ('600-900mm', 32922, 47996, 27864, 40622),
    ('900-1200mm', 35511, 51770, 40440, 58956),
    ('1200-2300mm', 36860, 53737, 41614, 60668),
    ('>2300mm', 36860, 53737, 41614, 60668);
-- Validate table
SELECT * FROM model.vulnerability

-- Create the actual loss table for 1-in-30 scenario
CREATE TABLE model.loss_1in30 AS SELECT lp.building_id, lp.uprn, lp.depth_band, lp.borough_name, lp.borough_gss_code, v.damage_25yr_2026 AS estimated_loss_2026 FROM model.loss_population_1in30 AS lp JOIN model.vulnerability AS v ON lp.depth_band = v.depth_band;

-- Check table
SELECT COUNT(*) AS total_records, COUNT(DISTINCT uprn) AS unique_uprns, COUNT(estimated_loss_2026) AS records_with_loss, MIN(estimated_loss_2026) AS minimum_loss, MAX(estimated_loss_2026) AS maximum_loss FROM model.loss_1in30
SELECT * FROM model.loss_1in30 LIMIT 5;

-- Create the actual loss table for 1-in100/200 scenario
CREATE TABLE model.loss_1in100_200 AS SELECT lp.building_id, lp.uprn, lp.depth_band, lp.borough_name, lp.borough_gss_code, v.damage_100yr_2026 AS estimated_loss_2026 FROM model.loss_population_1in100_200 AS lp JOIN model.vulnerability AS v ON lp.depth_band = v.depth_band;

-- Check table
SELECT COUNT(*) AS total_records, COUNT(DISTINCT uprn) AS unique_uprns, COUNT(estimated_loss_2026) AS records_with_loss, MIN(estimated_loss_2026) AS minimum_loss, MAX(estimated_loss_2026) AS maximum_loss FROM model.loss_1in100_200;
SELECT * FROM model.loss_1in100_200 LIMIT 5;

-- END OF DATABASE WORK

-- START OF OUTPUTS

-- Overall exposure and estimated loss- headline summary
SELECT
    '1-in-30 defended' AS scenario,
    COUNT(DISTINCT uprn) AS exposed_properties,
    COUNT(DISTINCT building_id) AS exposed_buildings,
    SUM(estimated_loss_2026) AS total_estimated_loss,
    ROUND(AVG(estimated_loss_2026), 2) AS mean_loss_per_property
FROM model.loss_1in30

UNION ALL

SELECT
    '1-in-100 river / 1-in-200 sea defended' AS scenario,
    COUNT(DISTINCT uprn) AS exposed_properties,
    COUNT(DISTINCT building_id) AS exposed_buildings,
    SUM(estimated_loss_2026) AS total_estimated_loss,
    ROUND(AVG(estimated_loss_2026), 2) AS mean_loss_per_property
FROM model.loss_1in100_200;

-- Damage by depth band (1in30)
SELECT
    depth_band,
    COUNT(*) AS exposed_properties,
    SUM(estimated_loss_2026) AS total_estimated_damage,
    ROUND(AVG(estimated_loss_2026), 2) AS mean_damage_per_property
FROM model.damage_1in30
GROUP BY depth_band
ORDER BY
    CASE depth_band
        WHEN '<150mm' THEN 1
        WHEN '150-300mm' THEN 2
        WHEN '300-600mm' THEN 3
        WHEN '600-900mm' THEN 4
        WHEN '900-1200mm' THEN 5
        WHEN '1200-2300mm' THEN 6
        WHEN '>2300mm' THEN 7
    END;

--Damage by depth band 1in100/200
SELECT
    depth_band,
    COUNT(*) AS exposed_properties,
    SUM(estimated_loss_2026) AS total_estimated_damage,
    ROUND(AVG(estimated_loss_2026), 2) AS mean_damage_per_property
FROM model.damage_1in100_200
GROUP BY depth_band
ORDER BY
    CASE depth_band
        WHEN '<150mm' THEN 1
        WHEN '150-300mm' THEN 2
        WHEN '300-600mm' THEN 3
        WHEN '600-900mm' THEN 4
        WHEN '900-1200mm' THEN 5
        WHEN '1200-2300mm' THEN 6
        WHEN '>2300mm' THEN 7
    END;

-- Damage by borough
SELECT
    COALESCE(a.borough_name, b.borough_name) AS borough_name,

    COALESCE(a.exposed_properties, 0) AS properties_1in30,
    COALESCE(a.total_estimated_damage, 0) AS damage_1in30,

    COALESCE(b.exposed_properties, 0) AS properties_1in100_200,
    COALESCE(b.total_estimated_damage, 0) AS damage_1in100_200

FROM (
    SELECT
        borough_name,
        COUNT(*) AS exposed_properties,
        SUM(estimated_loss_2026) AS total_estimated_damage
    FROM model.damage_1in30
    GROUP BY borough_name
) AS a

FULL OUTER JOIN (
    SELECT
        borough_name,
        COUNT(*) AS exposed_properties,
        SUM(estimated_loss_2026) AS total_estimated_damage
    FROM model.damage_1in100_200
    GROUP BY borough_name
) AS b

    ON a.borough_name = b.borough_name

ORDER BY damage_1in100_200 DESC;

--FINAL CHECKS

-- Nulls in the final damage tables
SELECT
    '1-in-30' AS scenario,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE building_id IS NULL
           OR uprn IS NULL
           OR depth_band IS NULL
           OR borough_name IS NULL
           OR estimated_loss_2026 IS NULL
    ) AS records_with_nulls
FROM model.damage_1in30

UNION ALL

SELECT
    '1-in-100/200' AS scenario,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE building_id IS NULL
           OR uprn IS NULL
           OR depth_band IS NULL
           OR borough_name IS NULL
           OR estimated_loss_2026 IS NULL
    ) AS records_with_nulls
FROM model.damage_1in100_200;

-- Each of the seven depth bands has exactly one vulnerability record
SELECT
    depth_band,
    COUNT(*) AS vulnerability_records
FROM model.vulnerability
GROUP BY depth_band
ORDER BY
    CASE depth_band
        WHEN '<150mm' THEN 1
        WHEN '150-300mm' THEN 2
        WHEN '300-600mm' THEN 3
        WHEN '600-900mm' THEN 4
        WHEN '900-1200mm' THEN 5
        WHEN '1200-2300mm' THEN 6
        WHEN '>2300mm' THEN 7
    END;

--MAKE TABLES FOR QGIS MAPS

CREATE TABLE model.map_damage_1in30 AS
SELECT
    b.id AS borough_id,
    b.name AS borough_name,
    b.gss_code,
    b.geom,
    COUNT(d.uprn) AS exposed_properties,
    SUM(d.estimated_loss_2026) AS total_estimated_damage
FROM model.boroughs AS b
LEFT JOIN model.damage_1in30 AS d
    ON b.gss_code = d.borough_gss_code
GROUP BY
    b.id,
    b.name,
    b.gss_code,
    b.geom;

CREATE INDEX map_damage_1in30_geom_idx ON model.map_damage_1in30 USING GIST (geom);

CREATE TABLE model.map_damage_1in100_200 AS
SELECT
    b.id AS borough_id,
    b.name AS borough_name,
    b.gss_code,
    b.geom,
    COUNT(d.uprn) AS exposed_properties,
    SUM(d.estimated_loss_2026) AS total_estimated_damage
FROM model.boroughs AS b
LEFT JOIN model.damage_1in100_200 AS d
    ON b.gss_code = d.borough_gss_code
GROUP BY
    b.id,
    b.name,
    b.gss_code,
    b.geom;

CREATE INDEX map_damage_1in100_200_geom_idx ON model.map_damage_1in100_200 USING GIST (geom);

SELECT
    '1-in-30' AS scenario,
    COUNT(*) AS boroughs,
    SUM(exposed_properties) AS exposed_properties,
    SUM(total_estimated_damage) AS total_damage
FROM model.map_damage_1in30

UNION ALL

SELECT
    '1-in-100/200' AS scenario,
    COUNT(*) AS boroughs,
    SUM(exposed_properties) AS exposed_properties,
    SUM(total_estimated_damage) AS total_damage
FROM model.map_damage_1in100_200;