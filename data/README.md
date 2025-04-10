# Dataset Information

This directory contains scripts to process the bike-sharing data.

## Data Source
The original data can be downloaded from [Divvy Trip Data](https://divvy-tripdata.s3.amazonaws.com/index.html).  
These are open source data made available under this [license](https://divvybikes.com/data-license-agreement).

## Data Processing
1. Download the monthly data files from January 2024 to December 2024
2. Run `merge_data.py` to combine them into a unified dataset
3. The unified dataset is approximately 1GB and should be uploaded to Google Cloud Storage
4. Use `../sql/data_cleaning.sql` to clean and transform the data in BigQuery