# Backup Automation

Este script configura y automatiza la creación de backups de todas las bases de datos en un servidor MariaDB/MySQL y programa su ejecución mediante cron.

## Instalación y Configuración

1. Copiar el archivo `backup-config.sh` en el servidor.
2. Asignar permisos de ejecución:
   ```bash
   chmod +x backup-config.sh
   ```
3. Ejecutar el script para configurar los backups:
   ```bash
   ./backup-config.sh --interval "0 3 * * *"
   ```
   Donde `"0 3 * * *"` significa que el backup se ejecutará todos los días a las 3 AM. Puedes modificar este valor según tus necesidades.

## Parámetros

- `--interval "CRON_EXPR"` : Expresión cron para definir la frecuencia del backup.
- `--backup-dir /ruta/a/backup` : Directorio donde se guardarán los backups.
- `--retention DAYS` : Número de días que se conservarán los backups antes de ser eliminados automáticamente.

## Ejemplo de Uso

```bash
./backup-config.sh --interval "0 3 * * *" --backup-dir /var/backups --retention 7
```

## Estrategia de Backups

Para garantizar la seguridad de los datos, el script puede configurarse en ambos servidores (Maestro y Esclavo), permitiendo redundancia en caso de fallos.

1. **Backup en el servidor Maestro**: Se ejecuta de manera programada con cron y se almacena localmente.
2. **Backup en el servidor Esclavo**: Se replica la misma configuración en el esclavo, asegurando que haya una copia en caso de fallo del maestro. Pero configurar el destino de los backups generados en el esclavo, podría ser una instancia completamente independiente sin nigun servicio
3. **Sincronización entre servidores**: Se puede configurar `rsync` o `scp` para transferir los backups de un servidor a otro automáticamente.

## Restauración de Backups

Para restaurar un backup, usa el siguiente comando:

```bash
mysql -u root -p < /ruta/al/backup.sql