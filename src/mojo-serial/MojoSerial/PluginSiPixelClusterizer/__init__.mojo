from MojoSerial.Framework.ESPluginFactory import fwkEventSetupModule
#from MojoSerial.Framework.PluginFactory import fwkModule
from MojoSerial.PluginSiPixelClusterizer.SiPixelFedCablingMapGPUWrapperESProducer import (
    SiPixelFedCablingMapGPUWrapperESProducer,
)
from MojoSerial.PluginSiPixelClusterizer.SiPixelGainCalibrationForHLTGPUESProducer import SiPixelGainCalibrationForHLTGPUESProducer
from MojoSerial.PluginSiPixelClusterizer.SiPixelRawToClusterCUDA import SiPixelRawToClusterCUDA

fn init():
    fwkEventSetupModule[SiPixelFedCablingMapGPUWrapperESProducer]()
    fwkEventSetupModule[SiPixelGainCalibrationForHLTGPUESProducer]()
    #fwkModule[SiPixelRawToClusterCUDA]()
