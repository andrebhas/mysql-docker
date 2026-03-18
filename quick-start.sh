#!/bin/bash

# Quick Start Script untuk MySQL Official
# Script ini akan menjalankan semua langkah dengan satu perintah

echo "🚀 MySQL Official Quick Start"
echo "================================"

# Beri executable permission pada script
chmod +x start.sh

# Jalankan start script
./start.sh

# Jika berhasil, buka MySQL CLI
if [ $? -eq 0 ]; then
    echo ""
    echo "💡 Ingin langsung masuk MySQL? (y/n)"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        make mysql
    fi
fi
