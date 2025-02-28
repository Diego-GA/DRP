#!/bin/bash

# TODO: mejorar el manejo de la contrasena
BACKUP_DIR="/var/backups/mysql"
REMOTE_SERVER="192.168.100.100"  # Cambiar por la IP del otro servidor
REMOTE_BACKUP_DIR="/var/backups/mysql"
MYSQL_USER="root"
MYSQL_PASSWORD="root_password"
BACKUP_RETENTION_DAYS=7  

CRON_SCHEDULE="$1"

if [ -z "$CRON_SCHEDULE" ]; then
    echo "ERROR: Debes proporcionar un horario para el cron (ejemplo: \"0 2 * * *\")"
    exit 1
fi

mkdir -p $BACKUP_DIR

# Generar el script de backup
cat <<EOF > /usr/local/bin/mysql_backup.sh
#!/bin/bash
BACKUP_FILE="\$BACKUP_DIR/\$(date +"%Y-%m-%d_%H-%M-%S").sql.gz"
echo "Iniciando backup: \$BACKUP_FILE"
mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD --all-databases | gzip > \$BACKUP_FILE
echo "Backup completado: \$BACKUP_FILE"

# Enviar backup al otro servidor
scp \$BACKUP_FILE root@$REMOTE_SERVER:$REMOTE_BACKUP_DIR/

# Eliminar backups antiguos
find $BACKUP_DIR -type f -mtime +$BACKUP_RETENTION_DAYS -delete
echo "Backups antiguos eliminados"
EOF

chmod +x /usr/local/bin/mysql_backup.sh

# Agregar tarea al cron
(crontab -l 2>/dev/null; echo "$CRON_SCHEDULE /usr/local/bin/mysql_backup.sh") | crontab -

echo "✅ Configuración de backups completada. Tarea programada: $CRON_SCHEDULE"
