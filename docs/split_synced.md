# Split Synced Threading

## Overview

The `--split-synced` option is an enhancement to the block-depth-threading algorithm that isolates synced addresses from unsynced addresses across different scanner threads. This prevents fully or near-fully synced addresses from being blocked by addresses that are still catching up to the blockchain.

## Requirements

- Requires `--block-depth-threading`
- Only affects initial thread assignment at startup
- `--split-synced` accepts a numeric value representing the maximum block depth for an address to be considered synced
- If `--split-synced` is not provided or set to 0, split-sync is disabled

## Behavior

### Address Classification

Addresses are classified as either **synced** or **unsynced** based on their block depth:
- **Synced address**: blockdepth ≤ `--split-synced` value
- **Unsynced address**: blockdepth > `--split-synced` value

Note: The `--min-block-depth` parameter is only used for assigning a minimum block depth value to addresses for workload calculations, and is not used to determine if an address is synced.

### Thread Isolation

When enabled, this option creates two classes of threads:
1. **Synced threads**: contain only synced addresses
2. **Unsynced threads**: contain only unsynced addresses

The separation occurs when the first unsynced address is encountered during thread assignment. If the current thread already contains addresses (which must be synced), the algorithm forces an increment to the next thread before assigning the unsynced address. All subsequent addresses continue following the standard block-depth-threading allocation algorithm.

### Thread Allocation

- Synced addresses may span multiple threads if the block-depth-threading algorithm determines it necessary for load balancing
- There is no minimum or maximum number of threads reserved for either class
- If the last thread would be exceeded, remaining addresses are assigned to that final thread
- The standard alternating over/under-allocation strategy continues to apply within each class

## Example

With 4 threads and 20 accounts with varying sync states:
- Accounts A-H: 16 blocks each (synced, at minimum) = 128 blocks
- Accounts I-L: 100 blocks each (unsynced) = 400 blocks
- Accounts M-P: 300 blocks each (unsynced) = 1,200 blocks
- Accounts Q-T: 500 blocks each (unsynced) = 2,000 blocks

**Without `--split-synced`** (standard block-depth-threading):
- Total: 3,728 blocks, target: 932 blocks/thread
- Thread 0 (even, over-allocate): A, B, C, D, E, F, G, H, I, J, K, L, M, N (1,128 blocks)
  - Contains: 8 synced (A-H) + 6 unsynced (I-N) - **mixed**
- Thread 1 (odd, under-allocate): O, P (600 blocks)
  - Contains: 2 unsynced
- Thread 2 (even, over-allocate): Q, R (1,000 blocks)
  - Contains: 2 unsynced
- Thread 3 (odd, under-allocate): S, T (1,000 blocks)
  - Contains: 2 unsynced
- **Problem**: Synced addresses (A-H) are mixed with unsynced addresses (I-N) in Thread 0, causing synced addresses to wait for unsynced ones to catch up

**With `--split-synced=16`** (isolated synced/unsynced):
- Total: 3,728 blocks, target: 932 blocks/thread
- Thread 0 (even, over-allocate): A, B, C, D, E, F, G, H (128 blocks)
  - Contains: 8 synced (A-H) only - **synced thread**
  - Split occurs when I (first unsynced) is encountered, forcing move to Thread 1
- Thread 1 (odd, under-allocate): I, J, K, L, M (800 blocks)
  - Contains: 5 unsynced (I-M) only - **unsynced thread**
  - N would exceed target (800+300=1100 > 932), so moves to Thread 2
- Thread 2 (even, over-allocate): N, O, P, Q (1,400 blocks)
  - Contains: 4 unsynced - **unsynced thread**
  - R would exceed target (1400+500=1900 >= 932), so moves to Thread 3
- Thread 3 (odd, under-allocate): R, S, T (1,500 blocks)
  - Contains: 3 unsynced - **unsynced thread**
  - Final thread receives remaining accounts
- **Result**: Synced addresses (A-H) are isolated in Thread 0 and can process updates quickly without waiting for unsynced addresses. All unsynced addresses are separated into threads 1-3

## Benefits

This approach ensures that synced addresses receive timely updates without being delayed by the potentially lengthy synchronization process of newly added or far-behind addresses.