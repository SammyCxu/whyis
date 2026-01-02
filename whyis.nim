import os, osproc, strutils, strformat, tables


# I've seperated the steps so it is easier to determine which part does what.

# Load Symptoms
var symptomsTable = initTable[string, tuple[collector: string, rules: string]]()

for line in lines("symptoms.db"):
  let l = line.strip()
  if l.len == 0 or l[0] == '#': continue
  let parts = l.split("|")
  if parts.len < 3: continue
  symptomsTable[parts[0].strip()] = (collector: parts[1].strip(), rules: parts[2].strip())


# Args
if paramCount() < 1:
  echo "Usage: whyis <symptom>"
  quit(1)

let symptom = paramStr(1)
echo fmt"Running whyis for symptom: {symptom}"

if not symptomsTable.contains(symptom):
  echo "Symptom not recognized."
  quit(1)

let collector = symptomsTable[symptom].collector
let ruleFile = symptomsTable[symptom].rules


# Get outputs of collectors
var output = ""
try:
  output = execProcess(collector, options={poStdErrToStdOut})
except OSError as e:
  echo fmt"Error running collector: {e.msg}"
  quit(1)


# Parse outputs into somewhat facts
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


# Load rules
var rules: seq[string] = @[]
try:
  for l in lines(ruleFile):
    rules.add(l.strip())
except OSError:
  echo fmt"Cannot open rules file: {ruleFile}"
  quit(1)


# Determine likely causes
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
      if facts.contains(key) and parseInt(facts[key]) < threshold:
        matched = true

  if matched:
    anyMatched = true
    echo "\nCause: ", cause
    echo "Fix: ", fix

if not anyMatched:
  echo "No likely cause found."
