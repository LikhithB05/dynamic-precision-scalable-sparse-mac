"""Run an original testbench in a fresh local directory with its matching memory pair."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
COMMON = "mode_controller operand_formatter booth_encoder_r4 partial_product_generator csa wallace_tree_32".split()
CLA = "cla_4bit cla_64bit acc".split()
C1 = "conv_mac_baugh_wooley conventional_mac_top_enhanced".split()
C2 = "rca_8bit csla_8bit csla_64bit acc_csla conv_mac_carry_select conventional_mac_csla_top".split()
SOURCES = {
    "oracle": ("candidate3_oracle_tb", COMMON + ["mac_sparse_ulp_precision_gated"], "DNN", "PASS pairs=3043"),
    "candidate3": ("tb_mac_sparse_ulp_precision_gated", COMMON + ["mac_sparse_ulp_precision_gated"], "DNN", "ALL VERIFICATION TESTS PASSED (0 ERRORS)"),
    "candidate1": ("conv_mac_tb", COMMON + CLA + C1 + ["conv_mac_booth_wallace"], "MEM_Files", "Failed Assertions          : 0"),
    "candidate2": ("conv_mac_csla_tb", ["csa"] + C2, "MEM_Files", "Failed Assertions    : 0"),
    "comparison": ("unified_5design_validation_tb", COMMON + CLA + C1 + C2 + ["conv_mac_booth_wallace","conventional_mac_top","adaptive_mac_top","adaptive_sparse_mac_top","sparsity_detector"], "MEM_Files", "FINAL WORKLOAD ACCUMULATOR COMPARISON"),
}
def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("design", choices=SOURCES)
    parser.add_argument("--bin", type=Path, help="Vivado bin directory if absent from PATH")
    parser.add_argument("--work", type=Path, default=ROOT/"build")
    args = parser.parse_args()
    args.work.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp(dir=args.work.resolve(), prefix=args.design+"-"))
    top, modules, dataset, marker = SOURCES[args.design]
    paths = {p.stem:p for p in (ROOT/"rtl").rglob("*.v")}
    for name in modules:
        shutil.copyfile(paths[name],work/paths[name].name)
    bench = ROOT/"verification"/(top+".sv") if args.design=="oracle" else ROOT/"testbench"/(top+".v")
    shutil.copyfile(bench,work/bench.name)
    for mem in (ROOT/"datasets"/dataset).glob("*.mem"):
        shutil.copyfile(mem,work/mem.name)
    print("Working directory",work,flush=True)
    env = dict(os.environ)
    for name in ["TMP","TEMP","TMPDIR","XILINX_LOCAL_USER_DATA"]:
        dest=work/name
        dest.mkdir()
        env[name]=str(dest)
    def run(tool, arguments):
        binary = args.bin/(tool+(".bat" if os.name=="nt" else "")) if args.bin else shutil.which(tool)
        if not binary:
            raise SystemExit("Could not locate "+tool)
        result = subprocess.run([str(binary),*arguments],cwd=work,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        output = result.stdout.decode(errors="replace")
        (work/(tool+"-output.txt")).write_text(output,encoding="utf-8")
        if result.returncode:
            raise SystemExit(output)
        return output
    run("xvlog",[name+".v" for name in modules])
    run("xvlog",(["-sv"] if bench.suffix==".sv" else [])+[bench.name])
    run("xelab",[top,"-s","mac_test"])
    output = run("xsim",["mac_test","-runall"])
    if marker not in output or "$finish" not in output:
        raise SystemExit(output)
    if args.design=="comparison" and ("0x1fffffff9f1392e5c" not in output or output.count("DIFFERENT")!=2):
        raise SystemExit(output)
    print(output)
if __name__=="__main__":
    main()

