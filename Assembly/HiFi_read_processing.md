# 1) Create PacBio BAM index
```bash
pbindex "$INPUT_BAM"
```

# 2) Generate CCS for one chunk
```bash
ccs "$INPUT_BAM" \
    "$DCS_DIR/$BAM_BASENAME.$SHARD_ID-of-$TOTAL_CHUNKS.ccs.bam" \
    --min-rq=0.88 \
    --chunk $SHARD_ID/$TOTAL_CHUNKS \
    -j $THREADS_PER_CHUNK
```

# 3) Align subreads to CCS (ACTC) (for each chunk)
```bash
actc -j $THREADS_PER_CHUNK \
    "$INPUT_BAM" \
    "$DCS_DIR/$BAM_BASENAME.$SHARD_ID-of-$TOTAL_CHUNKS.ccs.bam" \
    "$DCS_DIR/$BAM_BASENAME.$SHARD_ID-of-$TOTAL_CHUNKS.subreads_to_ccs.bam"
```

# 4) Run DeepConsensus (for each chunk)
```bash
deepconsensus run \
    --subreads_to_ccs="$DCS_DIR/$BAM_BASENAME.$SHARD_ID-of-$TOTAL_CHUNKS.subreads_to_ccs.bam" \
    --ccs_bam="$DCS_DIR/$BAM_BASENAME.$SHARD_ID-of-$TOTAL_CHUNKS.ccs.bam" \
    --checkpoint=/nexus/posix0/CBG-bat-data/sw/deepconsensus/model/checkpoint \
    --output="$DCS_DIR/$BAM_BASENAME.$SHARD_ID-of-$TOTAL_CHUNKS.output.fastq"
```


# 5) Merge chunk FASTQs
```bash
cat "$DCS_DIR/$BAM_BASENAME".*.output.fastq > \
    "$DCS_DIR/$BAM_BASENAME.dcs.fastq"
```
