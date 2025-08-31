# Compaction Logging Enhancement

## Changes Made

Enhanced the compaction logging in `db/compaction/compaction_job.cc` to provide clear visibility into when compactions occur and at which levels.

### 1. Enhanced Compaction Start Logging (CompactionJob::Run)

Added detailed start logging that shows:
- **When**: Timestamp in microseconds
- **Which Level**: Input level -> Output level (e.g., "Level 0->1")  
- **Why**: Compaction reason (e.g., LevelL0FilesNum, LevelMaxLevelSize)
- **Job ID**: For tracking specific compaction jobs

```cpp
ROCKS_LOG_INFO(db_options_.info_log, 
               "[%s] [JOB %d] COMPACTION STARTED: Level %d->%d, reason: %s, time: %lu", 
               cfd->GetName().c_str(), job_id_,
               compaction->start_level(), compaction->output_level(),
               GetCompactionReasonString(compaction->compaction_reason()),
               start_time_micros);
```

### 2. Enhanced Compaction Completion Logging

Added completion logging that shows:
- **Duration**: How long the compaction took (in milliseconds)
- **Status**: Whether it succeeded or failed
- **Completion timestamp**

```cpp
ROCKS_LOG_INFO(db_options_.info_log, 
               "[%s] [JOB %d] COMPACTION COMPLETED: Level %d->%d, status: %s, duration: %.3f ms, time: %lu", 
               cfd->GetName().c_str(), job_id_,
               compaction->start_level(), compaction->output_level(),
               status.ok() ? "OK" : status.ToString().c_str(),
               duration_micros / 1000.0,
               end_time_micros);
```

### 3. Enhanced Existing LogCompaction Function

Modified the existing detailed logging to explicitly show input and output levels:

```cpp
ROCKS_LOG_INFO(
    db_options_.info_log, "[%s] [JOB %d] Compacting %s, score %.2f, input_level: %d, output_level: %d",
    cfd->GetName().c_str(), job_id_,
    compaction->InputLevelSummary(&inputs_summary), compaction->score(),
    compaction->start_level(), compaction->output_level());
```

## Sample Log Output

With these changes, compaction logs will look like:

```
[default] [JOB 15] COMPACTION STARTED: Level 0->1, reason: LevelL0FilesNum, time: 1693834567123456
[default] [JOB 15] Compacting 4@0 + 3@1 files to L1, score 1.25, input_level: 0, output_level: 1
[default] Compaction start summary: Base version 2 L0 files: 4 L1 files: 3...
[default] [JOB 15] COMPACTION COMPLETED: Level 0->1, status: OK, duration: 245.632 ms, time: 1693834567369088
```

## Benefits

1. **Clear Timeline**: Easy to track when compactions start and finish
2. **Level Visibility**: Immediate visibility into which levels are being compacted
3. **Performance Monitoring**: Duration tracking for performance analysis
4. **Debugging**: Status information for troubleshooting failed compactions
5. **ADOC Integration**: Timestamps align with ADOC tuning intervals for correlation

## Usage

These logs will appear when:
- `info_log_level` is set to INFO or lower
- Compactions are triggered (automatic or manual)
- Log level allows INFO messages

To see these logs in db_bench:
```bash
./db_bench --benchmarks=fillseq,compactall --info_log_level=info_level
```