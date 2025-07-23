struct FEDNumbering:
    alias _in: List[Bool] = initIn()

    alias NOT_A_FEDID: Int = -1
    alias MAXFEDID: Int = 4096
    alias MINSiPixelFEDID: Int = 0
    alias MAXSiPixelFEDID: Int = 40
    alias MINSiStripFEDID: Int = 50
    alias MAXSiStripFEDID: Int = 489
    alias MINPreShowerFEDID: Int = 520
    alias MAXPreShowerFEDID: Int = 575
    alias MINTotemTriggerFEDID: Int = 577
    alias MAXTotemTriggerFEDID: Int = 577
    alias MINTotemRPHorizontalFEDID: Int = 578
    alias MAXTotemRPHorizontalFEDID: Int = 581
    alias MINCTPPSDiamondFEDID: Int = 582
    alias MAXCTPPSDiamondFEDID: Int = 583
    alias MINTotemRPVerticalFEDID: Int = 584
    alias MAXTotemRPVerticalFEDID: Int = 585
    alias MINTotemRPTimingVerticalFEDID: Int = 586
    alias MAXTotemRPTimingVerticalFEDID: Int = 587
    alias MINECALFEDID: Int = 600
    alias MAXECALFEDID: Int = 670
    alias MINCASTORFEDID: Int = 690
    alias MAXCASTORFEDID: Int = 693
    alias MINHCALFEDID: Int = 700
    alias MAXHCALFEDID: Int = 731
    alias MINLUMISCALERSFEDID: Int = 735
    alias MAXLUMISCALERSFEDID: Int = 735
    alias MINCSCFEDID: Int = 750
    alias MAXCSCFEDID: Int = 757
    alias MINCSCTFFEDID: Int = 760
    alias MAXCSCTFFEDID: Int = 760
    alias MINDTFEDID: Int = 770
    alias MAXDTFEDID: Int = 779
    alias MINDTTFFEDID: Int = 780
    alias MAXDTTFFEDID: Int = 780
    alias MINRPCFEDID: Int = 790
    alias MAXRPCFEDID: Int = 795
    alias MINTriggerGTPFEDID: Int = 812
    alias MAXTriggerGTPFEDID: Int = 813
    alias MINTriggerEGTPFEDID: Int = 814
    alias MAXTriggerEGTPFEDID: Int = 814
    alias MINTriggerGCTFEDID: Int = 745
    alias MAXTriggerGCTFEDID: Int = 749
    alias MINTriggerLTCFEDID: Int = 816
    alias MAXTriggerLTCFEDID: Int = 824
    alias MINTriggerLTCmtccFEDID: Int = 815
    alias MAXTriggerLTCmtccFEDID: Int = 815
    alias MINTriggerLTCTriggerFEDID: Int = 816
    alias MAXTriggerLTCTriggerFEDID: Int = 816
    alias MINTriggerLTCHCALFEDID: Int = 817
    alias MAXTriggerLTCHCALFEDID: Int = 817
    alias MINTriggerLTCSiStripFEDID: Int = 818
    alias MAXTriggerLTCSiStripFEDID: Int = 818
    alias MINTriggerLTCECALFEDID: Int = 819
    alias MAXTriggerLTCECALFEDID: Int = 819
    alias MINTriggerLTCTotemCastorFEDID: Int = 820
    alias MAXTriggerLTCTotemCastorFEDID: Int = 820
    alias MINTriggerLTCRPCFEDID: Int = 821
    alias MAXTriggerLTCRPCFEDID: Int = 821
    alias MINTriggerLTCCSCFEDID: Int = 822
    alias MAXTriggerLTCCSCFEDID: Int = 822
    alias MINTriggerLTCDTFEDID: Int = 823
    alias MAXTriggerLTCDTFEDID: Int = 823
    alias MINTriggerLTCSiPixelFEDID: Int = 824
    alias MAXTriggerLTCSiPixelFEDID: Int = 824
    alias MINCSCDDUFEDID: Int = 830
    alias MAXCSCDDUFEDID: Int = 869
    alias MINCSCContingencyFEDID: Int = 880
    alias MAXCSCContingencyFEDID: Int = 887
    alias MINCSCTFSPFEDID: Int = 890
    alias MAXCSCTFSPFEDID: Int = 901
    alias MINDAQeFEDFEDID: Int = 902
    alias MAXDAQeFEDFEDID: Int = 931
    alias MINMetaDataSoftFEDID: Int = 1022
    alias MAXMetaDataSoftFEDID: Int = 1022
    alias MINDAQmFEDFEDID: Int = 1023
    alias MAXDAQmFEDFEDID: Int = 1023
    alias MINTCDSuTCAFEDID: Int = 1024
    alias MAXTCDSuTCAFEDID: Int = 1099
    alias MINHCALuTCAFEDID: Int = 1100
    alias MAXHCALuTCAFEDID: Int = 1199
    alias MINSiPixeluTCAFEDID: Int = 1200
    alias MAXSiPixeluTCAFEDID: Int = 1349
    alias MINRCTFEDID: Int = 1350
    alias MAXRCTFEDID: Int = 1359
    alias MINCalTrigUp: Int = 1360
    alias MAXCalTrigUp: Int = 1367
    alias MINDTUROSFEDID: Int = 1369
    alias MAXDTUROSFEDID: Int = 1371
    alias MINTriggerUpgradeFEDID: Int = 1372
    alias MAXTriggerUpgradeFEDID: Int = 1409
    alias MINSiPixel2nduTCAFEDID: Int = 1500
    alias MAXSiPixel2nduTCAFEDID: Int = 1649
    alias MINSiPixelTestFEDID: Int = 1450
    alias MAXSiPixelTestFEDID: Int = 1461
    alias MINSiPixelAMC13FEDID: Int = 1410
    alias MAXSiPixelAMC13FEDID: Int = 1449
    alias MINCTPPSPixelsFEDID: Int = 1462
    alias MAXCTPPSPixelsFEDID: Int = 1466
    alias MINGEMFEDID: Int = 1467
    alias MAXGEMFEDID: Int = 1472
    alias MINME0FEDID: Int = 1473
    alias MAXME0FEDID: Int = 1478
    alias MINDAQvFEDFEDID: Int = 2815
    alias MAXDAQvFEDFEDID: Int = 4095


    @staticmethod
    fn lastFEDId() -> Int:
        return FEDNumbering.MAXFEDID

    @staticmethod
    fn inRange(i: Int) -> Bool:
        return FEDNumbering._in[i]

    @staticmethod
    fn inRangeNoGT(i: Int) -> Bool:
        if ((i >= FEDNumbering.MINTriggerGTPFEDID and i <= FEDNumbering.MAXTriggerGTPFEDID) or (i >= FEDNumbering.MINTriggerEGTPFEDID and i <= FEDNumbering.MAXTriggerEGTPFEDID)):
            return False
        return FEDNumbering._in[i]

fn initIn() -> List[Bool]:

    var inn: List[Bool] = [False] * (FEDNumbering.MAXFEDID + 1)
    
    @parameter
    for i in range(0, FEDNumbering.lastFEDId()):
        inn[i] = False
    
    @parameter
    for i in range(FEDNumbering.MINSiPixelFEDID, FEDNumbering.MAXSiPixelFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINSiStripFEDID, FEDNumbering.MAXSiStripFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINPreShowerFEDID, FEDNumbering.MAXPreShowerFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINECALFEDID, FEDNumbering.MAXECALFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINCASTORFEDID, FEDNumbering.MAXCASTORFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINHCALFEDID, FEDNumbering.MAXHCALFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINLUMISCALERSFEDID, FEDNumbering.MAXLUMISCALERSFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINCSCFEDID, FEDNumbering.MAXCSCFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINCSCTFFEDID, FEDNumbering.MAXCSCTFFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINDTFEDID, FEDNumbering.MAXDTFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINDTTFFEDID, FEDNumbering.MAXDTTFFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINRPCFEDID, FEDNumbering.MAXRPCFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINTriggerGTPFEDID, FEDNumbering.MAXTriggerGTPFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINTriggerEGTPFEDID, FEDNumbering.MAXTriggerEGTPFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINTriggerGCTFEDID, FEDNumbering.MAXTriggerGCTFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINTriggerLTCFEDID, FEDNumbering.MAXTriggerLTCFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINTriggerLTCmtccFEDID, FEDNumbering.MAXTriggerLTCmtccFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINCSCDDUFEDID, FEDNumbering.MAXCSCDDUFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINCSCContingencyFEDID, FEDNumbering.MAXCSCContingencyFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINCSCTFSPFEDID, FEDNumbering.MAXCSCTFSPFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINDAQeFEDFEDID, FEDNumbering.MAXDAQeFEDFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINDAQmFEDFEDID, FEDNumbering.MAXDAQmFEDFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINTCDSuTCAFEDID, FEDNumbering.MAXTCDSuTCAFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINHCALuTCAFEDID, FEDNumbering.MAXHCALuTCAFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINSiPixeluTCAFEDID, FEDNumbering.MAXSiPixeluTCAFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINDTUROSFEDID, FEDNumbering.MAXDTUROSFEDID + 1):
        inn[i] = True
    
    @parameter
    for i in range(FEDNumbering.MINTriggerUpgradeFEDID, FEDNumbering.MAXTriggerUpgradeFEDID + 1):
        inn[i] = True

    return inn