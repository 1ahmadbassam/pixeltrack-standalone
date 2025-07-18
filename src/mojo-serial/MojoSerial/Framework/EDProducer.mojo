from MojoSerial.Framework.Event import Event
from MojoSerial.Framework.EventSetup import EventSetup

trait EDProducer(Defaultable):
    fn produce(self, mut event: Event, eventSetup: EventSetup):
        ...
    fn endJob(self):
        ...