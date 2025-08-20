from MojoSerial.Framework.ESPluginFactory import fwkEventSetupModule
from MojoSerial.Framework.PluginFactory import fwkModule

from MojoSerial.PluginSiPixelRecHits.PixelCPEFastESProducer import (
    PixelCPEFastESProducer,
)


fn init(
    mut esreg: MojoSerial.Framework.ESPluginFactory.Registry,
    mut edreg: MojoSerial.Framework.PluginFactory.Registry,
):
    fwkEventSetupModule[PixelCPEFastESProducer](esreg)
    fwkModule[SiPixelRecHitCUDA](edreg)
