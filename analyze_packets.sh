#!/bin/bash

# pcap file name
PCAP_FILE="Wireshark_802_11.pcap"

# creating output file names.
PACKET_SIZE_OUTPUT="packet_size_output.txt"
PHY_DATA_RATE_OUTPUT="phy_data_rate_output.txt"
RSSI_OUTPUT="rssi_output.txt"
PACKET_RATE_OUTPUT="packet_rate_output.txt"
TEMP_OUTPUT="temp_output.txt"

# Extracting packet size, physical data rate, RSSI, and packet rate data.
tshark -r $PCAP_FILE -T fields -e frame.time_epoch -e frame.len -e wlan_radio.data_rate -e wlan_radio.signal_dbm > $TEMP_OUTPUT

# Calculating packet rate (pkts/sec) for each 1-minute interval
awk -v time_int=60 '
    {
        itr = int($1)
        pkt_count[itr]++
    }
    END {
        for (time in pkt_count) {
            printf "%.2f %d\n", time, pkt_count[time] / time_int
        }
    }
' $TEMP_OUTPUT > $PACKET_RATE_OUTPUT

# Calculating average packet size, PHY data rate, and RSSI for each 1-minute interval
awk -v time_resolution=60 '
    {
        epoch = int($1)
        packet_sizes[epoch] += $2
        data_rates[epoch] += $3
        rssis[epoch] += $4
        counts[epoch]++
    }
    END {
        for (time in packet_sizes) {
            printf "%.2f %.2f %.2f %.2f\n", time, packet_sizes[time] / counts[time], data_rates[time] / counts[time], rssis[time] / counts[time]
        }
    }
' $TEMP_OUTPUT > $PACKET_SIZE_OUTPUT

# Plotting graphs using GNU Plot
gnuplot <<- EOF
    # Packet size vs Time plot
    set terminal pngcairo enhanced font 'Verdana,10'
    set output 'packet_size_vs_time.png'
    set title 'Average Packet Size vs Time'
    set xlabel 'Time (Epoch)'
    set ylabel 'Average Packet Size'
    set xtics rotate by -45
    plot '$PACKET_SIZE_OUTPUT' using 1:2 smooth unique with lines title 'Avg Packet Size'

    # PHY data rate vs Time plot
    set output 'phy_data_rate_vs_time.png'
    set title 'Average PHY Data Rate vs Time'
    set ylabel 'Average PHY Data Rate'
    set xtics rotate by -45
    plot '$PACKET_SIZE_OUTPUT' using 1:3 smooth unique with lines title 'Avg PHY Data Rate'

    # RSSI vs Time plot
    set output 'rssi_vs_time.png'
    set title 'Average RSSI vs Time'
    set ylabel 'Average RSSI (dBm)'
    set xtics rotate by -45
    plot '$PACKET_SIZE_OUTPUT' using 1:4 smooth unique with lines title 'Avg RSSI'

    # Packet rate vs Time plot
    set output 'packet_rate_vs_time.png'
    set title 'Packet Rate vs Time'
    set ylabel 'Packet Rate (pkts/sec)'
    set xtics rotate by -45
    plot '$PACKET_RATE_OUTPUT' using 1:2 smooth unique with lines title 'Packet Rate'
EOF

# Cleaning temporary files
rm $TEMP_OUTPUT

