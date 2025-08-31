#!/bin/bash
set -u   # fail on undefined variables, but not on grep failures

DB_PATH="/mnt/db_data"
RESULTS_DIR="./experiment_results"
mkdir -p "$RESULTS_DIR"

# Sweep ranges
BG_THREADS="1 2 4 8"
BATCH_SIZES="67108864 134217728 268435456 536870912"
LOADS="1 2 4 8 16"

SUMMARY="$RESULTS_DIR/summary.csv"
echo "bg_threads,batch_size,load,stall_count,stall_micros,ops_sec_avg" > "$SUMMARY"

for bg in $BG_THREADS; do
  for batch in $BATCH_SIZES; do
    for load in $LOADS; do
      RUN_NAME="bg${bg}_batch${batch}_load${load}"
      RUN_DIR="$RESULTS_DIR/$RUN_NAME"
      mkdir -p "$RUN_DIR"

      echo ">>> Running $RUN_NAME"

      # clean DB path
#      rm -rf "$DB_PATH"
#      mkdir -p "$DB_PATH"
      sudo umount /dev/sda4
      sudo mkfs.ext4 -F /dev/sda4
      sudo mount /dev/sda4 /mnt/db_data/

      # run db_bench
      ./db_bench \
        --benchmarks=overwrite \
        --db="$DB_PATH" \
        --num=20000000 \
        --value_size=400 \
        --key_size=16 \
        --threads=$load \
        --max_background_jobs=$bg \
        --write_buffer_size=67108864 \
        --max_memtable_size=$batch \
        --TEA_enable=true \
        --FEA_enable=true \
        --stats_interval_seconds=1 \
        --statistics \
        > "$RUN_DIR/db_bench.log" 2>&1

      # parse stall count (default 0 if not found)
      stall_count=$(grep "rocksdb.db.write.stall" "$RUN_DIR/db_bench.log" | awk '{print $NF}' | tail -1 || echo 0)
      stall_micros=$(grep "rocksdb.stall.micros" "$RUN_DIR/db_bench.log" | awk '{print $NF}' | tail -1 || echo 0)

      # throughput trace (line-by-line ops/sec)
      grep "ops/sec;" "$RUN_DIR/db_bench.log" | awk '{print NR","$3}' > "$RUN_DIR/throughput_trace.csv" || true

      # average throughput (column 2 = ops/sec)
			grep "ops/sec" "$RUN_DIR/db_bench.log" | awk '{print NR","$3}' > "$RUN_DIR/throughput_trace.csv" || true
      avg_ops_sec=$(awk -F, '{sum+=$2; count++} END {print (count?sum/count:0)}' "$RUN_DIR/throughput_trace.csv")

      # append to summary CSV
      echo "$bg,$batch,$load,$stall_count,$stall_micros,$avg_ops_sec" >> "$SUMMARY"
      echo ">>> Done $RUN_NAME – stall_count=$stall_count, stall_micros=$stall_micros, avg_ops_sec=$avg_ops_sec"
    done
  done
done

echo "All experiments complete. Results in $SUMMARY"

