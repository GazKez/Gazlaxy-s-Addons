# Changelog

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
