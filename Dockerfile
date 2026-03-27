# Usamos la imagen de Ubuntu XFCE nativamente.
# "latest" utiliza Alpine por defecto, el cual usa 'apk' en lugar de 'apt/dpkg',
# y el instalador de OpenClaw necesita un sistema Ubuntu/Debian para instalar node.js.
FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# Instalamos dependencias base para la imagen, incluyendo herramientas de complilación para brew
RUN apt-get update && apt-get install -y \
    curl inotify-tools netcat-openbsd \
    build-essential procps file git sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Damos permisos a abc para usar sudo sin contraseña, necesario para el instalador de brew
RUN echo "abc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Creamos una carpeta home real para abc si no existe, o cambiamos su propierdades, 
# y evitamos que homebrew intente escribir en /config durante el build (lo cual falla porque es un volumen del host que no se monta durante el build).
RUN mkdir -p /home/abc && chown -R abc:abc /home/abc && usermod -d /home/abc abc

# Instalamos Homebrew bajo el usuario 'abc' (que es el usuario que usa webtop y openclaw internamente)
USER abc
ENV HOME=/home/abc
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Añadimos brew al PATH para el usuario abc temporalmente durante el build
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Volvemos a root para instalar OpenClaw globalmente tal y como requiere el script
USER root

# Restauramos las cosas como le gustan a linuxserver/webtop
# 1. El entorno por defecto HOME en webtop suele ser /config (aunque corra como root en s6)
ENV HOME=/config
# 2. Restauramos el directorio HOME físico de abc
RUN usermod -d /config abc
# 3. Y para openclaw, necesitamos asegurar que sabe lidiar con HOME
RUN curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard

# Copiamos nuestros scripts de arranque personalizados para s6-overlay. (Si el COPY falla por cache de Docker, nos aseguramos abajo)
COPY rootfs/ /

# Damos permisos estrictos de ejecución y creamos los scripts directamente para evitar 
# fallos de sincronización de volúmenes o contexto en macOS con s6-overlay.
RUN mkdir -p /custom-cont-init.d /custom-services.d && \
    printf '#!/command/with-contenv bash\n\necho "[openclaw-gateway] Iniciando Gateway..."\nchown -R abc:abc /config/.openclaw 2>/dev/null || true\nexec s6-setuidgid abc bash -l -c '"'"'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; openclaw gateway run --allow-unconfigured'"'"'\n' > /custom-services.d/openclaw-gateway && \
    printf '#!/command/with-contenv bash\n\necho "[openclaw-node] Esperando 5 segundos a que el gateway inicie..."\nsleep 5\n\necho "[openclaw-node] Iniciando Nodo..."\nexec s6-setuidgid abc bash -l -c '"'"'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; openclaw node run'"'"'\n' > /custom-services.d/openclaw-node && \
    chmod -R +x /custom-cont-init.d && \
    chmod -R +x /custom-services.d
