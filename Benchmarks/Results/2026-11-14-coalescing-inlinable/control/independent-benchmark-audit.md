# Independent matched-benchmark audit

Passed.

All 132 measured samples (192 processes), 22 excluded warmup samples (32 processes), and 224 retained stdout files were checked. Every output hash matches its original independently verified coverage reference. Raw time/RSS, empty stderr, commands, sample inventory, schedule/log chronology, balanced six-round ordering, frozen source/binary/harness files and prior reference preservation pass. All 22 group statistics and 66 paired changes were independently recomputed and match the summary. No observed samples were dropped or retried.

No benchmark harness was imported and no benchmark or coverage process was run. Nanosecond timings come from the immutable raw records and pass native-time sanity checks; coverage reference receipts were hash-verified rather than rerun.
