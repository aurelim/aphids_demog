#!/bin/bash
#SBATCH --job-name=bedtools
#SBATCH --cpus-per-task=1
#SBATCH --time=1-00:00:00
#SBATCH --mem=30g
#SBATCH -e slurm-%A_%a.err
#SBATCH -o slurm-%A_%a.out

module load bedtools/2.30.0 

for file_name in AGLY AGOS APIS DNOX DPLA DVIT ELAN MCER MPER PNIG RMAI RPAD SMIS
do 

    for TE_class in "ClassI:SINE" "ClassI:LINE" "ClassI:LTR" "ClassII:TIR" "ClassII:Maverick" "ClassII:Helitron" "ClassII:Sola"
    do

        path=/shared/projects/aphid_psmc/data/${file_name}
        fasta=$path/*.fna

        python gff_filtering.py $file_name $TE_class

        filtered_gff=$path/${file_name}_${TE_class}.gff3
        filtered_fasta=$path/${file_name}_${TE_class}.masked.fasta

        bedtools maskfasta -fi $fasta -bed $filtered_gff -fo $filtered_fasta

    done
done
