#!/usr/bin/env python3
"""
Rename scaffold names in an AGP file back to contig names when a scaffold
consists only of a single contig (no gaps). If the same contig occurs multiple
times as single-contig scaffolds, append the contig coordinates to make names unique.

Optionally rename the corresponding FASTA headers. Gzip (.gz) input/output is supported
automatically when filenames end with .gz.
"""
from collections import defaultdict
import argparse
import logging
import gzip
from pathlib import Path
import sys

def open_text(path, mode="rt"):
    """Open a text file, transparently supporting .gz files."""
    if path is None:
        raise ValueError("No path provided")
    if str(path).endswith(".gz"):
        return gzip.open(path, mode)
    return open(path, mode, encoding="utf-8")

def parse_args():
    p = argparse.ArgumentParser(
        description="Rename single-contig scaffolds in AGP back to contig names (optionally rename FASTA headers)."
    )
    p.add_argument("-i", "--input", required=True, help="Input AGP file (can be .gz)")
    p.add_argument("-o", "--output", required=True, help="Output AGP file (can be .gz)")
    p.add_argument("--fasta", help="Optional input FASTA file with scaffold sequences (can be .gz)")
    p.add_argument("--fasta-out", help="Output FASTA file with renamed headers (required if --fasta is set)")
    p.add_argument("-v", "--verbose", action="store_true", help="Verbose logging")
    p.add_argument("--map-out", help="Optional tab-separated mapping file: old_scaffold -> new_name")
    return p.parse_args()

def process_agp(input_agp, output_agp):
    """
    Read AGP, find scaffolds that contain exactly one component and it's a W line.
    If the contig is unique across candidate scaffolds -> rename scaffold -> contig_name
    If the contig occurs multiple times -> rename scaffold -> contig_componentBeg-componentEnd
    Ensure final names do not collide with scaffolds that are kept unchanged.
    Return rename_map: {old_scaffold_name: new_name}
    """
    scaffold_lines = {}
    scaffold_order = []  # preserve first-seen order

    logging.info(f"Reading AGP: {input_agp}")
    with open_text(input_agp, "rt") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if not line or line.strip() == "":
                continue
            if line.startswith("#"):
                # ignore comments for grouping; we'll not reinsert them in original position
                # but log them if verbose
                logging.debug(f"Skipping comment line in AGP: {line}")
                continue
            # split by tab first, fallback to whitespace
            parts = line.split("\t")
            if len(parts) == 1:
                parts = line.split()
            scaffold = parts[0]
            if scaffold not in scaffold_lines:
                scaffold_order.append(scaffold)
                scaffold_lines[scaffold] = []
            scaffold_lines[scaffold].append(parts)

    # find scaffolds that are single-line W components
    single_w_scaffolds = []
    for sc, lines in scaffold_lines.items():
        if len(lines) == 1:
            fields = lines[0]
            if len(fields) >= 6 and fields[4].upper() == "W":
                single_w_scaffolds.append(sc)

    # group those by contig id
    contig_to_entries = defaultdict(list)  # contig -> list of (scaffold, comp_beg, comp_end, fields)
    for sc in single_w_scaffolds:
        fields = scaffold_lines[sc][0]
        if len(fields) < 8:
            logging.warning(f"Skipping scaffold {sc}: not enough columns to extract component coords")
            continue
        contig = fields[5]
        comp_beg = fields[6]
        comp_end = fields[7]
        contig_to_entries[contig].append((sc, comp_beg, comp_end, fields))

    # reserved names are scaffold names that will NOT be renamed (we must avoid colliding with those)
    reserved_names = set(scaffold_lines.keys()) - set(single_w_scaffolds)

    rename_map = {}
    used_new_names = set()  # track new names to avoid duplicates

    def make_unique(name_base):
        """Return a name not in reserved_names/used_new_names by adding _dupN if necessary."""
        if name_base not in reserved_names and name_base not in used_new_names:
            return name_base
        i = 1
        candidate = f"{name_base}_dup{i}"
        while candidate in reserved_names or candidate in used_new_names:
            i += 1
            candidate = f"{name_base}_dup{i}"
        return candidate

    # create mapping
    for contig, entries in contig_to_entries.items():
        if len(entries) == 1:
            sc, beg, end, fields = entries[0]
            candidate = contig
            if candidate in reserved_names or candidate in used_new_names:
                # add coords to make unique
                candidate = f"{contig}_{beg}-{end}"
                candidate = make_unique(candidate)
            rename_map[sc] = candidate
            used_new_names.add(candidate)
            logging.debug(f"Will rename scaffold {sc} -> {candidate}")
        else:
            # contig appears multiple times -> always append coords
            for sc, beg, end, fields in entries:
                candidate = f"{contig}_{beg}-{end}"
                candidate = make_unique(candidate)
                rename_map[sc] = candidate
                used_new_names.add(candidate)
                logging.debug(f"Will rename scaffold {sc} -> {candidate} (duplicate contig)")

    # write AGP with replaced scaffold names
    logging.info(f"Writing AGP to: {output_agp}")
    with open_text(output_agp, "wt") as outfh:
        renamed_count = 0
        for sc in scaffold_order:
            for fields in scaffold_lines[sc]:
                new_sc = rename_map.get(sc, sc)
                if new_sc != sc:
                    renamed_count += 1
                fields[0] = new_sc
                outfh.write("\t".join(fields) + "\n")

    logging.info(f"AGP processing complete. Renamed {len(rename_map)} scaffolds (wrote {renamed_count} renamed lines).")
    return rename_map

def process_fasta(fasta_in, fasta_out, rename_map):
    """Rename FASTA headers according to rename_map. Only the header id (first token) is replaced."""
    logging.info(f"Renaming FASTA headers: {fasta_in} -> {fasta_out}")
    with open_text(fasta_in, "rt") as fin, open_text(fasta_out, "wt") as fout:
        current_header = None
        seq_lines = []

        def flush():
            nonlocal current_header, seq_lines
            if current_header is None:
                return
            header_body = current_header[1:].rstrip("\n")
            parts = header_body.split(None, 1)
            hid = parts[0]
            rest = (" " + parts[1]) if len(parts) > 1 else ""
            new_hid = rename_map.get(hid, hid)
            fout.write(">" + new_hid + rest + "\n")
            for s in seq_lines:
                fout.write(s)
            current_header = None
            seq_lines = []

        for line in fin:
            if line.startswith(">"):
                flush()
                current_header = line.rstrip("\n")
                seq_lines = []
            else:
                # keep original line endings as single '\n'
                seq_lines.append(line if line.endswith("\n") else line + "\n")
        flush()
    logging.info("FASTA renaming complete.")

def main():
    args = parse_args()
    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO,
                        format="%(levelname)s: %(message)s")

    if args.fasta and not args.fasta_out:
        logging.error("If --fasta is provided you must also provide --fasta-out")
        sys.exit(1)

    try:
        rename_map = process_agp(args.input, args.output)
        if args.map_out:
            logging.info(f"Writing mapping file: {args.map_out}")
            with open_text(args.map_out, "wt") as mapfh:
                for old, new in sorted(rename_map.items()):
                    mapfh.write(f"{old}\t{new}\n")
        if args.fasta:
            if not rename_map:
                logging.info("No scaffolds were renamed; copying FASTA header names unchanged.")
            process_fasta(args.fasta, args.fasta_out, rename_map)
    except Exception as exc:
        logging.exception(f"Error: {exc}")
        sys.exit(1)

if __name__ == "__main__":
    main()

