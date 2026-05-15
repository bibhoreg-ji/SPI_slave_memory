# SPI Slave Memory Backend Flow

This repository contains the synthesized gate-level netlist, timing constraints, MMMC setup, and Cadence Innovus scripts required for physical implementation of the SPI slave memory design.

---

# File Description

| File Name              | Description                                                         |
| ---------------------- | ------------------------------------------------------------------- |
| `spi_slave_memory.v`   | Gate-level synthesized Verilog netlist generated from Cadence Genus |
| `spi_slave_memory.sdc` | Timing constraint file                                              |
| `mmmc.tcl`             | Multi-Mode Multi-Corner setup file                                  |
| `innovus.tcl`          | Cadence Innovus backend implementation script                       |
| `synthesis.tcl`        | Cadence Genus synthesis script used to generate the netlist         |

---

# Design Flow

The RTL design is first synthesized using Cadence Genus to generate the gate-level netlist. The synthesized netlist is then imported into Cadence Innovus for physical design implementation.

---

# Backend Physical Design Flow

The physical implementation flow includes:

1. Design Import
2. Floorplanning
3. Power Planning
4. Standard Cell Placement
5. Clock Tree Synthesis (CTS)
6. Routing
7. Timing Optimization
8. GDSII Generation

---

# Running Physical Design in Innovus

## Step 1: Launch Innovus

```bash
innovus
```

---

## Step 2: Run the Innovus Script

Inside the Innovus terminal:

```tcl
source innovus.tcl
```

The Innovus script automatically performs:

- Loading MMMC timing views
- Importing synthesized netlist
- Reading timing constraints
- Floorplanning
- Power ring generation
- Placement optimization
- Clock tree synthesis
- Routing
- Timing optimization
- Report generation

---

# MMMC Setup

The `mmmc.tcl` file configures:

- Library sets
- Timing corners
- RC corners
- Constraint modes
- Analysis views

This enables accurate setup and hold timing analysis across different process-voltage-temperature corners.

---

# Timing Constraints

The `spi_slave_memory.sdc` file defines:

- Clock frequency
- Input delays
- Output delays
- False paths
- Timing exceptions

Example:

```tcl
create_clock -name clk -period 20 [get_ports clk]
```

---

# Synthesis Flow Using Cadence Genus

## Step 1: Launch Genus

```bash
genus
```

---

## Step 2: Run Synthesis Script

Inside Genus:

```tcl
source synthesis.tcl
```

The synthesis script performs:

- RTL elaboration
- Technology mapping
- Logic optimization
- Timing optimization
- Netlist generation

---

# Generated Outputs from Synthesis

After synthesis, the following outputs are generated:

| Output               | Description                         |
| -------------------- | ----------------------------------- |
| `spi_slave_memory.v` | Gate-level synthesized netlist      |
| Timing reports       | Setup and hold timing reports       |
| Area reports         | Cell utilization and area           |
| Power reports        | Estimated dynamic and leakage power |

---

# Running Backend Flow in Innovus

After generating the synthesized gate-level netlist using Cadence Genus, the backend physical design flow is performed using Cadence Innovus.

---

## Step 1: Launch Innovus

Open terminal and run:

```bash
innovus
```

---

## Step 2: Source the Backend Script

Inside the Innovus command terminal:

```tcl
source innovus.tcl
```

---

# What the Innovus Script Performs

The `innovus.tcl` script automatically performs:

- Importing the synthesized netlist
- Loading MMMC configuration
- Reading timing constraints
- Floorplanning
- Power planning
- Standard cell placement
- Clock Tree Synthesis (CTS)
- Routing
- Post-route optimization
- Timing analysis
- GDSII generation

---

# Backend Outputs Generated

After successful backend implementation, Innovus generates:

| Output         | Description                         |
| -------------- | ----------------------------------- |
| Routed netlist | Post-route Verilog netlist          |
| DEF file       | Physical placement and routing data |
| SDF file       | Delay annotation file               |
| Timing reports | Post-route setup/hold analysis      |
| Power reports  | Backend power estimation            |
| GDSII          | Final layout file                   |

---

# Complete ASIC Design Flow

```text
RTL Verilog
      ↓
Cadence Genus
      ↓
Synthesized Netlist
(spi_slave_memory.v)
      ↓
Cadence Innovus
      ↓
Floorplanning
      ↓
Placement
      ↓
Clock Tree Synthesis
      ↓
Routing
      ↓
Post-Route Optimization
      ↓
GDSII Generation
```

---

# Notes

- Kindly go through the `synthesis.tcl` and `innovus.tcl` scripts before execution.
- Update the file paths, library locations, technology files, and report directories if required according to your system setup.
- Ensure that the standard-cell libraries and LEF files are correctly linked in the scripts.
- Verify that the MMMC setup paths inside `mmmc.tcl` are correct.
- Make sure the synthesized netlist (`spi_slave_memory.v`) and constraint file (`spi_slave_memory.sdc`) are present in the expected directories.
- If all paths and library references are correctly configured, the provided backend commands should run without modification.

---

---

---

# Author

Bibhore Goswami  
MTech ESE  
Indian Institute of Science (IISc)
