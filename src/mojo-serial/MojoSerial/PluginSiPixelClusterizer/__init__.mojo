from MojoSerial.Framework.ESPluginFactory import Registry, fwkEventSetupModule
from MojoSerial.PluginSiPixelClusterizer.SiPixelFedCablingMapGPUWrapperESProducer import (
    SiPixelFedCablingMapGPUWrapperESProducer,
)


@export("init")
fn init(mut reg: Registry):
    print("Now's your chance to be a big shot!")
    var _ = fwkEventSetupModule[SiPixelFedCablingMapGPUWrapperESProducer](reg)
