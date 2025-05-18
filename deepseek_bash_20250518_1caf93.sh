#!/bin/bash

echo "Masukkan tanggal kelahiran Anda dalam format angka!"
read tanggal

echo "Masukkan bulan kelahiran Anda dalam format angka!"
read bulan

# Validate input
if [ "$tanggal" -lt 1 ] || [ "$tanggal" -gt 31 ] || [ "$bulan" -lt 1 ] || [ "$bulan" -gt 12 ]; then
    echo "Angka yang Anda masukkan tidak sesuai!"
    exit 1
fi

# Determine zodiac sign
if ( [ "$tanggal" -ge 21 ] && [ "$bulan" -eq 3 ] ) || ( [ "$tanggal" -le 19 ] && [ "$bulan" -eq 4 ] ); then
    echo "Bintang Anda Aries"
elif ( [ "$tanggal" -ge 20 ] && [ "$bulan" -eq 4 ] ) || ( [ "$tanggal" -le 20 ] && [ "$bulan" -eq 5 ] ); then
    echo "Bintang Anda Taurus"
elif ( [ "$tanggal" -ge 21 ] && [ "$bulan" -eq 5 ] ) || ( [ "$tanggal" -le 20 ] && [ "$bulan" -eq 6 ] ); then
    echo "Bintang Anda Gemini"
elif ( [ "$tanggal" -ge 21 ] && [ "$bulan" -eq 6 ] ) || ( [ "$tanggal" -le 22 ] && [ "$bulan" -eq 7 ] ); then
    echo "Bintang Anda Cancer"
elif ( [ "$tanggal" -ge 23 ] && [ "$bulan" -eq 7 ] ) || ( [ "$tanggal" -le 22 ] && [ "$bulan" -eq 8 ] ); then
    echo "Bintang Anda Leo"
elif ( [ "$tanggal" -ge 23 ] && [ "$bulan" -eq 8 ] ) || ( [ "$tanggal" -le 22 ] && [ "$bulan" -eq 9 ] ); then
    echo "Bintang Anda Virgo"
elif ( [ "$tanggal" -ge 23 ] && [ "$bulan" -eq 9 ] ) || ( [ "$tanggal" -le 22 ] && [ "$bulan" -eq 10 ] ); then
    echo "Bintang Anda Libra"
elif ( [ "$tanggal" -ge 23 ] && [ "$bulan" -eq 10 ] ) || ( [ "$tanggal" -le 21 ] && [ "$bulan" -eq 11 ] ); then
    echo "Bintang Anda Scorpio"
elif ( [ "$tanggal" -ge 22 ] && [ "$bulan" -eq 11 ] ) || ( [ "$tanggal" -le 21 ] && [ "$bulan" -eq 12 ] ); then
    echo "Bintang Anda Sagittarius"
elif ( [ "$tanggal" -ge 22 ] && [ "$bulan" -eq 12 ] ) || ( [ "$tanggal" -le 19 ] && [ "$bulan" -eq 1 ] ); then
    echo "Bintang Anda Capricorn"
elif ( [ "$tanggal" -ge 20 ] && [ "$bulan" -eq 1 ] ) || ( [ "$tanggal" -le 18 ] && [ "$bulan" -eq 2 ] ); then
    echo "Bintang Anda Aquarius"
elif ( [ "$tanggal" -ge 19 ] && [ "$bulan" -eq 2 ] ) || ( [ "$tanggal" -le 20 ] && [ "$bulan" -eq 3 ] ); then
    echo "Bintang Anda Pisces"
else
    echo "Tanggal dan bulan tidak valid untuk menentukan zodiak."
fi