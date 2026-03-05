#!/usr/bin/env python3
"""
Generate config.yaml for the assembly workflow

This script interactively or non-interactively generates a config.yaml file
with all necessary paths and parameters for the assembly workflow.
"""

import argparse
import os
import sys
from pathlib import Path
from typing import Dict, Any, Optional
import yaml


class ConfigGenerator:
    """Generate config.yaml for assembly workflow"""

    def __init__(self, template: Optional[str] = None, interactive: bool = True):
        """
        Initialize ConfigGenerator

        Args:
            template: Path to template config file (optional)
            interactive: Whether to run in interactive mode
        """
        self.template = template
        self.interactive = interactive
        self.config: Dict[str, Any] = {}

    def load_template(self) -> None:
        """Load template config if provided"""
        if self.template and os.path.exists(self.template):
            with open(self.template, 'r') as f:
                self.config = yaml.safe_load(f)
            print(f"Loaded template from {self.template}")
        else:
            self.config = self._get_default_config()

    def _get_default_config(self) -> Dict[str, Any]:
        """Get default configuration structure"""
        return {
            "samples": "config/samples.tsv",
            "output": {
                "base": "../output"
            },
            "references": {
                "chm13": "",
                "grch38": "",
                "chm13_satellite": "",
                "grch38_centromeres": "",
                "grch38_exclusions": "",
                "grch38_gtf": ""
            },
            "tools": {
                "minimap2": "",
                "samtools": "",
                "bgzip": "",
                "tabix": "",
                "htslib": "",
                "dna_brnn": "",
                "dna_nn_model": "",
                "trf_mod": "",
                "seqtk": "",
                "flagger_alpha_hifi": "",
                "flagger_alpha_ont_r9": "",
                "flagger_alpha_ont_r10": "",
                "compleasm_library": ""
            },
            "images": {
                "base": "",
                "bedtools": "",
                "fastq_checker": "",
                "gffread": "",
                "liftoff": "",
                "transanno": "",
                "chaintools": "",
                "tetools": "",
                "hifiasm": "",
                "verkko": "",
                "yak": "",
                "flagger": "",
                "inspector": "",
                "nucflag": "",
                "merqury": "",
                "mashmap": "",
                "compleasm": "",
                "pstools": "",
                "censat_alphasat": "",
                "censat_hmmer": "",
                "censat_hsat": "",
                "censat_rm2bed": "",
                "censat_summarize": ""
            },
            "resources": self._get_default_resources(),
            "params": {
                "filter": {
                    "min_length": 100000
                },
                "trf_mod": {
                    "match": 2,
                    "mismatch": 7,
                    "delta": 7,
                    "pm": 80,
                    "pi": 10,
                    "minscore": 50,
                    "maxperiod": 2000,
                    "minlength": 30
                }
            }
        }

    def _get_default_resources(self) -> Dict[str, Dict[str, Any]]:
        """Get default resource allocations"""
        return {
            # Assembly resources
            "hifiasm_hic": {"cpus": 56, "mem_per_cpu": "8G"},
            "hifiasm_trio": {"cpus": 56, "mem_per_cpu": "8G"},
            "verkko_hic": {"cpus": 56, "mem_per_cpu": "8G"},
            "verkko_porec": {"cpus": 56, "mem_per_cpu": "8G"},
            "verkko_trio_prep": {"cpus": 32, "mem_per_cpu": "8G"},
            "verkko_trio": {"cpus": 56, "mem_per_cpu": "8G"},
            # Assembly filter
            "filter": {"cpus": 16, "mem_per_cpu": "8G"},
            # Annotation resources
            "trf_mod": {"cpus": 1, "mem_per_cpu": "100G"},
            "dna_nn": {"cpus": 16, "mem_per_cpu": "5G"},
            "repeatmasker": {"cpus": 56, "mem_per_cpu": "8G"},
            "sedef": {"cpus": 14, "mem_per_cpu": "8G"},
            "filter_sedef": {"cpus": 1, "mem_per_cpu": "10G"},
            "chain_files": {"cpus": 16, "mem_per_cpu": "8G"},
            "liftoff": {"cpus": 50, "mem_per_cpu": "8G"},
            "censat_split": {"cpus": 1, "mem_per_cpu": "30G"},
            "censat_alphasat": {"cpus": 56, "mem_per_cpu": "8G"},
            "censat_rdna": {"cpus": 24, "mem_per_cpu": "8G"},
            "censat_gaps": {"cpus": 1, "mem_per_cpu": "30G"},
            "censat_hsat": {"cpus": 1, "mem_per_cpu": "30G"},
            "censat_repeatmasker": {"cpus": 1, "mem_per_cpu": "30G"},
            "censat_create": {"cpus": 1, "mem_per_cpu": "30G"},
            # Evaluation resources
            "alignment_hifi": {"cpus": 16, "mem_per_cpu": "8G"},
            "alignment_ont": {"cpus": 16, "mem_per_cpu": "8G"},
            "flagger": {"cpus": 16, "mem_per_cpu": "8G"},
            "inspector": {"cpus": 16, "mem_per_cpu": "16G"},
            "nucflag": {"cpus": 16, "mem_per_cpu": "8G"},
            "merqury": {"cpus": 16, "mem_per_cpu": "8G"},
            "yak": {"cpus": 16, "mem_per_cpu": "8G"},
            "yak_trioeval": {"cpus": 32, "mem_per_cpu": "8G"},
            "pstools": {"cpus": 56, "mem_per_cpu": "8G"},
            "t2t": {"cpus": 16, "mem_per_cpu": "8G"},
            "compleasm": {"cpus": 16, "mem_per_cpu": "8G"}
        }

    def _prompt(self, message: str, default: str = "") -> str:
        """Prompt user for input

        Args:
            message: Prompt message
            default: Default value

        Returns:
            User input or default value
        """
        if not self.interactive:
            return default

        if default:
            response = input(f"{message} [{default}]: ").strip()
            return response if response else default
        else:
            return input(f"{message}: ").strip()

    def configure_basic(self) -> None:
        """Configure basic settings"""
        print("\n=== Basic Configuration ===")

        self.config["samples"] = self._prompt(
            "Path to samples.tsv",
            self.config.get("samples", "config/samples.tsv")
        )

        if "output" not in self.config:
            self.config["output"] = {}

        self.config["output"]["base"] = self._prompt(
            "Base output directory",
            self.config["output"].get("base", "../output")
        )

    def configure_references(self) -> None:
        """Configure reference files"""
        print("\n=== Reference Files ===")

        ref_descriptions = {
            "chm13": "CHM13 reference genome FASTA",
            "grch38": "GRCh38 reference genome FASTA",
            "chm13_satellite": "CHM13 CenSat annotation BED",
            "grch38_centromeres": "GRCh38 centromeres file",
            "grch38_exclusions": "GRCh38 exclusion regions BED",
            "grch38_gtf": "GRCh38 GTF annotation file"
        }

        for key, desc in ref_descriptions.items():
            self.config["references"][key] = self._prompt(
                f"{desc}",
                self.config["references"].get(key, "")
            )

    def configure_tools(self) -> None:
        """Configure tool paths"""
        print("\n=== Tool Paths ===")

        tool_descriptions = {
            "minimap2": "minimap2 binary",
            "samtools": "samtools binary",
            "bgzip": "bgzip binary",
            "tabix": "tabix binary",
            "htslib": "htslib directory",
            "dna_brnn": "dna-brnn binary",
            "dna_nn_model": "DNA-NN model file",
            "trf_mod": "trf-mod binary",
            "seqtk": "seqtk binary",
            "flagger_alpha_hifi": "Flagger alpha file (HiFi)",
            "flagger_alpha_ont_r9": "Flagger alpha file (ONT R9)",
            "flagger_alpha_ont_r10": "Flagger alpha file (ONT R10)",
            "compleasm_library": "Compleasm library directory"
        }

        for key, desc in tool_descriptions.items():
            self.config["tools"][key] = self._prompt(
                f"{desc}",
                self.config["tools"].get(key, "")
            )

    def configure_images(self) -> None:
        """Configure Singularity image paths"""
        print("\n=== Singularity Images ===")

        self.config["images"]["base"] = self._prompt(
            "Base directory for images",
            self.config["images"].get("base", "")
        )

        if self.interactive:
            detail = self._prompt(
                "Configure each image path individually? (y/N)",
                "N"
            ).lower()

            if detail != 'y':
                print("Using default image paths (update config.yaml manually if needed)")
                return

        image_descriptions = {
            "bedtools": "bedtools",
            "fastq_checker": "fastq_checker",
            "gffread": "gffread",
            "liftoff": "liftoff",
            "transanno": "transanno",
            "chaintools": "chaintools",
            "tetools": "tetools",
            "hifiasm": "hifiasm",
            "verkko": "verkko",
            "yak": "yak",
            "flagger": "flagger",
            "inspector": "inspector",
            "nucflag": "nucflag",
            "merqury": "merqury",
            "mashmap": "mashmap",
            "compleasm": "compleasm",
            "pstools": "pstools",
            "censat_alphasat": "CenSat AlphaSat",
            "censat_hmmer": "CenSat HMMER",
            "censat_hsat": "CenSat HSat",
            "censat_rm2bed": "CenSat rm2bed",
            "censat_summarize": "CenSat summarize"
        }

        for key, desc in image_descriptions.items():
            self.config["images"][key] = self._prompt(
                f"{desc} image",
                self.config["images"].get(key, "")
            )

    def configure_resources(self) -> None:
        """Configure resource allocations"""
        print("\n=== Resource Configuration ===")

        if self.interactive:
            modify = self._prompt(
                "Modify default resource allocations? (y/N)",
                "N"
            ).lower()

            if modify != 'y':
                print("Using default resource allocations")
                return

        print("\nDefault resources loaded. Edit config.yaml to modify specific rules.")

    def generate(self, output_path: str) -> None:
        """
        Generate config.yaml file

        Args:
            output_path: Path to output config.yaml
        """
        self.load_template()

        if self.interactive:
            print("=== Assembly Workflow Configuration Generator ===")
            print("\nThis script will help you generate a config.yaml file.")
            print("Press Enter to accept default values shown in brackets.")

        self.configure_basic()
        self.configure_references()
        self.configure_tools()
        self.configure_images()
        self.configure_resources()

        # Create output directory if needed
        output_dir = os.path.dirname(output_path)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)

        # Write config file
        with open(output_path, 'w') as f:
            yaml.dump(
                self.config,
                f,
                default_flow_style=False,
                sort_keys=False,
                indent=2
            )

        print(f"\n✓ Config file generated: {output_path}")
        print("\nNext steps:")
        print("1. Review and edit the generated config.yaml")
        print("2. Create samples.tsv with your sample information")
        print("3. Run the workflow with: snakemake --use-singularity -j <cores>")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Generate config.yaml for assembly workflow",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Interactive mode
  python scripts/set_config.py -o config/config.yaml

  # Non-interactive mode with template
  python scripts/set_config.py -o config/config.yaml -t config/template.yaml --non-interactive

  # Use existing config as template
  python scripts/set_config.py -o config/new_config.yaml -t config/config.yaml
        """
    )

    parser.add_argument(
        "-o", "--output",
        type=str,
        default="config/config.yaml",
        help="Output config file path (default: config/config.yaml)"
    )

    parser.add_argument(
        "-t", "--template",
        type=str,
        help="Template config file to use as base"
    )

    parser.add_argument(
        "--non-interactive",
        action="store_true",
        help="Run in non-interactive mode (use defaults/template values)"
    )

    args = parser.parse_args()

    # Confirm overwrite if file exists
    if os.path.exists(args.output) and not args.non_interactive:
        response = input(f"{args.output} already exists. Overwrite? (y/N): ").lower()
        if response != 'y':
            print("Aborted.")
            sys.exit(0)

    generator = ConfigGenerator(
        template=args.template,
        interactive=not args.non_interactive
    )

    try:
        generator.generate(args.output)
    except KeyboardInterrupt:
        print("\n\nAborted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
