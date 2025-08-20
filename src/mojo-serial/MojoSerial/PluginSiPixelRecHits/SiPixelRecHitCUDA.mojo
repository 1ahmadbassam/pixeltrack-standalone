from MojoSerial.Framework.Event import Event
from MojoSerial.Framework.EDProducer import EDProducer
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.Framework.EDGetToken import EDGetTokenT
from MojoSerial.Framework.EDPutToken import EDPutTokenT
from MojoSerial.Framework.ProductRegistry import ProductRegistry

from MojoSerial.DataFormats.BeamSpotPOD import BeamSpotPOD
from MojoSerial.CUDADataFormats.SiPixelClustersSoA import SiPixelClustersSoA
from MojoSerial.CUDADataFormats.SiPixelDigisSoA import SiPixelDigisSoA
from MojoSerial.CondFormats.PixelCPEFast import PixelCPEFast
from MojoSerial.CUDADataFormats.TrackingRecHit2DHeterogeneous import (
    TrackingRecHit2DCPU,
)
from MojoSerial.CUDADataFormats.TrackingRecHit2DSOAView import (
    TrackingRecHit2DSOAView,
)
from MojoSerial.PluginSiPixelRecHits.PixelRecHits import (
    PixelRecHitGPUKernel,
)  # TODO : spit product from kernel
from MojoSerial.MojoBridge.DTypes import Typeable, TypeableOwnedPointer


struct SiPixelRecHitCUDA(Defaultable, EDProducer, Typeable):
    # The mess with inputs will be cleaned up when migrating to the new framework
    var tBeamSpot: EDGetTokenT[BeamSpotPOD]
    var token_: EDGetTokenT[SiPixelClustersSoA]
    var tokenDigi_: EDGetTokenT[SiPixelDigisSoA]

    var tokenHit_: EDPutTokenT[TrackingRecHit2DCPU]

    var gpuAlgo_: PixelRecHitGPUKernel

    fn __init__(out self):
        self.tBeamSpot = EDGetTokenT[BeamSpotPOD]()
        self.token_ = EDGetTokenT[SiPixelClustersSoA]()
        self.tokenDigi_ = EDGetTokenT[SiPixelDigisSoA]()
        self.tokenHit_ = EDPutTokenT[TrackingRecHit2DCPU]()

        self.gpuAlgo_ = PixelRecHitGPUKernel()

    fn __init__(out self, mut reg: ProductRegistry):
        try:
            self.tBeamSpot = reg.consumes[BeamSpotPOD]()
            self.token_ = reg.consumes[SiPixelClustersSoA]()
            self.tokenDigi_ = reg.consumes[SiPixelDigisSoA]()
            self.tokenHit_ = reg.produces[TrackingRecHit2DCPU]()
        except e:
            print("Handled exception in SiPixelRawToClusterCUDA, ", e)
            return Self()

        self.gpuAlgo_ = PixelRecHitGPUKernel()

    fn produce(mut self, mut iEvent: Event, ref es: EventSetup):
        ref clusters = iEvent.get(self.token_)
        ref digis = iEvent.get(self.tokenDigi_)
        ref bs = iEvent.get(self.tBeamSpot)

        var nHits = clusters.nClusters()

        if nHits >= TrackingRecHit2DSOAView.maxHits():
            print(
                "Clusters/Hits Overflow ",
                nHits,
                " ]= ",
                TrackingRecHit2DSOAView.maxHits(),
                sep="",
            )

        try:
            iEvent.put(
            self.tokenHit_,
            self.gpuAlgo_.makeHits(
                digis, clusters, bs, UnsafePointer(to=es.get[PixelCPEFast]().getCPUProduct())
            ),
        )
        except e:
            print("Error during produce in SiPixelRecHitCUDA, ", e)

    fn endJob(mut self):
        pass

    @staticmethod
    fn dtype() -> String:
        return "SiPixelRecHitCUDA"
