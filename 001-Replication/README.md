# Configuración de Replicación en MariaDB

Este documento describe el proceso de configuración de replicación en **MariaDB**, asegurando que un servidor esclavo pueda recibir los cambios del servidor maestro.

## 📌 Requisitos Previos

1. **Dos servidores con MariaDB instalado** (`mariadb.service` debe estar activo).
2. **Conectividad entre los servidores** (verifica con `ping` o `telnet`).
3. **Acceso root en ambos servidores**.
4. **El archivo `replication-config` ya existe en la misma ubicación que este README**.

---

## 📌 Paso 1: Copiar y Asignar Permisos al Script de Configuración

Ejecuta los siguientes comandos en ambos servidores:

```bash
sudo cp replication-config /usr/local/bin/
sudo chmod +x /usr/local/bin/replication-config
```

---

## 📌 Paso 2: Ejecutar el Script en el Maestro

En el **servidor maestro**, ejecuta:

```bash
sudo /usr/local/bin/replication-config
```

Este comando:
- Configura `server-id=1` y habilita `log-bin=mysql-bin`.
- Crea el usuario de replicación `repl`.
- Obtiene la información de `SHOW MASTER STATUS` y la guarda en `/root/master_status.txt`.

---

## 📌 Paso 3: Ejecutar el Script en el Esclavo

En el **servidor esclavo**, ejecuta:

```bash
sudo /usr/local/bin/replication-config
```

Este comando:
- Configura `server-id=2`.
- Obtiene los datos de replicación desde el maestro.
- Ejecuta `CHANGE MASTER TO` con la información correcta.
- Inicia la replicación con `START SLAVE`.
- Verifica el estado con `SHOW SLAVE STATUS \G`.

---

## 📌 Paso 4: Verificar la Replicación

En el **servidor esclavo**, ejecuta:

```bash
mysql -u root -p -e "SHOW SLAVE STATUS \G;"
```

✅ **Si la configuración es correcta**, deberías ver:
- `Slave_IO_Running: Yes`
- `Slave_SQL_Running: Yes`

⚠️ **Si hay errores**, revisa los logs con:

```bash
sudo journalctl -u mariadb --no-pager | tail -50
```

---

## 🚀 Conclusión

Después de estos pasos, el servidor esclavo estará sincronizado con el maestro. En caso de falla del maestro, podrás promover el esclavo a maestro manualmente.
