PROJECT_ID=vpTaxBacc_B34-6_hap2

# set up general parameter
SLURM_PARTITION=core
NTHREADS=16
TIM="96:00:00"
MEM=110G 
ADD_SLURM_OPT=" -A uppmax2025-2-58 "

LOG_DIR=logs

# path to assembly file - (linked file) 
ASM=asm.fa
ASM_TYPE=final
ASM_LEVEL=chromosome
ASM_VERSION=1
## full species name 
SPECIES_NAME="Taxus baccata"
## species taxonomy ID from (https://www.ncbi.nlm.nih.gov/taxonomy) - used in the blast searches
TAXID=25629
## ToLID from: https://id.tol.sanger.ac.uk/
## in case no ToLID can offcially be requested, just search for the species at https://id.tol.sanger.ac.uk/ and use the identifier - those ID's don't have sample number at the end
ToLID=vpTaxBacc
PHYLUM=Streptophyta

# fofn of read data for coverage analysis - usually PacBio HiFi (or ONT)
READS=reads.fofn
# map-pb/map-ont - PacBio CLR/Nanopore vs reference mapping
# map-hifi - PacBio HiFi reads vs reference mapping
# sr - illumina / other
READS_TYPE=map-hifi


# Blobtools singularity container
SINGULARITY_BINDS="-B /projects/dazzler/:/projects/dazzler"
BTK_SINGULARITY_IMAGE="singularity exec ${SINGULARITY_BINDS} /projects/dazzler/pippel/prog/blobtools/blobtoolkit_4.4.5.sif"

########## SETUP ##########
TMP_ASM_DIR=assembly
BGZIP_THREADS=6
MIN_COV=0.5
MAX_COV=100

########## WINDOWMASKER ##########
MASKER_DIR=windowmasker
MASKER_THREADS=1
MASKER_MEM=150G
MASKER_TIM=12:00:00
MASKER_PARTITION=${SLURM_PARTITION}

########## CHUNK fasta ##########
CHUNK_DIR=chunk_fasta
CHUNK_NUM=100000
CHUNK_OVL=0
CHUNK_MAX=10
CHUNK_MINLEN=1000
CHUNK_THREADS=1
CHUNK_MEM=50G
CHUNK_TIM=12:00:00
CHUNK_PARTITION=${SLURM_PARTITION}

########## BUSCO ##########
BUSCO_DIR=busco_v5
BUSCO_DOWNLOAD_DIR=/projects/dazzler/pippel/prog/busco_datasets/v5/data
BUSCO_LINEAGES=(viridiplantae_odb10)
BUSCO_BASAL_LINEAGES=(eukaryota_odb10)
BUSCO_THREADS=16
BUSCO_MEM=110G
## todo derive TIME from genomesize 
BUSCO_TIM=96:00:00      
BUSCO_PARTITION=${SLURM_PARTITION}


########## DIAMOND ##########
DIAMOND_X_DIR=diamond_x
DIAMOND_X_DB=/sw/data/diamond_databases/reference_proteomes/latest/reference_proteomes.dmnd
DIAMOND_X_EVAL=1.0e-25
DIAMOND_X_MAXTARSEQS=10
DIAMOND_X_TAXID=${TAXID}
DIAMOND_X_THREADS=16
DIAMOND_X_MEM=110G
DIAMOND_X_TIM=96:00:00      
DIAMOND_X_PARTITION=${SLURM_PARTITION}

DIAMOND_P_DIR=diamond_p
DIAMOND_P_DB=/sw/data/diamond_databases/reference_proteomes/latest/reference_proteomes.dmnd
DIAMOND_P_EVAL=1.0e-25
DIAMOND_P_MAXTARSEQS=100000
DIAMOND_P_TAXID=${TAXID}
DIAMOND_P_THREADS=16
DIAMOND_P_MEM=110G
DIAMOND_P_TIM=96:00:00      
DIAMOND_P_PARTITION=${SLURM_PARTITION}

########## MINIMAP2 ##########
MINIMAP2_DIR=minimap2
MINIMAP2_TYPE=${READS_TYPE}          #map-pb map-ont map-hifi sr
MINIMAP2_THREADS=20
MINIMAP2_MEM=110G
MINIMAP2_TIM=96:00:00      
MINIMAP2_PARTITION=${SLURM_PARTITION}



########## BLASTN ##########
BLASTN_DIR=blastn
#BLASTN_DB=/sw/data/blast_databases/nt
## use chunked nt database:
BLASTN_DB_PATH=/projects/dazzler/pippel/prog/blast_dbs_240314
BLASTN_DB_CHUNKS=10
BLASTN_DB_NAME=nt_240314
BLASTN_MAXTARSEQS=10
BLASTN_EVAL=1.0e-25
BLASTN_MAXTARSEQS=10
BLASTN_THREADS=16
BLASTN_MEM=120G		## 111Gb is the biggest chunk of the database
BLASTN_TIM=96:00:00 
BLASTN_TAXID=74615     
BLASTN_PARTITION=${SLURM_PARTITION}




########## OUTPUT_DIRS ##########
CHUNK_STATS_DIR=chunk_stats
COV_STATS_DIR=cov_stats
WINDOW_STATS_DIR=window_stats
ASM_VERSION=1
BLOB_DIR=${ToLID}_${ASM_VERSION}
BLOB_RESULTS_DIR=results
## this is updated every week 
TAXONOMY_DB=/sw/data/ncbi_taxonomy/latest/new_taxdump


function create_meta_yaml ()
{
    { 
        ## add assembly block 
        IFS=' ' read -r -a stats <<<  $BTK_SINGULARITY_IMAGE awk '{if ($1 ~ /^>/) {c++} else {s+=length($1)}} END {print c" "s}' ${ASM}

        echo "assembly:"
        echo "  accession: ${ASM_TYPE}"
        echo "  level: ${ASM_LEVEL}"
        echo "  scaffold-count: ${stats[0]}"
        echo "  span: ${stats[1]}"
        echo "  prefix: ${ToLID}_${ASM_LEVEL}_${ASM_VERSION}"
        echo "  file: ${ASM}"

        ## add busco block 
        echo "busco:"
        echo "  lineages:"
        for l in ${BUSCO_BASAL_LINEAGES[@]}; 
        do
            echo "  - ${l}"
        done   

        ## add reads block 
        echo "reads:"
        echo "  coverage:"
        echo "    max: ${MAX_COV}"
        echo "    min: ${MIN_COV}"
        if [[ ${READS_TYPE} == "map-hifi" || ${READS_TYPE} == "map-pb" ]]
        then 
            echo "  single:"
            for f in $(cat ${READS})
            do 
                echo "    - prefix: $(basename ${f%.*.*})"
                echo "      file: $f"
                echo "      platform: PACBIO"
            done
        elif [[ ${READS_TYPE} == "map-ont" ]]
        then 
            echo "  single:"
            for f in $(cat ${READS})
            do 
                echo "    - prefix: $(basename ${f%.*.*})"
                echo "      file: $f"
                echo "      platform: ONT"
            done            
        elif [[ ${READS_TYPE} == "illumina" ]]
        then 
            echo "  paired:"
            IFS=$'\n' 
            for f in $(cat ${READS})
            do 
                echo "    - prefix: $(basename $(echo "${f}" | awk '{print $1}') | sed -e "s/.f[aq].gz$//;s/.fast[aq].gz$//;s/.f[aq]$//;s/.fast[aq]$//")"
                echo "      file: $(echo "${f}" | tr " " ",")"
                echo "      platform: ILLUMINA"
            done            

        else 
            (>&2 echo -e "[ERROR] function create_meta_yaml(): READS_TYPE: ${READS_TYPE} not supported!")
            exit 1
        fi 
        
        ## add taxon block
        echo "taxon:"
        echo "  name: ${SPECIES_NAME}"
        echo "  taxid: '${TAXID}'"
        echo "  phylum: ${PHYLUM}"

        ## add version line
        echo "version: ${ASM_VERSION}"
        
    } > $1
}
