# -*- coding: utf-8 -*-
"""
Code to apply the C2RCC processor for inherent optical property (IOP) retrieval and
calculation of the IOP btot, for a folder with Sentinel-2 1C images that were geographically 
subset to an AOI and all bands resampled to 10 m spatial resolution in ESA SNAP

"""
import numpy as np
import snappy
from snappy import GPF
from snappy import HashMap
from snappy import ProductIO
from snappy import jpy
import pandas as pd
import os
import time
import rasterio
from rasterio.transform import from_origin

path = "..." # Insert path to source files
out_path = "..." # Insert path to output folder
dim_files = []
for file in os.listdir(path):
    if file.endswith('.dim'):
        dim_files.append(file)

for idx, file in enumerate(dim_files):
    start_time = time.time()
    print("#############################################")
    print(f"\nProcessing file {idx+1} of {len(dim_files)}")
    name = file.split('.')[0]
    input_file = os.path.join(path, file)
    
    #Load Excel data with ancillary data
    file_path = input_file.split('.')[0]
    excel = pd.read_csv(file_path+'.csv', header=None, names=['Property', 'Value'], index_col=0)
    print("\nUsing the following Parameters:")
    for i, row in excel.iterrows():
        unique_id = i
        value = row['Value']
        print(f"{i}: {value}")
    
    # Read the input product
    source_product = ProductIO.readProduct(input_file)
    
    # Get the width and height from one of the bands
    band_index = source_product.getSceneRasterWidth()
    
    # Print the available band names to check
    #band_names = [band.getName() for band in source_product.getBands()]
    #print(f"Available band names: {band_names}")

    # Set the C2RCC parameters
    parameters = HashMap()
    parameters.put('salinity', str(excel._get_value('salinity', 'Value')))
    parameters.put('temperature', str(excel._get_value('temperature', 'Value')))
    parameters.put('ozone', str(excel._get_value('ozone', 'Value')))
    parameters.put('press', str(excel._get_value('press', 'Value')))
    parameters.put('elevation', str(excel._get_value('elevation', 'Value')))
    parameters.put('TSMfac', str(excel._get_value('TSMfac', 'Value')))
    parameters.put('TSMexp', str(excel._get_value('TSMexp', 'Value')))
    parameters.put('CHLexp', str(excel._get_value('CHLexp', 'Value')))
    parameters.put('CHLfac', str(excel._get_value('CHLfac', 'Value')))
    parameters.put('thresholdRtosaOOS', str(excel._get_value('thresholdRtosaOOS', 'Value')))
    parameters.put('thresholdAcReflecOos', str(excel._get_value('thresholdAcReflecOos', 'Value')))
    parameters.put('thresholdCloudTDown865', str(excel._get_value('thresholdCloudTDown865', 'Value')))
    parameters.put('outputAsRrs', str(excel._get_value('outputAsRrs', 'Value')))
    parameters.put('deriveRwFromPathAndTransmittance', str(excel._get_value('deriveRwFromPathAndTransmittance', 'Value')))
    parameters.put('outputRtoa', str(excel._get_value('outputRtoa', 'Value')))
    parameters.put('outputRtosaGc', str(excel._get_value('outputRtosaGc', 'Value')))
    parameters.put('outputRtosaGcAann', str(excel._get_value('outputRtosaGcAann', 'Value')))
    parameters.put('outputRpath', str(excel._get_value('outputRpath', 'Value')))
    parameters.put('outputTdown', str(excel._get_value('outputTdown', 'Value')))
    parameters.put('outputTup', str(excel._get_value('outputTup', 'Value')))
    parameters.put('outputAcReflectance', str(excel._get_value('outputAcReflectance', 'Value')))
    parameters.put('outputRhown', str(excel._get_value('outputRhown', 'Value')))
    parameters.put('outputOos', str(excel._get_value('outputOos', 'Value')))
    parameters.put('outputKd', str(excel._get_value('outputKd', 'Value')))
    parameters.put('outputUncertainties', str(excel._get_value('outputUncertainties', 'Value')))
    parameters.put('netSet', str(excel._get_value('netSet', 'Value')))

    # Apply the C2RCC processor
    c2rcc_product = GPF.createProduct('c2rcc.msi', parameters, source_product)
    
    # Extract Bands
    parameters = HashMap()
    parameters.put('sourceBands', 'iop_bwit,iop_bpart')
    c2rcc_band = GPF.createProduct('BandSelect', parameters, c2rcc_product)
    
    # Band Maths to create btot, which is the IOP used to derive turbidity, from bwit and bpart
    expression = 'iop_bwit + iop_bpart' #expression takes the average of all filtered bands
    GPF.getDefaultInstance().getOperatorSpiRegistry().loadOperatorSpis()
    def bandMathsProduct(product):
        BandDescriptor = jpy.get_type('org.esa.snap.core.gpf.common.BandMathsOp$BandDescriptor')
        targetBand = BandDescriptor()
        targetBand.name = 'iop_btot'
        targetBand.type = 'float32'
        targetBand.expression = expression
        targetBands = jpy.array('org.esa.snap.core.gpf.common.BandMathsOp$BandDescriptor', 1)
        targetBands[0] = targetBand
        parameters.put('targetBands', targetBands)
        parameters.put('NoDataValue', 'NaN')
        return GPF.createProduct('BandMaths', parameters, product)
    
    iop_btot = bandMathsProduct(c2rcc_band)
    
    # Write the output product
    ProductIO.writeProduct(c2rcc_band, out_path + name + '_C2RCC_Bands', 'BEAM-DIMAP')
    ProductIO.writeProduct(c2rcc_product, out_path + name + '_C2RCC', 'BEAM-DIMAP')
    ProductIO.writeProduct(iop_btot, out_path + name + '_C2RCC_iop_btot', 'BEAM-DIMAP')
    
    c2rcc_product.closeIO()
    c2rcc_band.closeIO()

    # Print elapsed time for the current iteration
    end_time = time.time()

    elapsed_time_seconds = end_time - start_time

    print("Elapsed time: " + time.strftime("%H:%M:%S.{}".format(str(elapsed_time_seconds % 1)[2:])[:15], time.gmtime(elapsed_time_seconds)))
    
print("\nDone")