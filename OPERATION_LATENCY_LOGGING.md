# Operation Latency Logging Enhancement

## Overview

Added comprehensive latency logging for all major RocksDB operations, measuring microsecond-level timing from operation start to completion.

## Changes Made

### 1. Write Operations Latency Logging

#### Put Operations (`db/db_impl/db_impl_write.cc`)

**Standard Put:**
- **Location**: `DBImpl::Put()` - lines 22-42
- **Measures**: Complete Put operation including validation and DB::Put call
- **Format**: `[CF_NAME] PUT operation latency: X microseconds, key_size: Y, value_size: Z, status: STATUS`

**Timestamped Put:**
- **Location**: `DBImpl::Put()` with timestamp - lines 44-64  
- **Measures**: Complete timestamped Put operation
- **Format**: `[CF_NAME] PUT (with timestamp) operation latency: X microseconds, key_size: Y, value_size: Z, status: STATUS`

#### Batch Write Operations

**Write Batch:**
- **Location**: `DBImpl::Write()` - lines 145-167
- **Measures**: Complete batch write operation including protection info and WriteImpl
- **Format**: `[BATCH] WRITE operation latency: X microseconds, batch_count: N, batch_size: Y, status: STATUS`

#### Merge Operations
- **Location**: `DBImpl::Merge()` - lines 77-102
- **Measures**: Complete merge operation including merge operator validation
- **Format**: `[CF_NAME] MERGE operation latency: X microseconds, key_size: Y, value_size: Z, status: STATUS`

#### Delete Operations  
- **Location**: `DBImpl::Delete()` - lines 104-124
- **Measures**: Complete delete operation
- **Format**: `[CF_NAME] DELETE operation latency: X microseconds, key_size: Y, status: STATUS`

### 2. Read Operations Latency Logging

#### Get Operations (`db/db_impl/db_impl.cc`)

**Standard Get:**
- **Location**: `DBImpl::Get()` - lines 1860-1882
- **Measures**: Complete Get operation including GetImpl call
- **Format**: `[CF_NAME] GET operation latency: X microseconds, key_size: Y, value_size: Z, status: STATUS`

## Sample Log Output

```
[default] PUT operation latency: 234 microseconds, key_size: 10, value_size: 100, status: OK
[default] GET operation latency: 12 microseconds, key_size: 10, value_size: 100, status: OK
[BATCH] WRITE operation latency: 1567 microseconds, batch_count: 50, batch_size: 5000, status: OK
[default] MERGE operation latency: 456 microseconds, key_size: 15, value_size: 200, status: OK
[default] DELETE operation latency: 89 microseconds, key_size: 10, status: OK
[default] PUT (with timestamp) operation latency: 267 microseconds, key_size: 10, value_size: 150, status: OK
```

## Key Features

### Timing Precision
- **Microsecond accuracy**: Uses `clock->NowMicros()` for high-precision timing
- **End-to-end measurement**: Captures complete operation latency including validation, execution, and result processing

### Comprehensive Information
- **Operation type**: Clear identification (PUT, GET, WRITE, MERGE, DELETE)
- **Data sizes**: Key size, value size (where applicable), batch size
- **Status reporting**: Success/failure status with error details
- **Column family**: Identifies which column family was accessed

### Performance Impact
- **Minimal overhead**: Simple timestamp recording with minimal CPU cost
- **Conditional logging**: Only logs when info_log_level allows INFO messages
- **No synchronization**: Uses existing RocksDB logging infrastructure

## Benefits for ADOC Integration

### 1. Performance Analysis
- **Latency tracking**: Monitor per-operation latency trends
- **Hotspot identification**: Identify slow operations affecting performance
- **Tuning correlation**: Correlate ADOC tuning decisions with operation latencies

### 2. System Monitoring  
- **Real-time visibility**: Immediate feedback on operation performance
- **Debugging support**: Detailed timing information for troubleshooting
- **Capacity planning**: Historical latency data for system sizing

### 3. YCSB Benchmarking
- **Workload analysis**: Track latency patterns across different YCSB workloads
- **Performance validation**: Verify ADOC tuning improvements through latency reduction
- **Comparative analysis**: Before/after latency comparisons

## Configuration

### Enable Logging
Set the appropriate log level in RocksDB options:
```cpp
Options options;
options.info_log_level = InfoLogLevel::INFO_LEVEL;
```

### db_bench Usage
```bash
./db_bench --benchmarks=fillseq,readseq --info_log_level=info_level
```

### Log File Location
Logs are written to the RocksDB info log file specified by:
```cpp
options.info_log = nullptr;  // stderr (default)
// or
options.db_log_dir = "/path/to/logs";
```

## Integration Points

### With ADOC Tuning
- **Tuning intervals**: Latency measurements align with ADOC tuning cycles
- **Performance feedback**: Immediate visibility into tuning effectiveness
- **Correlation analysis**: Link latency spikes to compaction/flush events

### With System Metrics
- **Timestamp synchronization**: All logs use consistent microsecond timestamps
- **Cross-component tracking**: Correlate with compaction logs and system events
- **Performance baselines**: Establish latency baselines for different workload patterns

## Usage Scenarios

### Development
- **Performance regression detection**: Identify when changes impact operation latency
- **Optimization validation**: Verify performance improvements
- **Bottleneck analysis**: Identify slow operations in application workflows

### Production Monitoring
- **SLA monitoring**: Track operation latencies against performance targets  
- **Alerting**: Set up alerts on latency threshold violations
- **Capacity planning**: Analyze latency trends for scaling decisions

### Research and Analysis
- **ADOC effectiveness**: Measure tuning algorithm impact on operation latencies
- **Workload characterization**: Understand latency patterns across different workloads
- **System behavior**: Correlate latency with system resource utilization

This comprehensive latency logging provides the foundation for detailed performance analysis and optimization of RocksDB operations within the ADOC framework.