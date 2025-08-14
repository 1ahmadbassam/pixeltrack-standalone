from MojoSerial.Framework.ESPluginFactory import fwkEventSetupModule
from MojoSerial.PluginSiPixelRecHits.PixelCPEFastESProducer import (
    PixelCPEFastESProducer,
)


fn init(
    mut esreg: MojoSerial.Framework.ESPluginFactory.Registry,
    mut edreg: MojoSerial.Framework.PluginFactory.Registry,
):
    fwkEventSetupModule[PixelCPEFastESProducer](esreg)
