#!/usr/bin/env python3
"""
Plot metrics comparison between seL4 and Linux
Usage: ./plot_metrics.py [results_csv] [output_png]
"""

import sys
import csv
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import numpy as np

def read_csv(filename):
    """Read CSV file and return data"""
    iterations = []
    latencies = []
    
    try:
        with open(filename, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                iterations.append(int(row['iteration']))
                latencies.append(float(row['latency_ns']) / 1000.0)  # Convert to microseconds
    except Exception as e:
        print(f"Error reading CSV: {e}", file=sys.stderr)
        return None, None
    
    return iterations, latencies

def plot_metrics(sel4_csv=None, linux_csv=None, output_file='metrics_comparison.png'):
    """Plot metrics comparison"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))
    
    if sel4_csv:
        sel4_iter, sel4_lat = read_csv(sel4_csv)
        if sel4_iter and sel4_lat:
            ax1.plot(sel4_iter, sel4_lat, 'b-o', label='seL4', markersize=4)
            ax1.set_xlabel('Iteration')
            ax1.set_ylabel('Latency (microseconds)')
            ax1.set_title('seL4 IPC Latency')
            ax1.grid(True, alpha=0.3)
            ax1.legend()
            
            # Statistics
            avg = np.mean(sel4_lat)
            min_val = np.min(sel4_lat)
            max_val = np.max(sel4_lat)
            ax1.axhline(avg, color='r', linestyle='--', alpha=0.5, label=f'Avg: {avg:.2f} us')
            ax1.text(0.05, 0.95, f'Avg: {avg:.2f} us\nMin: {min_val:.2f} us\nMax: {max_val:.2f} us',
                    transform=ax1.transAxes, verticalalignment='top',
                    bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    if linux_csv:
        linux_iter, linux_lat = read_csv(linux_csv)
        if linux_iter and linux_lat:
            ax2.plot(linux_iter, linux_lat, 'g-o', label='Linux', markersize=4)
            ax2.set_xlabel('Iteration')
            ax2.set_ylabel('Latency (microseconds)')
            ax2.set_title('Linux IPC Latency')
            ax2.grid(True, alpha=0.3)
            ax2.legend()
            
            # Statistics
            avg = np.mean(linux_lat)
            min_val = np.min(linux_lat)
            max_val = np.max(linux_lat)
            ax2.axhline(avg, color='r', linestyle='--', alpha=0.5, label=f'Avg: {avg:.2f} us')
            ax2.text(0.05, 0.95, f'Avg: {avg:.2f} us\nMin: {min_val:.2f} us\nMax: {max_val:.2f} us',
                    transform=ax2.transAxes, verticalalignment='top',
                    bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    
    plt.tight_layout()
    plt.savefig(output_file, dpi=150)
    print(f"Plot saved to: {output_file}")

if __name__ == '__main__':
    sel4_csv = sys.argv[1] if len(sys.argv) > 1 else None
    linux_csv = sys.argv[2] if len(sys.argv) > 2 else None
    output_file = sys.argv[3] if len(sys.argv) > 3 else 'metrics_comparison.png'
    
    # Fix double slashes in path
    output_file = output_file.replace('//', '/')
    
    plot_metrics(sel4_csv, linux_csv, output_file)

