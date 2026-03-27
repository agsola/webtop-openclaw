# OpenClaw + Webtop (Docker Compose V2)

Este proyecto despliega un entorno integrado con **Webtop** y **OpenClaw** usando **Docker Compose**, lo que simplifica drásticamente toda la instalación, la configuración y el uso a través de un único archivo declarativo `docker-compose.yml`.

---

## 🚀 Requisitos

- **Docker** y el plugin **Docker Compose** (`docker compose`).
- No es necesario tener instalado nada más a nivel de host.

---

## ⚙️ Estructura del Proyecto

- `docker-compose.yml`: El recetario principal declarativo donde se configuran volúmenes, puertos y variables de entorno.
- `Dockerfile`: Especifica la receta a partir de la imagen base `lscr.io/linuxserver/webtop:latest` (un escritorio gráfico accesible vía navegador), instalando **Openclaw** limpiamente sin onboarding en tiempo de construcción.
- `rootfs/`: Contiene los scripts de inicio del sistema `s6-overlay`. Cuando el contenedor arranca, `s6-overlay` ejecuta los scripts bajo `rootfs/custom-services.d/` permitiéndonos lanzar *Openclaw Gateway* y *Openclaw Node* en background de manera natural.

---

## 🏃‍♂️ Cómo Empezar (Día a Día)

1. **Construir y levantar el entorno**  
   Simplemente ejecuta este comando en la raíz del repositorio:
   ```bash
   docker compose up -d --build
   ```
   > Esto construirá la imagen y ejecutará el contenedor. El parámetro `-d` (detached) lo deja en segundo plano.

2. **Acceder a los paneles web**
   * **Escritorio Web (Webtop):** [http://localhost:3000](http://localhost:3000)
   * **Openclaw Dashboard:** [http://localhost:18789](http://localhost:18789) *(o puerto equivalente si en local tienes algo ocupándolo, puedes cambiarlo en el `docker-compose.yml`)*

3. **Primer acceso (Onboarding de Openclaw)**  
   Si es tu primera vez iniciando el contenedor vacío, debes registrarte o inicializar Openclaw "onboard":
   ```bash
   docker compose exec openclaw-webtop openclaw onboard
   ```
   Sigue las instrucciones en la consola para emparejar tu dispositivo.

4. **Ver estado (Doctor y Logs)**  
   Puedes ver los logs en directo con:  
   ```bash
   docker compose logs -f
   ```  
   Para ver el estado de Openclaw:
   ```bash
   docker compose exec openclaw-webtop openclaw doctor
   ```

5. **Aprobar / Emparejar Dispositivos** 
   * Listar y aprobar **Pairing/DM**:
     ```bash
     docker compose exec openclaw-webtop openclaw pairing list
     # Y para aprobar:
     docker compose exec openclaw-webtop openclaw pairing approve <CÓDIGO>
     ```
   * Listar y aprobar **Devices**:
     ```bash
     docker compose exec openclaw-webtop openclaw devices list
     # Y para aprobar:
     docker compose exec openclaw-webtop openclaw devices approve <REQUEST-ID>
     ```

6. **Parar el contenedor**  
   Cuando ya no lo estés usando:
   ```bash
   docker compose down
   ```
   > Toda tu configuración está a salvo y persistirá en la carpeta `./config/` que se creará localmente.

---

## 💾 Persistencia de Datos y Volúmenes

Gracias al `docker-compose.yml`, todos los ajustes de *Webtop* y todas las claves y tokens correspondientes al directorio *oculto* de Openclaw se guardarán en tú máquina en la carpeta `./config`. Así puedes migrar, borrar la imagen y hacer backup sin miedo a perder nada simplemente copiando esa carpeta.

## 📝 Modificar variables (Opcional)

Si necesitas utilizar algún archivo o montura adicional:
1. Edita el archivo `docker-compose.yml`.
2. Añade más mapeos en el bloque `volumes:` o puertos en `ports:`.
3. Para aplicar los cambios, ejecuta de nuevo: `docker compose up -d`. (Recreará automáticamente el contenedor).
