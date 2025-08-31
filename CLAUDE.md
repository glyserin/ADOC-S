# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Repository

This is a modified version of RocksDB implementing **ADOC (Automatic Data Overflow Control)**, a research project published at FAST'23. ADOC provides online tuning for LSM-tree storage systems to optimize performance under varying workloads.

The repository includes:
- **ADOC-T**: Thread-based tuning (`--TEA_enable=true --FEA_enable=false`)
- **ADOC-B**: Batch size tuning (`--TEA_enable=false --FEA_enable=true`)  
- **ADOC**: Combined tuning (`--TEA_enable=true --FEA_enable=true`)
- **YCSB workload generator**: Custom implementation in `ycsbcore/` and `ycsb_workload/`
- **SILK integration**: Placeholder implementation (use original SILK repo for production)

## Build Commands

### Primary Build System - Make
```bash
# Build main benchmark tool (recommended for ADOC)
make db_bench -j4

# Production builds (release mode)
make static_lib     # Static library
make shared_lib     # Shared library

# Development builds (debug mode)
make all           # All tools and tests
make dbg          # Debug build with no optimizations

# Testing
make check        # Run all unit tests + formatting checks
make asan_check   # AddressSanitizer checks
make ubsan_check  # UBSanitizer checks
```

### CMake (Alternative)
```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j
```

### Running Individual Tests
```bash
# Single test executable
make cache_test && ./cache_test

# Specific test filter
./db_test --gtest_filter=DBTest.OpenWhenOpen
```

## Core Architecture

### Directory Structure
- **`db/`**: Core database engine, compaction, memtables, version management
  - `db/db_impl/`: Main DB implementation 
  - `db/compaction/`: Compaction logic and job management
  - `db/blob/`: Blob storage support
- **`table/`**: SSTable format, readers, writers, and table caches
- **`cache/`**: Block cache implementations (LRU, Clock cache)
- **`memtable/`**: In-memory table implementations
- **`util/`**: Core utilities and data structures
- **`env/`**: Environment abstraction layer (filesystem, threads)
- **`options/`**: Configuration and options management
- **`include/rocksdb/`**: Public C++ API headers
- **`java/`**: Java bindings (RocksJava)

### ADOC-Specific Components
- **`utilities/DOTA/`**: 
  - `DOTA_tuner.cc`: Main ADOC tuning logic
  - `report_agent.cc`: Metrics collection and reporting
- **`include/rocksdb/utilities/DOTA_tuner.h`**: ADOC tuner interface
- **`include/rocksdb/utilities/report_agent.h`**: Reporter agent interface
- **`ycsbcore/`** and **`ycsb_workload/`**: YCSB workload generator
- **`tools/db_bench_tool.cc`**: Integration point for ADOC (look for FEA_enable/TEA_enable)

### Key Concepts
- **LSM-tree**: Log-Structured Merge tree storage engine
- **Compaction**: Background process that merges SST files across levels
- **MemTable**: In-memory write buffer before flushing to disk
- **SST Files**: Sorted String Table files on disk
- **Column Families**: Logical partitioning within a single DB instance
- **Write-Ahead Log (WAL)**: Durability mechanism for uncommitted writes

### Performance Tuning Areas (ADOC Focus)
- **Thread Pool Configuration**: Compaction and flush thread management
- **Batch Size Tuning**: Write batch optimization  
- **Level-based Compaction**: Multi-level SST file organization
- **Memory Management**: Buffer pool and cache sizing

## Development Workflow

### Code Organization
- Implementation files in respective directories (`db/`, `table/`, etc.)
- Unit tests alongside implementation (e.g., `cache_test.cc` near `cache.cc`)
- Integration tests in `db/` for database-level functionality
- Tools and benchmarks in `tools/`

### Testing Strategy
- Use Google Test framework for unit tests
- Integration tests cover full DB operations
- Stress testing via `db_stress_tool/`
- Performance benchmarking with `db_bench`

### ADOC Development
- ADOC logic is primarily in `utilities/DOTA/` 
- Configuration through db_bench command-line options
- Metrics collection integrated into existing RocksDB stats framework
- Online tuning operates through reporter agent callbacks

### Dependencies
- **Required**: C++17 compiler (GCC ≥ 7, Clang ≥ 5)
- **Optional but recommended**: gflags, snappy, lz4, zstd, bzip2, zlib
- **For Java**: JDK for RocksJava bindings
- **For benchmarking**: Google Benchmark ≥ 1.6.0

This codebase extends RocksDB with research-oriented automatic tuning capabilities while maintaining compatibility with the standard RocksDB API.