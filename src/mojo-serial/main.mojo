from time import perf_counter_ns
from pathlib import Path

from MojoSerial.Bin.EventProcessor import EventProcessor
from MojoSerial.Bin.PosixClockGettime import (
    PosixClockGettime,
    CLOCK_PROCESS_CPUTIME_ID,
)
from MojoSerial.MojoBridge.DTypes import Double


fn main() raises:
    var warmupEvents = 100
    var maxEvents = 0
    var runForMinutes = 10
    var path = Path("data")
    var validation = False

    if not path.exists():
        print("Data directory '", path, "' does not exist", sep="")
        return

    ## Init plugins manually
    var _esreg = MojoSerial.Framework.ESPluginFactory.Registry()
    var _edreg = MojoSerial.Framework.PluginFactory.Registry()
    MojoSerial.PluginSiPixelClusterizer.init(_esreg, _edreg)

    var processor = EventProcessor(
        warmupEvents, maxEvents, runForMinutes, path, validation, _esreg, _edreg
    )
    if runForMinutes < 0:
        print("Processing", processor.maxEvents(), "events,", end="")
    else:
        print("Processing for about", runForMinutes, "minutes,", end="")
    if warmupEvents > 0:
        print(" after", warmupEvents, "events of warm up", end="")
    print(" with 1 concurrent events and 1 threads.")

    processor.warmUp()
    var cpu_start = PosixClockGettime[CLOCK_PROCESS_CPUTIME_ID].now()
    var start = perf_counter_ns()
    processor.runToCompletion()
    var cpu_stop = PosixClockGettime[CLOCK_PROCESS_CPUTIME_ID].now()
    var stop = perf_counter_ns()
    processor.endJob()

    # Work done, report timing
    var diff = stop - start
    # in seconds
    var time: Double = diff / (10**9)
    var cpu_diff = cpu_stop - cpu_start
    var cpu: Double = cpu_diff / (10**9)
    maxEvents = Int(processor.processedEvents())

    print(
        "Processed ",
        maxEvents,
        " events in ",
        time,
        " seconds, throughput ",
        (maxEvents / time),
        " events/s, CPU usage: ",
        round(cpu / time * 100),
        "%",
        sep="",
    )

    # Lifetime registry extension
    _ = _esreg^
    _ = _edreg^
