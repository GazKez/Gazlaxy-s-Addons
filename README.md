# Gazlaxy's Home Assistant Add-ons

Repositorio de add-ons mantenidos por GazKez para instalaciones de Home
Assistant OS y Home Assistant Supervised.

[![Añadir repositorio a Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FGazKez%2FGazlaxy-s-Addons)

## Instalación

1. Abre **Ajustes > Complementos > Tienda de complementos**.
2. En el menú superior derecho, selecciona **Repositorios**.
3. Añade `https://github.com/GazKez/Gazlaxy-s-Addons`.
4. Selecciona el add-on que quieras instalar y revisa su documentación.

También puedes utilizar el botón anterior para abrir directamente el diálogo
de Home Assistant.

## Add-ons disponibles

### [aMule](./amule)

Cliente eD2k/Kad basado en aMule 3.0, con interfaz web integrada mediante
Home Assistant Ingress, persistencia y directorios de descarga configurables.

![Arquitectura amd64 compatible][amd64-shield]

- [Documentación](./amule/DOCS.md)
- [Registro de cambios](./amule/CHANGELOG.md)
- Base: [`ngosang/docker-amule`](https://github.com/ngosang/docker-amule)

### [Gazlaxy AceServe](./aceserve)

AceStream Engine con HTTPAceProxy e interfaz de estadísticas integrada mediante
Home Assistant Ingress.

![Arquitectura amd64 compatible][amd64-shield]

## Compatibilidad

Los add-ons publicados actualmente son compatibles con sistemas `amd64`.
Necesitan una instalación de Home Assistant que disponga de Supervisor y tienda
de add-ons.

## Incidencias y contribuciones

Utiliza [GitHub Issues](https://github.com/GazKez/Gazlaxy-s-Addons/issues) para
informar de errores o proponer mejoras. Incluye la versión del add-on, la versión
de Home Assistant y los registros relevantes, eliminando antes contraseñas y
otros datos privados.

## Licencia

El contenido propio de este repositorio se distribuye bajo la licencia incluida
en [LICENSE](./LICENSE). Cada aplicación empaquetada conserva su licencia y sus
condiciones originales.

[amd64-shield]: https://img.shields.io/badge/amd64-compatible-green.svg
