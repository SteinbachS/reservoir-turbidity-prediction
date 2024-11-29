
## Code to automate CSV file creation as input data for Sentinel-2 C2RCC server processing

## Libraries and settings
library(rgdal)
library(raster)
library(terra)
library(stringr)

# Set default paths
temp_dir <- tempdir()  # Temporary directory for processing
dim_folder <- "data/dim_files"  # Relative path for dim files
csv_folder <- "data/csv_output"  # Relative path for output CSVs

# Create output folder if it does not exist
if (!dir.exists(csv_folder)) {
  dir.create(csv_folder, recursive = TRUE)
}

## Load data
# Replace with paths to ancillary data files containing date and value
ozone <- read.csv("data/toms_omi_daily_averages.csv", sep = ";", dec = ".")
pressure <- read.csv("data/daily_averages_by_band_pressure.csv", sep = ";", dec = ".")
temp <- read.csv("data/daily_averages_by_band.csv", sep = ";", dec = ".")

## Define fixed parameters
salinity <- 0.0001
elevation <- 1791
TSMfac <- 0.66
TSMexp <- 1.13
CHLexp <- 1.04
CHLfac <- 21.0
thresholdRtosaOOS <- 0.05
thresholdAcReflecOos <- 0.1
thresholdCloudTDown865 <- 0.955
outputAsRrs <- "false"
deriveRwFromPathAndTransmittance <- "false"
outputRtoa <- "false" # output* parameters define which of the following is generated from the input image file during C2RCC processing
outputRtosaGc <- "false"
outputRtosaGcAann <- "false"
outputRpath <- "false"
outputTdown <- "false"
outputTup <- "false"
outputAcReflectance <- "false"
outputRhown <- "true"
outputOos <- "false"
outputKd <- "true"
outputUncertainties <- "true"
netSet <- "C2X-COMPLEX-Nets" # Other options: C2RCC-Nets (not recommended for inland waters), C2X-Nets

## Processing
# Pattern to match .dim files
dim_pattern <- ".*resampled.*\\.dim$"
dim_files <- list.files(path = dim_folder, pattern = dim_pattern, full.names = TRUE)

# Iterate over each .dim file
for (dim_file in dim_files) {
  # Extract date from the .dim file name - adjust to naming convention used
  date_string <- str_sub(basename(dim_file), 19, 26)
  date <- tryCatch(as.Date(date_string, format = "%Y%m%d"), error = function(e) NA)
  
  # Skip invalid dates
  if (is.na(date)) {
    cat("Invalid date format for file:", dim_file, "\n")
    next
  }
  
  # Filter and extract data for the date
  pressure$date <- as.Date(pressure$date, format = "%d.%m.%Y") # Ajust to table date format
  pressure_value <- pressure[as.Date(pressure$date) == date,]
  
  temp$date <- as.Date(temp$date, format = "%d.%m.%Y")
  temp_value <- temp[as.Date(temp$date) == date,]
  
  ozone$date <- as.Date(ozone$date, format = "%d.%m.%Y")
  ozone_value <- ozone[as.Date(ozone$date) == date,]
  
  # Check if data is available for the date
  if (nrow(pressure_value) > 0 & nrow(temp_value) > 0 & nrow(ozone_value) > 0) {
    # Create a data frame with parameters and values
    df <- data.frame(
      parameter = c(
        "salinity", "temperature", "ozone", "press", "elevation", 
        "TSMfac", "TSMexp", "CHLexp", "CHLfac", 
        "thresholdRtosaOOS", "thresholdAcReflecOos", 
        "thresholdCloudTDown865", "outputAsRrs", "deriveRwFromPathAndTransmittance", 
        "outputRtoa", "outputRtosaGc", "outputRtosaGcAann", "outputRpath", 
        "outputTdown", "outputTup", "outputAcReflectance", "outputRhown", 
        "outputOos", "outputKd", "outputUncertainties", "netSet"
      ),
      value = c(
        salinity, temp_value$air, ozone_value$ozone, pressure_value$slp, 
        elevation, TSMfac, TSMexp, CHLexp, CHLfac, 
        thresholdRtosaOOS, thresholdAcReflecOos, thresholdCloudTDown865, 
        outputAsRrs, deriveRwFromPathAndTransmittance, outputRtoa, 
        outputRtosaGc, outputRtosaGcAann, outputRpath, outputTdown, 
        outputTup, outputAcReflectance, outputRhown, outputOos, 
        outputKd, outputUncertainties, netSet
      )
    )
    
    # Create a new .csv file
    new_csv_file <- file.path(csv_folder, sub(".dim$", ".csv", basename(dim_file)))
    write.csv(df, new_csv_file, row.names = FALSE)
  } else {
    cat("No data available for date", date, "in file:", dim_file, "\n")
  }
}




