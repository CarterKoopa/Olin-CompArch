import matplotlib.pyplot as plt
import numpy as np
import os
import math


def bits_to_grid(bit_string, width=8, height=8):
    """Convert a 64-bit string to an 8x8 grid."""
    # Remove '0b' prefix if present and ensure it's 64 bits
    bit_string = bit_string.replace("0b", "").zfill(64)

    # Convert to numpy array
    bits = np.array([int(b) for b in bit_string[::-1]])  # Reverse for LSB first

    # Reshape to 8x8 grid
    grid = bits.reshape(height, width)

    return grid


def create_tiled_visualization(csv_file, color, output_dir="tb-output"):
    """Create a tiled visualization of all timesteps for one color."""

    if not os.path.exists(csv_file):
        print(f"Warning: {csv_file} not found")
        return

    print(f"Processing {csv_file}...")

    # Read CSV file
    with open(csv_file, "r") as f:
        lines = f.readlines()

    # Skip header
    data_lines = lines[1:]

    if not data_lines:
        print(f"No data found in {csv_file}")
        return

    # Parse all patterns
    patterns = []
    times = []
    changes = []

    for line in data_lines:
        parts = line.strip().split(",")
        if len(parts) < 4:
            continue

        change_num = parts[0]
        time = parts[1]
        pattern_bin = parts[3]

        grid = bits_to_grid(pattern_bin)
        patterns.append(grid)
        times.append(time)
        changes.append(change_num)

    num_patterns = len(patterns)
    print(f"Found {num_patterns} patterns")

    # Calculate grid dimensions for tiling
    cols = math.ceil(math.sqrt(num_patterns))
    rows = math.ceil(num_patterns / cols)

    # Create figure with subplots
    fig, axes = plt.subplots(rows, cols, figsize=(cols * 3, rows * 3))

    # Flatten axes array for easier indexing
    if rows == 1 and cols == 1:
        axes = np.array([axes])
    axes = axes.flatten()

    # Plot each pattern
    for idx, (grid, time, change) in enumerate(zip(patterns, times, changes)):
        ax = axes[idx]

        # Create the heatmap
        im = ax.imshow(grid, cmap="binary", interpolation="nearest", vmin=0, vmax=1)

        # Add grid lines
        ax.set_xticks(np.arange(-0.5, 8, 1), minor=True)
        ax.set_yticks(np.arange(-0.5, 8, 1), minor=True)
        ax.grid(which="minor", color="gray", linestyle="-", linewidth=0.5)

        # Remove tick labels to save space
        ax.set_xticks([])
        ax.set_yticks([])

        # Title with change number and time
        ax.set_title(f"#{change} (t={time})", fontsize=8)

    # Hide unused subplots
    for idx in range(num_patterns, len(axes)):
        axes[idx].axis("off")

    # Overall title
    fig.suptitle(
        f"Pattern {color} Evolution - All Timesteps", fontsize=16, fontweight="bold"
    )

    plt.tight_layout()

    # Save figure
    output_file = os.path.join(output_dir, f"pattern_{color}_tiled.png")
    plt.savefig(output_file, dpi=150, bbox_inches="tight")
    plt.close()

    print(f"Created {output_file}")


def create_detailed_tiled_visualization(csv_file, color, output_dir="tb-output"):
    """Create a tiled visualization with cell values shown."""

    if not os.path.exists(csv_file):
        print(f"Warning: {csv_file} not found")
        return

    print(f"Processing {csv_file} (detailed)...")

    # Read CSV file
    with open(csv_file, "r") as f:
        lines = f.readlines()

    # Skip header
    data_lines = lines[1:]

    if not data_lines:
        print(f"No data found in {csv_file}")
        return

    # Parse all patterns
    patterns = []
    times = []
    changes = []

    for line in data_lines:
        parts = line.strip().split(",")
        if len(parts) < 4:
            continue

        change_num = parts[0]
        time = parts[1]
        pattern_bin = parts[3]

        grid = bits_to_grid(pattern_bin)
        patterns.append(grid)
        times.append(time)
        changes.append(change_num)

    num_patterns = len(patterns)

    # Calculate grid dimensions for tiling
    cols = min(4, num_patterns)  # Max 4 columns for readability
    rows = math.ceil(num_patterns / cols)

    # Create figure with subplots
    fig, axes = plt.subplots(rows, cols, figsize=(cols * 4, rows * 4))

    # Flatten axes array for easier indexing
    if rows == 1 and cols == 1:
        axes = np.array([axes])
    elif rows == 1 or cols == 1:
        axes = axes.flatten()
    else:
        axes = axes.flatten()

    # Plot each pattern
    for idx, (grid, time, change) in enumerate(zip(patterns, times, changes)):
        ax = axes[idx]

        # Create the heatmap
        im = ax.imshow(grid, cmap="RdYlGn_r", interpolation="nearest", vmin=0, vmax=1)

        # Add grid lines
        ax.set_xticks(np.arange(-0.5, 8, 1), minor=True)
        ax.set_yticks(np.arange(-0.5, 8, 1), minor=True)
        ax.grid(which="minor", color="black", linestyle="-", linewidth=1)

        # Set tick labels
        ax.set_xticks(np.arange(0, 8, 1))
        ax.set_yticks(np.arange(0, 8, 1))
        ax.tick_params(labelsize=8)

        # Add text annotations showing 1s and 0s
        for i in range(8):
            for j in range(8):
                text = ax.text(
                    j,
                    i,
                    int(grid[i, j]),
                    ha="center",
                    va="center",
                    color="white" if grid[i, j] else "black",
                    fontsize=10,
                    fontweight="bold",
                )

        # Title with change number and time
        ax.set_title(f"Change #{change}\nTime: {time}", fontsize=10)

    # Hide unused subplots
    for idx in range(num_patterns, len(axes)):
        axes[idx].axis("off")

    # Overall title
    fig.suptitle(
        f"Pattern {color} Evolution (Detailed)", fontsize=16, fontweight="bold"
    )

    plt.tight_layout()

    # Save figure
    output_file = os.path.join(output_dir, f"pattern_{color}_tiled_detailed.png")
    plt.savefig(output_file, dpi=200, bbox_inches="tight")
    plt.close()

    print(f"Created {output_file}")


def process_all_colors(input_dir="tb-output", output_dir="tb-output"):
    """Process all color CSV files and generate tiled visualizations."""

    os.makedirs(output_dir, exist_ok=True)

    for color in ["R", "G", "B"]:
        csv_file = os.path.join(input_dir, f"pattern_{color}.csv")

        # Create compact tiled view
        create_tiled_visualization(csv_file, color, output_dir)

        # Create detailed tiled view with cell values
        create_detailed_tiled_visualization(csv_file, color, output_dir)

    print("\nDone! Generated files:")
    print("  - pattern_X_tiled.png (compact view)")
    print("  - pattern_X_tiled_detailed.png (with cell values)")


if __name__ == "__main__":
    process_all_colors()
