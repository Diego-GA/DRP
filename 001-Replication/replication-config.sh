#!/bin/bash

# Configuración
# TODO: Usar parametro para ingresar la contrasena
MAESTRO_IP="192.168.100.99"
ESCLAVO_IP="192.168.100.100"
ROOT_PASSWORD="root_password"
REPL_USER="repl"
REPL_PASSWORD="123"
MY_CNF="/etc/my.cnf"

# Detectar la IP del servidor actual
MI_IP=$(hostname -I | awk '{print $1}')

# Función para configurar el Maestro
configurar_maestro() {
    echo "🔵 Configurando el servidor Maestro ($MI_IP)..."
    
    # Editar my.cnf

    #TODO: Revisar la importancia del nombre de la variable server_id o server-id
    sed -i '/log-bin=mysql-bin/d' $MY_CNF
    sed -i '/server-id=/d' $MY_CNF
    sed -i '/\[mysqld\]/a log-bin=mysql-bin\nserver-id=1' $MY_CNF

    # Reiniciar MariaDB
    sudo systemctl restart mariadb

    # Crear usuario de replicación
    mysql -u root -p$ROOT_PASSWORD -e "
    GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '$REPL_USER'@'%' IDENTIFIED BY '$REPL_PASSWORD';
    FLUSH PRIVILEGES;
    "

    # Obtener los datos de log
    MASTER_STATUS=$(mysql -u root -p$ROOT_PASSWORD -e "SHOW MASTER STATUS\G")
    FILE=$(echo "$MASTER_STATUS" | grep 'File:' | awk '{print $2}')
    POSITION=$(echo "$MASTER_STATUS" | grep 'Position:' | awk '{print $2}')
    
    # TODO: El uso de estos archivos
    echo "MASTER_LOG_FILE=$FILE"
    echo "MASTER_LOG_POS=$POSITION"
    
    echo "$FILE $POSITION" > /root/master_status.txt
}

# Función para configurar el Esclavo
configurar_esclavo() {
    echo "🟢 Configurando el servidor Esclavo ($MI_IP)..."

    # Editar my.cnf
    # TODO: Se duplica la sección de mysqld
    sudo tee -a $MY_CNF > /dev/null <<EOF
[mysqld]
server-id=2
EOF

    # Reiniciar MariaDB
    sudo systemctl restart mariadb

    # Obtener datos del Maestro
    MASTER_FILE=$(ssh root@$MAESTRO_IP "cat /root/master_status.txt | awk '{print \$1}'")
    MASTER_POS=$(ssh root@$MAESTRO_IP "cat /root/master_status.txt | awk '{print \$2}'")

    # Configurar el esclavo
    mysql -u root -p$ROOT_PASSWORD -e "
    CHANGE MASTER TO
        MASTER_HOST='$MAESTRO_IP',
        MASTER_USER='$REPL_USER',
        MASTER_PASSWORD='$REPL_PASSWORD',
        MASTER_LOG_FILE='$MASTER_FILE',
        MASTER_LOG_POS=$MASTER_POS;
    START SLAVE;
    "

    # Verificar estado
    mysql -u root -p$ROOT_PASSWORD -e "SHOW SLAVE STATUS\G"
}

# Determinar si es Maestro o Esclavo
if [ "$MI_IP" == "$MAESTRO_IP" ]; then
    configurar_maestro
elif [ "$MI_IP" == "$ESCLAVO_IP" ]; then
    configurar_esclavo
else
    echo "ERROR: La IP de este servidor no coincide con las configuradas."
    exit 1
fi

echo "Configuración finalizada correctamente."
