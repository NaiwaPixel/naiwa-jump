"""Run pure gameplay rules in Lua 5.4; this is not UrhoX/UI acceptance."""
import json
import sys
from pathlib import Path

project = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(project / ".test-runs" / "python"))
from lupa.lua54 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().package.path = (project / "scripts" / "?.lua").as_posix()
result = {"runtime": "Lua 5.4 / Lupa 2.6", "scope": "pure gameplay rules, not native UI", "passed": 0, "failed": []}

def check(condition, message):
    if condition:
        result["passed"] += 1
    else:
        result["failed"].append(str(message))

lua.eval("require('Tests.Rules').run")(check)
lua.eval("require('Tests.Rewards').run")(check)
lua.eval("require('Tests.Leaderboard').run")(check)
result["total"] = result["passed"] + len(result["failed"])
result["result"] = "PASS" if not result["failed"] else "FAIL"
report = project / ".test-runs" / "model-rules.json"
report.parent.mkdir(parents=True, exist_ok=True)
report.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(result, ensure_ascii=False))
sys.exit(0 if result["result"] == "PASS" else 1)
