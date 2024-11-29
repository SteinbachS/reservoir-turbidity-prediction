
## Code for value extraction from C2RCC processed data and conversion to turbidity in NTU

# Load necessary libraries
library(terra)
library(raster)
library(lubridate)
library(dplyr)
library(stringr)

# Set working directory and temporary directory
rasterOptions(tmpdir = tempdir())  # Use a system temporary directory
path <- "/path/C2RCC"  # Default path for input files
setwd(path)

# Read point locations
loc <- vect("/path/Points.shp") # Insert points for which the data should be extracted

# Read Sentinel-2 images; corrected bands are stored in layers 9-14
dlist <- dir(path, pattern = ".dim$", recursive = TRUE)
# Recursive allows to search in subfolders, but adds the subfolder to the output

# Extract dates from file names and order files by date
dates <- substr(dlist, 31, 38) # adjust to 
dates_df <- data.frame(Dates = dates, Index = 1:length(dates))
order_dates <- dates_df[order(dates_df$Dates), ]
dlist <- dlist[order_dates$Index]

# Construct full file paths
dfiles <- file.path(path, dlist)

# Create empty list to store raster stacks
bilder <- list()

# Read and process raster files
for (i in seq_along(dfiles)) {
  raster_stack <- stack(read.dim(dfiles[i]))  # Read .dim file as raster stack
  raster_stack[raster_stack == 0] <- NA      # Replace 0 values with NA
  bilder[[i]] <- raster_stack                # Store in list
}

# Extract values for each raster at reservoir locations
extracted_values <- list()
for (i in seq_along(bilder)) {
  extracted_values[[i]] <- raster::extract(bilder[[i]], loc, buffer = 15, fun = mean) # use buffer to increase robustness
}

# Combine extracted values into a single data frame
values_df <- as.data.frame(extracted_values)
values_T <- as.data.frame(t(values_df))  # Transpose to have rows as observations

# Convert 0 to NA
is.na(values_T) <- !values_T

# Add metadata (dates and IOP names)
IOP <- rep("btot", times = nrow(values_T))  # Add placeholder for IOP
values_T$Date <- as.Date(dates, "%Y%m%d")   # Add extracted dates
values_T$IOP <- IOP

# Set column names for reservoir IDs
colnames(values_T)[1:(ncol(values_T) - 2)] <- unique(loc$ID)  # Reservoir IDs
rownames(values_T) <- NULL  # Remove row names

# Write combined raw data to a single CSV file
output_file <- file.path(path, "c2rcc_values_combined_buffer15m.csv")
write.csv(values_T, output_file, row.names = FALSE)


# Load the combined data and convert to NTU
df <- read.csv(output_file)
df <- subset(df, select = -c(IOP))  # Remove the IOP column if it exists
df_NTU <- df %>%
  mutate(across(1:(ncol(df) - 1), ~ 0.66 * (. ^ 1.13)))  # Convert to NTU using equation; default for Sentinel-2 is ~ 1.06 * (. ^ 0.942)))

# Add NTU suffix to column names for clarity
colnames(df_NTU)[1:(ncol(df_NTU) - 1)] <- paste0(colnames(df_NTU)[1:(ncol(df_NTU) - 1)], "_NTU")

# Save the NTU data to a separate CSV file
output_file_ntu <- file.path(path, "c2rcc_values_NTU_buffer15m.csv")
write.csv(df_NTU, output_file_ntu, row.names = FALSE)

