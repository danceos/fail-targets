#!/usr/bin/env python3

import subprocess
import os
import re
import time

def trace(arch, rounds=10):
    cmd = "make clean-benchmark trace-benchmark"
    env = os.environ.copy()
    env.update({"ARCH": arch,
                "CFLAGS": "-DBENCHMARK_ROUNDS=" + str(rounds)})
    output = subprocess.check_output(cmd, shell=True, env=env)

    lines = [l.strip() for l in output.split(b"\n") if l.startswith(b"[GenericTracing")]

    ret = {}
    for (pattern, key) in [
            (b"Start FAIL*", "start_fail"),
            (b"start_trace reached, save", "start_save"),
            (b"... and start tracing", "start_trace"),
            (b"... and stop tracing", "stop_trace")]:
        for l in lines:
            if pattern in l:
                m = re.match("\[GenericTracing ([^.]+).(\d{3})\]", l.decode())
                coarse = time.strptime(m.group(1), "%H:%M:%S")
                coarse = time.mktime(coarse)
                fine = int(m.group(2))
                ret[key] = coarse + fine / 1000.
                break
        else:
            assert False, f"Pattern {pattern} not found in output. This is bad"
    start = ret['start_fail']
    for k in ret:
        ret[k] -= start
    del ret['start_fail']
    ret['ARCH']   = arch
    ret['ROUNDS'] = rounds


    cmd = "make dump-benchmark"
    instrs = 0
    proc = subprocess.Popen(cmd, shell=True, env=env, stdout=subprocess.PIPE)
    for line in proc.stdout.readlines():
        if line.startswith(b"IP "):
            instrs += 1
    proc.wait()

    ret['instrs'] = instrs


    return ret

CSV = None

x = trace("riscv32", 1000)
print(x)

x = trace("bochs", 1000)

print(x)
