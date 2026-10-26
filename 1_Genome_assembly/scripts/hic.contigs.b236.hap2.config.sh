### MARVEL PATH
MARVEL_SOURCE_PATH="/projects/dazzler/pippel/prog/DAMAR"
MARVEL_PATH="/projects/dazzler/pippel/prog/MARVEL/DAMAR-build"

### REPCOMP PATH
REPCOMP_SOURCE_PATH="/projects/dazzler/pippel/prog/repcomp"
REPCOMP_PATH="LIBMAUS2_DAZZLER_ALIGN_ALIGNMENTFILECONSTANTS_TRACE_XOVR=125 /projects/dazzler/pippel/prog/repcomp-build/repcomp_TRACE_XOVR_125"

### DACCORD PATH - used progs: fastaidrename, forcealign
DACCORD_SOURCE_PATH="/projects/dazzler/pippel/prog/daccord/"
DACCORD_PATH="LIBMAUS2_DAZZLER_ALIGN_ALIGNMENTFILECONSTANTS_TRACE_XOVR=125 /projects/dazzler/pippel/prog/daccord-mpi-build/daccord_0_0_635"

### LASTOOL PATH - used progs: lassort2
LASTOOLS_SOURCE_PATH="/projects/dazzler/pippel/prog/lastools"
LASTOOLS_PATH="LIBMAUS2_DAZZLER_ALIGN_ALIGNMENTFILECONSTANTS_TRACE_XOVR=125 /projects/dazzler/pippel/prog/lastools-build"

### DZZLER PATH
DAZZLER_SOURCE_PATH="/projects/dazzler/pippel/prog/dazzlerGIT"
DAZZLER_PATH="/projects/dazzler/pippel/prog/dazzlerGIT/TRACE_XOVR_125"


### slurm scripts path
SUBMIT_SCRIPTS_PATH="${MARVEL_PATH}/scripts"

############################## tools for pacbio arrow correction 
CONDA_BASE_ENV="source /sw/apps/conda/latest/bin/activate /projects/dazzler/pippel/prog/conda_envs/pbbioconda"
CONDA_PBMM2_ENV="source /sw/apps/conda/latest/bin/activate /projects/dazzler/pippel/prog/conda_envs/pbmm2"
CONDA_GCPP_ENV="source /sw/apps/conda/latest/bin/activate /projects/dazzler/pippel/prog/conda_envs/gcpp"
CONDA_PURGEHAPLOTIGS_ENV="source /sw/apps/conda/latest/bin/activate /projects/dazzler/pippel/prog/conda_envs/purge_haplotigs_env"
############################## tools HiC HiGlass pipleine, bwa, samtools, pairstools, cooler, ..;
CONDA_HIC_ENV="source /sw/apps/conda/latest/bin/activate /projects/dazzler/pippel/prog/conda_envs/HIC"
CONDA_PRETEXT_ENV="source /sw/apps/conda/latest/bin/activate /projects/dazzler/pippel/prog/conda_envs/PRETEXT"
CONDA_BIOBAMBAM_ENV="source /sw/apps/conda/latest/bin/activate /projects/dazzler/pippel/prog/conda_envs/BIOBAMBAM2"

### ENVIRONMENT VARIABLES 
export PATH=${MARVEL_PATH}/bin:${MARVEL_PATH}/scripts:$PATH
export PYTHONPATH=${MARVEL_PATH}/lib.python:$PYTHONPATH
export SCAFF10X_PATH="/projects/dazzler/pippel/prog/scaffolding/Scaff10X_git/src"
export BIONANO_PATH="/projects/dazzler/pippel/prog/bionano/Solve3.5_12162019"
export SALSA_PATH="/projects/dazzler/pippel/prog/SALSA/"
export QUAST_PATH="/projects/dazzler/pippel/prog/quast/"
export JUICER_PATH="/projects/dazzler/pippel/prog/scaffolding/juicer"
export JUICER_TOOLS_PATH="/projects/dazzler/pippel/prog/scaffolding/juicer_tools.1.9.8_jcuda.0.8.jar"
export THREEDDNA_PATH="/projects/dazzler/pippel/prog/3d-dna/"
export LONGRANGER_PATH="/projects/dazzler/pippel/prog/longranger-2.2.2"
export SUPERNOVA_PATH="/projects/dazzler/pippel/prog/supernova-2.1.1"
export ARKS_PATH="/projects/dazzler/pippel/prog/scaffolding/arks-build/bin"
export TIGMINT_PATH="/projects/dazzler/pippel/prog/scaffolding/tigmint/bin"
export LINKS_PATH="/projects/dazzler/pippel/prog/scaffolding/links_v1.8.6/"
export JELLYFISH_PATH="/projects/dazzler/pippel/prog/Jellyfish/jellyfish-2.2.10/bin/"
export GENOMESCOPE_PATH="/projects/dazzler/pippel/prog/genomescope/"
export GATK_PATH="/projects/dazzler/pippel/prog/gatk-4.0.3.0/gatk-package-4.0.3.0-local.jar"
export BCFTOOLS_PATH="/projects/dazzler/pippel/prog/bcftools"
export SEQKIT_PATH="/projects/dazzler/pippel/prog/bin/seqkit"
export FASTP_PATH="/projects/dazzler/pippel/prog/fastp/"
export PURGEDUPS_PATH="/projects/dazzler/pippel/prog/purge_dups"

BGZIP_THREADS=6
MARVEL_STATS=1
SLURM_STATS=0

## general information
PROJECT_ID=vpTaxBaccB23-6-hap2
GSIZE=10000M
SLURM_PARTITION=main # default slurm partition - todo define individual partion for tasks
SLURM_NUMACTL=0

################# define marvel phases and their steps that should be done 

HIC_PATH=/projects/dazzler/pippel/vpTaxBacc/b23-6/hic
DB_PATH=${HIC_PATH} ## fake, its not used in HIC pipeline

ASSMEBLY_DIR="hic_rapidCuration"
PATCHING_DIR="hic_patch"
CONT_DB="vpTaxBacc_B23-6-hap2"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> marvel phase 15 - HiC QC and scaffolding  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

SC_HIC_TYPE=5
# Type: 0 Arima Mapping Pipeline (For QC) 				 steps: 01_HICsalsaPrepareInput, 02_HICsalsaBwa, 03_HICsalsaFilter, 04_HICsalsaMerge, 05_HICsalsaMarkduplicates, 06_HICsalsaSalsa, 07_HICsalsaStatistics 
# Type: 1 Phase Genomics Mapping Pipeline (For QC) 		 steps: 01_HICphasePrepareInput, 02_HICphaseBwa, 03_HICphaseFilter, 04_HICphaseMatlock
# Type: 2 Aiden Lab Juicer/3d-dna Scaffolding Pipeline   steps: 01_HIC3dnaPrepareInput, 02_HIC3dnaJuicer, 03_HIC3dnaAssemblyPipeline
# Type: 3 Aiden Lab Juicer/3d-dna visualization Pipeline steps: 01_HIC3dnaPrepareInput, 02_HIC3dnaJuicer, 03_HIC3dnaVisualize
# Type: 4 - higlass visualization                        steps: 01_HIChiglassPrepare, 02_HiChiglassBwa, 03_HiChiglassFilter, 04_HiChiglassMatrix
# TYPE: 5 - rapid curation                   		 steps: 01_HICrapidCurPrepareInput, 02_HICrapidCurBwa, 03_HICrapidCurFilter, 04_HICrapidCurMerge, 05_HICrapidCurMarkduplicates, 06_HICrapidCurBam2Bed, 07_HICrapidCurHiGlass, 08_HICrapidCurPretext
SC_HIC_SUBMIT_SCRIPTS_FROM=1
SC_HIC_SUBMIT_SCRIPTS_TO=8

# ----------------------------------------------------------------- SCAFFOLDING - HIC QC AND SALSA, 3DNA, JUICER OPTIONS ----------------------------------------------------------------------------------------------------

### general options
SC_HIC_RUNID=hap2											# used for output directory purgeHaplotigs_run${PB_ARROW_RUNID}
SC_HIC_READS="${HIC_PATH}"   								# directory with pacbio fasta files
SC_HIC_OUTDIR="./"
SC_HIC_REF=/projects/dazzler/pippel/vpTaxBacc/b23-6/contigs/vpTaxBacc_B23-6.hifiasm.asm.hic.hap2_l1.fasta
#SC_HIC_REF_EXCLUDELIST="stats/contigs/m1/haploSplit/filter/mMyoMyo_m1_h.p.excludeP65RepeatContigs.clist"
SC_HIC_ENZYME_NAME="ArimaV2"
SC_HIC_ENZYME_SEQ="GATC,GANTC,CTNAG,TTAA"
SC_HIC_FULLSTATS=0		
### fastp
SC_HIC_FASTP_THREADS=12
### bwa
SC_HIC_BWA_THREADS=40
SC_HIC_BWA_VERBOSITY=3						# 1=error, 2=warning, 3=message, 4+=debugging [3]
### picard tools
SC_HIC_PICARD_XMX=64						# java memory options in Gb
SC_HIC_PICARD_XMS=64						# java memory options in Gb
### samtools sort
SC_HIC_SAMTOOLS_THREADS=24
SC_HIC_SAMTOOLS_MEM=4							# Set maximum memory in Gigabases per thread
### juicer and 3d-dna HiC options 

### HiGlass pipeline
SC_HIC_HIGLASS_PROJECT=hap2
SC_HIC_HIGLASS_SEQTYPE=1
SC_HIC_HIGLASS_MAPQ=0
SC_HIC_HIGLASS_NODEDUP=0
SC_HIC_HIGLASS_COOLERRESOLUTION=(1000)	# cooler binning: binsize : e.g.) 5000 (high resolution), 500000 (lower resolution)
SC_HIC_HIGLASS_PAIRTOOLSTHREADS=16
SC_HIC_FULLSTATS=0
#### Rapid curation
SC_HIC_BWA_MISMATCHPENALTY=8   		# default mismatch penalty value from Sanger
# arima qv min mapping quality
SC_HIC_MINMAPQV=0			# currently also 1,10 and 20 are created 
# sort threads 
SC_HIC_SORT_THREADS=16
SC_HIC_SORT_MEM=$((50*1024))
## markduplicates threads
SC_HIC_BIOBAMBAM_THREADS=16
# PretextMap 
SC_HIC_PRETEXTMAP_QV=0
SC_HIC_PRETEXTMAP_HIGHRES=1

# ***************************************************************** runtime parameter for slurm settings:  threads, mem, time ***************************************************************

### default parameter for 24-core nodes  #####
THREADS_DEFAULT=6
MEM_DEFAULT=16144
TIME_DEFAULT=72:00:00

########### HIC salsa bwa 
THREADS_HICsalsaBwa=${SC_HIC_BWA_THREADS}
MEM_HICsalsaBwa=$((${SC_HIC_BWA_THREADS}*1024+${SC_HIC_SAMTOOLS_THREADS}*${SC_HIC_SAMTOOLS_MEM}*1024))
TIME_HICsalsaBwa=72:00:00

########### HIC picard markduplicates - run indexing parallel  
THREADS_HICsalsaMarkduplicates=${SC_HIC_SAMTOOLS_THREADS}
MEM_HICsalsaMarkduplicates=$((${SC_HIC_SAMTOOLS_THREADS}*${SC_HIC_SAMTOOLS_MEM}*1024+${SC_HIC_PICARD_XMS}*1024))
TIME_HICsalsaMarkduplicates=72:00:00

#### Juicer/3d-dna pipeline
THREADS_juicer=24
if [[ "${SLURM_PARTITION}" == "gpu" ]]
then 
	THREADS_juicer=40
elif [[ "${SLURM_PARTITION}" == "bigmem" ]]
then 
	THREADS_juicer=48
fi

THREADS_HIC3dnaJuicer=${THREADS_juicer}
MEM_HIC3dnaJuicer=$((${THREADS_juicer}*4096))
TIME_HIC3dnaJuicer=72:00:00

THREADS_HIC3dnaAssemblyPipeline=${THREADS_juicer}
MEM_HIC3dnaAssemblyPipeline=$((${THREADS_juicer}*4096))
TIME_HIC3dnaAssemblyPipeline=72:00:00

THREADS_HIC3dnaVisualizePipeline=${THREADS_juicer}
MEM_HIC3dnaVisualizePipeline=$((${THREADS_juicer}*4096))
TIME_HIC3dnaVisualizePipeline=72:00:00

## HiGlass pipeline
THREADS_HiChiglassFilter=${SC_HIC_HIGLASS_PAIRTOOLSTHREADS}
MEM_HiChiglassFilter=64000
TIME_HiChiglassFilter=72:00:00

THREADS_HiChiglassBwa=${SC_HIC_BWA_THREADS}
MEM_HiChiglassBwa=64000
TIME_HiChiglassBwa=72:00:00

THREADS_HICrapidCurBwa=${SC_HIC_BWA_THREADS}
MEM_HICrapidCurBwa=64000
TIME_HICrapidCurBwa=72:00:00

THREADS_HiChiglassMatrix=${SC_HIC_HIGLASS_PAIRTOOLSTHREADS}
MEM_HiChiglassMatrix=64000
TIME_HiChiglassMatrixs=72:00:00

THREADS_bamsplit=12
MEM_bamsplit=6144
TIME_bamsplit=72:00:00
STEPSIZE_bamsplit=10
MAXJOBS_bamsplit=100

THREADS_HICrapidCurBam2Bed=${SC_HIC_SAMTOOLS_THREADS}
MEM_HICrapidCurBam2Bed=120000
TIME_HICrapidCurBam2Bed=72:00:00
#STEPSIZE_HICrapidCurBam2Bed=10

THREADS_HICrapidCurHiGlass=${SC_HIC_SORT_THREADS}
MEM_HICrapidCurHiGlass=${SC_HIC_SORT_MEM}
TIME_HICrapidCurHiGlas=72:00:00

THREADS_HICrapidCurMerge=${SC_HIC_SAMTOOLS_THREADS}
MEM_HICrapidCurMerge=$((SC_HIC_SAMTOOLS_THREADS*4096))
TIME_HICrapidCurMerge=72:00:00

THREADS_HICrapidCurMarkduplicates=${SC_HIC_BIOBAMBAM_THREADS}
MEM_HICrapidCurMarkduplicates=$((SC_HIC_BIOBAMBAM_THREADS*4096))
TIME_HICrapidCurMarkduplicates=72:00:00
