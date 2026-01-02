import os, osproc, strutils, strformat, tables

let dataDir = "/usr/share/whyis"

var symptomsTable = initTable[string, tuple[collector: string, rules: string]]()
let symptomsPath = dataDir / "symptoms.db"

try:
  for line in lines(symptomsPath):
    let l = line.strip()
    if l.len == 0 or l[0] == '#': continue
    let parts = l.split("|")
    if parts.len < 3: continue
    symptomsTable[parts[0].strip()] =
      (collector: dataDir / parts[1].strip(),
       rules: dataDir / parts[2].strip())
except OSError:
  echo "Error: cannot open symptoms.db"
  quit(1)

if paramCount() < 1:
  echo "Usage: whyis <symptom> | -l | --list"
  quit(1)

let arg = paramStr(1)

if arg in ["-l", "--list"]:
  echo "Available symptoms:"
  for key in symptomsTable.keys:
    echo " - ", key
  quit(0)

let symptom = arg
echo fmt"Running whyis for symptom: {symptom}"

if not symptomsTable.contains(symptom):
  echo "Symptom not recognized."
  quit(1)

let collector = symptomsTable[symptom].collector
let ruleFile = symptomsTable[symptom].rules

var output = ""
try:
  output = execProcess(collector, options={poStdErrToStdOut})
except OSError as e:
  echo fmt"Error running collector: {e.msg}"
  quit(1)

var facts = initTable[string, string]()
for line in output.splitLines():
  let l = line.strip()
  if l.contains("power_save"):
    if l.contains("on"): facts["power_save"] = "on"
    else: facts["power_save"] = "off"
  elif l.contains("signal"):
    let parts = l.split(":")
    if parts.len >= 2:
      facts["signal_dbm"] = parts[1].strip()

var rules: seq[string] = @[]
try:
  for l in lines(ruleFile):
    rules.add(l.strip())
except OSError:
  echo fmt"Cannot open rules file: {ruleFile}"
  quit(1)

echo "\nLikely causes and suggested fixes:"

var anyMatched = false

for r in rules:
  if r.len == 0 or r[0] == '#': continue
  let parts = r.split("|")
  if parts.len < 3: continue

  let condition = parts[0].strip()
  let cause = parts[1].strip()
  let fix = parts[2].strip()

  var matched = false

  if condition.contains("="):
    let condParts = condition.split("=")
    if condParts.len == 2:
      let key = condParts[0].strip()
      let value = condParts[1].strip()
      if facts.contains(key) and facts[key] == value:
        matched = true

  elif condition.contains("<"):
    let condParts = condition.split("<")
    if condParts.len == 2:
      let key = condParts[0].strip()
      let threshold = parseInt(condParts[1].strip())
      if facts.contains(key):
        let rawValue = facts[key].strip()
        var intValue = 0
        var ok = false
        for part in rawValue.split():
          try:
            intValue = parseInt(part)
            ok = true
            break
          except ValueError:
            continue
        if ok and intValue < threshold:
          matched = true

  if matched:
    anyMatched = true
    echo "\nCause: ", cause
    echo "Fix: ", fix

if not anyMatched:
  echo "No likely cause found."
