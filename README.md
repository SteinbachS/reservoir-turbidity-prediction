![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14245504.svg)
# reservoir-turbidity-prediction
Workflow and code for predicting turbidity dynamics in small reservoirs in central Kenya using Sentinel-2 1C data and machine learning as done in Steinbach, S., Bartels, A., Rienow, A., Thiong'o Kuria, B., Zwart S. & Nelson, A. Predicting turbidity dynamics in small reservoirs in central Kenya using remote sensing and machine learning. Int. J. Appl. Earth Obs. Geoinf.

[Stefanie Steinbach](www.linkedin.com/in/stefanie-steinbach-59b4b41b6)

This repository contains the workflow and main code scripts used for the paper titled "Predicting turbidity dynamics in small reservoirs in central Kenya using remote sensing and machine learning." The provided scripts use R for ancillary data processing, Python and specific packages installed in a Conda environment for turbidity modelling, and R for machine learning-based predictor selection. Credit for Python support: Torben Dedring

# Input imagery and pre-processing

Sentinel-2 1C imagery is downloaded from the [Copernicus Dataspace](https://dataspace.copernicus.eu/) and all bands resampled to 10 m spatial resolution and a spatial subset created in [ESA SNAP](https://step.esa.int/main/download/snap-download/). The 

# Prepare ancillary data

C2RCC can use default configuration for the retrieval of Inherent Optical Properties (IOPs) or select them from ancillary data. Here, we used ancillary data; NCEP-NCAR for temperature (converted to °C) and surface level pressure, CHIRPS for rainfall (mm), TOMS for ozone (DU), and the SRTM DEM for elevation (masl), all available in the [Google Earth Engine Data Catalog](https://developers.google.com/earth-engine/datasets). For each Sentinel-2 image file, a CSV file is created with the respective information from the ancillary data, salinity set to 0.0001 (minimum value which is assumed for freshwater), and the other parameters set as desired. The CSV file is named according to the respective Sentinel-2 image file, e.g., Subset_S2A_MSIL1C_20230108T074311_N0509_R092_T37MBV_20230108T092516_resampled.csv. Parameter retrieval and naming can be automated in R using [C2RCC_Ancillary_data_table_creation.R](C2RCC_Ancillary_data_table_creation.R).

| Parameter                  | Value         |
|----------------------------|---------------|
| salinity                  | 1e-04         |
| temperature               | 25.1624798    |
| ozone                     | 260.4819619   |
| press                     | 1010.258063   |
| elevation                 | 1791          |
| TSMfac                    | 0.66          |
| TSMexp                    | 1.13          |
| CHLexp                    | 1.04          |
| CHLfac                    | 21            |
| thresholdRtosaOOS         | 0.05          |
| thresholdAcReflecOos      | 0.1           |
| thresholdCloudTDown865    | 0.955         |
| outputAsRrs               | false         |
| deriveRwFromPathAndTransmittance | false   |
| outputRtoa                | false         |
| outputRtosaGc             | false         |
| outputRtosaGcAann         | false         |
| outputRpath               | false         |
| outputTdown               | false         |
| outputTup                 | false         |
| outputAcReflectance       | false         |
| outputRhown               | true          |
| outputOos                 | false         |
| outputKd                  | true          |
| outputUncertainties       | true          |
| netSet                    | C2X-COMPLEX-Nets |

Move all image and CSV files to a server folder for subsequent automatic processing.

# Run C2RCC on server

### Software and Tools
1. **Python**: Version 3.6.13 (managed using [Anaconda](https://www.anaconda.com/)).
2. **Conda environment**: The required environment can be created and activated using Anaconda.
3. **Remote access software**: To run the script on a server, a we used [MobaXTerm](https://mobaxterm.mobatek.net/).

### Dependencies
The required Python libraries are installed via the Conda environment (see below).

### Step 1: Configure the Conda environment with [ESA snappy](https://github.com/senbox-org/esa-snappy)
1. Install Anaconda, c.f. [here](https://docs.anaconda.com/anaconda/install/).
2. Create an environment called SNAP using the instructions in [this video](https://www.youtube.com/watch?v=14YM1kKdgA8)
3. Transfer the Python script to server [C2RCC_Server.py](C2RCC_Server.py)

### Step 2: Activate the environment from server
   ```bash
   conda activate /path/to/conda/SNAP
```
### Step 3: Run the script
   ```bash
   python /path/to/C2RCC_Server.py
```

# Extract values for AOIs
Once the btot files are created, they can be moved to the local machine and the values for the respective AOI(s) extracted, e.g., using a shapefile in R, and saved in table format as shown in the script [Value_extraction_from_dim_file.R](Value_extraction_from_dim_file.R). This script writes the raw values to CSV file. For the analysis conducted in the study, monthly and overall averages were used which can be created based on the raw dataframe, if needed. Requirements, such as a minimum number of valid observations per month or period can also be defined.

# Add predictor data

Predictors are added to the dataframe. We used meteorological, land cover, land management, surface water, and topographic predictors. All predictors used here can be created and downloaded in the Google Earth Engine (refer to the article named above). Wetland Use Intensity as a land management predictor can be calculated in the Google Earth Engine following the scripts published in Steinbach, S., Hentschel, E., Hentze, K., Rienow, A., Umulisa, V., Zwart, S.J., Nelson, A., 2023. Automatization and evaluation of a remote sensing-based indicator for wetland health assessment in East Africa on national and local scales. Ecological Informatics 75, 102032. [https://doi.org/10.1016/j.ecoinf.2023.102032](https://doi.org/10.1016/j.ecoinf.2023.102032).

# Apply machine learning to model turbidity outcomes

Use Random Forest and XGBoost, recursive feature selection, and hyperparameter tuning to optimize models and extract predictor importances using [ML_Turbidity_prediction.R](ML_Turbidity_prediction.R).

