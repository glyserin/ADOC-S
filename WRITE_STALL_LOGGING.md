# Write Stall and Queue Wait Time Logging

## Overview

Added comprehensive logging to track write stall and queue waiting times in RocksDB, providing visibility into when write operations are blocked or delayed due to write controller throttling and write queue contention.

## Features Added

### 1. Write Queue Waiting Time Logging

#### Writer Queue Tracking (`db/write_thread.cc`, `db/write_thread.h`)

**Enhanced Writer Struct:**
- Added `join_start_time`: Timestamp when writer joins the queue
- Added `wait_time_micros`: Time spent waiting in the write queue

**JoinBatchGroup Function:**
- **Location**: `db/write_thread.cc:372-424`
- **Measures**: Time from joining queue to getting processed
- **Timing**: High-precision using `std::chrono::steady_clock`

**Logging at DB Level:**
- **Location**: `db/db_impl/db_impl_write.cc:356-363` and `720-727`
- **Format**: `[WRITE_QUEUE] Writer wait time: X microseconds, batch_size: Y, final_state: Z`
- **Triggers**: Only logs when `wait_time_micros > 0` (actual waiting occurred)

### 2. Write Controller Stall Logging

#### Write Delay Detection (`db/db_impl/db_impl_write.cc`)

**DelayWrite Function Enhancement:**
- **Location**: `db/db_impl/db_impl_write.cc:1806-1894`
- **Measures**: Complete write stall duration from detection to completion
- **Detailed Information**: Includes write controller state, rate limits, and stall reasons

**Stall Start Logging:**
```cpp
[WRITE_STALL] Write delay triggered: X microseconds, bytes: Y, 
delayed_writes: N, stopped_writes: M, rate_limit: Z bytes/sec
```

**Stall Completion Logging:**
```cpp
[WRITE_STALL] Write stall completed: total_time: X microseconds, 
measured_delay: Y microseconds, bytes: Z, delayed: true/false
```

#### Write Controller Integration

**Enhanced GetDelay Function:**
- **Location**: `db/write_controller.cc:51-116`
- **Features**: Tracks write controller state and delay calculations
- **Rate Limiting**: Logs when writes are throttled due to compaction pressure

### 3. Write Operation Types Covered

#### Standard Write Operations
- **Single Put/Delete/Merge**: Individual operation stalls
- **Batch Writes**: Multi-operation batch stalls
- **Pipelined Writes**: Advanced write pipeline stalls

#### Write Stall Scenarios
- **Rate Limiting**: When write rate exceeds configured limits
- **Compaction Pressure**: When compaction can't keep up with writes
- **Memory Pressure**: When memtables are full
- **L0 Stalls**: When L0 has too many files

## Sample Log Output

### Write Queue Waiting
```
[WRITE_QUEUE] Writer wait time: 1250 microseconds, batch_size: 1024, final_state: 2
[WRITE_QUEUE] Pipelined writer wait time: 850 microseconds, batch_size: 2048, final_state: 4
```

### Write Stall Events  
```
[WRITE_STALL] Write delay triggered: 5000 microseconds, bytes: 1048576, delayed_writes: 5, stopped_writes: 0, rate_limit: 16777216 bytes/sec
[WRITE_STALL] Write stall completed: total_time: 5234 microseconds, measured_delay: 5000 microseconds, bytes: 1048576, delayed: true
[WRITE_STALL] Write rejected due to no_slowdown option
```

### Combined with Operation Latency
```
[default] PUT operation latency: 234 microseconds, key_size: 10, value_size: 100, status: OK
[WRITE_QUEUE] Writer wait time: 150 microseconds, batch_size: 110, final_state: 2
[WRITE_STALL] Write delay triggered: 2000 microseconds, bytes: 512, delayed_writes: 2, stopped_writes: 0, rate_limit: 8388608 bytes/sec
[WRITE_STALL] Write stall completed: total_time: 2156 microseconds, measured_delay: 2000 microseconds, bytes: 512, delayed: true
```

## Key Metrics Tracked

### Write Queue Metrics
- **wait_time_micros**: Actual time spent waiting in the write queue
- **batch_size**: Size of the write batch that waited
- **final_state**: Final writer state after processing (leader, follower, etc.)

### Write Stall Metrics
- **delay**: Calculated delay time from write controller
- **total_time**: End-to-end stall duration including all overhead
- **measured_delay**: Actual measured delay time via StopWatch
- **bytes**: Number of bytes being written
- **delayed_writes**: Number of currently delayed write operations
- **stopped_writes**: Number of currently stopped write operations
- **rate_limit**: Current write rate limit in bytes/sec

## Writer States

### WriteThread States
- **STATE_INIT**: Writer just created
- **STATE_GROUP_LEADER**: Writer became batch group leader
- **STATE_PARALLEL_MEMTABLE_WRITER**: Writer processing in parallel
- **STATE_COMPLETED**: Writer finished processing

## Benefits for ADOC Integration

### 1. Write Performance Analysis
- **Queue Congestion**: Identify when write queue becomes a bottleneck
- **Stall Patterns**: Understand write stall frequency and duration
- **Throughput Impact**: Measure how stalls affect overall write throughput

### 2. Tuning Correlation
- **ADOC Feedback**: Correlate ADOC tuning decisions with write stall patterns
- **Parameter Optimization**: Use stall data to optimize max_background_jobs and other parameters
- **Proactive Tuning**: Detect stall conditions before they become severe

### 3. System Monitoring
- **Real-time Visibility**: Immediate feedback on write performance issues
- **SLA Tracking**: Monitor write latency against performance targets
- **Capacity Planning**: Historical stall data for system scaling decisions

## Configuration

### Enable Logging
```cpp
Options options;
options.info_log_level = InfoLogLevel::INFO_LEVEL;
```

### db_bench Usage
```bash
./db_bench --benchmarks=fillseq,overwrite --info_log_level=info_level \
           --num=1000000 --value_size=1000 --write_buffer_size=67108864
```

### Log Analysis Commands
```bash
# Filter write stall events
grep "WRITE_STALL" rocksdb.log

# Filter write queue events  
grep "WRITE_QUEUE" rocksdb.log

# Analyze stall durations
grep "WRITE_STALL.*completed" rocksdb.log | awk '{print $6}' | sort -n

# Count stall events by hour
grep "WRITE_STALL.*triggered" rocksdb.log | cut -d' ' -f1-2 | uniq -c
```

## Integration Points

### With Operation Latency Logging
- **End-to-end tracking**: Operation latency + queue wait + stall time
- **Performance attribution**: Identify which component contributes most to latency
- **Optimization guidance**: Focus tuning efforts on the largest contributor

### With Compaction Logging  
- **Stall correlation**: Link write stalls to specific compaction events
- **Resource contention**: Understand when compaction and writes compete
- **Tuning validation**: Verify compaction tuning reduces write stalls

### With ADOC Metrics
- **Tuning effectiveness**: Measure ADOC impact on write stall reduction
- **Performance baselines**: Establish before/after performance comparisons
- **Adaptive tuning**: Use real-time stall data for ADOC decision making

## Use Cases

### Development and Testing
- **Performance regression detection**: Identify when changes increase write stalls
- **Load testing**: Understand write behavior under different load patterns
- **Configuration optimization**: Find optimal settings for specific workloads

### Production Monitoring
- **Alerting**: Set up alerts on excessive write stall duration or frequency
- **Performance troubleshooting**: Identify root cause of write performance issues
- **Capacity planning**: Predict when system will hit write throughput limits

### Research and Analysis
- **ADOC validation**: Measure automatic tuning effectiveness
- **Workload characterization**: Understand write patterns across different applications
- **System optimization**: Identify opportunities for write path improvements

This comprehensive write stall logging provides detailed insights into RocksDB's write performance characteristics, enabling data-driven optimization and effective ADOC tuning.