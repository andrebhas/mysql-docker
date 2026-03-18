#!/bin/bash

# MySQL Official Docker - Startup Script

set -e

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         MySQL Official Docker - Startup Script             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Fungsi untuk mengecek apakah Docker berjalan
check_docker() {
    echo -e "${BLUE}🔍 Memeriksa Docker...${NC}"
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker tidak berjalan. Mohon jalankan Docker terlebih dahulu.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker berjalan dengan baik${NC}"
}

# Fungsi untuk mengecek file .env
check_env() {
    echo -e "${BLUE}🔍 Memeriksa file .env...${NC}"
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  File .env tidak ditemukan. Membuat dari template...${NC}"
        cat > .env << 'EOF'
# MySQL Official Configuration
MYSQL_ROOT_PASSWORD=root_password_123
MYSQL_DATABASE=myapp_db
MYSQL_USER=myapp_user
MYSQL_PASSWORD=myapp_password_123
CONTAINER_NAME=mysql-official
MYSQL_PORT=3306
MYSQL_VERSION=8.0
MYSQL_DATA_PATH=./mysql_data
MYSQL_CONF_PATH=./mysql_conf
TZ=Asia/Jakarta
EOF
        echo -e "${GREEN}✓ File .env default dibuat${NC}"
        echo -e "${YELLOW}⚠️  Silakan edit file .env untuk mengatur password${NC}"
        echo -e "${YELLOW}   Kemudian jalankan script ini lagi${NC}"
        exit 0
    fi
    echo -e "${GREEN}✓ File .env ditemukan${NC}"
}

# Fungsi untuk membuat direktori yang diperlukan
create_directories() {
    echo -e "${BLUE}🔍 Memeriksa direktori yang diperlukan...${NC}"
    
    mkdir -p mysql_data mysql_conf init-scripts backups exports
    
    # Buat file my.cnf default jika belum ada
    if [ ! -f mysql_conf/my.cnf ]; then
        cat > mysql_conf/my.cnf << 'EOF'
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-authentication-plugin=mysql_native_password

[client]
default-character-set=utf8mb4
EOF
        echo -e "${GREEN}✓ Konfigurasi default dibuat di mysql_conf/my.cnf${NC}"
    fi
    
    echo -e "${GREEN}✓ Direktori dibuat/divalidasi${NC}"
}

# Fungsi untuk mengecek apakah container sudah berjalan
check_container() {
    echo -e "${BLUE}🔍 Memeriksa container MySQL...${NC}"
    
    source .env 2>/dev/null || true
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME:-mysql-official}$"; then
        echo -e "${YELLOW}⚠️  Container MySQL sudah berjalan.${NC}"
        docker ps --filter "name=${CONTAINER_NAME:-mysql-official}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo -e "${YELLOW}Apakah Anda ingin me-restart container? (y/n)${NC}"
        read -r restart
        if [[ "$restart" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Merestart container...${NC}"
            docker compose restart
        else
            echo -e "${GREEN}Menggunakan container yang sudah berjalan.${NC}"
        fi
        return 0
    else
        echo -e "${GREEN}✓ Container siap dijalankan${NC}"
        return 1
    fi
}

# Fungsi untuk menjalankan container
start_container() {
    echo -e "${BLUE}🚀 Menjalankan MySQL Official container...${NC}"
    
    # Load environment variables
    source .env 2>/dev/null || true
    
    # Jalankan dengan docker compose
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Container berhasil dijalankan${NC}"
    else
        echo -e "${RED}❌ Gagal menjalankan container${NC}"
        exit 1
    fi
}

# Fungsi untuk menunggu MySQL siap
wait_for_mysql() {
    echo -e "${BLUE}⏳ Menunggu MySQL siap (mungkin perlu 30-60 detik)...${NC}"
    
    # Load environment variables
    source .env 2>/dev/null || true
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec ${CONTAINER_NAME:-mysql-official} mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD} --silent > /dev/null 2>&1; then
            echo -e "${GREEN}✓ MySQL siap digunakan!${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ MySQL tidak merespons dalam waktu yang diharapkan${NC}"
    echo -e "${YELLOW}⚠️  Cek logs dengan: make logs atau docker compose logs${NC}"
    return 1
}

# Fungsi untuk menampilkan informasi koneksi
show_connection_info() {
    # Load environment variables
    source .env 2>/dev/null || true
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ MySQL Official berhasil dijalankan!${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📊 INFORMASI KONEKSI:${NC}"
    echo -e "  ${BLUE}Host:${NC} localhost"
    echo -e "  ${BLUE}Port:${NC} ${MYSQL_PORT:-3306}"
    echo -e "  ${BLUE}Container:${NC} ${CONTAINER_NAME:-mysql-official}"
    echo -e "  ${BLUE}MySQL Version:${NC} ${MYSQL_VERSION:-8.0}"
    echo ""
    echo -e "${YELLOW}🔑 KREDENSIAL:${NC}"
    echo -e "  ${BLUE}Root User:${NC} root"
    echo -e "  ${BLUE}Root Password:${NC} ${MYSQL_ROOT_PASSWORD}"
    echo -e "  ${BLUE}Database:${NC} ${MYSQL_DATABASE:-myapp_db}"
    echo -e "  ${BLUE}Application User:${NC} ${MYSQL_USER:-myapp_user}"
    echo -e "  ${BLUE}Application Password:${NC} ${MYSQL_PASSWORD}"
    echo ""
    echo -e "${YELLOW}📋 PERINTAH YANG TERSEDIA:${NC}"
    echo -e "  ${GREEN}make mysql${NC}        - Masuk MySQL sebagai root"
    echo -e "  ${GREEN}make mysql-user${NC}   - Masuk MySQL sebagai user aplikasi"
    echo -e "  ${GREEN}make logs${NC}         - Lihat log MySQL"
    echo -e "  ${GREEN}make backup${NC}       - Backup database"
    echo -e "  ${GREEN}make help${NC}         - Lihat semua perintah"
    echo ""
    echo -e "${YELLOW}🌐 AKSES DARI APLIKASI LAIN:${NC}"
    echo -e "   JDBC URL: jdbc:mysql://localhost:${MYSQL_PORT:-3306}/${MYSQL_DATABASE:-myapp_db}?useSSL=false&serverTimezone=Asia/Jakarta"
    echo -e "   PHP PDO:  mysql:host=localhost;port=${MYSQL_PORT:-3306};dbname=${MYSQL_DATABASE:-myapp_db};charset=utf8mb4"
    echo -e "   Python:   mysql+pymysql://${MYSQL_USER:-myapp_user}:${MYSQL_PASSWORD}@localhost:${MYSQL_PORT:-3306}/${MYSQL_DATABASE:-myapp_db}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}📁 Data tersimpan di: ./mysql_data/${NC}"
    echo -e "${BLUE}📁 Konfigurasi di: ./mysql_conf/my.cnf${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
}

# Fungsi untuk inisialisasi database sample (opsional)
init_sample_data() {
    echo ""
    echo -e "${YELLOW}Apakah Anda ingin menginisialisasi dengan data sample? (y/n)${NC}"
    read -r init_sample
    
    if [[ "$init_sample" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Membuat sample data...${NC}"
        make init
        echo -e "${GREEN}✓ Sample data siap${NC}"
        echo -e "${BLUE}Merestart container untuk menginisialisasi...${NC}"
        docker compose restart
        sleep 5
    fi
}

# Main execution
main() {
    check_docker
    check_env
    create_directories
    
    if ! check_container; then
        start_container
    fi
    
    wait_for_mysql
    show_connection_info
    init_sample_data
    
    echo ""
    echo -e "${GREEN}🎉 MySQL Official siap digunakan! Selamat bekerja!${NC}"
}

# Jalankan main function
main
