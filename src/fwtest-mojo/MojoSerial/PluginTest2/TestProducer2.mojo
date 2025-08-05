from MojoSerial.Framework.EDProducer import EDProducer
from MojoSerial.Framework.EDGetToken import EDGetTokenT
from MojoSerial.Framework.EventSetup import EventSetup
from MojoSerial.Framework.ProductRegistry import ProductRegistry
from MojoSerial.Framework.Event import Event
from MojoSerial.MojoBridge.DTypes import Typeable, TypeableUInt


var __nevents: Int = 0


struct TestProducer2(Defaultable, EDProducer, Typeable):
    var _getToken: EDGetTokenT[TypeableUInt]

    fn __init__(out self):
        self._getToken = EDGetTokenT[TypeableUInt]()

    fn __init__(out self, mut reg: ProductRegistry):
        try:
            self._getToken = reg.consumes[TypeableUInt]()
        except e:
            print("Error occurred in PluginTest2/TestProducer2.mojo, ", e)
            return Self()

    fn produce(mut self, mut event: Event, eventSetup: EventSetup):
        var value = event.get[TypeableUInt](self._getToken).val
        debug_assert(
            value == UInt(event.eventID() + 10 * event.streamID() + 100)
        )
        __nevents += 1
        print(
            "TestProducer2::produce Event ",
            event.eventID(),
            " stream ",
            event.streamID(),
            sep="",
        )

    @always_inline
    @staticmethod
    fn dtype() -> String:
        return "TestProducer2"

    fn endJob(mut self):
        print("TestProducer2::endJob processed ", __nevents, " events", sep="")
