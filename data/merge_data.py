import os
import csv
import zipfile
import pandas as pd
from pathlib import Path

def process_archives_to_csv(path):
    """
    Extracts CSV files from zip archives and merges them into a single CSV file.
    
    Args:
        path (str): The path to a directory containing zip files with CSVs inside.
    
    Returns:
        tuple: Lists of processed zip files and extracted CSV files for cleanup.
    """
    # Track files for later cleanup
    processed_zip_files = []
    extracted_csv_files = []
    
    # Create lists of files in the directory
    files_list = os.listdir(path)
    
    # Filter to only include zip files
    zip_files = [f for f in files_list if f.endswith('.zip')]
    
    # Path for the output file
    output_path = Path(path) / 'merged_data.csv'
    
    # Extract all CSV files from zip archives
    for zip_file in sorted(zip_files):
        zip_path = Path(path) / zip_file
        processed_zip_files.append(str(zip_path))
        
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            # Extract only CSV files
            csv_in_zip = [f for f in zip_ref.namelist() if f.endswith('.csv')]
            for csv_file in csv_in_zip:
                zip_ref.extract(csv_file, path)
                extracted_csv_files.append(str(Path(path) / csv_file))
    
    # Find all extracted CSV files in the directory
    all_csv_files = [str(Path(path) / f) for f in os.listdir(path) if f.endswith('.csv')]
    
    # Merge CSV files into a single CSV
    if all_csv_files:
        # Initialize a flag to track if this is the first file (to include headers)
        is_first_file = True
        
        # Open the output file
        with open(output_path, 'w', newline='') as output_file:
            for csv_file in sorted(all_csv_files):
                with open(csv_file, 'r', newline='') as input_file:
                    reader = csv.reader(input_file)
                    writer = csv.writer(output_file)
                    
                    # For the first file, include the header
                    if is_first_file:
                        for row in reader:
                            writer.writerow(row)
                        is_first_file = False
                    else:
                        # For subsequent files, skip the header
                        next(reader, None)  # Skip header
                        for row in reader:
                            writer.writerow(row)
    
    print(f"Created merged CSV at {output_path}")
    print(f"Processed {len(processed_zip_files)} zip files and {len(all_csv_files)} CSV files")
    
    return processed_zip_files, extracted_csv_files

def cleanup_files(files_to_remove):
    """
    Removes the specified files from the filesystem.
    
    Args:
        files_to_remove (list): List of file paths to remove.
    """
    removed_count = 0
    for file_path in files_to_remove:
        try:
            os.remove(file_path)
            removed_count += 1
        except Exception as e:
            print(f"Error removing {file_path}: {e}")
    
    print(f"Removed {removed_count} files during cleanup")

def main():
    """Main function that orchestrates the entire process."""
    path = os.getcwd()  # You can specify your own path here
    
    # Process zip files and create merged CSV
    zip_files, csv_files = process_archives_to_csv(path)
    
    # Clean up temporary files
    all_files_to_remove = zip_files + csv_files
    cleanup_files(all_files_to_remove)
    
    print("Process completed successfully!")

if __name__ == '__main__':
    main()