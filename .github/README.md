# whyis

`whyis` is a lightweight Linux diagnostic tool that helps you find likely causes for system issues like slow Wi-Fi, high CPU, audio problems, and more. It uses **collector scripts** to gather system information, and **rules files** to match conditions to likely causes and fixes no AI bs. Obviously you don't want to waste hours to setup api keys rather than fixing the real problem.

---

## Project Layout

```
whyis/
├── collectors/           # Shell scripts that gather system facts
│   └── collector.sh      
├── rules/                # Rule files that map conditions to causes/fixes
│   └── rule.rules
├── symptoms.db           # Defines which symptoms map to which collectors and rules
├── whyis.nim             # Main Nim executable
├── whyis                 # Compiled binary (optional)
└── .github/              # github stuff
```

---

## Installion


**Use aur:**
```bash
yay -S whyis
```

**Or:**
```bash
curl -fsSL https://raw.githubusercontent.com/xZepyx/whyis/main/install.sh | sh
```

---

## How It Works

1. **Load Symptoms**
   The main program reads `symptoms.db` to know which collector and rules file corresponds to each symptom.

   Example entry in `symptoms.db`:

   ```
   wifi slow|collectors/wifi.sh|rules/wifi.rules
   ```


2. **Run Collector**  
   The collector script gathers facts about the system. For example, `wifi.sh`:

   ```bash
    #!/bin/bash
    iw dev wlan0 link 2>/dev/null
    cat /proc/net/wireless 2>/dev/null
    ````

3. **Parse Facts**
   `whyis.nim` parses the collector output into key-value facts, e.g.:

   ```
    power_save=on
    signal_dbm=-70
   ```



4. **Load Rules**  
   Rules files define conditions, likely causes, and suggested fixes in this format:
    ```
    condition | cause | fix
    ```



   Example `wifi.rules`:

    ```
    power_save=on | Wi-Fi power saving reduces throughput. | sudo iw dev wlan0 set power_save off
    signal_dbm<-65 | Weak signal; move closer to AP. | Check access point or use 5GHz
    ```




5. **Evaluate Rules & Print Fixes**  
   The program evaluates each condition against the facts and prints any matching cause and suggested fix.

---

## Adding New Symptoms

1. **Create a collector** in `collectors/`. For example:
* **collectors/cpu.sh**
   ```bash
    mpstat 1 1 | awk '/all/ {print "idle=" $12}'
    ````

2. **Create a rule file** in `rules/`. For example:

   ```
    idle<20 | CPU is overloaded | Close heavy apps or investigate processes
   ```




3. **Add the symptom to `symptoms.db`**:

    ```
    high-cpu-usage|collectors/cpu.sh|rules/cpu.rules
    ````

4. Run the tool:

   ```bash
    nim c -r whyis.nim
    ./whyis "high cpu"
    ````

---

## Example Usage
**For wifi/a-symptom:**

    ./whyis wifi-slow/slow-internet/slow-wifi/or-a-symptom

Output:

    Running whyis for symptom: wifi slow

    Likely causes and suggested fixes:

    Cause: Wi-Fi power saving reduces throughput.
    Fix: sudo iw dev wlan0 set power_save off

    Cause: Weak signal; move closer to AP.
    Fix: Check access point or use 5GHz

---

## Notes

* For contributors: The main Nim program is generic and does not need modification for new symptoms — just add new collector scripts, rules files, and update `symptoms.db`.
* All outputs are plain text and easily readable in any terminal.
* Conditions supported: `key=value` (string match) and `key<number` (numeric threshold).
