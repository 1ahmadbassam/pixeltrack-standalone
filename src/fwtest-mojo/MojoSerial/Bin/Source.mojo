from memory import UnsafePointer
from pathlib import Path

from MojoSerial.DataFormats.FEDRawDataCollection import FEDRawDataCollection
from MojoSerial.DataFormats.DigiClusterCount import DigiClusterCount
from MojoSerial.DataFormats.TrackCount import TrackCount
from MojoSerial.DataFormats.VertexCount import VertexCount
from MojoSerial.Framework.Event import Event
from MojoSerial.Framework.ProductRegistry import ProductRegistry
from MojoSerial.Framework.EDPutToken import EDPutTokenT
from MojoSerial.MojoBridge.DTypes import Typeable
from MojoSerial.MojoBridge.File import read_simd, read_simd_eof


fn readRaw(mut file: FileHandle, nfeds: UInt32) raises -> FEDRawDataCollection:
    var rawCollection = FEDRawDataCollection()
    for _ in range(nfeds):
        var fedId = read_simd[DType.uint32](file)
        var fedSize = read_simd[DType.uint32](file)
        rawCollection.FEDData(Int(fedId))._data = file.read_bytes(Int(fedSize))
    return rawCollection^


struct Source(Defaultable, Movable, Typeable):
    var _maxEvents: Int32
    # skip time for now
    var _numEvents: Int32
    var _rawToken: EDPutTokenT[FEDRawDataCollection]
    var _digiClusterToken: EDPutTokenT[DigiClusterCount]
    var _trackToken: EDPutTokenT[TrackCount]
    var _vertexToken: EDPutTokenT[VertexCount]
    var _raw: List[FEDRawDataCollection]
    var _digiclusters: List[DigiClusterCount]
    var _tracks: List[TrackCount]
    var _vertices: List[VertexCount]
    var _validation: Bool

    @always_inline
    fn __init__(out self):
        self._maxEvents = 0

        self._numEvents = 0
        self._rawToken = EDPutTokenT[FEDRawDataCollection]()
        self._digiClusterToken = EDPutTokenT[DigiClusterCount]()
        self._trackToken = EDPutTokenT[TrackCount]()
        self._vertexToken = EDPutTokenT[VertexCount]()
        self._raw = []
        self._digiclusters = []
        self._tracks = []
        self._vertices = []
        self._validation = False

    fn __init__(
        out self,
        owned maxEvents: Int32,
        mut reg: ProductRegistry,
        owned path: Path,
        owned validation: Bool,
    ):
        try:
            self._maxEvents = maxEvents
            # no timing

            self._numEvents = 0
            self._rawToken = reg.produces[FEDRawDataCollection]()
            self._validation = validation
            self._raw = []
            self._digiclusters = []
            self._tracks = []
            self._vertices = []

            if self._validation:
                self._digiClusterToken = reg.produces[DigiClusterCount]()
                self._trackToken = reg.produces[TrackCount]()
                self._vertexToken = reg.produces[VertexCount]()
            else:
                self._digiClusterToken = EDPutTokenT[DigiClusterCount]()
                self._trackToken = EDPutTokenT[TrackCount]()
                self._vertexToken = EDPutTokenT[VertexCount]()

            var in_digiclusters = FileHandle()
            var in_tracks = FileHandle()
            var in_vertices = FileHandle()

            with open(path / "raw.bin", "r") as in_raw:
                if self._validation:
                    in_digiclusters = open(path / "digicluster.bin", "r")
                    in_tracks = open(path / "tracks.bin", "r")
                    in_vertices = open(path / "vertices.bin", "r")

                var nfeds = read_simd[DType.uint32](in_raw)
                while True:
                    self._raw.append(readRaw(in_raw, nfeds))
                    if self._validation:
                        var nm = read_simd[DType.uint32](in_digiclusters)
                        var nd = read_simd[DType.uint32](in_digiclusters)
                        var nc = read_simd[DType.uint32](in_digiclusters)
                        var nt = read_simd[DType.uint32](in_tracks)
                        var nv = read_simd[DType.uint32](in_vertices)
                        self._digiclusters.append(DigiClusterCount(nm, nd, nc))
                        self._tracks.append(TrackCount(nt))
                        self._vertices.append(VertexCount(nv))
                    var eofEvent = read_simd_eof[DType.uint32](in_raw)
                    if eofEvent[0]:
                        break
                    else:
                        nfeds = eofEvent[1]

                if self._validation:
                    in_digiclusters.close()
                    in_tracks.close()
                    in_vertices.close()

            if self._validation:
                debug_assert(
                    self._raw.__len__() == self._digiclusters.__len__()
                )
                debug_assert(self._raw.__len__() == self._tracks.__len__())
                debug_assert(self._raw.__len__() == self._vertices.__len__())

            if self._maxEvents < 0:
                self._maxEvents = self._raw.__len__()
        except e:
            print("Error occurred in Bin/Source.mojo,", e)
            return Self()

    @always_inline
    fn __moveinit__(out self, owned other: Self):
        self._maxEvents = other._maxEvents
        self._numEvents = other._numEvents
        self._rawToken = other._rawToken
        self._digiClusterToken = other._digiClusterToken
        self._trackToken = other._trackToken
        self._vertexToken = other._vertexToken
        self._raw = other._raw^
        self._digiclusters = other._digiclusters^
        self._tracks = other._tracks^
        self._vertices = other._vertices^
        self._validation = other._validation

    @always_inline
    fn reconfigure(mut self, owned maxEvents: Int32):
        self._maxEvents = maxEvents
        self._numEvents = 0

    @always_inline
    fn startProcessing(mut self):
        pass

    @always_inline
    fn maxEvents(self) -> Int32:
        return self._maxEvents

    @always_inline
    fn processedEvents(self) -> Int32:
        return self._numEvents

    fn produce(
        mut self, streamId: Int32, ref reg: ProductRegistry
    ) -> UnsafePointer[Event]:
        var res = UnsafePointer[Event]()
        if self._numEvents >= self._maxEvents:
            return res
        self._numEvents += 1
        var ev = Event(Int(streamId), Int(self._numEvents), reg)
        var index = (self._numEvents - 1) % self._raw.__len__()

        ev.put[FEDRawDataCollection](self._rawToken, self._raw[index])
        if self._validation:
            ev.put[DigiClusterCount](
                self._digiClusterToken, self._digiclusters[index]
            )
            ev.put[TrackCount](self._trackToken, self._tracks[index])
            ev.put[VertexCount](self._vertexToken, self._vertices[index])
        res = UnsafePointer[Event].alloc(1)
        res.init_pointee_move(ev^)
        return res

    @staticmethod
    @always_inline
    fn dtype() -> String:
        return "Source"
