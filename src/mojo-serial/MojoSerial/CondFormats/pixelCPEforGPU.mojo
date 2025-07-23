from DataFormats.SOARotation import SOARotation,SOAFrame
from Geometry.Phase1PixelTopology import Phase1PixelTopology, AverageGeometry
from memory import UnsafePointer
from CUDADataFormats.GPUClusteringConstants import PixelGPUConstants
from testing import assert_true
alias PPT = Phase1PixelTopology
alias Frame = SOAFrame[DType.float32]
alias Rotation = SOARotation[DType.float32]
alias Float = Float32
@fieldwise_init
struct CommonParams(Copyable, Movable):
    var theThicknessB: Float32
    var theThicknessE: Float32
    var thePitchX: Float32
    var thePitchY: Float32

struct DetParams(Copyable, Movable):
    var isBarrel: Bool
    var isPosZ: Bool
    var layer: UInt16
    var index: UInt16
    var rawId: UInt16

    var shiftX: Float32
    var shiftY: Float32
    var chargeWidthX: Float32
    var chargeWidthY: Float32

    var x0: Float32
    var y0: Float32
    var z0: Float32

    var sx : InlineArray[Float32, 3]
    var sy : InlineArray[Float32, 3]

    #var frame: Frame  
@fieldwise_init
struct LayerGeometry(Copyable, Movable):
    var layerStart: InlineArray[UInt32, Int(PPT.numberOfLayers + 1)]
    var layer: InlineArray[UInt8, Int(PPT.layerIndexSize)]
@fieldwise_init
struct ParamsOnGPU:
    var m_commonParams: UnsafePointer[CommonParams]
    var m_detParams: UnsafePointer[DetParams]
    var m_layerGeometry: UnsafePointer[LayerGeometry]
    var m_averageGeometry: UnsafePointer[AverageGeometry]
    
    fn commonParams(self) -> CommonParams:
        return self.m_commonParams[]

    fn detParams(self, i: Int) -> DetParams:
        return self.m_detParams[i]

    fn layerGeometry(self) -> LayerGeometry:
        return self.m_layerGeometry[]

    fn averageGeometry(self) -> AverageGeometry:
        return self.m_averageGeometry[]

    fn layer(self, id: UInt16) -> UInt8:
        index = Int(id) // PPT.maxModuleStride  
        return self.m_layerGeometry[].layer[index]

@fieldwise_init
struct ClusParamsT[N: UInt32](Copyable, Movable):
    var minRow: InlineArray[UInt32, Int(N)]
    var maxRow: InlineArray[UInt32, Int(N)]
    var minCol: InlineArray[UInt32, Int(N)]
    var maxCol: InlineArray[UInt32, Int(N)]

    var Q_f_X: InlineArray[Int32, Int(N)]
    var Q_f_Y: InlineArray[Int32, Int(N)]
    
    var Q_l_X: InlineArray[Int32, Int(N)]
    var Q_l_Y: InlineArray[Int32, Int(N)]

    var charge: InlineArray[Int32, Int(N)]
    var xpos: InlineArray[Float, Int(N)]
    var ypos: InlineArray[Float, Int(N)]

    var xerr: InlineArray[Float, Int(N)]
    var yerr: InlineArray[Float, Int(N)]

    var xsize: InlineArray[Int16, Int(N)]
    var ysize: InlineArray[Int16, Int(N)]
alias MaxHitsInIter: UInt32 = (PixelGPUConstants.maxHitsInIter())
alias ClusParams = ClusParamsT[MaxHitsInIter]


@always_inline
fn computeAnglesFromDet(detParams: DetParams, x: Float, 
    y: Float, mut cotalpha: Float , mut cotbeta: Float):
    var gvx = x - detParams.x0
    var gvy = y - detParams.y0
    var gvz = - 1.0 / detParams.z0
    cotalpha = gvx * gvz
    cotbeta = gvy * gvz

@always_inline
fn correction(sizeM1: Int, Q_f: Int, Q_l: Int, 
    upper_edge_first_pix: UInt16,   
    lower_edge_last_pix: UInt16,  
    lorentz_shift: Float32,      
    theThickness: Float32,         
    cot_angle: Float32,             
    pitch: Float32,                 
    first_is_big: Bool,           
    last_is_big: Bool               
) -> Float32:
    if 0 == sizeM1:
        return 0.0
    var W_eff: Float = 0.0
    simple: Bool = True
    if 1 == sizeM1:
        var W_inner = pitch * Float(lower_edge_last_pix - upper_edge_first_pix)
        var W_pred = theThickness * cot_angle - lorentz_shift
        W_eff = abs(W_inner) + W_pred
        simple = (W_eff < 0.0) | (W_eff > pitch)
    if simple:
        sum_of_edge: Float = 2.0
        if first_is_big:
            sum_of_edge += 1.0
        if last_is_big:
            sum_of_edge += 1.0
        W_eff = pitch * sum_of_edge * 0.5
    Qdiff: Float32 = Float32(Q_l - Q_f)
    Qsum: Float32 = Float32(Q_f + Q_l)
    if Qsum == 0.0:
        Qsum = 1.0
    return 0.5 * (Qdiff / Qsum) * W_eff

@always_inline
fn position(comParams: CommonParams, detParams: DetParams,
            mut clusParams: ClusParams, ic: UInt32)  raises :
            var llx: UInt16 = clusParams.minRow[ic].cast[DType.uint16]() + 1
            var lly: UInt16 = clusParams.minCol[ic].cast[DType.uint16]() + 1
            var urx: UInt16 = clusParams.maxRow[ic].cast[DType.uint16]() + 1
            var ury: UInt16 = clusParams.maxCol[ic].cast[DType.uint16]() + 1

            var llxl = PPT.localX(llx)
            var llyl = PPT.localY(lly)
            var urxl = PPT.localX(urx)
            var uryl = PPT.localY(ury)

            var mx = llxl + urxl
            var my = llyl + uryl

            var xsize = Int(urxl) - Int(llxl) + 2
            var ysize = Int(uryl) - Int(llyl) + 2
            assert_true(xsize >= 0)
            assert_true(ysize >= 0)

            if PPT.isBigPixX(UInt16(clusParams.minRow[ic])):
                xsize += 1
            if PPT.isBigPixX(UInt16(clusParams.maxRow[ic])):
                xsize += 1
            if PPT.isBigPixY(UInt16(clusParams.minCol[ic])):
                ysize += 1
            if PPT.isBigPixY(UInt16(clusParams.maxCol[ic])):
                ysize += 1

            var unbalanceX: Int = Int(8 * abs(Float(clusParams.Q_f_X[ic] - clusParams.Q_l_X[ic])) / Float(clusParams.Q_f_X[ic] + clusParams.Q_l_X[ic]))
            var unbalanceY: Int = Int(8 * abs(Float(clusParams.Q_f_Y[ic] - clusParams.Q_l_Y[ic])) / Float(clusParams.Q_f_Y[ic] + clusParams.Q_l_Y[ic]))
            xsize  = 8 * xsize - unbalanceX
            ysize  = 8 * ysize - unbalanceY

            clusParams.xsize[ic] = min(xsize, 1023)
            clusParams.ysize[ic] = min(ysize, 1023)

            if ((clusParams.minRow[ic] == 0)  | (UInt32(clusParams.maxRow[ic])  == UInt32(PPT.lastRowInModule))):
                clusParams.xsize[ic] = -clusParams.xsize[ic]
            if ((clusParams.minCol[ic] == 0)  | (UInt32(clusParams.maxCol[ic])  == UInt32(PPT.lastColInModule))):
                clusParams.ysize[ic] = -clusParams.ysize[ic]
            var xPos = detParams.shiftX + comParams.thePitchX * (0.5 * Float(mx) + Float(PPT.xOffset))
            var yPos = detParams.shiftY + comParams.thePitchY * (0.5 * Float(my) + Float(PPT.yOffset))

            cotalpha:Float  = 0
            cotbeta:Float = 0

            computeAnglesFromDet(detParams, xPos, yPos, cotalpha, cotbeta)
            var thickness:Float
            if detParams.isBarrel: 
                thickness = comParams.theThicknessB 
            else: 
                thickness = comParams.theThicknessE
            
            var xcorr = correction(
                Int(clusParams.maxRow[ic] - clusParams.minRow[ic]),
                Int(clusParams.Q_f_X[ic]), Int(clusParams.Q_l_X[ic]),
                llxl, urxl,
                detParams.chargeWidthX, thickness, cotalpha,
                comParams.thePitchX, PPT.isBigPixX(UInt16(clusParams.minRow[ic])),
                PPT.isBigPixX(UInt16(clusParams.maxRow[ic]))
            )
            var ycorr = correction(
                Int(clusParams.maxCol[ic] - clusParams.minCol[ic]),
                Int(clusParams.Q_f_Y[ic]), Int(clusParams.Q_l_Y[ic]),
                llyl, uryl,
                detParams.chargeWidthY, thickness, cotbeta,
                comParams.thePitchY, PPT.isBigPixY(UInt16(clusParams.minCol[ic])),
                PPT.isBigPixY(UInt16(clusParams.maxCol[ic]))
            )
            clusParams.xpos[ic] = xPos + xcorr
            clusParams.ypos[ic] = yPos + ycorr

@always_inline
fn errorFromSize(comParams: CommonParams, detParams: DetParams,
            mut cp: ClusParams, ic: UInt32):
            cp.xerr[ic] = 0.0050
            cp.yerr[ic] = 0.0085

            alias xerr_barrel_l1 = InlineArray[Float32, 3](0.00115, 0.00120, 0.00088)
            alias xerr_barrel_l1_def = 0.00200
            alias yerr_barrel_l1 = InlineArray[Float32, 9](0.00375, 0.00230, 0.00250, 0.00250, 0.00230, 0.00230, 0.00210, 0.00210, 0.00240)
            alias yerr_barrel_l1_def = 0.00210
            alias  xerr_barrel_ln = InlineArray[Float32, 3](0.00115, 0.00120, 0.00088)
            alias  xerr_barrel_ln_def = 0.00200
            alias  yerr_barrel_ln = InlineArray[Float32, 9] (0.00375, 0.00230, 0.00250, 0.00250, 0.00230, 0.00230, 0.00210, 0.00210, 0.00240)
            alias  yerr_barrel_ln_def = 0.00210
            alias  xerr_endcap = InlineArray[Float32, 2](0.0020, 0.0020)
            alias  xerr_endcap_def = 0.0020
            alias  yerr_endcap = InlineArray[Float32, 1](0.00210)
            alias  yerr_endcap_def = 0.00210

            var sx = cp.maxRow[ic] - cp.minRow[ic]
            var sy = cp.maxCol[ic] - cp.minCol[ic]

            var isEdgeX: Bool = ((cp.minRow[ic] == 0) | (UInt32(cp.maxRow[ic]) == UInt32(PPT.lastRowInModule)))
            var isEdgeY: Bool = ((cp.minCol[ic] == 0) | (UInt32(cp.maxCol[ic]) == UInt32(PPT.lastColInModule)))
            var isBig1X: Bool = (sx == 0) & PPT.isBigPixX(UInt16(cp.minRow[ic]))
            var isBig1Y: Bool = (sy == 0) & PPT.isBigPixY(UInt16(cp.minCol[ic]))

            if (not isEdgeX & not isBig1X):
                if (not detParams.isBarrel):
                    if (sx < len(xerr_endcap)):
                        cp.xerr[ic] = xerr_endcap[sx]
                    else:
                        cp.xerr[ic] = xerr_endcap_def
                elif detParams.layer == 1:
                    if (sx < len(xerr_barrel_l1)):
                        cp.xerr[ic] = xerr_barrel_l1[sx]
                    else:
                        cp.xerr[ic] = xerr_barrel_l1_def
                else:
                    if (sx < len(xerr_barrel_ln)):
                        cp.xerr[ic] = xerr_barrel_ln[sx]
                    else:
                        cp.xerr[ic] = xerr_barrel_ln_def
            if (not isEdgeY & not isBig1Y):
                if (not detParams.isBarrel):
                    if (sy < len(yerr_endcap)):
                        cp.yerr[ic] = yerr_endcap[sy]
                    else:
                        cp.yerr[ic] = yerr_endcap_def
                elif detParams.layer == 1:
                    if (sy < len(yerr_barrel_l1)):
                        cp.yerr[ic] = yerr_barrel_l1[sy]
                    else:
                        cp.yerr[ic] = yerr_barrel_l1_def
                else:
                    if (sy < len(yerr_barrel_ln)):
                        cp.yerr[ic] = yerr_barrel_ln[sy]
                    else:
                        cp.yerr[ic] = yerr_barrel_ln_def

@always_inline
fn errorFromDB(comParams: CommonParams, detParams: DetParams,
            mut cp: ClusParams, ic: UInt32):
            cp.xerr[ic] = 0.0050
            cp.yerr[ic] = 0.0085

            var sx = cp.maxRow[ic] - cp.minRow[ic]
            var sy = cp.maxCol[ic] - cp.minCol[ic]

            var isEdgeX: Bool = ((cp.minRow[ic] == 0) | (UInt32(cp.maxRow[ic]) == UInt32(PPT.lastRowInModule)))
            var isEdgeY: Bool = ((cp.minCol[ic] == 0) | (UInt32(cp.maxCol[ic]) == UInt32(PPT.lastColInModule)))

            var ix: UInt32 = UInt32( sx == 0)
            var iy: UInt32 = UInt32( sy == 0)
            var toix: Bool = (sx == 0) & PPT.isBigPixX(UInt16(cp.minRow[ic]))
            if toix: ix+=1
            var toiy: Bool = (sy == 0) & PPT.isBigPixY(UInt16(cp.minCol[ic]))
            if toiy: iy+=1

            if not isEdgeX:
                cp.xerr[ic] = detParams.sx[ix]
            if not isEdgeY:
                cp.yerr[ic] = detParams.sy[iy]

                











































