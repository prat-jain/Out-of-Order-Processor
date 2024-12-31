#!/bin/bash

rm -r everything_logs
mkdir everything_logs

# start

echo "TC_START - coremark"
make run_vcs_top_tb PROG=../testcode/coremark_im.elf > everything_logs/coremark.log
echo "TC_DONE - coremark"
tail everything_logs/coremark.log
echo "run time"
get_run_time.sh

echo ""
echo "TC_START - coremark spike"
make spike ELF=../testcode/coremark_im.elf > everything_logs/spike_coremark.log
echo "TC_DONE - coremark spike"
check_spike.sh


echo "TC_START - needle"
make run_vcs_top_tb PROG=/home/ppahuja2/ece411ooo/mp_ooo/testcode/needle.elf > everything_logs/needle.log
echo "TC_DONE - needle"
tail everything_logs/needle.log
echo "run time"
get_run_time.sh

echo ""
echo "TC_START - needle spike"
make spike ELF=/home/ppahuja2/ece411ooo/mp_ooo/testcode/needle.elf > everything_logs/spike_needle.log
echo "TC_DONE - needle spike"
check_spike.sh


echo "TC_START - compression"
make run_vcs_top_tb PROG=../testcode/additional_testcases/compression_im.elf > everything_logs/compression.log
echo "TC_DONE - compression"
echo "ipc"
get_ipc.sh
echo "run time"
get_run_time.sh

echo ""
echo "TC_START - compression spike"
make spike ELF=../testcode/additional_testcases/compression_im.elf > everything_logs/spike_compression.log
echo "TC_DONE - compression spike"
check_spike.sh


echo "TC_START - aes"
make run_vcs_top_tb PROG=../testcode/cp3_release_benches/aes_sha_im.elf > everything_logs/aes.log
echo "TC_DONE - aes"
echo "ipc"
get_ipc.sh
echo "run time"
get_run_time.sh

echo ""
echo "TC_START - aes spike"
make spike ELF=../testcode/cp3_release_benches/aes_sha_im.elf > everything_logs/spike_aes.log
echo "TC_DONE - aes spike"
check_spike.sh


echo "TC_START - fft"
make run_vcs_top_tb PROG=../testcode/cp3_release_benches/fft_im.elf > everything_logs/fft.log
echo "TC_DONE - fft"
echo "ipc"
get_ipc.sh
echo "run time"
get_run_time.sh

echo ""
echo "TC_START - fft spike"
make spike ELF=../testcode/cp3_release_benches/fft_im.elf > everything_logs/spike_fft.log
echo "TC_DONE - fft spike"
check_spike.sh


echo "TC_START - mergesort"
make run_vcs_top_tb PROG=../testcode/cp3_release_benches/mergesort_im.elf > everything_logs/mergesort.log
echo "TC_DONE - mergesort"
echo "ipc"
get_ipc.sh
echo "run time"
get_run_time.sh

echo ""
echo "TC_START - mergesort spike"
make spike ELF=../testcode/cp3_release_benches/mergesort_im.elf > everything_logs/spike_mergesort.log
echo "TC_DONE - mergesort spike"
check_spike.sh