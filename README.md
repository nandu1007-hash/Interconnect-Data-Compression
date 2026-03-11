# Interconnect-Data-Compression
Team ID : 44 , Problem Statement number : 10
# SoC Interconnect Data Compression (BDI + DBI)

**Team ID:** [Insert Team ID Here]  
**Question Number:** [Insert Question Number Here] / [R:3, V:4, S:2]

---

## 📌 Problem Statement
**Specification:** Implement a lossless hardware encoder/decoder pair for an SoC interconnect to reduce bus toggling and data width.

**Objective:** Modern System-on-Chip (SoC) interconnects consume significant power due to wide data buses and high toggle rates. This project implements a two-stage lossless compression and encoding pipeline to minimize both the effective data width and the number of bit transitions on the interconnect highway.

---

## 🏗️ Architecture Overview

The design consists of two main hardware modules (`bdi_dbi_encoder` and `bdi_dbi_decoder`) that execute a two-stage data transformation pipeline on a 256-bit wide data bus. 

### Stage 1: Base-Delta-Immediate (BDI) Compression
* The 256-bit input is treated as eight 32-bit words.
* **Base Value:** The first word (`data_in[31:0]`) acts as the base value.
* **Delta Calculation:** The hardware calculates the difference between the base and the remaining seven words.
* **Compression:** If all seven differences fit within a 7-bit signed integer range (-64 to +63), the bus is successfully compressed. The `bdi_flag` is asserted, and the output is packed with the base value and the seven 7-bit deltas, effectively masking the upper bits to zero to save dynamic power.

### Stage 2: Data Bus Inversion (DBI)
* The hardware counts the number of '1's in the 256-bit BDI-processed data.
* If the number of '1's exceeds 128 (more than 50% of the bus width), the entire 256-bit data is bitwise inverted.
* The `dbi_flag` is asserted alongside the data to tell the decoder to re-invert the data upon reception, significantly reducing the toggle rate on the physical bus lines.

---

## 🏗️ Architecture Overview

The design consists of two main hardware modules (`bdi_dbi_encoder` and `bdi_dbi_decoder`) that execute a two-stage data transformation pipeline on a 256-bit wide data bus. 

### System Block Diagram
```mermaid
flowchart LR
    %% Inputs
    DIN["data_in [255:0]"] --> BDI_ENC

    %% Encoder Module
    subgraph ENCODER ["bdi_dbi_encoder"]
        direction LR
        BDI_ENC["Stage 1: BDI Compression"] --> DBI_ENC["Stage 2: DBI Inversion"]
        DBI_ENC --> ENC_REG["Output Flops"]
    end

    %% Interconnect Bus
    ENC_REG -- "bus_out [255:0]\nbdi_flag, dbi_flag" --> REV_DBI

    %% Decoder Module
    subgraph DECODER ["bdi_dbi_decoder"]
        direction LR
        REV_DBI["Stage 1: Reverse DBI"] --> REV_BDI["Stage 2: Reverse BDI"]
        REV_BDI --> DEC_REG["Output Flops"]
    end

    %% Outputs
    DEC_REG --> DOUT["data_out [255:0]"]
