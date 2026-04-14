#!/bin/bash

INPUT=$1
FRAC=$2
OUTPUT=$3

module purge
module load bcftools/1.21

bcftools view --header-only $1 > $3

bcftools view --no-header $1 | awk -v f=$2 'BEGIN{srand()}{if(rand() < f) print $0}' >> $3

module purge
