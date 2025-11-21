#!/bin/bash

# set your project root
project="/quobyte/lasallegrp/Ensi/project/nhip_macaque/fromBen_MacaqueObese_brain"   # <-- change this
dmrs_dir="$project/DMRs"
align_dir="$project/align"


csv="$dmrs_dir/sample_info_master.csv"

# read the CSV, skip header
tail -n +2 "$csv" | while IFS=$'\t' read -r Name InfantID Region ZymoID Group rest; do
    # Strip possible \r from fields (common in Excel CSVs)
    Region=${Region%$'\r'}
    ZymoID=${ZymoID%$'\r'}
    Group=${Group%$'\r'}

    # If any of these are empty, show it for debugging
    if [[ -z "$ZymoID" || -z "$Region" || -z "$Group" ]]; then
        echo "Skipping line: missing field. Got ZymoID='$ZymoID', Region='$Region', Group='$Group'"
        continue
    fi

    # normalize
    Region_clean=$(echo "$Region" | tr -d ' ')
    Zymo_clean=$(echo "$ZymoID" | tr '-' '_')
    Name_clean=$(echo "$Name" | tr ' ' '_' | tr -d '\r')
    # map group -> code using case (no associative array)
    case "$Group" in
        Obese)        Group_code="O" ;;
        Pravastatin)  Group_code="Pv" ;;
        Restriction)  Group_code="R" ;;
        Control)      Group_code="C" ;;
        *)
            echo "Skipping $Zymo_clean: unknown group '$Group'"
            continue
            ;;
    esac

    sample_dir="$align_dir/$Zymo_clean"

    # find the cov file for this sample
    src_file=$(find "$sample_dir" -type f -name "*bismark.cov.gz.CpG_report.merged_CpG_evidence.cov.gz" | head -n 1)
    if [[ -z "$src_file" ]]; then
        echo "WARNING: no cov.gz found for $Zymo_clean in $sample_dir"
        continue
    fi

    # loop over DMR dirs
    for dmr in "$dmrs_dir"/*; do
        [[ -d "$dmr" ]] || continue
        dmr_name=$(basename "$dmr")

        # must match region
        if [[ "$dmr_name" != ${Region_clean}_* ]]; then
            continue
        fi

        comp="${dmr_name#*_}"   # e.g. OvC, PvO, RvC

        # does this comparison include this sample's group?
        if [[ "$comp" == *"$Group_code"* ]]; then
	    base_src=$(basename "$src_file")
            dest="$dmr/${Name_clean}_${Zymo_clean}_$base_src"
            echo "Copying $src_file -> $dest"
            cp "$src_file" "$dest"
        fi
    done
done

