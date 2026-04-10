#! /bin/awk -f

########################################
# get basic statistics from gtf files #
#######################################

# NOTE: braker disregards UTRs, and so does this script
# this files works for genemark.gtf, in which "exon" entries are used instead of "CDS" entries

# set up variables
BEGIN {
	lines = 0
	otherlines = 0
}

# read every line, store infos in arrays
{
	lines++
	id = substr($0, match($0, /transcript_id ".[[:graph:]]*/), RLENGTH)
	switch ($3) {
	case "gene":
		data["genes"][++a] = $5 - $4 + 1
		local_exon_count = 0
		local_intron_count = 0
		break
	case "transcript":
		data["transcriptsa"][++b] = $5 - $4 + 1
		data["pg_transcriptsc"][a]++
		local_exon_count = 0
		local_intron_count = 0
		break
	case "mRNA":
		#
		break
	case "start_codon":
		local_exon_count = 0
		local_intron_count = 0
		break
	case "stop_codon":
		local_exon_count = 0
		local_intron_count = 0
		break
	case "exon":
		idx=(id "::" ++local_cds_count)
		data["cdsl"][idx] = $5 - $4 + 1
		data["transcriptsl"][b] += data["cdsl"][idx]
		data["pt_cdsc"][id]++
		break
	case "intron":
		idx=(id "::" ++local_intron_count)
		data["intronsl"][idx] = $5 - $4 + 1
		data["pt_intronsc"][id]++
		break
	default:
		otherlines++
	}

}

END {
	# calculate stats
	for (i in data) {
		# count stats
		total_count[i] = length(data[i])
		cumul[i] = a_sum(data[i])
		asort(data[i]) # sorted arrays get new indices, starting with 1
		# length stats
		ar_min[i] = data[i][1]
		ar_q1[i] = a_quart(data[i], 0.25)
		ar_median[i] = a_quart(data[i], 0.5)
		ar_q3[i] = a_quart(data[i], 0.75)
		ar_max[i] = data[i][length(data[i])]
		ar_mean[i] = cumul[i] / total_count[i]
	}
	multiex_count = 0; for (i in data["pt_cdsc"]){if (data["pt_cdsc"][i] != 1) multiex_count++ } # = how many local_cds_counts are 2?
	monoex_count = total_count["transcriptsa"] - multiex_count
        if (multiex_count > 0)
                ratio = (monoex_count / multiex_count)
        else
                ratio = 0

	# print output
	printf "Analysis results for %s:\n", FILENAME
	printf "lines read: %G\n", lines
	printf "unrecognized lines: %G\n", otherlines
	printf "--- genes ---\n"
	printf "1	total gene count			%G\n",		total_count["genes"]
	printf "2	min/mean/max gene length		%G/%G/%G\n",	ar_min ["genes"], ar_mean["genes"], ar_max["genes"]
	printf "3	q1/median/q3 gene length		%G/%G/%G\n",	ar_q1["genes"], ar_median["genes"], ar_q3["genes"]
        printf "--- transcripts ---\n"
	printf "4       total transcript count        		%G\n",		total_count["transcriptsl"]
        printf "5	cumulative transcripts area		%G\n",		cumul["transcriptsa"]
	printf "6	min/mean/max transcript area		%G/%G/%G\n",	ar_min["transcriptsa"], ar_mean["transcriptsa"], ar_max["transcriptsa"]
        printf "7	q25/median/q75 transcript area		%G/%G/%G\n",	ar_q1["transcriptsa"], ar_median["transcriptsa"], ar_q3["transcriptsa"]
	printf "8	cumulative transcript length		%G\n",		cumul["transcriptsl"]
	printf "9	min/mean/max transcript length		%G/%G/%G\n",    ar_min["transcriptsl"], ar_mean["transcriptsl"], ar_max["transcriptsl"]
	printf "10	q25/median/q75 transcript length	%G/%G/%G\n",	ar_q1["transcriptsl"], ar_median["transcriptsl"], ar_q3["transcriptsl"]
	printf "--- cds / exons ---\n" # effectively the same here since braker ignores UTRs
	printf "11	total cds count				%G\n",		total_count["cdsl"]
	printf "12	min/mean/max cds per transcript		%G/%G/%G\n",	ar_min["pt_cdsc"], ar_mean["pt_cdsc"], ar_max["pt_cdsc"]
	printf "13	q25/median/q75 cds per transcript	%G/%G/%G\n",	ar_q1["pt_cdsc"], ar_median["pt_cdsc"], ar_q3["pt_cdsc"]
	printf "14	cumulative cds length			%G\n", 		cumul["cdsl"]
        printf "15	min/mean/max/ cds length		%G/%G/%G\n",	ar_min["cdsl"], ar_mean["cdsl"], ar_max["cdsl"]
        printf "16	q25/median/q75 cds length		%G/%G/%G\n",	ar_q1["cdsl"], ar_median["cdsl"], ar_q3["cdsl"]
        printf "--- introns ---\n"
	printf "17	total intron count			%G\n",		total_count["intronsl"]
	printf "18	min/mean/max introns per transcript	%G/%G/%G\n",	ar_min["pt_intronsc"], ar_mean["pt_intronsc"], ar_max["pt_intronsc"]
	printf "19	mean/median/max introns per transcript	%G/%G/%G\n",	ar_q1["pt_intronsc"], ar_median["pt_intronsc"], ar_q3["pt_intronsc"]
        printf "20	cumulative intron length		%G\n",		cumul["intronsl"]
	printf "21	min/mean/max intron length		%G/%G/%G\n",	ar_min["intronsl"], ar_mean["intronsl"], ar_max["intronsl"]
        printf "22	q25/median/q75 intron length		%G/%G/%G\n",	ar_q1["intronsl"], ar_median["intronsl"], ar_q3["intronsl"]
	printf "--- other ---\n"
	printf "23	monoexonic transcript count		%G\n",		monoex_count
	printf "24	multiexonic transcript count		%G\n",		multiex_count
	printf "25	mono:multi-exonic transcript ratio	%.3f\n",	ratio

}

# define functions

function a_sum(array)
{
	sum=0; z = 0
	for (z in array) {
		sum += array[z]
	}
	return sum
}

function a_quart(array, quartile)
{
	
	if (length(array) % 2) {
		return array[int((length(array)) * quartile)];
	} else {
		return (array[int((length(array) * quartile))] + array[int((length(array) * quartile) + 1)]) / 2.0;
	}
}
