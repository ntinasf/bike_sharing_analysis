# Dataset Information

This directory contains scripts to process the bike-sharing data.

## Data Source
The original data can be downloaded from [Divvy Trip Data](https://divvy-tripdata.s3.amazonaws.com/index.html).

## Data Processing
1. Download the monthly data files from July 2023 to June 2024
2. Run `merge_data.py` to combine them into a unified dataset
3. The unified dataset is approximately 1GB and should be uploaded to Google Cloud Storage
4. Use `../sql/data_cleaning.sql` to clean and transform the data in BigQuery