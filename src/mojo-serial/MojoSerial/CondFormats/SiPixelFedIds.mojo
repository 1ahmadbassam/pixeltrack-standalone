struct SiPixelFedIds(Copyable & Movable):

    var fedIds_: List[UInt32]
    fn __init__(out self, owned fedIds: List[UInt32]):
        self.fedIds_ = fedIds^
    #There is no need to implement a getter for fedIds since here it is not private at all
    #But i will do it for the sake of making life easier when someone calls this function.
    fn fedIds( self) -> List[UInt32]:
        return self.fedIds_



    


