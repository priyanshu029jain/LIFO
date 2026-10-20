# Synchronous LIFO (Hardware Stack) with Dual Verification Suite

A 16-deep, 8-bit wide **Last-In-First-Out (LIFO / Stack)** memory buffer designed in Verilog, verified through both:
1. **Layered SystemVerilog Constrained-Random Testbench (IEEE 1800)**
2. **Formal Property Verification (SVA + SymbiYosys + Z3 SMT Solver)**

---

## 📌 Features & Specifications

- **Memory Organization**: 16 entries $\times$ 8 bits (`mem_array [15:0]`).
- **Clocking & Reset**: Fully synchronous active-high reset.
- **Operations**:
  - `PUSH`: Pushes 8-bit data into the stack; auto-protected against overflow.
  - `POP`: Retrieves the most recently pushed element; auto-protected against underflow.
  - `PUSH + POP`: Replaces/overwrites the top of the stack simultaneously without altering pointer depth.
  - `PEEK` (`peek_data`): Real-time combinational visibility of the current top-of-stack without removing it.
- **Status Flags**:
  - `empty`: Asserted when pointer is `0x00`.
  - `full`: Asserted when pointer is `0x10` (16 entries).

---

## 📁 Repository Structure

```
├── LIFO.v                  # LIFO RTL design + inline formal verification block
├── tb_LIFO.v               # Directed Verilog testbench (Icarus Verilog compatible)
├── lifo_if.sv              # SystemVerilog Interface with DRIVER, MONITOR, and DUT modports
├── lifo_transaction.sv     # SystemVerilog Transaction packet with randomization and copy methods
├── lifo_generator.sv       # Stimulus Generator with mailbox and completion handshake
├── lifo_driver.sv          # Synchronous pin-level Driver
├── lifo_monitor.sv         # Passive interface Monitor forwarding packets to Scoreboard
├── lifo_scoreboard.sv      # Golden reference stack model and automated checker
├── lifo_agent.sv           # Verification Agent encapsulating Generator, Driver, and Monitor
├── lifo_environment.sv     # Testbench Environment (pre_test, test, post_test phases)
├── tb_top.sv               # Top-level SystemVerilog testbench runner
├── lifo_sva.sv             # SystemVerilog Assertions (SVA) module
├── lifo_formal.sv          # Top wrapper for formal verification
├── lifo.sby                # SymbiYosys configuration file (BMC, Prove, Cover)
├── waveform.png            # GTKWave simulation waveform snapshot
└── .gitignore              # Ignores simulation and formal artifacts
```

---

## 🏗️ Layered SystemVerilog Testbench Architecture

The SystemVerilog verification suite follows industry-standard OOP layered testbench methodology:

```
+---------------------------------------------------------------+
|                            tb_top                             |
|  +---------------------------------------------------------+  |
|  |                    lifo_environment                     |  |
|  |  +---------------------------------------------------+  |  |
|  |  |                  lifo_scoreboard                  |  |  |
|  |  |            (Golden Reference Stack Model)         |  |  |
|  |  +---------------------------^-----------------------+  |  |
|  |                              | mon2scb mailbox           |  |
|  |  +---------------------------|-----------------------+  |  |
|  |  |  lifo_agent               |                       |  |  |
|  |  |  +-------------------+    |   +----------------+  |  |  |
|  |  |  |  lifo_generator   |    |   |  lifo_driver   |  |  |  |
|  |  |  +---------+---------+    |   +-------+--------+  |  |  |
|  |  |            |              |           |           |  |  |
|  |  |            +--> gen2drv mailbox ------+           |  |  |
|  |  |                                       |           |  |  |
|  |  |  +-------------------+                |           |  |  |
|  |  |  |   lifo_monitor    +----------------+           |  |  |
|  |  |  +---------^---------+                            |  |  |
|  |  +------------|--------------------------|-----------+  |  |
|  +---------------|--------------------------|--------------+  |
|                  |                          |                 |
|  +---------------+--------------------------v--------------+  |
|  |                     lifo_if (Interface)                 |  |
|  +-------------------------------+-------------------------+  |
|                                  |                            |
|  +-------------------------------v-------------------------+  |
|  |                         LIFO (DUT)                      |  |
|  +---------------------------------------------------------+  |
+---------------------------------------------------------------+
```

---

## 🔍 Formal Property Verification (SymbiYosys + SVA)

Formal verification mathematically proves the correctness of the design across all possible execution traces without writing test vectors.

### Properties Verified:
- **Safety Invariants**:
  - $0 \le \text{ptr} \le 16$ at all times.
  - `empty` is strictly asserted iff $\text{ptr} == 0$.
  - `full` is strictly asserted iff $\text{ptr} == 16$.
  - Mutual exclusion: `!(empty && full)` never occurs.
  - `peek_data == 8'h00` whenever stack is empty.
- **Functional Transitions**:
  - Push increments pointer by 1 when not full.
  - Pop decrements pointer by 1 when not empty.
  - Push on full is ignored (overflow-proof).
  - Pop on empty is ignored (underflow-proof).
  - Simultaneous Push+Pop preserves stack depth.
- **Coverage Goals**:
  - Stack full state reachability.
  - Full-to-empty drain cycle reachability.
  - Simultaneous Push and Pop reachability.

### Formal Verification Summary:
| Task | Mode | Engine / Solver | Result |
| :--- | :--- | :--- | :--- |
| **`bmc`** | Bounded Model Checking (Depth 20) | `smtbmc z3` | **PASS** |
| **`prove`** | Mathematical Proof by k-Induction | `smtbmc z3` | **PASS** |
| **`cover`** | State Reachability & Functional Coverage | `smtbmc z3` | **PASS** |

---

## 🚀 How to Run

### 1. Directed Simulation (Icarus Verilog + GTKWave)
```bash
# Compile and run simulation
iverilog -o testbench.vvp tb_LIFO.v
vvp testbench.vvp

# View waveform in GTKWave
gtkwave testbench.vcd
```

### 2. Formal Verification (SymbiYosys)
```bash
# Run all formal verification tasks (BMC, k-induction proof, and cover)
sby -f lifo.sby
```

### 3. Layered SystemVerilog Testbench
Run on any standard IEEE 1800 simulator or [EDA Playground](https://edaplayground.com):
```bash
# Siemens QuestaSim / ModelSim
vlog -sv LIFO.v lifo_if.sv tb_top.sv
vsim -c tb_top -do "run -all; quit"

# Synopsys VCS
vcs -sverilog -debug_access+all tb_top.sv
./simv
```

---

## 📊 Waveform Preview

![Simulation Waveform](waveform.png)
