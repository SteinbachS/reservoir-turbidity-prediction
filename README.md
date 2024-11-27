# reservoir-turbidity-prediction
Code for predicting turbidity dynamics in small reservoirs in central Kenya using Sentinel-2 1C data and machine learning.

Stefanie Steinbach  
s.steinbach@utwente.nl; stefanie.steinbach@rub.de

This repository contains the code used for the paper titled "Predicting turbidity dynamics in small reservoirs in central Kenya using remote sensing and machine learning." The provided script uses Python and specific packages installed in a Conda environment for processing and analysis. Credit for Python support to: Torben Dedring

# Preparing Ancillary Data

C2RCC can use default configuration for the retrieval of Inherent Optical Properties (IOPs) or select them from ancillary data

# Run C2RCC on Server

### Software and Tools
1. **Python**: Version 3.6.13 (managed using [Anaconda](https://www.anaconda.com/)).
2. **Conda environment**: The required environment can be created and activated using Anaconda.
3. **Remote access software**: To run the script on a server, a we used [MobaXTerm](https://mobaxterm.mobatek.net/).

### Dependencies
The required Python libraries are installed via the Conda environment (see below).

### Step 1: Configure the Conda Environment with [ESA snappy](https://github.com/senbox-org/esa-snappy)
1. Install Anaconda, c.f. [here](https://docs.anaconda.com/anaconda/install/).
2. Create an environment called SNAP using the instructions in [this video](https://www.youtube.com/watch?v=14YM1kKdgA8)

### Step 2: Activate the Environment from Server
   ```bash
   conda activate /path/to/conda/SNAP
```
### Step 3: Run the Script
   ```bash
   python /path/to/C2RCC_Server.py
```

### Step 4: Extract Values for AOIs
Once the btot files are created, they can be moved to a local machine and the values for the respective AOI(s) extracted, e.g., using a shapefile in R, and saved in table format.


# Apply Machine Learning to Model Turbidity Outcomes

### Software and Tools
1. **Python**: Version 3.6.13 (managed using [Anaconda](https://www.anaconda.com/)).
2. **Conda environment**: The required environment can be created and activated using Anaconda.
3. **Remote access software**: To run the script on a server, a we used [MobaXTerm](https://mobaxterm.mobatek.net/).

### Dependencies
The required Python libraries are installed via the Conda environment (see below).

### Step 1: Configure the Conda Environment with [ESA snappy](https://github.com/senbox-org/esa-snappy)
1. Install Anaconda, c.f. [here](https://docs.anaconda.com/anaconda/install/).
2. Create an environment called SNAP using the instructions in [this video](https://www.youtube.com/watch?v=14YM1kKdgA8)

### Step 2: Activate the Environment from Server
   ```bash
   conda activate /path/to/conda/SNAP
```
### Step 3: Run the Script
   ```bash
   python /path/to/C2RCC_Server.py
```
