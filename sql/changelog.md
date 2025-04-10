## Changelog
This file contains notable changes made during data cleaning.

Version 1.0 (2024-04-10)

### Changes to the original data table "rides"
* Deleted 7232 rows with missing spatial information and strange ride durations.
* Coordinate values rounded to four decimal places to avoid grouping inconsistencies.

### New
* Added table "dim_station" which contains information about docking stations.
* Added table “fact_rides” whick contains ride information for rides with duration between 2 and 600 minutes in a clean format.
* Added table "outlier" which contains the rest of the rides, created directly from "fact_rides" table.