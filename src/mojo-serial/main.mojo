from pathlib import Path

from MojoSerial.Bin.EventProcessor import EventProcessor


fn main() raises:
    var warmupEvents = 10
    var maxEvents = 1000
    var path = Path("data")
    var validation = False

    if not path.exists():
        print("Data directory '", path, "' does not exist", sep="")
        return

    ## Init plugins manually
    MojoSerial.PluginSiPixelClusterizer.init()

    var processor = EventProcessor(warmupEvents, maxEvents, path, validation)
    print("Processing ", processor.maxEvents(), " events", sep="", end="")
    if warmupEvents > 0:
        print(", after ", warmupEvents, " events of warm up", sep="", end="")
    print(".")

    processor.warmUp()
    processor.runToCompletion()
    processor.endJob()

    print("Processed ", processor.processedEvents(), " events.", sep="")
