#! /bin/awk -f

###########################################################
# print only monoexonic transcripts entries from GTF file #
###########################################################


# set up variables
{
	if ( $1 ~ /^#/) {next} #ignore commented lines	
	switch ($3) {
	case "transcript":
	        last_id = id
	        id = substr($0, match($0, /transcript_id ".[[:graph:]]*/), RLENGTH)
	        lline = line
	        line = $0
		exc[id] = 0
		if (exc[last_id] == 1 ){ print lline}
		break
	case "exon":
		exc[id]++
		break
	}
}
END {if (exc[id] == 1 ){ print lline}}
