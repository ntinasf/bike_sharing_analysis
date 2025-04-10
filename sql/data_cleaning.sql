--------------------------------------------------------------------------------------------

-- Schema of the initial table that contains all data 
-- The name of the table is 'rides'
CREATE TABLE `bike_rides.rides`
(
  ride_id STRING,
  rideable_type STRING,
  started_at TIMESTAMP,
  ended_at TIMESTAMP,
  start_station_name STRING,
  start_station_id STRING,
  end_station_name STRING,
  end_station_id STRING,
  start_lat FLOAT64,
  start_lng FLOAT64,
  end_lat FLOAT64,
  end_lng FLOAT64,
  member_casual STRING
);

-- Take a quick look at the data
SELECT *
FROM bike_rides.rides
LIMIT 10;
-- There are 5,860,568 rows in this table. 

-- Check string variables for duplicates, nulls or spelling errors
SELECT  COUNT(*)
FROM bike_rides.rides
WHERE ride_id IS NULL;

SELECT  COUNT(*)
FROM bike_rides.rides
WHERE rideable_type IS NULL;

SELECT  COUNT(*)
FROM bike_rides.rides
WHERE member_casual IS NULL;
-- Everything is fine

-- Chech time values for nulls
SELECT  COUNT(*)
FROM bike_rides.rides
WHERE (started_at IS NULL) OR (ended_at IS NULL);
-- No nulls found

-- Check if dates are inside bounds
SELECT 
  MIN(DATE(started_at)),
  MAX(DATE(started_at)),
  MIN(DATE(ended_at)),
  MAX(DATE(ended_at))
FROM bike_rides.rides;
-- Everything fine

-- Check station coordinates for nulls
SELECT COUNT(*)
FROM bike_rides.rides
WHERE (start_lat IS NULL) OR (start_lng IS NULL) OR (end_lat IS NULL) OR (end_lng IS NULL);
-- There are 7232 rows with nulls values. By further inspection, we see that the missing values come 
-- only from the end stations' coordinates

-- This might be an indication of something going wrong with these rides, and it would be better to omit them
DELETE
FROM bike_rides.rides
WHERE (end_lat IS NULL) OR (end_lng IS NULL) ;
-- 7232 rows were deleted

-- Check station names for nulls
SELECT 
  COUNT(*)
FROM bike_rides.rides
WHERE (start_station_name IS NULL) OR (end_station_name IS NULL);
-- there are 1645027 rows with at least one null value in the station names, an indication of rides 
-- starting or ending away from a docking station

-- Round coordinate values without losing spatial information
UPDATE bike_rides.rides
SET start_lat = ROUND(start_lat, 4)
WHERE true;

UPDATE bike_rides.rides
SET end_lat = ROUND(end_lat, 4)
WHERE true;

UPDATE bike_rides.rides
SET start_lng = ROUND(start_lng, 4)
WHERE true;

UPDATE bike_rides.rides
SET end_lng = ROUND(end_lng, 4)
WHERE true;

-- Check for duplicates in station names
SELECT COUNT(*)
FROM (SELECT start_station_id
  FROM bike_rides.rides
  GROUP BY start_station_id
  HAVING COUNT (DISTINCT start_station_name)  > 1);

SELECT COUNT(*)
FROM (SELECT end_station_id
  FROM bike_rides.rides
  GROUP BY end_station_id
  HAVING COUNT (DISTINCT end_station_name)  > 1);
-- There are at least 95 station ids that correspond to more than one station names

-- Check for duplicates in station ids
SELECT COUNT(*)
FROM (SELECT start_station_name
FROM bike_rides.rides
GROUP BY start_station_name
HAVING COUNT (DISTINCT start_station_id)  > 1);

SELECT COUNT(*)
FROM (
  SELECT end_station_name
  FROM bike_rides.rides
  GROUP BY end_station_name
  HAVING COUNT (DISTINCT end_station_id)  > 1);
-- There are at least 49 station names that have more than one station ids

-- Low traffic stations
SELECT COUNT(*) AS low_traffic_station_count
FROM (
  SELECT station_id
  FROM (
    -- Combine start and end stations
    SELECT 
      start_station_id AS station_id, 
      COUNT(*) AS ride_count
    FROM bike_rides.rides
    WHERE start_station_id IS NOT NULL
    GROUP BY start_station_id
    
    UNION ALL
    
    SELECT 
      end_station_id AS station_id, 
      COUNT(*) AS ride_count
    FROM bike_rides.rides
    WHERE end_station_id IS NOT NULL
    GROUP BY end_station_id
  )
  GROUP BY station_id
  HAVING SUM(ride_count) <= 20);

-- New table dim_station
-- Create a table that includes the stations with over 20 rides, which also mitigates the duplicates issue
CREATE OR REPLACE TABLE bike_rides.dim_station AS
WITH station_traffic AS (
  SELECT  -- Temp table which contains stations with over 20 rides
    station_id, 
    SUM(ride_count) AS total_rides
  FROM (
    SELECT -- Count rides starting at each station
      start_station_id AS station_id, 
      COUNT(*) AS ride_count
    FROM bike_rides.rides
    WHERE start_station_id IS NOT NULL
    GROUP BY start_station_id
    
    UNION ALL
    
    SELECT  -- Count rides ending at each station
      end_station_id AS station_id, 
      COUNT(*) AS ride_count
    FROM bike_rides.rides
    WHERE end_station_id IS NOT NULL
    GROUP BY end_station_id
  )
  GROUP BY station_id
  HAVING SUM(ride_count) >= 20 
),
station_info AS (
  SELECT  -- Second temp table with distinct station information
    start_station_id AS station_id,
    start_station_name AS station_name,
    start_lat AS latitude,
    start_lng AS longitude
  FROM bike_rides.rides
  WHERE start_station_id IS NOT NULL
  
  UNION ALL
  
  SELECT 
    end_station_id AS station_id,
    end_station_name AS station_name,
    end_lat AS latitude,
    end_lng AS longitude
  FROM bike_rides.rides
  WHERE end_station_id IS NOT NULL
)
SELECT --Combine the new temp tables into one
  s.station_id,
  MAX(s.station_name) AS station_name,  -- Take the most common name if there are variants
  ROUND(AVG(s.latitude), 4) AS latitude,  -- Average coordinates if slightly different
  ROUND(AVG(s.longitude), 4) AS longitude
FROM station_info s
JOIN station_traffic st ON s.station_id = st.station_id
GROUP BY s.station_id, st.total_rides;

-- New table fact_rides
-- Contains the main ride data that we will keep for our analysis
CREATE OR REPLACE TABLE bike_rides.rides AS
SELECT
    ride_id,
    EXTRACT(DATE FROM started_at) AS date,
    TIME_TRUNC(EXTRACT(TIME FROM started_at), MINUTE) AS start_time,
    DATETIME_DIFF(ended_at, started_at, MINUTE) AS ride_duration_min,
    rideable_type,
    member_casual,
    start_station_id,
    end_station_id,
    start_lat,
    start_lng,
    end_lat,
    end_lng
FROM bike_rides.rides ;

--New table outliers
-- Contains rides with duration larger than 600 min and smaller than 2 min, 
-- which won't be used in our analysis
CREATE OR REPLACE TABLE bike_rides.outliers AS
SELECT *
FROM bike_rides.fact_rides
WHERE (ride_duration_min < 2) OR (ride_duration_min > 600);

-- Delete the outliers from the fact_rides table
DELETE
FROM bike_rides.fact_rides
WHERE (ride_duration_min < 2) OR (ride_duration_min > 600);
-- 246,150 rows have been deleted