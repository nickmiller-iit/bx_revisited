################################################################################
#                                Read data                                     #
################################################################################

# SRA Accessions

## 428G-exposed samples
Sra428G=SRR1611192 SRR1611196 SRR1611197 SRR1611199 SRR1611246 SRR1611296
## H88-exposed samples
SraH88=SRR1614633 SRR1614695 SRR1614743 SRR1614766 SRR1614800 SRR1614824
## Combined
SraAll=$(Sra428G) $(SraH88)

# Read files

readDir=reads

$(readDir):
	if [ ! -d $(readDir) ]; then mkdir $(readDir); fi

p1Reads=$(addprefix $(readDir)/,$(addsuffix _1.fastq, $(SraAll)))
p2Reads=$(addprefix $(readDir)/,$(addsuffix _2.fastq, $(SraAll)))
reads = $(p1Reads) $(p2Reads)

# Note to future me: The automatic $@ variable will reference each element in a
# list of targets. Use the read 1 rules as "trigger" targets. The read 2 files
# will get made automatically, and it's unlikely we would ever want to
# download on set of mates without the other.

fastqDumpOpts=-O $(readDir) --split-3 --readids

$(p1Reads): | $(readDir)
	conda run --name bx_sratools \
	fastq-dump \
	$(fastqDumpOpts) \
	$(subst $(readDir)/,,$(subst _1.fastq,,$@))

.PHONY: sra-dl

sra-dl: $(p1Reads)
