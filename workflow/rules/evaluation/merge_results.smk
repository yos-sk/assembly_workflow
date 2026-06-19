# ====================================================================
# Merge results
# ====================================================================
rule merge_assembly_errors:
    input:
        flagger_hifi=config["output"]["base"] + "/{sample}/evaluation/flagger/{assembler}/hifi/final_flagger_prediction.bed",
        flagger_ont=config["output"]["base"] + "/{sample}/evaluation/flagger/{assembler}/ont/final_flagger_prediction.bed",
        nucflag=config["output"]["base"] + "/{sample}/evaluation/nucflag/{assembler}/nucflag_misassembly.txt",
        inspector_hap1_small=config["output"]["base"] + "/{sample}/evaluation/inspector/{assembler}/HiFi/hp1/small_scale_error.bed",
        inspector_hap2_small=config["output"]["base"] + "/{sample}/evaluation/inspector/{assembler}/HiFi/hp2/small_scale_error.bed",
        inspector_hap1_structural=config["output"]["base"] + "/{sample}/evaluation/inspector/{assembler}/HiFi/hp1/structural_error.bed",
        inspector_hap2_structural=config["output"]["base"] + "/{sample}/evaluation/inspector/{assembler}/HiFi/hp2/structural_error.bed"
    output:
        hap1_merged=config["output"]["base"] + "/{sample}/evaluation/merge_assembly_errors/{assembler}/misassembly.intersect.hap1.bed.gz",
        hap2_merged=config["output"]["base"] + "/{sample}/evaluation/merge_assembly_errors/{assembler}/misassembly.intersect.hap2.bed.gz"
    params:
        output_dir=config["output"]["base"] + "/{sample}/evaluation/merge_assembly_errors/{assembler}",
        work_dir=config["output"]["base"] + "/{sample}/evaluation/merge_assembly_errors/{assembler}/workspace"
    threads: 1
    resources:
        mem_mb=8192
    singularity:
        config.get("images", {}).get("assembly_filter", "")
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/evaluation/merge_results/merge_assemble_errors.sh \
            {input.flagger_hifi} \
            {input.flagger_ont} \
            {input.nucflag} \
            {input.inspector_hap1_small} \
            {input.inspector_hap2_small} \
            {input.inspector_hap1_structural} \
            {input.inspector_hap2_structural} \
            {params.output_dir} \
            {params.work_dir} \
            {SCRIPTS_DIR}/evaluation/merge_results
        """

# Optional inputs for the summary table: each is present only when the sample's
# data supports it, otherwise [] (Snakemake expands that to "" and the script
# prints "-" for the column). This lets the summary table always be generated.
def _summary_yak_qv(hap):
    """yak QV path for {hap} — only when the sample has HiFi reads, else []."""
    def _f(wildcards):
        if has_hifi(wildcards.sample):
            return (config["output"]["base"] +
                    "/" + wildcards.sample + "/evaluation/yak/" + wildcards.assembler + "/" +
                    wildcards.sample + "." + hap + ".pb.yak.qv.txt")
        return []
    return _f


def _summary_merged(hap):
    """merged-misassembly path for {hap} — only when merge_assembly_errors can run
    (needs flagger-HiFi + flagger-ONT + inspector + nucflag, i.e. HiFi and ONT)."""
    def _f(wildcards):
        s = wildcards.sample
        if has_hifi(s) and (has_ont(s) or has_ont_ul(s)):
            return (config["output"]["base"] +
                    "/" + s + "/evaluation/merge_assembly_errors/" + wildcards.assembler + "/" +
                    "misassembly.intersect." + hap + ".bed.gz")
        return []
    return _f


def _summary_merqury(wildcards):
    """merqury QV path — only when the sample has Illumina reads, else []."""
    if col_value(wildcards.sample, "illumina_r1"):
        return (config["output"]["base"] +
                "/" + wildcards.sample + "/evaluation/merqury/" + wildcards.assembler + "/out.qv")
    return []


def _summary_pstools(wildcards):
    """pstools Hi-C phasing result — only when the sample has Hi-C reads, else []."""
    if col_value(wildcards.sample, "hic_r1"):
        return (config["output"]["base"] +
                "/" + wildcards.sample + "/evaluation/haplotype_switch/" + wildcards.assembler + "/" +
                "pstools/phase_error_output.txt")
    return []


def _summary_trio(parent):
    """yak trioeval phasing result for {parent} — only with parental reads, else []."""
    def _f(wildcards):
        if col_value(wildcards.sample, "pat_r1"):
            return (config["output"]["base"] +
                    "/" + wildcards.sample + "/evaluation/haplotype_switch/" + wildcards.assembler + "/" +
                    "yak_trioeval/" + parent + ".yak_phasing.txt")
        return []
    return _f


rule make_summary_table:
    input:
        # Always available for an evaluation sample (filter + compleasm + t2t):
        hap1_stats=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1_stats.txt",
        hap2_stats=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2_stats.txt",
        compleasm_hap1=config["output"]["base"] + "/{sample}/evaluation/compleasm/{assembler}/hp1/summary.txt",
        compleasm_hap2=config["output"]["base"] + "/{sample}/evaluation/compleasm/{assembler}/hp2/summary.txt",
        t2t_hap1=config["output"]["base"] + "/{sample}/evaluation/t2t/{assembler}/t2t_contigs_hap1.txt",
        t2t_hap2=config["output"]["base"] + "/{sample}/evaluation/t2t/{assembler}/t2t_contigs_hap2.txt",
        # Optional: only when the sample's data supports them (else printed as "-"):
        yak_hap1_qv=_summary_yak_qv("hap1"),
        yak_hap2_qv=_summary_yak_qv("hap2"),
        hap1_merged=_summary_merged("hap1"),
        hap2_merged=_summary_merged("hap2"),
        merqury=_summary_merqury,
        pstools=_summary_pstools,
        trio_pat=_summary_trio("paternal"),
        trio_mat=_summary_trio("maternal"),
    output:
        summary=config["output"]["base"] + "/{sample}/evaluation/summary_table/{assembler}/assembly_summary_stats.txt"
    params:
        sample="{sample}",
        assembler="{assembler}",
        output_dir=config["output"]["base"] + "/{sample}/evaluation/summary_table/{assembler}"
    threads: 1
    resources:
        mem_mb=4096
    shell:
        """
        mkdir -p {params.output_dir}
        python3 {SCRIPTS_DIR}/evaluation/merge_results/make_summary_table.py \
            -n {params.sample} \
            -l {params.assembler} \
            -a {input.hap1_stats} \
            -b {input.hap2_stats} \
            -y "{input.yak_hap1_qv}" \
            -z "{input.yak_hap2_qv}" \
            -d "{input.hap1_merged}" \
            -e "{input.hap2_merged}" \
            -f {input.compleasm_hap1} \
            -g {input.compleasm_hap2} \
            -i {input.t2t_hap1} \
            -j {input.t2t_hap2} \
            -c "{input.merqury}" \
            --pstools "{input.pstools}" \
            --trio-pat "{input.trio_pat}" \
            --trio-mat "{input.trio_mat}" \
            -o {output.summary}
        """
