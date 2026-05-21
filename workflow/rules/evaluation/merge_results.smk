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
        hap1_merged=config["output"]["base"] + "/{sample}/evaluation/merge_assembly_errors/{assembler}/misassembly.intersect.merged.hap1.bed.gz",
        hap2_merged=config["output"]["base"] + "/{sample}/evaluation/merge_assembly_errors/{assembler}/misassembly.intersect.merged.hap2.bed.gz"
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

rule make_summary_table:
    input:
        hap1_stats=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap1_stats.txt",
        hap2_stats=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.hap2_stats.txt",
        yak_hap1_qv=config["output"]["base"] + "/{sample}/evaluation/yak/{assembler}/{sample}.hap1.pb.yak.qv.txt",
        yak_hap2_qv=config["output"]["base"] + "/{sample}/evaluation/yak/{assembler}/{sample}.hap2.pb.yak.qv.txt",
        hap1_merged=config["output"]["base"] + "/{sample}/evaluation/merge_assembly_errors/{assembler}/misassembly.intersect.merged.hap1.bed.gz",
        hap2_merged=config["output"]["base"] + "/{sample}/evaluation/merge_assembly_errors/{assembler}/misassembly.intersect.merged.hap2.bed.gz",
        compleasm_hap1=config["output"]["base"] + "/{sample}/evaluation/compleasm/{assembler}/hp1/summary.txt",
        compleasm_hap2=config["output"]["base"] + "/{sample}/evaluation/compleasm/{assembler}/hp2/summary.txt",
        t2t_hap1=config["output"]["base"] + "/{sample}/evaluation/t2t/{assembler}/t2t_contigs_hap1.txt",
        t2t_hap2=config["output"]["base"] + "/{sample}/evaluation/t2t/{assembler}/t2t_contigs_hap2.txt"
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
            -y {input.yak_hap1_qv} \
            -z {input.yak_hap2_qv} \
            -d {input.hap1_merged} \
            -e {input.hap2_merged} \
            -f {input.compleasm_hap1} \
            -g {input.compleasm_hap2} \
            -i {input.t2t_hap1} \
            -j {input.t2t_hap2} \
            -o {output.summary}
        """
