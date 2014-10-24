# Auto generated configuration file
# using: 
# Revision: 1.381.2.27 
# Source: /local/reps/CMSSW/CMSSW/Configuration/PyReleaseValidation/python/ConfigBuilder.py,v 
# with command line options: step0 --filein /store/user/mbuttign/Prod_S1/prod_S1_mres1000p0_mchi825p0/prod_S1_mres1000p0_mchi825p0_1_HepMC.root --fileout output_RECO.root --mc --eventcontent AODSIM --datatier RECOSIM --conditions START53_V29::All --pileup 2012_Summer_50ns_PoissonOOTPU --step GEN,SIM,DIGI,L1,DIGI2RAW,HLT:7E33v2,RAW2DIGI,L1Reco,RECO --python_filename prod_HepMCtoRECO.py --no_exec -n 2
import FWCore.ParameterSet.Config as cms

process = cms.Process('HLT')

# import of standard configurations
process.load('Configuration.StandardSequences.Services_cff')
process.load('SimGeneral.HepPDTESSource.pythiapdt_cfi')
process.load('FWCore.MessageService.MessageLogger_cfi')
process.load('Configuration.EventContent.EventContent_cff')
process.load('SimGeneral.MixingModule.mix_2012_Summer_50ns_PoissonOOTPU_cfi')
process.load('Configuration.StandardSequences.GeometryRecoDB_cff')
process.load('Configuration.StandardSequences.GeometrySimDB_cff')
process.load('Configuration.StandardSequences.MagneticField_38T_cff')
process.load('Configuration.StandardSequences.Generator_cff')
process.load('IOMC.EventVertexGenerators.VtxSmearedRealistic8TeVCollision_cfi')
process.load('GeneratorInterface.Core.genFilterSummary_cff')
process.load('Configuration.StandardSequences.SimIdeal_cff')
process.load('Configuration.StandardSequences.Digi_cff')
process.load('Configuration.StandardSequences.SimL1Emulator_cff')
process.load('Configuration.StandardSequences.DigiToRaw_cff')
process.load('HLTrigger.Configuration.HLT_7E33v2_cff')
process.load('Configuration.StandardSequences.RawToDigi_cff')
process.load('Configuration.StandardSequences.L1Reco_cff')
process.load('Configuration.StandardSequences.Reconstruction_cff')
process.load('Configuration.StandardSequences.EndOfProcess_cff')
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(1000)
)

#process.options = cms.untracked.PSet(
#
#)

from FWCore.ParameterSet.VarParsing import VarParsing
options = VarParsing('python')

options.register('fileItr',"",VarParsing.multiplicity.singleton,VarParsing.varType.string,'File index')

options.parseArguments()

# Input source
process.source = cms.Source("PoolSource",
    secondaryFileNames = cms.untracked.vstring(),
    fileNames = cms.untracked.vstring('/store/user/mbuttign/Prod_S1_GEN/prod_S1_mres1000p0_mchi800p0/prod_S1_mres1000p0_mchi800p0_'+str( options.fileItr )+'_GEN.root')
)

# Production Info
process.configurationMetadata = cms.untracked.PSet(
    version = cms.untracked.string('$Revision: 1.381.2.27 $'),
    annotation = cms.untracked.string('step0 nevts:2'),
    name = cms.untracked.string('PyReleaseValidation')
)

# Output definition

process.AODSIMoutput = cms.OutputModule("PoolOutputModule",
    eventAutoFlushCompressedSize = cms.untracked.int32(15728640),
    outputCommands = process.AODSIMEventContent.outputCommands,
    fileName = cms.untracked.string('file:RECO.root'),
    dataset = cms.untracked.PSet(
        filterName = cms.untracked.string(''),
        dataTier = cms.untracked.string('RECOSIM')
    ),
    SelectEvents = cms.untracked.PSet(
        SelectEvents = cms.vstring('generation_step')
    )
)

# Additional output definition

# Other statements
process.genstepfilter.triggerConditions=cms.vstring("generation_step")
from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, 'START53_V29::All', '')

# Path and EndPath definitions
process.generation_step = cms.Path(process.pgen)
process.simulation_step = cms.Path(process.psim)
process.digitisation_step = cms.Path(process.pdigi)
process.L1simulation_step = cms.Path(process.SimL1Emulator)
process.digi2raw_step = cms.Path(process.DigiToRaw)
process.raw2digi_step = cms.Path(process.RawToDigi)
process.L1Reco_step = cms.Path(process.L1Reco)
process.reconstruction_step = cms.Path(process.reconstruction)
process.genfiltersummary_step = cms.EndPath(process.genFilterSummary)
process.endjob_step = cms.EndPath(process.endOfProcess)
process.AODSIMoutput_step = cms.EndPath(process.AODSIMoutput)

#process.g4SimHits.Generator.HepMCProductLabel = 'source'
#process.VtxSmearedCommon.src = 'source'
#process.genParticles.src = 'source'
#process.VtxSmeared.src='source'

# Schedule definition
process.schedule = cms.Schedule(process.generation_step,process.genfiltersummary_step,process.simulation_step,process.digitisation_step,process.L1simulation_step,process.digi2raw_step)
process.schedule.extend(process.HLTSchedule)
process.schedule.extend([process.raw2digi_step,process.L1Reco_step,process.reconstruction_step,process.endjob_step,process.AODSIMoutput_step])

# customisation of the process.

# Automatic addition of the customisation function from HLTrigger.Configuration.customizeHLTforMC
from HLTrigger.Configuration.customizeHLTforMC import customizeHLTforMC 

#call to customisation function customizeHLTforMC imported from HLTrigger.Configuration.customizeHLTforMC
process = customizeHLTforMC(process)

# End of customisation functions
