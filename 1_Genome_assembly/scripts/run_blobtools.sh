#!/bin/bash 

# exit when any command fails
set -e
# exit when any pipe fail
set -o pipefail


### pipeline 
#  0. setup step                                     runs locally
#  1. windowmasker                                   (Dependency: NONE)
#  2. busco                                          (Dependency: NONE)
#  3. chunk_fasta                                    (Dependency: 1,2)
#  4. chunk fasta by busco                           (Dependency: 1,2)
#  5. diamond blastx                                 (Dependency: 4)
#  6. diamond blastp                                 (Dependency: 1,2)
#  7. minimap2 index                                 (Dependency: NONE)
#  8. minimap2 align                                 (Dependency: 7)
#  9. extract nothit fasta                           (Dependency: 1,5)
# 10. chunk nothit fasta                             (Dependency: 9)
# 11. blastn                                         (Dependency: 10)
# 12. unchunk blastn                                 (Dependency: 11)
# 13. bamtools-stats                                 (Dependency: 8)
# 14. blobtk-depth                                   (Dependency: 8)
# 15. wm-chunk-stats                                 (Dependency: 1)
# 16. count_busco_genes                              (Dependency: 2,15)
# 17. add_cov_to_tsv                                 (Dependency: 14,16)
# 18. get-window-stats                               (Dependency: 17)
# 19. blobtools_create                               (Dependency: 2,5,6,11,18)
# 20. blobtools_view                                 (Dependency: 19)
# 21. cleanup intermediate fles                      (Dependency: 20)")


usage() {
    (>&2 echo -e "usage: bash $0 blobtools.config.sh [FROM_STEP TO_STEP] ")
    (>&2 echo -e "")
    (>&2 echo -e "The default pipeline runs from step 0 to step 21: ($0 blobtools.config.sh 0 21)")
    (>&2 echo -e "")
    (>&2 echo -e "the individual steps of the pipeline are:\n")
    (>&2 echo -e "\
 0. setup step                                     runs locally
 1. windowmasker                                   (Dependency: NONE)
 2. busco                                          (Dependency: NONE)
 3. chunk_fasta                                    (Dependency: 1,2)
 4. chunk fasta by busco                           (Dependency: 1,2)
 5. diamond blastx                                 (Dependency: 4)
 6. diamond blastp                                 (Dependency: 1,2)
 7. minimap2 index                                 (Dependency: NONE)
 8. minimap2 align                                 (Dependency: 7)
 9. extract nothit fasta                           (Dependency: 1,5)
10. chunk nothit fasta                             (Dependency: 9)
11. blastn                                         (Dependency: 10)
12. unchunk blastn                                 (Dependency: 11)
13. bamtools-stats                                 (Dependency: 8)
14. blobtk-depth                                   (Dependency: 8)
15. wm-chunk-stats                                 (Dependency: 1)
16. count_busco_genes                              (Dependency: 2,15)
17. add_cov_to_tsv                                 (Dependency: 14,16)
18. get-window-stats                               (Dependency: 17)
19. blobtools_create                               (Dependency: 2,5,6,11,18)
20. blobtools_view                                 (Dependency: 19)
21. cleanup intermediate fles                      (Dependency: 20)")
    exit 1
}

config=${1}
if [[ ! -f "${config}" ]]
then
    (>&2 echo -e "[ERROR] Blobtoolkit config file required!")
    usage 
    exit 1
fi 

source ${config}

FROM=${2:-0}
TO=${3:-20}

re='^[0-9]+$'
if ! [[ $FROM =~ $re ]] ;
then
    (>&2 echo -e "[ERROR]: FROM_STEP ${FROM} must be a number")
    usage
    exit 1
fi
if ! [[ $TO =~ $re ]] ;
then
    (>&2 echo -e "[ERROR]: TO_STEP ${TO} must be a number")
    usage
    exit 1
fi

if [[ $FROM -gt $TO ]] ;
then
    (>&2 echo -e "[ERROR]: FROM_STEP ${FROM} must be smaller or equal to TO_STEP ${TO}")
    usage
    exit 1
fi

if [[ $FROM -lt 0 ]] ;
then
    (>&2 echo -e "[ERROR]: FROM_STEP ${FROM} must be in [1,21]")
    usage
    exit 1
fi

if [[ $TO -gt 21 ]] ;
then
    (>&2 echo -e "[ERROR]: TO_STEP ${TO} must be in [1,21]")
    usage
    exit 1
fi

## check if all required databases, images, and files exist
if [[ ! -f $(echo $BTK_SINGULARITY_IMAGE | awk '{print $NF}') ]]
then 
    (>&2 echo -e "[ERROR]: singularity image is not available $(echo $BTK_SINGULARITY_IMAGE | awk '{print $NF}')")
    usage
    exit 1
fi

nerr=0
for l in ${BUSCO_LINEAGES[@]} ${BUSCO_BASAL_LINEAGES[@]}; 
do 
    if [[ ! -d ${BUSCO_DOWNLOAD_DIR}/lineages/${l} ]]
    then 
        (>&2 echo -e "[ERROR]: Cannot find busco lineage dir ${BUSCO_DOWNLOAD_DIR}/lineages/${l}")
        nerr=$((nerr+1))        
    fi 
done 

if [[ $nerr -gt 0 ]]
then 
    (>&2 echo -e "[ERROR]: Some busco lineages are missing")
    usage
    exit 1
fi 

if [[ ! -f ${DIAMOND_X_DB} ]]
then 
    (>&2 echo -e "[ERROR]: Diamondx db not available: DIAMOND_X_DB=${DIAMOND_X_DB}")
    usage
    exit 1
fi 

if [[ ! -f ${DIAMOND_P_DB} ]]
then 
    (>&2 echo -e "[ERROR]: Diamondp  db not available: DIAMOND_P_DB=${DIAMOND_P_DB}")
    usage
    exit 1
fi 

if [[ ! -d ${TAXONOMY_DB} ]]
then 
    (>&2 echo -e "[ERROR]: TAXONOMY_DB  db not available: TAXONOMY_DB=${TAXONOMY_DB}")
    usage
    exit 1
fi 

if [[ ! -d ${BLASTN_DB_PATH} ]]
then 
    (>&2 echo -e "[ERROR]: BLASTN_DB_PATH  db not available: BLASTN_DB_PATH=${BLASTN_DB_PATH}")
    usage
    exit 1
fi 

nerr=0
for x in $(seq 1 ${BLASTN_DB_CHUNKS})
do 
    if [[ ! -f ${BLASTN_DB_PATH}/${BLASTN_DB_NAME}_${x}.ndb ]]
    then 
        (>&2 echo -e "[ERROR]: BLASTN_DB chunk $x is not available ${BLASTN_DB_PATH}/${BLASTN_DB_NAME}_${x}.ndb")
        nerr=$((nerr+1))
    fi 
done 
if [[ $nerr -gt 0 ]]
then 
    (>&2 echo -e "[ERROR]: Some blast database chunks are missing. Plz check the variables: BLASTN_DB_NAME, BLASTN_DB_CHUNKS and BLASTN_DB_PATH in your config file")
    usage
    exit 1
fi 

## ensure that log directory exist

mkdir -p "${LOG_DIR}"

######################### step 0 - set up directory and file structure ##############################
cur_jid=0
JobName=setup
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then 

    for dirName in MASKER_DIR CHUNK_DIR TMP_ASM_DIR BUSCO_DIR BLOB_RESULTS_DIR BLOB_DIR CHUNK_STATS_DIR COV_STATS_DIR WINDOW_STATS_DIR MINIMAP2_DIR BLASTN_DIR DIAMOND_P_DIR DIAMOND_X_DIR
    do 
        TMP="${dirName}"
        if [[ -n ${!TMP} &&  "x${!TMP}" != "x" ]]
        then 
            mkdir -p ${!TMP}
        else 
            (>&2 echo -e "[ERROR]: Step  ${cur_jid} - Variable $dirName must be set in the config file!")
            exit 1
        fi
    done 

    if [[ -f "${TMP_ASM_DIR}/asm.fasta" ]]
    then 
        (>&2 echo -e "[ERROR]: Step  ${cur_jid} - temprary file ${TMP_ASM_DIR}/asm.fasta already present! When rerunning step 0 please remove the old file ${TMP_ASM_DIR}/asm.fasta or change the dir via the variable TMP_ASM_DIR in the config file")
        exit 1
    fi 

    # link assembly into current dir 
    if [[ -f ${ASM} ]]
    then 
        if [[ "${ASM##*.}" == ".gz" ]]
        then 
            zcat ${ASM} > "${TMP_ASM_DIR}"/asm.fasta
        else 
            ln -s -r ${ASM} "${TMP_ASM_DIR}"/asm.fasta
        fi 
    else
        (>&2 echo -e "[ERROR]: Step  ${cur_jid} - Variable ASM must be set and needs to refer to an assembly file!")
        exit 1
    fi 
else 
    (>&2 echo -e "[INFO] Skip step  ${cur_jid} - ${JobName}!")
fi


######################### step 1 - windowmasker  ##############################
cur_jid=1
JobName=windowmasker
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then 
    
    dep=""
    cmd1="${BTK_SINGULARITY_IMAGE} windowmasker -in ${TMP_ASM_DIR}/asm.fasta -infmt fasta -mem 32000 -smem 4096 -mk_counts -sformat obinary -out ${MASKER_DIR}/asm.wm.counts"
    cmd2="${BTK_SINGULARITY_IMAGE} windowmasker -in ${TMP_ASM_DIR}/asm.fasta -infmt fasta -ustat ${MASKER_DIR}/asm.wm.counts -dust T -outfmt fasta -out ${MASKER_DIR}/asm.wm.fasta"
    
    jid1=$(sbatch ${ADD_SLURM_OPT} -c ${MASKER_THREADS} -n 1 -p ${MASKER_PARTITION} --mem=${MASKER_MEM} -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --time=${MASKER_TIM} -J "${JobName}" --wrap="echo \"${cmd1} && ${cmd2}\" && ${cmd1} && ${cmd2}")
    echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName} job: ${jid1##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step  ${cur_jid} - ${JobName}!")
fi 

######################### step 2 - run busco  ##############################
cur_jid=2
JobName=busco_v5
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then 
    # there is no slurm dependency - but step 0 has to run 
    dep=""
    # sanity check 
    if [[ ! -f "${TMP_ASM_DIR}"/asm.fasta ]]
    then 
        (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Input fasta "${TMP_ASM_DIR}"/asm.fasta missing") 
        exit 1
    fi 
    
    all_jids2=""
    for l in ${BUSCO_LINEAGES[@]} ${BUSCO_BASAL_LINEAGES[@]}; 
    do 
        cmd1="mkdir -p ${BUSCO_DIR}/asm_$l ${BUSCO_DIR}/asm_busco_${l}"
        cmd2="${BTK_SINGULARITY_IMAGE} busco -f -i ${TMP_ASM_DIR}/asm.fasta -o ${BUSCO_DIR}/asm_$l --download_path ${BUSCO_DOWNLOAD_DIR} -l ${l} --offline -m geno -c ${BUSCO_THREADS}"
        cmd3="${BTK_SINGULARITY_IMAGE} bgzip -@${BGZIP_THREADS} -c ${BUSCO_DIR}/asm_${l}/run_${l}/full_table.tsv > ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz"
        cmd4="${BTK_SINGULARITY_IMAGE} bgzip -@${BGZIP_THREADS} -c ${BUSCO_DIR}/asm_${l}/run_${l}/short_summary.txt > ${BUSCO_DIR}/asm_busco_${l}/short_summary.txt.gz"
        cmd5="${BTK_SINGULARITY_IMAGE} bgzip -@${BGZIP_THREADS} -c ${BUSCO_DIR}/asm_${l}/run_${l}/missing_busco_list.tsv > ${BUSCO_DIR}/asm_busco_${l}/missing_busco_list.tsv.gz"
        cmd6="tar czf ${BUSCO_DIR}/asm_busco_${l}/busco_sequences.tar.gz -C ${BUSCO_DIR}/asm_${l}/run_${l} busco_sequences"
        cmd7="rm -rf ${BUSCO_DIR}/asm_$l" 
        jid2=$(sbatch ${ADD_SLURM_OPT} -c ${BUSCO_THREADS} -n 1 -p ${BUSCO_PARTITION} --mem=${BUSCO_MEM} --time=${BUSCO_TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1} && ${cmd2} && ${cmd3} && ${cmd4} && ${cmd5} && ${cmd6} && ${cmd7}\" && ${cmd1} && ${cmd2} && ${cmd3} && ${cmd4} && ${cmd5} && ${cmd6} && ${cmd7}")
                
        if [[ "x${all_jids2}" == "x" ]]
        then 
            all_jids2="${jid2##* }"
        else
            all_jids2="${all_jids2}:${jid2##* }"
        fi

        echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName} job: (${l}): ${jid2##* } (${dep})"
    done
else 
    (>&2 echo -e "[INFO] Skip step  ${cur_jid} - ${JobName}!")
fi 

######################### step 3 - chunk fasta file  ##############################
cur_jid=3
JobName=chunk_fasta
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then 
    if [[ $FROM -lt ${cur_jid} ]]
    then 
        dep="--dependency=afterok:${jid1##* }"
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${MASKER_DIR}/asm.wm.fasta ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Input fasta ${MASKER_DIR}/asm.wm.fasta missing") 
            exit 1
        fi 
    fi
    
    cmd1="${BTK_SINGULARITY_IMAGE} btk pipeline chunk-fasta --in ${MASKER_DIR}/asm.wm.fasta --chunk ${CHUNK_NUM} --overlap ${CHUNK_OVL} --max-chunks ${CHUNK_MAX} --min-length ${CHUNK_MINLEN} --busco None --out None --bed ${CHUNK_DIR}/asm.fasta.bed"
    
    jid3=$(sbatch ${ADD_SLURM_OPT} ${dep} -c ${CHUNK_THREADS} -n 1 -p ${CHUNK_PARTITION} --mem=${CHUNK_MEM} --time=${CHUNK_TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")
    echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName} job: ${jid3##* } (${dep})"

else 
    (>&2 echo -e "[INFO] Skip step  ${cur_jid} - ${JobName}!")
fi 

######################### step 4 - chunk fasta by busco file  ##############################
cur_jid=4
JobName=chunk_fasta_by_busco
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then 
    ## INPUT
    ##    fasta = "%s/{assembly}.windowmasker.fasta" % windowmasker_path,
    ##    busco = "%s/{assembly}.busco.%s/full_table.tsv.gz" % (busco_path, config["busco"]["lineages"][0])
    ## OUTPUT
    ##    fasta = "{assembly}.fasta.chunks"

    if [[ $FROM -lt 2 ]]           
    then 
        dep="--dependency=afterok:${jid1##* }:${all_jids2}"
    elif [[ $FROM -lt 3 ]]           
    then 
        dep="--dependency=afterok:${all_jids2}"
        if [[ ! -f ${MASKER_DIR}/asm.wm.fasta ]]
        then 
            (>&2 echo -e "[ERROR]: Step  ${cur_jid} ${JobName} - Input fasta ${MASKER_DIR}/asm.wm.fasta missing") 
            exit 1
        fi 
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${MASKER_DIR}/asm.wm.fasta ]]
        then 
            (>&2 echo -e "[ERROR]: Step  ${cur_jid} ${JobName} - Input fasta ${MASKER_DIR}/asm.wm.fasta missing") 
            exit 1
        fi 
    fi
        
    cmd1="${BTK_SINGULARITY_IMAGE} btk pipeline chunk-fasta --in ${MASKER_DIR}/asm.wm.fasta --chunk ${CHUNK_NUM} --overlap ${CHUNK_OVL} --max-chunks ${CHUNK_MAX} --min-length ${CHUNK_MINLEN} --busco ${BUSCO_DIR}/asm_busco_${BUSCO_LINEAGES[0]}/full_table.tsv.gz --out ${CHUNK_DIR}/asm.fasta.chunks --bed None"
    
    jid4=$(sbatch ${ADD_SLURM_OPT} ${dep} -c ${CHUNK_THREADS} -n 1 -p ${CHUNK_PARTITION} --mem=${CHUNK_MEM} --time=${CHUNK_TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")
    echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName} job: ${jid4##* } (${dep})"

else 
    (>&2 echo -e "[INFO] Skip step  ${cur_jid} - ${JobName}!")
fi 


######################### step 5 - diamond blastx ##############################
cur_jid=5
JobName=diamond_blastx
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then 
    ## input:
    ##     fasta = "{assembly}.fasta.chunks",
    ##     dmnd = "%s/%s.dmnd" % (similarity_setting(config, "diamond_blastx", "path"), similarity_setting(config, "diamond_blastx", "name"))
    ## output:
    ##     "{assembly}.diamond.reference_proteomes.out.raw"
    if [[ $FROM -lt ${cur_jid} ]]
    then 
        dep="--dependency=afterok:${jid4##* }"
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${CHUNK_DIR}/asm.fasta.chunks ]]
        then 
            (>&2 echo -e "[ERROR]: Step  ${cur_jid} ${JobName} - Input fasta ${CHUNK_DIR}/asm.fasta.chunks missing") 
            exit 1
        fi 
    fi
        
    cmd1="${BTK_SINGULARITY_IMAGE} diamond blastx --query ${CHUNK_DIR}/asm.fasta.chunks --db ${DIAMOND_X_DB} --outfmt 6 qseqid staxids bitscore qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore --max-target-seqs ${DIAMOND_X_MAXTARSEQS} --max-hsps 1 --evalue ${DIAMOND_X_EVAL} --threads ${DIAMOND_X_THREADS} --taxon-exclude ${DIAMOND_X_TAXID} > ${DIAMOND_X_DIR}/asm.diamond.reference_proteomes.out.raw"
    cmd2="${BTK_SINGULARITY_IMAGE} btk pipeline unchunk-blast --in ${DIAMOND_X_DIR}/asm.diamond.reference_proteomes.out.raw --count ${DIAMOND_X_MAXTARSEQS} --out ${DIAMOND_X_DIR}/asm.diamond.reference_proteomes.out"
    jid5=$(sbatch ${ADD_SLURM_OPT} ${dep} -c ${DIAMOND_X_THREADS} -n 1 -p ${DIAMOND_X_PARTITION} --mem=${DIAMOND_X_MEM} --time=${DIAMOND_X_TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1} && ${cmd2}\" && ${cmd1} && ${cmd2}")
    echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName}: ${jid5##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step  ${cur_jid} - ${JobName}!")
fi 


######################### step 6 - diamond blastp ##############################
cur_jid=6
JobName=diamond_blastp
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## extract_busco_genes.smk
    ## input:
    ##     busco = expand("%s/%s.busco.{lineage}/full_table.tsv.gz" % (busco_path, config["assembly"]["prefix"]), lineage=get_basal_lineages(config)),
    ## output:
    ##     fasta = "{assembly}.busco_genes.fasta"

    ## run_diamond_blastp.smk
    ## input:
    ##     fasta = "{assembly}.busco_genes.fasta",
    ##     dmnd = "%s/%s.dmnd" % (similarity_setting(config, "diamond_blastp", "path"), similarity_setting(config, "diamond_blastx", "name"))
    ## output:
    ##     "{assembly}.diamond.busco_genes.out"

    ## combine rules extract_busco_genes.smk and run_diamond_blastp.smk into step 6

    if [[ $FROM -lt 2 ]]           
    then 
        dep="--dependency=afterok:${jid1##* }:${all_jids2}"
    else 
        dep=""
    fi

    busco_arg=""
    for l in ${BUSCO_BASAL_LINEAGES[@]}; 
    do 
        busco_arg="${busco_arg} --busco ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz"
    done 

    cmd1="${BTK_SINGULARITY_IMAGE} btk pipeline extract-busco-genes ${busco_arg} --out ${DIAMOND_P_DIR}/asm.busco_genes.fasta"
    cmd2="${BTK_SINGULARITY_IMAGE} diamond blastp --query ${DIAMOND_P_DIR}/asm.busco_genes.fasta --db ${DIAMOND_P_DB} --outfmt 6 qseqid staxids bitscore qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore --max-target-seqs ${DIAMOND_P_MAXTARSEQS} --max-hsps 1 --evalue ${DIAMOND_P_EVAL} --threads ${DIAMOND_X_THREADS} --taxon-exclude ${DIAMOND_P_TAXID} > ${DIAMOND_P_DIR}/asm.diamond.busco_genes.out"

    jid6=$(sbatch ${ADD_SLURM_OPT} ${dep} -c ${DIAMOND_P_THREADS} -n 1 -p ${DIAMOND_P_PARTITION} --mem=${DIAMOND_P_MEM} --time=${DIAMOND_P_TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1} && ${cmd2}\" && ${cmd1} && ${cmd2}")
    echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName} job: ${jid6##* } (${dep})"

else 
    (>&2 echo -e "[INFO] Skip step  ${cur_jid} - ${JobName}!")
fi 

######################### step 7 - minimap2 index ##############################
cur_jid=7
JobName=minimap2_index
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    dep=""

    if [[ ! -f ${TMP_ASM_DIR}/asm.fasta ]]
    then 
        (>&2 echo -e "[ERROR]: Step  ${cur_jid} ${JobName} - Input fasta ${TMP_ASM_DIR}/asm.fasta missing") 
        exit 1
    fi     
    
    cmd1="grep -v -e \">\" ${TMP_ASM_DIR}/asm.fasta | tr -d '\\n' | wc -c > ${MINIMAP2_DIR}/span.txt"
    cmd2="${BTK_SINGULARITY_IMAGE} minimap2 -t 3 -x ${MINIMAP2_TYPE} -I \$(cat ${MINIMAP2_DIR}/span.txt) -d ${MINIMAP2_DIR}/asm.${MINIMAP2_TYPE}.mmi ${TMP_ASM_DIR}/asm.fasta"

    jid7=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 3 -n 1 -p ${MINIMAP2_PARTITION} --mem=${MINIMAP2_MEM} --time=${MINIMAP2_TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="${cmd1} && ${cmd2}")
    echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName} job: ${jid7##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step  ${cur_jid} - ${JobName}!")
fi 

######################### step 8 - minimap2 align ##############################
cur_jid=8
JobName=minimap2_align
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    if [[ $FROM -lt ${cur_jid} ]]           
    then 
        dep="--dependency=afterok:${jid7##* }"
    else 
        dep=""
        if [[ ! -f ${MINIMAP2_DIR}/asm.${MINIMAP2_TYPE}.mmi ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Input index ${MINIMAP2_DIR}/asm.${MINIMAP2_TYPE}.mmi missing") 
            exit 1
        fi 
    fi
    
    all_jids8a=""
    file_counter=0;
    file_list_forMerging=""
    for f in $(cat ${READS})
    do 
        if [[ ! -f ${f} ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Cannot access read file $f") 
            exit 1 
        fi 

        fname=$(basename ${f%.*})

        cmd1="${BTK_SINGULARITY_IMAGE} minimap2 -t ${MINIMAP2_THREADS} -ax ${MINIMAP2_TYPE} ${MINIMAP2_DIR}/asm.${MINIMAP2_TYPE}.mmi ${f} | ${BTK_SINGULARITY_IMAGE} samtools view -h -T ${TMP_ASM_DIR}/asm.fasta - | ${BTK_SINGULARITY_IMAGE} samtools sort -@4 -O BAM -o ${MINIMAP2_DIR}/asm.${fname}.bam -"
        cmd2="${BTK_SINGULARITY_IMAGE} samtools index -c ${MINIMAP2_DIR}/asm.${fname}.bam ${MINIMAP2_DIR}/asm.${fname}.bam.csi"

        jid8a=$(sbatch ${ADD_SLURM_OPT} ${dep} -c ${MINIMAP2_THREADS} -n 1 -p ${MINIMAP2_PARTITION} --mem=${MINIMAP2_MEM} --time=${MINIMAP2_TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1} && ${cmd2}\" && ${cmd1} && ${cmd2}")
        echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName} job: (${f}): ${jid8a##* }  (${dep})" 
        
        file_counter=$((file_counter+1))
        file_list_forMerging="${file_list_forMerging} ${MINIMAP2_DIR}/asm.${fname}.bam"

        if [[ "x${all_jids8a}" == "x" ]]
        then 
            all_jids8a="${jid8a##* }"
        else
            all_jids8a="${all_jids8a}:${jid8a##* }"
        fi
    done


    JobName=minimap2_merge
    dep="--dependency=afterok:${all_jids8a}"

    if [[ ${file_counter} -eq 0 ]]
    then 
        (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Cannot access read file $f") 
        exit 1 
    elif [[ ${file_counter} -eq 1 ]]
    then 
        f=$(cat ${READS})
        fname=$(basename ${f%.*})

        cmd1="ln -s -r -f ${MINIMAP2_DIR}/asm.${fname}.bam ${MINIMAP2_DIR}/asm_minimap2.bam"
        cmd2="ln -s -r -f ${MINIMAP2_DIR}/asm.${fname}.bam.csi ${MINIMAP2_DIR}/asm_minimap2.bam.csi"        

        jid8b=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${MINIMAP2_PARTITION} --mem=1Gb --time=00:15:00 -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1} && ${cmd2}\" && ${cmd1} && ${cmd2}")
        echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName} job: (${f}): ${jid8b##* }  (${dep})" 
    else 

        threads=$((file_counter + 1))
        if [[ ${threads} -gt ${MINIMAP2_THREADS} ]]
        then 
            threads=${MINIMAP2_THREADS}
        fi

        cmd1="${BTK_SINGULARITY_IMAGE} samtools merge -@ ${threads} ${MINIMAP2_DIR}/asm_minimap2.bam ${file_list_forMerging}"
        cmd2="${BTK_SINGULARITY_IMAGE} samtools index -c ${MINIMAP2_DIR}/asm_minimap2.bam ${MINIMAP2_DIR}/asm_minimap2.bam.csi"

        jid8b=$(sbatch ${ADD_SLURM_OPT} ${dep} -c ${threads} -n 1 -p ${MINIMAP2_PARTITION} --mem=${MINIMAP2_MEM} --time=${MINIMAP2_TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1} && ${cmd2}\" && ${cmd1} && ${cmd2}")
        echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName} job: (${f}): ${jid8b##* }  (${dep})" 
    fi
    jid8=${jid8b}
else 
    (>&2 echo -e "[INFO] Skip step  ${cur_jid} - ${JobName}!")
fi 

######################### step 9 - extract nothit fasta (prepare blastn) ##############################
cur_jid=9
JobName=extract-nohit-fasta
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## input:
    ##     blastx = "%s/%s.diamond.reference_proteomes.out" % (diamond_path, config["assembly"]["prefix"]),
    ##     fasta = "%s/{assembly}.windowmasker.fasta" % windowmasker_path
    ## output:
    ##     "{assembly}.nohit.fasta"
    
    if [[ $FROM -lt 2 ]]           
    then 
        dep="--dependency=afterok:${jid1##* }:${jid5##* }"
    elif [[ $FROM -lt 6 ]]           
    then 
        dep="--dependency=afterok:${jid5##* }"
        if [[ ! -f ${MASKER_DIR}/asm.wm.fasta ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Input fasta ${MASKER_DIR}/asm.wm.fasta missing") 
            exit 1
        fi 
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${MASKER_DIR}/asm.wm.fasta ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Input fasta ${MASKER_DIR}/asm.wm.fasta missing") 
            exit 1
        fi 

        if [[ ! -f ${DIAMOND_X_DIR}/asm.diamond.reference_proteomes.out ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Input diamond_x result file ${DIAMOND_X_DIR}/asm.diamond.reference_proteomes.out missing") 
            exit 1
        fi 
    fi
        
    ### unfortunately its not working via slurm submission 
    #cmd1="${BTK_SINGULARITY_IMAGE} seqtk subseq ${MASKER_DIR}/asm.wm.fasta <(grep '>' ${MASKER_DIR}/asm.wm.fasta | grep -v -w -f <(awk '{ if(\$14 < ${DIAMOND_X_EVAL} ) { print \$1} }' ${DIAMOND_X_DIR}/asm.diamond.reference_proteomes.out | sort | uniq) | cut -f1 | sed 's/>//') > ${BLASTN_DIR}/asm.nohit.fasta"
    # workaround: create temporary files
    cmd1="awk '{ if(\$14 < ${DIAMOND_X_EVAL} ) { print \$1} }' ${DIAMOND_X_DIR}/asm.diamond.reference_proteomes.out | sort | uniq > ${BLASTN_DIR}/tmp_hits1.txt"
    cmd2="grep '>' ${MASKER_DIR}/asm.wm.fasta | grep -v -w -f ${BLASTN_DIR}/tmp_hits1.txt | cut -f1 | sed 's/>//' > ${BLASTN_DIR}/tmp_hits2.txt"
    cmd3="${BTK_SINGULARITY_IMAGE} seqtk subseq ${MASKER_DIR}/asm.wm.fasta ${BLASTN_DIR}/tmp_hits2.txt > ${BLASTN_DIR}/asm.nohit.fasta"

    jid9=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 2 -n 1 -p ${SLURM_PARTITION} --mem=${MEM} --time=${TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1} && ${cmd2} && ${cmd3}\" && ${cmd1} && ${cmd2} && ${cmd3}")
    echo "BLOBTOOLKIT Step  ${cur_jid} - submit ${JobName} job: ${jid9##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step  ${cur_jid} - ${JobName}!")
fi 


######################### step 10 - chunk nohit fasta (prepare blastn) ##############################
cur_jid=10
JobName=chunk-nohit-fasta
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## input:
    ##     fasta = "{assembly}.nohit.fasta",
    ## output:
    ##     fasta = "{assembly}.nohit.fasta.chunks"
    
    if [[ $FROM -lt ${cur_jid} ]]           
    then 
        dep="--dependency=afterok:${jid9##* }"
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${BLASTN_DIR}/asm.nohit.fasta ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Input fasta ${BLASTN_DIR}/asm.nohit.fasta missing") 
            exit 1
        fi 
    fi
        
    cmd1="${BTK_SINGULARITY_IMAGE} btk pipeline chunk-fasta --in ${BLASTN_DIR}/asm.nohit.fasta --chunk ${CHUNK_NUM} --overlap ${CHUNK_OVL} --max-chunks ${CHUNK_MAX} --min-length ${CHUNK_MINLEN} --busco None --out ${BLASTN_DIR}/asm.nohit.fasta.chunks --bed None"

    jid10=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 2 -n 1 -p ${SLURM_PARTITION} --mem=${MEM} --time=${TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")
    echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid10##* } (${dep})"

else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 

######################### step 11 - blastn ##############################
cur_jid=11
JobName=blastn
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## input:
    ##     fasta = "{assembly}.nohit.fasta.chunks",
    ##     db = "%s/%s.nal" % (similarity_setting(config, "blastn", "path"), similarity_setting(config, "blastn", "name"))
    ## output:
    ##     "{assembly}.blastn.nt.out.raw"
    if [[ $FROM -lt ${cur_jid} ]]           
    then 
        dep="--dependency=afterok:${jid10##* }"
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${BLASTN_DIR}/asm.nohit.fasta.chunks ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Input fasta ${BLASTN_DIR}/asm.nohit.fasta.chunks missing") 
            exit 1
        fi 
    fi

    #BLASTN_DB_PATH=/proj/snic2022-6-208/private/martin/prog/blast_dbs
    #BLASTN_DB_CHUNKS=10
    #BLASTN_DB_NAME=nt_230613

    #cmd1="${BTK_SINGULARITY_IMAGE} blastn -task megablast -query ${BLASTN_DIR}/asm.nohit.fasta.chunks -db ${BLASTN_DB} -outfmt \"6 qseqid staxids bitscore std\" -max_target_seqs ${BLASTN_MAXTARSEQS} -max_hsps 1 -evalue ${BLASTN_EVAL} -num_threads ${BLASTN_THREADS} -negative_taxid ${BLASTN_TAXID} -lcase_masking -dust \"20 64 1\" > ${BLASTN_DIR}/asm.blastn.nt.out.raw 2> ${BLASTN_DIR}/run_blastn.log || sleep 30; if [ -s ${BLASTN_DIR}/run_blastn.log ]; then echo \"Restarting blastn without taxid filter\" >> ${BLASTN_DIR}/run_blastn.log; ${BTK_SINGULARITY_IMAGE} blastn -task megablast -query ${BLASTN_DIR}/asm.nohit.fasta.chunks -db ${BLASTN_DB} -outfmt \"6 qseqid staxids bitscore std\" -max_target_seqs ${BLASTN_MAXTARSEQS} -max_hsps 1 -evalue ${BLASTN_EVAL} -num_threads ${BLASTN_THREADS} -lcase_masking -dust \"20 64 1\" > ${BLASTN_DIR}/asm.blastn.nt.out.raw 2> ${BLASTN_DIR}/run_blastn.log; fi"
    
    db_name="${BLASTN_DB_PATH}/${BLASTN_DB_NAME}_\${SLURM_ARRAY_TASK_ID}"
    out_file="${BLASTN_DIR}/asm.blastn.nt_\${SLURM_ARRAY_TASK_ID}.out.raw"
    out_log="${BLASTN_DIR}/run_blastn_\${SLURM_ARRAY_TASK_ID}.log"
    
    blast_fmt="6 qseqid staxids bitscore std"
    blast_query="${BLASTN_DIR}/asm.nohit.fasta.chunks"

    cmd1="${BTK_SINGULARITY_IMAGE} blastn -task megablast -query ${blast_query} -db ${db_name} -outfmt \"${blast_fmt}\" -max_target_seqs ${BLASTN_MAXTARSEQS} -max_hsps 1 -evalue ${BLASTN_EVAL} -num_threads ${BLASTN_THREADS} -negative_taxid ${BLASTN_TAXID} -lcase_masking -dust \"20 64 1\" > ${out_file} 2> ${out_log} || sleep 30; if [ -s ${out_log} ]; then echo \"Restarting blastn without taxid filter\" >> ${out_log}; ${BTK_SINGULARITY_IMAGE} blastn -task megablast -query ${blast_query} -db ${db_name} -outfmt \"${blast_fmt}\" -max_target_seqs ${BLASTN_MAXTARSEQS} -max_hsps 1 -evalue ${BLASTN_EVAL} -num_threads ${BLASTN_THREADS} -lcase_masking -dust \"20 64 1\" > ${out_file} 2> ${out_log}; fi"
    jid11_1=$(sbatch ${ADD_SLURM_OPT} ${dep} -c ${BLASTN_THREADS} -a 1-${BLASTN_DB_CHUNKS} -n 1 -p ${BLASTN_PARTITION} --mem=${BLASTN_MEM} --time=${BLASTN_TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A_%a.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A_%a.out --wrap="echo \"${cmd1}\" && ${cmd1}")
    echo "BLOBTOOLKIT Step ${cur_jid} - ${JobName} job: ${jid11_1##* }  (${dep})"
    dep="--dependency=afterok:${jid11_1##* }"
    JobName=concatBlastChunks
    cmd1="cat ${BLASTN_DIR}/asm.blastn.nt_*.out.raw > ${BLASTN_DIR}/asm.blastn.nt.out.raw"    
    jid11_2=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${BLASTN_PARTITION} --mem=1G --time=00:10:00 -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")

    jid11="${jid11_2}"
else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 

######################### step 12 - unchunk blastn ##############################
cur_jid=12
JobName=unchunk-blastn
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## input:
    ##     "{assembly}.blastn.nt.out.raw"
    ## output:
    ##     "{assembly}.blastn.nt.out"

    if [[ $FROM -lt ${cur_jid} ]]           
    then 
        dep="--dependency=afterok:${jid11##* }"
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${BLASTN_DIR}/asm.blastn.nt.out.raw ]]
        then 
            (>&2 echo -e "[ERROR]: Step 12 unchunk blastn - Input ${BLASTN_DIR}/asm.blastn.nt.out.raw missing") 
            exit 1
        fi 
    fi
    
    cmd1="${BTK_SINGULARITY_IMAGE} btk pipeline unchunk-blast --in ${BLASTN_DIR}/asm.blastn.nt.out.raw --count ${BLASTN_MAXTARSEQS} --out ${BLASTN_DIR}/asm.blastn.nt.out"
    jid12=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${SLURM_PARTITION} --mem=${MEM} --time=${TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")
    echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid12##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 


######################### step 13 - bamtools stats ##############################
cur_jid=13
JobName=bamtools-stats
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## run_bamtools_stats.smk
    ## input:
    ##     bam = "%s/{assembly}.{sra}.bam" % minimap_path
    ## output:
    ##     "{assembly}.{sra}.bam.stats"

    if [[ $FROM -lt 9 ]]           
    then 
        dep="--dependency=afterok:${jid8##* }"
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${MINIMAP2_DIR}/asm_minimap2.bam || ! -f ${MINIMAP2_DIR}/asm_minimap2.bam.csi ]]
        then 
            (>&2 echo -e "[ERROR]: Step 13 bamtools stats - one of the two files are missing: ${MINIMAP2_DIR}/asm_minimap2.bam ${MINIMAP2_DIR}/asm_minimap2.bam.csi!") 
            exit 1
        fi 
    fi
        
    cmd1="${BTK_SINGULARITY_IMAGE} bamtools stats -in ${MINIMAP2_DIR}/asm_minimap2.bam -insert > ${MINIMAP2_DIR}/asm_minimap2.bam.stats"
    
    jid13=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${SLURM_PARTITION} --mem=${MEM} --time=${TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")
    echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid13##* } (${dep})"

else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 

######################### step 14 - blobtk depth ##############################
cur_jid=14
JobName=blobtk-depth
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## run_blobtk_depth:
    ## input:
    ##     bam = "%s/{assembly}.{sra}.bam" % minimap_path,
    ##     csi = "%s/{assembly}.{sra}.bam.csi" % minimap_path,
    ## output:
    ##     bed = "{assembly}.{sra}.regions.bed.gz"

    if [[ $FROM -lt 9 ]]           
    then 
        dep="--dependency=afterok:${jid8##* }"
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${MINIMAP2_DIR}/asm_minimap2.bam || ! -f ${MINIMAP2_DIR}/asm_minimap2.bam.csi ]]
        then 
            (>&2 echo -e "[ERROR]: Step 13 bamtools stats - one of the two files are missing: ${MINIMAP2_DIR}/asm_minimap2.bam ${MINIMAP2_DIR}/asm_minimap2.bam.csi!") 
            exit 1
        fi 
    fi
    
    cmd1="${BTK_SINGULARITY_IMAGE} blobtk depth -b ${MINIMAP2_DIR}/asm_minimap2.bam -s 1000 -O ${MINIMAP2_DIR}/asm_minimap2.regions.bed.gz"
    
    jid14=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${SLURM_PARTITION} --mem=${MEM} --time=${TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")
    echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid14##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 

######################### step 15 - get chunk stats (based on windowmasker output)  ##############################
cur_jid=15
JobName=wm-chunk-stats
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## get_chunked_stats:
    ## input:
    ##     fasta = "%s/{assembly}.windowmasker.fasta" % windowmasker_path,
    ## output:
    ##     bed = "{assembly}.chunk_stats.mask.bed",
    ##     tsv = "{assembly}.chunk_stats.tsv",

    if [[ $FROM -lt 2 ]]           
    then 
        dep="--dependency=afterok:${jid1##* }"
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${MASKER_DIR}/asm.wm.fasta ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${MASKER_DIR}/asm.wm.fasta!") 
            exit 1
        fi 
    fi
    
    cmd1="${BTK_SINGULARITY_IMAGE} btk pipeline chunk-fasta --in ${MASKER_DIR}/asm.wm.fasta --chunk 1000 --overlap 0 --max-chunks 1000000000 --min-length 1000 --busco None --out None --bed ${CHUNK_STATS_DIR}/asm_chunk_stats.bed"

    jid15=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${SLURM_PARTITION} --mem=${MEM} --time=${TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")
    echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid15##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 

######################### step 16 - count_busco_genes  ##############################
cur_jid=16
JobName=count_busco_genes
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## count_busco_genes:
    ## input:
    ##     busco = expand("{{assembly}}.busco.{lineage}/full_table.tsv.gz", lineage=config["busco"]["lineages"]),
    ##     mask = "%s/{assembly}.chunk_stats.tsv" % chunk_stats_path
    ## output:
    ##     tsv = "{assembly}.chunk_stats.tsv"
    ## params:
    ##     busco = lambda wc: " --in ".join(expand("%s.busco.{lineage}/full_table.tsv.gz" % wc.assembly, lineage=config['busco']['lineages'])),
    
    if [[ $FROM -lt 3 ]]           
    then 
        dep="--dependency=afterok:${all_jids2}:${jid15##* }"
    elif [[ $FROM -lt 16 ]]           
    then 
        dep="--dependency=afterok:${jid15##* }"

        # sanity check
        err=0
        for l in ${BUSCO_LINEAGES[@]} ${BUSCO_BASAL_LINEAGES[@]}; 
        do 
            if [[ ! -f ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz ]]
            then 
                (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz!") 
                err=1
            fi
        done 
        if [[ $err -eq 1  ]]
        then 
            exit 1
        fi
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${CHUNK_STATS_DIR}/asm_chunk_stats.tsv ]] 
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${CHUNK_STATS_DIR}/asm_chunk_stats.tsv!") 
            exit 1
        fi 
        
        # sanity check
        err=0
        for l in ${BUSCO_LINEAGES[@]} ${BUSCO_BASAL_LINEAGES[@]}; 
        do 
            if [[ ! -f ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz ]]
            then 
                (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz!") 
                err=1
            fi
        done 
        if [[ $err -eq 1  ]]
        then 
            exit 1
        fi
    fi

    busco_flist=""
    for l in ${BUSCO_LINEAGES[@]} ${BUSCO_BASAL_LINEAGES[@]}; 
    do
        busco_flist="${busco_flist} --in ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz"
    done 

    cmd1="${BTK_SINGULARITY_IMAGE} btk pipeline count-busco-genes ${busco_flist} --mask ${CHUNK_STATS_DIR}/asm_chunk_stats.tsv --out ${BUSCO_DIR}/asm_chunk_stats.tsv"
    
    jid16=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${SLURM_PARTITION} --mem=${MEM} --time=${TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")
    echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid15##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 

######################### step 17 - add_cov_to_tsv  ##############################
cur_jid=17
JobName=add_cov_to_tsv
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## add_cov_to_tsv:
    ## input:
    ##     bed = expand("{{assembly}}.{sra}.regions.bed.gz", sra=reads_by_prefix(config).keys()),
    ##     tsv = "%s/{assembly}.chunk_stats.tsv" % busco_path
    ## output:
    ##     tsv = "{assembly}.chunk_stats.tsv"
    ## params:
    ##     bedfiles = gzipped_bed_cols(config)

    if [[ $FROM -lt 15 ]]           
    then 
        dep="--dependency=afterok:${jid14##* }:${jid16##* }"
    elif [[ $FROM -lt 17 ]]           
    then 
        dep="--dependency=afterok:${jid16##* }"
        # sanity check 
        if [[ ! -f ${MINIMAP2_DIR}/asm_minimap2.regions.bed.gz ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${MINIMAP2_DIR}/asm_minimap2.regions.bed.gz!") 
            exit 1
        fi 

    else 
        dep=""
        # sanity check 
        if [[ ! -f ${MINIMAP2_DIR}/asm_minimap2.regions.bed.gz || ! -f ${BUSCO_DIR}/asm_chunk_stats.tsv ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file(s) is missing: ${MINIMAP2_DIR}/asm_minimap2.regions.bed.gz or ${BUSCO_DIR}/asm_chunk_stats.tsv!") 
            exit 1
        fi 
    fi
    
    cmd1="echo \"s_cov\" > ${COV_STATS_DIR}/tmp.txt"
    cmd2="gunzip -c ${MINIMAP2_DIR}/asm_minimap2.regions.bed.gz | cut -f 4 >> ${COV_STATS_DIR}/tmp.txt"
    cmd3="paste ${BUSCO_DIR}/asm_chunk_stats.tsv ${COV_STATS_DIR}/tmp.txt > ${COV_STATS_DIR}/asm_chunk_stats.tsv"    
    cmd4="rm ${COV_STATS_DIR}/tmp.txt" 

    jid17=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${SLURM_PARTITION} --mem=${MEM} --time=${TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="${cmd1} && ${cmd2} && ${cmd3} && ${cmd4}")
    echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid17##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 



######################### step 18 - get window stats  ##############################
cur_jid=18
JobName=get-window-stats
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## get_window_stats:
    ## input:
    ##     tsv = "%s/{assembly}.chunk_stats.tsv" % cov_stats_path
    ## output:
    ##     tsv = "{assembly}.window_stats.tsv"
    ## params:
    ##     window = " --window ".join([str(window) for window in set_stats_windows(config)]),
    
    if [[ $FROM -lt 18 ]]           
    then 
        dep="--dependency=afterok:${jid17##* }"
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${COV_STATS_DIR}/asm_chunk_stats.tsv ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${COV_STATS_DIR}/asm_chunk_stats.tsv!") 
            exit 1
        fi 
    fi
    
    cmd1="${BTK_SINGULARITY_IMAGE} btk pipeline window-stats --in ${COV_STATS_DIR}/asm_chunk_stats.tsv --window 0.1 --window 0.01 --window 1 --out ${WINDOW_STATS_DIR}/asm_window_stats.tsv"

    jid18=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${SLURM_PARTITION} --mem=${MEM} --time=${TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")
    echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid18##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 


######################### step 19 - blobtools_create  ##############################
cur_jid=19
JobName=blobtools_create
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then
    ## run_blobtools_create:
    ## input:
    ##     tsv = "%s/%s.window_stats.tsv" % (window_stats_path, config["assembly"]["prefix"]),
    ##     busco = "%s/%s.busco.%s/full_table.tsv.gz" % (busco_path, config["assembly"]["prefix"], config['busco']['lineages'][0]),
    ##     blastp = "%s/%s.diamond.busco_genes.out" % (diamond_blastp_path, config["assembly"]["prefix"]),
    ##     taxdump = config["settings"]["taxdump"],
    ##     yaml = "%s.meta.yaml" % config["assembly"]["prefix"]
    ## output:
    ##     "%s/meta.json" % blobdir_name(config),
    ##     "%s/identifiers.json" % blobdir_name(config),
    ##     "%s/buscogenes_phylum.json" % blobdir_name(config),
    ##     expand("%s/{sra}_cov.json" % blobdir_name(config), sra=reads_by_prefix(config).keys()),
    ##     "%s/%s_busco.json" % (blobdir_name(config), config['busco']['lineages'][0])
    ## params:
    ##     statsdir = window_stats_path,
    ##     busco = lambda wc: " --busco ".join(expand("%s/%s.busco.{lineage}/full_table.tsv.gz" % (busco_path, config["assembly"]["prefix"]), lineage=config['busco']['lineages'])),
    ##     cov = blobtools_cov_flag(config),
    ##     blobdir = blobdir_name(config),
    ##     evalue = similarity_setting(config, "diamond_blastp", "import_evalue"),
    ##     max_target_seqs = similarity_setting(config, "diamond_blastp", "import_max_target_seqs")
    
    ## (Dependency: 2,5,6,11,18)
    DIAMONDX_IN="${DIAMOND_X_DIR}/asm.diamond.reference_proteomes.out"    # step 5
    DIAMONDP_IN="${DIAMOND_P_DIR}/asm.diamond.busco_genes.out"            # step 6
    BLASTN_IN="${BLASTN_DIR}/asm.blastn.nt.out"                           # step 11
    WINDOW_STATS_IN="${WINDOW_STATS_DIR}/asm_window_stats.tsv"            # step 18    

    if [[ $FROM -lt 3 ]]           
    then 
        dep="--dependency=afterok:${all_jids2}:${jid5##* }:${jid6##* }:${jid11##* }:${jid18##* }"
    elif [[ $FROM -lt 6 ]]           
    then 
        dep="--dependency=afterok:${jid5##* }:${jid6##* }:${jid11##* }:${jid18##* }"
        ## sanity check
        for l in ${BUSCO_LINEAGES[@]}; 
        do 
            fail=0
            if [[ ! -f ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz ]]
            then 
                fail=1
                (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz!") 
            fi 
            if [[ ${fail} -eq 1 ]]
            then 
                exit 1
            fi 
        done 
    elif [[ $FROM -lt 7 ]]           
    then 
        dep="--dependency=afterok:${jid6##* }:${jid11##* }:${jid18##* }"
        # sanity check 
        for l in ${BUSCO_LINEAGES[@]}; 
        do 
            fail=0
            if [[ ! -f ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz ]]
            then 
                fail=1
                (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz!") 
            fi 
            if [[ ${fail} -eq 1 ]]
            then 
                exit 1
            fi 
        done 
        if [[ ! -f ${DIAMONDP_IN} ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${DIAMONDP_IN}!") 
            exit 1
        fi 
    elif [[ $FROM -lt 11 ]]           
    then 
        dep="--dependency=afterok:${jid11##* }:${jid18##* }"
        # sanity check 
        for l in ${BUSCO_LINEAGES[@]}; 
        do 
            fail=0
            if [[ ! -f ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz ]]
            then 
                fail=1
                (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz!") 
            fi 
            if [[ ${fail} -eq 1 ]]
            then 
                exit 1
            fi 
        done
        if [[ ! -f ${DIAMONDP_IN} || ! -f ${DIAMONDX_IN} ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file(s) missing: DIAMONDP_IN=${DIAMONDP_IN}, DIAMONDX_IN=${DIAMONDX_IN}!") 
            exit 1
        fi 
    elif [[ $FROM -lt 19 ]]           
    then 
        dep="--dependency=afterok:${jid18##* }"
        for l in ${BUSCO_LINEAGES[@]}; 
        do 
            fail=0
            if [[ ! -f ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz ]]
            then 
                fail=1
                (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz!") 
            fi 
            if [[ ${fail} -eq 1 ]]
            then 
                exit 1
            fi 
        done
        # sanity check 
        if [[ ! -f ${DIAMONDP_IN} || ! -f ${DIAMONDX_IN} || ! -f ${BLASTN_IN} ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file(s) missing: ${DIAMONDP_IN}, ${DIAMONDX_IN}, ${BLASTN_IN}!") 
            exit 1
        fi 

        if [[ ! -f ${busco_in} || ! -f ${blastp_in} ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file(s) missing: ${busco_in}, ${blastp_in}!") 
            exit 1
        fi 
    else 
        dep=""
        # sanity check 
        if [[ ! -f ${DIAMONDP_IN} || ! -f ${DIAMONDX_IN} || ! -f ${BLASTN_IN} || ! -f ${WINDOW_STATS_IN} ]]
        then 
            (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file(s) missing: ${DIAMONDP_IN}, ${DIAMONDX_IN}, ${BLASTN_IN}, ${WINDOW_STATS_IN}!") 
            exit 1
        fi 
        for l in ${BUSCO_LINEAGES[@]}; 
        do 
            fail=0
            if [[ ! -f ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz ]]
            then 
                fail=1
                (>&2 echo -e "[ERROR]: Step ${cur_jid} ${JobName} - Required input file is missing: ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz!") 
            fi 
            if [[ ${fail} -eq 1 ]]
            then 
                exit 1
            fi 
        done 
    fi 
    
    ## create list of busco results
    busco_arg=""
    for l in ${BUSCO_LINEAGES[@]}; 
    do 
        busco_arg="${busco_arg} --busco ${BUSCO_DIR}/asm_busco_${l}/full_table.tsv.gz"
    done 

    #cmd1="eval $(cat ${config})" ### TODO don't know why source is not working
    cmd1="source ${config}"
    cmd2="create_meta_yaml meta.yaml"
    cmd3="${BTK_SINGULARITY_IMAGE} blobtools create --meta meta.yaml --fasta ${ASM} ${BLOB_DIR}"
    cmd4="${BTK_SINGULARITY_IMAGE} blobtools replace --bedtsvdir ${WINDOW_STATS_DIR} --taxid ${TAXID} --taxdump ${TAXONOMY_DB} --taxrule bestdistorder ${busco_arg} --hits ${DIAMONDX_IN} --hits ${BLASTN_IN} --evalue ${DIAMOND_X_EVAL} --hit-count ${DIAMOND_X_MAXTARSEQS} --threads 4 ${BLOB_DIR}"
    cmd5="${BTK_SINGULARITY_IMAGE} blobtools replace --taxdump ${TAXONOMY_DB} --taxrule=buscogenes --hits ${DIAMONDP_IN} --evalue ${DIAMOND_P_EVAL} --hit-count ${DIAMOND_P_MAXTARSEQS} --threads 4 ${BLOB_DIR}"    
    cmd6="${BTK_SINGULARITY_IMAGE} blobtools replace --taxdump ${TAXONOMY_DB} --taxrule bestdistorder=buscoregions --update-plot --hits ${BLASTN_IN} --hits ${DIAMONDX_IN} --evalue ${DIAMOND_X_EVAL} --hit-count ${DIAMOND_X_MAXTARSEQS} --threads 4 ${BLOB_DIR}" 

    jid19=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 4 -n 1 -p ${SLURM_PARTITION} --mem=10G --time=${TIM} -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd2} && ${cmd3} && ${cmd4} && ${cmd5} && ${cmd6}\" && bash -c \"${cmd1} && ${cmd2}\" && ${cmd3} && ${cmd4} && ${cmd5} && ${cmd6}")
    echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid19##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 

######################### step 20 - create plots  ##############################
cur_jid=20
JobName=blobtools_view 
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then

    if [[ $FROM -lt 20 ]]           
    then 
        dep="--dependency=afterok:${jid19##* }"
    else 
        dep=""
    fi

    # specify all fields that should be reported in the results table 
    # TODO: remove unneccessary fields
    #table_fields="gc,length,s_cov,buscogenes_species,buscogenes_genus,buscogenes_family,buscogenes_order,buscogenes_phylum,buscoregions_species,buscoregions_genus,buscoregions_family,buscoregions_order,buscoregions_phylum,bestdistorder_species,bestdistorder_genus,bestdistorder_family,bestdistorder_order,bestdistorder_phylum"
    table_fields="gc,length,s_cov,buscoregions_genus,buscoregions_family,buscoregions_order,buscoregions_phylum,bestdistorder_genus,bestdistorder_family,bestdistorder_order,bestdistorder_phylum"
    
    cmd1="${BTK_SINGULARITY_IMAGE} blobtools view --out ${BLOB_RESULTS_DIR} --host http://localhost --timeout 30 --ports 8000-8099 --view snail ${BLOB_DIR}" 
    cmd2="${BTK_SINGULARITY_IMAGE} blobtools filter --summary ${BLOB_DIR}/summary.json ${BLOB_DIR}"
    cmd3="${BTK_SINGULARITY_IMAGE} blobtools filter --table-fields ${table_fields} --table ${BLOB_RESULTS_DIR}/asm_result.tsv ${BLOB_DIR}"
    cmd4="${BTK_SINGULARITY_IMAGE} blobtools view --out ${BLOB_RESULTS_DIR} --host http://localhost --timeout 30 --ports 8000-8099 --view cumulative ${BLOB_DIR}"  
    ## command 3 has stupid bug : it creates a file btk__1.blob.square.png but it waits until a file btk__1.blob.circle.png is written 
    ## workaround for now: use a timeout of 30s   --> this job always fails 
    #cmd4="${BTK_SINGULARITY_IMAGE} blobtools view --out ${BLOB_RESULTS_DIR} --timeout 30 --view blob ${BLOB_DIR}"  
    cmd5="for p in circle hex square kite; do ${BTK_SINGULARITY_IMAGE} blobtools view --host http://localhost --timeout 30 --ports 8000-8099 --view blob --param plotShape=\${p} --param largeFonts=true --format png --out ${BLOB_RESULTS_DIR} ${BLOB_DIR}; done"

    jid20=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${SLURM_PARTITION} --mem=20G --time=04:00:00 -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1} && ${cmd2} && ${cmd3} && ${cmd4} && ${cmd5}\" && ${cmd1} && ${cmd2} && ${cmd3} && ${cmd4} && ${cmd5}")
    echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid20##* } (${dep})"
else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 


######################### step 21 - cleanup temporary data  ##############################
cur_jid=21
JobName=cleanup 
if [[ $FROM -le ${cur_jid} && $TO -ge ${cur_jid} ]]
then

    if [[ $FROM -lt ${cur_jid} ]]           
    then 
        dep="--dependency=afterok:${jid20##* }"
    else 
        dep=""        
    fi

    cmd1="rm -r ${MASKER_DIR} ${CHUNK_DIR} ${TMP_ASM_DIR} ${BUSCO_DIR} ${CHUNK_STATS_DIR} ${COV_STATS_DIR} ${WINDOW_STATS_DIR} ${MINIMAP2_DIR} ${BLASTN_DIR} ${DIAMOND_P_DIR} ${DIAMOND_X_DIR}"	 
    if [[ $FROM -eq 21 && $TO -eq 21 ]]
    then
        echo "BLOBTOOLKIT Step ${cur_jid} - run ${JobName} locally" 
        echo "${cmd1}"
        ${cmd1}
    else
        jid21=$(sbatch ${ADD_SLURM_OPT} ${dep} -c 1 -n 1 -p ${SLURM_PARTITION} --mem=1G --time=00:15:00 -J "${JobName}" -e "${LOG_DIR}"/${cur_jid}_${JobName}.%A.err -o "${LOG_DIR}"/${cur_jid}_${JobName}.%A.out --wrap="echo \"${cmd1}\" && ${cmd1}")
        echo "BLOBTOOLKIT Step ${cur_jid} - submit ${JobName} job: ${jid21##* } (${dep})"
    fi
else 
    (>&2 echo -e "[INFO] Skip step ${cur_jid} - ${JobName}!")
fi 

(>&2 echo -e "\n[INFO] REACHED END OF PIPELINE - plots and contamination files will show up in directory: \"${BLOB_RESULTS_DIR}\"!\n")

