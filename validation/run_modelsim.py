"""Reproduce the report's checks in isolated ModelSim work libraries.

Run with the bundled Python or a normal Python 3 installation:
    python validation/run_modelsim.py
ModelSim must be on PATH, or pass --modelsim-bin C:/modeltech64_2020.4/win64.
No exercise input files or GUI simulation libraries are overwritten.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def reg_checks(prefix, values):
    return {f"x{i}": (f"{prefix}/regs[{i}]", v) for i, v in values.items()}


def cases():
    jobs = []
    for folder, tag in [("p2_q1", "original"), ("p2_q2", "unsigned")]:
        src = [f"exo/{folder}/ramchip.vhd", f"exo/{folder}/ram_tb.vhd"]
        jobs.append(dict(name=f"ram_{tag}_bench", src=src, top="ram_tb(bench)", ns=80,
                         checks={"out": ("/ram_tb/dataout", 7),
                                 "m1": ("/ram_tb/UUT/ram(1)", 4),
                                 "m2": ("/ram_tb/UUT/ram(2)", 7)}))
        jobs.append(dict(name=f"ram_{tag}_bench2", src=src, top="ram_tb(bench2)", ns=20490,
                         checks={"ok": ("/ram_tb/ok", "true")}))
    for addr, data in [(4, 16), (10, 32), (10, 8)]:
        jobs.append(dict(name=f"ram_generic_{2**addr}x{data}",
                         src=["exo/p2_q4/ramchip.vhd", "exo/p2_q4/ram_tb.vhd",
                              "exo/p2_q4/ram_generic_check.vhd"],
                         top="ram_tb(genericcheck)", opts=[f"-gNbits_addr={addr}", f"-gNbits_data={data}"],
                         ns=(4*2**addr+2)*10, checks={"ok": ("/ram_tb/ok", "true")}))
    jobs.append(dict(name="ram_chip_select", src=["exo/p2_q5/ramchip.vhd", "exo/p2_q5/ram_tb.vhd"],
                     top="ram_tb(bench)", ns=110,
                     steps=[("67 ns", {"disabled": ("/ram_tb/cs", 0),
                                        "high_z": ("/ram_tb/dataout", "z")}),
                            ("18 ns", {"blocked_write": ("/ram_tb/UUT/ram(1)", 4)}),
                            ("2 ns", {"enabled": ("/ram_tb/cs", 1),
                                       "old_word": ("/ram_tb/dataout", 4)})],
                     checks={"m1": ("/ram_tb/UUT/ram(1)", 4)}))
    jobs.append(dict(name="decoder", src=["exo/p3_q1/decoder.vhd", "exo/p3_q1/decoder_tb.vhd"],
                     top="decoder_tb(bench)", ns=50,
                     checks={"invalid_selects_none": ("/decoder_tb/cs_out", 0)}))
    jobs.append(dict(name="quadram_fixed", src=["exo/p2_q5/ramchip.vhd", "exo/p3_q1/decoder.vhd",
                                               "exo/p3_q2/quadram.vhd", "exo/p3_q2/quadram_tb.vhd"],
                     top="quadram_tb(bench)", ns=100,
                     checks={"last_read": ("/quadram_tb/dataout", 0x44)}))
    for sel, addr, data in [(3, 4, 16), (2, 10, 32)]:
        jobs.append(dict(name=f"quadram_{2**sel}x{2**addr}x{data}",
                         src=["exo/p2_q5/ramchip.vhd", "exo/p3_q4/decoder.vhd",
                              "exo/p3_q4/quadram_for.vhd", "exo/p3_q4/quadram_tb_for.vhd"],
                         top="quadram_tb(bench)", opts=[f"-gNbits_sel={sel}", f"-gNbits_addr={addr}", f"-gNbits_data={data}"],
                         ns=(2*2**sel+2)*10,
                         checks={"last_read": ("/quadram_tb/dataout", 0x11*2**sel)}))

    base = {0: 0, 1: -7, 2: 100, 3: 107, 4: -16, 5: -1, 6: 3,
            7: 800, 8: 536870911, 9: 107, 10: -7, 11: 0}
    mult = {1: -7, 2: 2, 3: -14, 4: -3, 5: -1, 6: 2147483644,
            7: -1, 8: -1, 9: 1, 10: 1, 11: -2147483648, 12: -1,
            13: 31, 14: -2147483648, 15: 0, 16: -1}
    programs = [("instr.txt", {1: 1, 2: 6}, {65: 6}, 70),
                ("instr2.txt", {1: 1, 2: 6}, {65: 6}, 70),
                ("test_base.txt", base, {104: 107, 96: -7}, 160),
                ("test_rv32im.txt", mult, {}, 190)]

    old = reg_checks("/system", {0: 5, 1: 4089, 3: -3989, 4: 4080,
                                 5: 4095, 8: 511, 9: 4089, 10: 4089, 11: 10})
    old.update({"m0": ("/system/memory[0]", 4089), "m104": ("/system/memory[104]", "unknown")})
    jobs.append(dict(name="cpu_original_base_known_defects", src=["exo/p4_q1/riscvproc_original.sv"],
                     top="system", program="test_base.txt", ns=160, checks=old))
    old2 = reg_checks("/system", {1: 1, 2: 6})
    old2.update({"m0": ("/system/memory[0]", 6), "m65": ("/system/memory[65]", "unknown")})
    jobs.append(dict(name="cpu_original_instr2_known_defect", src=["exo/p4_q1/riscvproc_original.sv"],
                     top="system", program="instr2.txt", ns=70, checks=old2))
    jobs.append(dict(name="cpu_original_rv32m_unsupported", src=["exo/p4_q1/riscvproc_original.sv"],
                     top="system", program="test_rv32im.txt", ns=190,
                     message_counts={"erreur: mauvaise instruction arith": 11},
                     checks=reg_checks("/system", {i: 0 for i in [3,4,5,6,7,8,9,10,14,15,16]})))

    for program, regs, words, ns in programs:
        src = "exo/p4_q2/riscvproc-2.sv" if program == "test_rv32im.txt" else "exo/p4_q1/riscvproc-2.sv"
        checks = reg_checks("/system", regs)
        checks.update({f"m{a}": (f"/system/memory[{a}]", v) for a, v in words.items()})
        jobs.append(dict(name=f"cpu_corrected_{Path(program).stem}", src=[src], top="system",
                         program=program, ns=ns, checks=checks))
        checks = reg_checks("/tb_riscvproc/cpu", regs)
        checks.update({f"m{a}": (f"/tb_riscvproc/cpu/memory[{a}]", v) for a, v in words.items()})
        jobs.append(dict(name=f"cpu_clocked_{Path(program).stem}",
                         src=["exo/p4_q3/riscvproc.sv", "exo/p4_q3/tb_riscvproc.sv"],
                         top="tb_riscvproc", program=program, ns=ns, checks=checks))

    memregs = {20: 11, 21: 22, 22: 33, 23: 44, 24: 110, 25: 44, 26: 110}
    memwords = {5: 11, 1029: 22, 2053: 33, 3077: 44, 1023: 110}
    sysprograms = [("instr2.txt", {1: 1, 2: 6}, {65: 6}, 80),
                   ("test_base.txt", base, {104: 107, 96: -7}, 200),
                   ("test_rv32im.txt", mult, {}, 190),
                   ("test_memoire.txt", memregs, memwords, 350),
                   ("instr.txt", {1: "unknown", 2: "unknown"}, {65: "unknown"}, 100)]
    for program, regs, words, ns in sysprograms:
        checks = reg_checks("/systeme_tb/UUT/CPU", regs)
        checks.update({f"m{a}": (f"/systeme_tb/UUT/MEM/RAMS({a//1024})/RAM/ram({a%1024})", v)
                       for a, v in words.items()})
        jobs.append(dict(name=f"system_{Path(program).stem}" + ("_uninitialised_external_data" if program == "instr.txt" else ""),
                         src=["exo/p5/riscvproc.sv", "exo/p2_q5/ramchip.vhd", "exo/p3_q4/decoder.vhd",
                              "exo/p3_q4/quadram_for.vhd", "exo/p5/systeme.vhd", "exo/p5/systeme_tb.vhd"],
                         top="systeme_tb(bench)", program=program, ns=ns, checks=checks))
    return jobs


def check_lines(checks):
    return [f'echo "REPORT_CHECK|{key}|[examine -radix hexadecimal {{{path}}}]"'
            for key, (path, _) in checks.items()]


def matches(raw, expected):
    raw = raw.strip().strip('"').lower()
    if expected == "true":
        return raw == "true"
    if expected == "unknown":
        return bool(raw) and set(raw) <= {"u", "x"}
    if expected == "z":
        return bool(raw) and set(raw) == {"z"}
    try:
        return int(raw, 16) == expected % (1 << (4 * len(raw)))
    except ValueError:
        return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--modelsim-bin", default="C:/modeltech64_2020.4/win64")
    parser.add_argument("--only", help="Run cases whose names contain this string")
    args = parser.parse_args()
    vsim = shutil.which("vsim") or str(Path(args.modelsim_bin) / "vsim.exe")
    out = ROOT / "tmp/pdfs/report-validation"
    out.mkdir(parents=True, exist_ok=True)
    summary = []
    for job in cases():
        if args.only and args.only not in job["name"]:
            continue
        folder = out / job["name"]
        folder.mkdir(exist_ok=True)
        lines = ["onerror {quit -code 1 -f}", "onbreak {}",
                 "if {![file isdirectory work]} {vlib work}", "vmap work work"]
        for name in job["src"]:
            compiler = "vlog -sv" if name.endswith(".sv") else "vcom -93"
            lines.append(f"{compiler} {{{(ROOT / name).as_posix()}}}")
        options = job.get("opts", []).copy()
        if job.get("program"):
            options.append(f"+prog={(ROOT / 'programmes' / job['program']).as_posix()}")
        lines.append("vsim -voptargs=+acc -onfinish stop " + " ".join("{" + option + "}" for option in options)
                     + " work." + job["top"])
        checks = {}
        for duration, step_checks in job.get("steps", []):
            lines.append("run " + duration)
            lines.extend(check_lines(step_checks))
            checks.update(step_checks)
        lines.append("run -all")
        lines.extend(check_lines(job["checks"]))
        checks.update(job["checks"])
        lines.extend(['echo "REPORT_TIME|$now"', 'quit -code 0 -f'])
        script = folder / "check.do"
        script.write_text("\n".join(lines) + "\n", encoding="ascii")
        try:
            result = subprocess.run([vsim, "-c", "-do", script.as_posix()], cwd=folder,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=45)
            log = result.stdout.decode("utf-8", errors="replace")
            (folder / "validation.log").write_text(log, encoding="utf-8")
            actual = dict(re.findall(r"^# REPORT_CHECK\|([^|\r\n]+)\|([^\r\n]+)", log, re.M))
            failures = [f"{key}: {actual.get(key)!r}, expected {value!r}"
                        for key, (_, value) in checks.items() if not matches(actual.get(key, ""), value)]
            time_match = re.search(r"^# REPORT_TIME\|([0-9.e+-]+)\s*(\w+)?", log, re.M)
            time_ns = None
            if time_match:
                unit = (time_match.group(2) or "ns").lower()
                time_ns = float(time_match.group(1)) * {"fs": 1e-6, "ps": 1e-3, "ns": 1, "us": 1e3}[unit]
            if time_ns != job["ns"]:
                failures.append(f"time: {time_ns} ns, expected {job['ns']} ns")
            if result.returncode:
                failures.append(f"ModelSim exit {result.returncode}")
            if re.search(r"^# \*\* (?:Error|Fatal):", log, re.M):
                failures.append("ModelSim reported an error/fatal diagnostic")
            for message, count in job.get("message_counts", {}).items():
                if log.count(message) != count:
                    failures.append(f"message {message!r}: {log.count(message)} occurrences, expected {count}")
            row = dict(case=job["name"], passed=not failures, time_ns=time_ns,
                       checks=len(checks), observed=actual,
                       expected={key: value for key, (_, value) in checks.items()}, failures=failures)
        except (subprocess.TimeoutExpired, OSError) as error:
            row = dict(case=job["name"], passed=False, failures=[str(error)])
        summary.append(row)
        print(("PASS " if row["passed"] else "FAIL ") + row["case"] + " " + str(row.get("time_ns")), flush=True)
        if row["failures"]:
            print("  " + "; ".join(row["failures"]), flush=True)
        (out / "results.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    passed = sum(row["passed"] for row in summary)
    print(f"RESULT: {passed}/{len(summary)} cases passed", flush=True)
    return 0 if passed == len(summary) and summary else 1


if __name__ == "__main__":
    sys.exit(main())
