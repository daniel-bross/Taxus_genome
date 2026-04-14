#! /bin/awk -f

##############################################################
# print QualByDepth value for each variant in input VCF file #
##############################################################

# ignore header lines
$1 ~ /^#/{
	next
}

# for each variant site, get sum of depths from all samples which contain the variant, and output QUAL / DP
{
	d = 0
	for (i=10; i<= NF; i++) {
		if($i !~ /^0\/0/ ) {
			split($i,a,":")
			d += a[3]
		}
		}
	if (d != 0) {
		print $6 / d
	}
}
