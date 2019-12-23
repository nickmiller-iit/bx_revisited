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
# to try again.

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
.NOTPARALLEL: sra-dl

sra-dl: $(sraFiles)
