#!/bin/bash

# ----------- PATHS -----------
PROJECT="/quobyte/lasallegrp/Ensi/project/nhip_macaque/fromBen_MacaqueObese_cfDna"
DMRS_DIR="$PROJECT/DMRs"
ALIGN_DIR="$PROJECT/align"
MASTER="$DMRS_DIR/master_sample_info_cfDNA.csv"

CHR="chr10"
START=2432261
END=2443263

echo
echo "=== Extract cfDNA CpG ROI using master_sample_info_cfDNA.csv ==="
echo

# Extract folder-to-sample mapping from the master metadata
# Format: Folder,SampleName (Name column)
declare -A folder_to_samples

# Using awk to collect sample names per folder
while IFS=, read -r Name Group Csec Foster Cohort Region Comparison Folder; do
    # skip header
    if [[ "$Name" == "Name" ]]; then continue; fi

    folder_to_samples["$Folder"]+="$Name "
done < "$MASTER"

# Now loop through each DMR folder
for d in "$DMRS_DIR"/*; do
    [ -d "$d" ] || continue

    folder=$(basename "$d")

    echo ">>> Processing folder: $folder"

    sample_list=${folder_to_samples[$folder]}

    if [[ -z "$sample_list" ]]; then
        echo "    !! No samples listed for $folder in master sheet"
        continue
    fi

    echo "    Samples: $sample_list"
    echo

    # For each sample belonging to this folder
    for sname in $sample_list; do
        
        # locate cov.gz
        cov=$(ls "$ALIGN_DIR/$sname"/*merged_CpG_evidence.cov.gz 2>/dev/null)

        if [[ ! -f "$cov" ]]; then
            echo "    !! No CpG cov.gz found for sample $sname"
            continue
        fi

        out="$d/${sname}.roi.tsv.gz"

        if [[ -f "$out" ]]; then
            echo "    $sname -> ROI exists (skipping)"
            continue
        fi

        echo "    Extracting $sname → $(basename "$out")"

        zcat "$cov" \
            | awk -v c="$CHR" -v s="$START" -v e="$END" '( $1 == c && $2 >= s && $2 <= e )' \
            | gzip > "$out"

    done

    echo
done

echo "=== DONE ==="

