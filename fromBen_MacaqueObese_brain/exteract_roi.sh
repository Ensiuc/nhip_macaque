#!/usr/bin/env bash
# ============================================================
# Extract region of interest (ROI) from all *.cov.gz files
# within each DMR subdirectory.
#
# Input file format:
#   chrom   start   end   pct   meth   unmeth
#
# Output files:
#   same directory, named <original>.roi.tsv.gz
#
# Maryam's macaque brain project
# ============================================================

# ----------- CONFIG -----------
PROJECT="/quobyte/lasallegrp/Ensi/project/nhip_macaque/fromBen_MacaqueObese_brain/"     # <-- change to your real path
DMRS_DIR="$PROJECT/DMRs"

CHR="chr10"
START=2332261
END=2543263
# -------------------------------

echo "=== Extracting region $CHR:$START-$END from all .cov.gz files ==="
echo "Project: $PROJECT"
echo

# loop over all DMR subdirectories
for d in "$DMRS_DIR"/*; do
    # skip if not a directory
    [ -d "$d" ] || continue

    echo "Processing directory: $(basename "$d")"

    shopt -s nullglob  # avoids literal *.cov.gz if no files
    for f in "$d"/*.cov.gz; do
        [ -f "$f" ] || continue

        base=$(basename "$f")
        out="$d/${base%.cov.gz}.roi100kb.tsv.gz"

        # skip if ROI file already exists
        if [ -f "$out" ]; then
            echo "  -> $base (ROI exists, skipping)"
            continue
        fi

        echo "  -> Extracting $CHR:$START-$END from $base"

        # Extract region: filter by chromosome and position range
        # cov.gz columns: chrom  start  end  pct  meth  unmeth
        zcat "$f" \
          | awk -v c="$CHR" -v s="$START" -v e="$END" '($1 == c && $2 >= s && $2 <= e)' \
          | gzip > "$out"

        if [ $? -eq 0 ]; then
            echo "     ✓ Created $(basename "$out")"
        else
            echo "     ✗ Error processing $base"
        fi
    done
    shopt -u nullglob
    echo
done

echo "=== Extraction complete ==="

