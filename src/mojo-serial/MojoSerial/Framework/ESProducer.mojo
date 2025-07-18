from MojoSerial.Framework.EventSetup import EventSetup

trait ESProducer(Defaultable):
    fn produce(mut self, eventSetup: EventSetup):
        ...