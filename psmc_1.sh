#!/bin/bash
#SBATCH --job-name=rpad_psmc
#SBATCH --cpus-per-task=4
#SBATCH --time=1-00:00:00
#SBATCH --partition=fast
#SBATCH --mem=30g
#SBATCH -e slurm-%A_%a.err
#SBATCH -o slurm-%A_%a.out

module load bwa/0.7.17 
module load samtools/1.15.1 
module load bcftools/1.16
#module load bioinfo/psmc-0.6.5

wd=/shared/ifbstor1/projects/aphid_psmc

#####################################################################################################################
##### A MODIFIER
TE_type="LINE"
name="Rpad"
file_name="RPAD"
reads_name="ERR2234453"
name=${name}_${TE_type}

########################################################################################################################
##### DO NOT MODIFY !!!

Ref=$wd/results/$file_name/${name}_masked.fasta
#Ref=$wd/results/$file_name/Dp_genome_v3_masked.fasta
#Ref=$wd/data/$file_name/Eriosoma_lanigerum_v1.0.scaffolds.fa
fq1=$wd/data/$file_name/${reads_name}_1.fastq.gz
fq2=$wd/data/$file_name/${reads_name}_2.fastq.gz
out=$wd/results/$file_name

##### Alignement

bwa mem -t 4 -o $out/${name}msk_${reads_name}.sam $Ref $fq1 $fq2

samtools view -b -@ 4 -o $out/${name}msk_${reads_name}.bam $out/${name}msk_${reads_name}.sam
samtools sort -@ 4 -o $out/${name}msk_${reads_name}_sorted.bam $out/${name}msk_${reads_name}.bam

samtools coverage $out/${name}msk_${reads_name}_sorted.bam -o $out/${name}msk_${reads_name}.txt

samtools view -b -@ 4 -o $out/${name}msk_${reads_name}.bam $out/${name}msk_${reads_name}.sam
samtools sort -@ 4 -o $out/${name}msk_${reads_name}_sorted.bam $out/${name}msk_${reads_name}.bam


##### Variant calling

bcftools mpileup -C100 -f $Ref $out/${name}msk_${reads_name}_sorted.bam | bcftools call -c \
	| vcfutils.pl vcf2fq -d 10 -D 100 | gzip > $out/${name}msk_${reads_name}_diploid.fq.gz

fq2psmcfa -q20 $out/${name}msk_${reads_name}_diploid.fq.gz > $out/${name}msk_${reads_name}_diploid.psmcfa


###### PSMC WITHOUT BOOTSRAPPING

psmc -N25 -t15 -r5 -p "4+25*2+4+6" -o $out/DPLA_D1_diploid.psmc $out/DPLA_D1_diploid.psmcfa

psmc2history.pl $out/DPLA_D1_diploid.psmc | history2ms.pl > ms-cmd.sh

psmc_plot.pl -p $out/DPLA_D1_diploid $out/DPLA_D1_diploid.psmc


###### PSMC WITH BOOTSTRAPPING 

splitfa $out/${name}msk_${reads_name}_diploid.psmcfa > $out/${name}msk_${reads_name}_split.psmcfa

seq 100 | xargs -i echo psmc -N25 -t15 -r5 -b -p "4+25*2+4+6" \
	    -o $out/${name}msk_${reads_name}_round-{}.psmc $out/${name}msk_${reads_name}_split.psmcfa | sh

cat $out/${name}msk_${reads_name}_split.psmcfa $out/${name}msk_${reads_name}_round-*.psmc > $out/${name}msk_${reads_name}_combined.psmc

psmc_plot.pl -p $out/${name}msk_${reads_name}_combined $out/${name}msk_${reads_name}_combined.psmc

# -c min allele count

#Here option -d sets and minimum read depth and -D sets the maximum. It is
#recommended to set -d to a third of the average depth and -D to twice. 

######### PSMC options

#-p STR      pattern of parameters [4+5*3+4]
#-t FLOAT    maximum 2N0 coalescent time [15]
#-N INT      maximum number of iterations [30]
#-r FLOAT    initial theta/rho ratio [4]
#-c FILE     CpG counts generated by cntcpg [null]
#-o FILE     output file [stdout]
#-i FILE     input parameter file [null]
#-T FLOAT    initial divergence time; -1 to disable [-1]
#-b          bootstrap (input be preprocessed with split_psmcfa)
#-S          simulate sequence
#-d          perform decoding
#-D          print full posterior probabilities

