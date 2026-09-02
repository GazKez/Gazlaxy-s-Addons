# Changelog

## 1.2.0

- Integra `amuleweb-adaptable` como interfaz responsive predeterminada para
  Ingress y dispositivos móviles.
- Permite volver a la interfaz clásica mediante `webui_theme`.
- Empaqueta localmente los recursos de la interfaz para no depender de CDN
  externos durante el uso.
- Corrige rutas y metadatos de viewport para su funcionamiento bajo Ingress.
- Evita que la imagen base muestre las contraseñas EC y web en el registro.
- Documenta el acceso LAN opcional mediante los puertos 4711 y 4712, que siguen
  sin publicarse de forma predeterminada.

## 1.1.0

- Actualiza la base a la imagen estable `ngosang/amule:3.0.1-2`.
- Corrige la instalación de dependencias para la base Debian.
- Integra la interfaz web mediante Home Assistant Ingress.
- Guarda la configuración de aMule en el volumen persistente `/data`.
- Añade directorios `incoming` y `temp` configurables bajo `/media` o `/share`.
- Añade contraseñas obligatorias y opciones completas de permisos, reinicio y
  compartición automática.
- Limita oficialmente la arquitectura a `amd64`.
- Amplía la documentación de instalación, red, persistencia y diagnóstico.

## 1.0.0

- Versión inicial incompleta.
