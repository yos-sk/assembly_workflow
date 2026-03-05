"""
Tandem Repeat Finder (TRF-mod) annotation
Identifies tandem repeats in assembly sequences
"""

# ====================================================================
# TRF-mod annotation
# ====================================================================
rule trf_mod:
    input:
        assembly=config["output"]["base"] + "/{sample}/assembly/filter/{assembler}/{sample}.filt.fa"
    output:
        bed=config["output"]["base"] + "/{sample}/annotation/trf_mod/{assembler}/{sample}.trf-mod.bed"
    params:
        sample="{sample}",
        assembler="{assembler}",
        output_dir=config["output"]["base"] + "/{sample}/annotation/trf_mod/{assembler}",
        match=config["params"]["trf_mod"]["match"],
        mismatch=config["params"]["trf_mod"]["mismatch"],
        delta=config["params"]["trf_mod"]["delta"],
        pm=config["params"]["trf_mod"]["pm"],
        pi=config["params"]["trf_mod"]["pi"],
        minscore=config["params"]["trf_mod"]["minscore"],
        maxperiod=config["params"]["trf_mod"]["maxperiod"],
        minlength=config["params"]["trf_mod"]["minlength"],
        trf_mod=config["tools"]["trf_mod"]
    threads:
        get_threads("trf_mod", 1)
    resources:
        mem_mb=get_mem_mb("trf_mod", 102400)
    log:
        "logs/annotation/trf_mod/{sample}/{assembler}.log"
    shell:
        """
        /bin/bash {SCRIPTS_DIR}/annotation/trf-mod/trf-mod.sh \
            {params.sample} \
            {params.assembler} \
            {input.assembly} \
            {params.output_dir} &> {log}
        """
