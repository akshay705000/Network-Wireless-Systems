#!/bin/bash

# Extracting packet sizes and physical data rates from pcap file.
tshark -r Wireshark_802_11.pcap -T fields -e frame.len -e radiotap.datarate > extracted_data.txt

# Creating file and extracting data for packet sizes.
awk '{print $1}' extracted_data.txt | sort -n | uniq -c | awk '{print $2, $1}' > packet_sizes_histogram.txt

# Creating file and extracting data for physical data rates.
awk '{print $2}' extracted_data.txt | sort | uniq -c | awk '{print $2, $1}' > phy_data_rates_histogram.txt

# Plotting histograms.
gnuplot -persist <<- GNU
    set terminal pngcairo
    set output 'packet_sizes_histogram.png'
    set title 'Packet Sizes Histogram'
    set xlabel 'Packet Size (bytes)'
    set ylabel 'Frequency'
    set style fill solid
    plot 'packet_sizes_histogram.txt' using 1:2 with boxes notitle
    
    set output 'phy_data_rates_histogram.png'
    set title 'PHY Data Rates Histogram'
    set xlabel 'PHY Data Rate (Mbps)'
    set ylabel 'Frequency'
    set style fill solid
    plot 'phy_data_rates_histogram.txt' using 1:2 with boxes notitle
GNU

# Cleaning temporary files created
rm extracted_data.txt packet_sizes_histogram.txt phy_data_rates_histogram.txt

