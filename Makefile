################################################################################
#                                Read data                                     #
################################################################################

# SRA Accessions

## 428G-exposed samples
sra428G=SRR1611192 SRR1611196 SRR1611197 SRR1611199 SRR1611246 SRR1611296
## H88-exposed samples
sraH88=SRR1614633 SRR1614695 SRR1614743 SRR1614766 SRR1614800 SRR1614824
## Combined
sraAll=$(sra428G) $(sraH88)

# SRA downloads
#
# Download data from SRA. Note that direct downloading fastq via fastq-dump is
# bad idea. Downloads frequently fail and fastq-dump will leave partial files
# making it hard to know if download was successful or not. Prefetch at least
# cleans up after itself if it fails, so we know what we don't have and need
# to try again. Probably best not to run this step in parallel.

sraDir=sra

$(sraDir):
	if [ ! -d $(sraDir) ]; then mkdir $(sraDir); fi

sraFiles=$(addprefix $(sraDir)/, $(addsuffix .sra, $(sraAll)))

$(sraFiles): | $(sraDir)
	conda run --name bx_sratools \
	prefetch \
	-o $@ \
	$(notdir $(basename $@))


.PHONY: sra-dl


sra-dl: $(sraFiles)

# Extract fastq

fastqDir=fastq

$(fastqDir):
	if [ ! -d $(fastqDir) ]; then mkdir $(fastqDir); fi

p1Fastq=$(addprefix $(fastqDir)/,$(addsuffix _1.fastq, $(sraAll)))
p2Fastq=$(addprefix $(fastqDir)/,$(addsuffix _2.fastq, $(sraAll)))
allFastq=$(p1Fastq) $(p2Fastq)

# Note to future me: The automatic $@ variable will reference each element in a
# list of targets. Use the read 1 files as "trigger" targets. The read 2 files
# will get made automatically, and it's unlikely we would ever want one set
# of mates without the other.



fastqDumpOpts=-O $(fastqDir) --split-3 --readids

$(p1Fastq): | $(fastqDir)
	conda run --name bx_sratools \
	fastq-dump \
	$(fastqDumpOpts) \
	$(subst $(fastqDir),$(sraDir),$(subst _1.fastq,.sra,$@))

.PHONY: extract-fastq
extract-fastq: $(p1Fastq)


################################################################################
#                       Reference transcript set                               #
################################################################################

#
# Download reference transcript sequences from NCBI
#

refDir=ref

$(refDir):
	if [ ! -d $(refDir) ]; then mkdir $(refDir); fi

refURL=ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/013/835/GCF_003013835.1_Dvir_v2.0/GCF_003013835.1_Dvir_v2.0_rna.fna.gz

refDl=$(addprefix $(refDir)/, GCF_003013835.1_Dvir_v2.0_rna.fna.gz)

refFile=$(subst .gz,,$(refDl))

$(refDl): | $(refDir)
	wget \
	--directory-prefix $(refDir) \
	$(refURL)

$(refFile): $(refDl)
	zcat $(refDl) > $(refFile)

.PHONY: ref-dl
ref-dl: $(refFile)

################################################################################
#                                  Kallisto                                    #
################################################################################

kallistoIdx=$(addsuffix .idx, $(refFile))

$(kallistoIdx): $(refFile)
	conda run --name bx_kallisto \
	kallisto index -i $(kallistoIdx) $(refFile)

#
# kalliso quant produces a directory of output files
#

kallistoBaseDir=kallisto

$(kallistoBaseDir):
	if [ ! -d $(kallistoBaseDir) ]; then mkdir $(kallistoBaseDir); fi

kallistoDirs=$(addprefix $(kallistoBaseDir)/,$(sraAll))

kallistoOpts=-b 100 --seed 20191224 -i $(kallistoIdx)

$(kallistoDirs): $(allFastq) $(kallistoIdx) | $(kallistoBaseDir)
	conda run --name bx_kallisto \
	kallisto quant $(kallistoOpts) \
	-o $@ \
	$(addsuffix _1.fastq, $(subst $(kallistoBaseDir), $(fastqDir), $@)) \
	$(addsuffix _2.fastq, $(subst $(kallistoBaseDir), $(fastqDir), $@))

.PHONY: quant
quant: $(kallistoDirs)
