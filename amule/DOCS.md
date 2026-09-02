# aMule para Home Assistant

Este add-on ejecuta `amuled` y `amuleweb` usando la imagen estable
[`ngosang/amule:3.0.1-2`](https://github.com/ngosang/docker-amule). La interfaz
web se publica mediante Ingress y puede abrirse desde el panel lateral de Home
Assistant sin exponer su puerto a la red local. El diseño responsive incluido
está adaptado para el panel estrecho y para teléfonos móviles.

## Instalación

1. Añade el repositorio `https://github.com/GazKez/Gazlaxy-s-Addons` a la
   tienda de add-ons de Home Assistant.
2. Selecciona **aMule** y pulsa **Instalar**.
3. Abre la pestaña **Configuración** y establece `gui_pwd` y `webui_pwd`.
4. Mantén `webui_theme` en `responsive` o elige `default` si prefieres el
   diseño clásico de aMule.
5. Revisa las rutas `incoming_dir` y `temp_dir`.
6. Guarda la configuración e inicia el add-on.
7. Activa **Mostrar en la barra lateral** y abre aMule desde Home Assistant.

La primera puesta en marcha puede tardar mientras aMule crea su configuración,
descarga la lista de servidores e inicializa Kad. Consulta el registro del
add-on antes de asumir que la interfaz web ha fallado.

## Opciones

### `gui_pwd`

Contraseña de External Connections (EC). La utilizan `amuleweb`, `amulegui` y
`amulecmd` para comunicarse con `amuled`. Es obligatoria y no debe coincidir con
una contraseña importante utilizada en otros servicios.

### `webui_pwd`

Contraseña para iniciar sesión en la interfaz web. Es obligatoria aunque la
interfaz se abra mediante Ingress, porque aMule mantiene su propia sesión.

Las contraseñas configuradas no se muestran en el registro del add-on. Si
publicas los puertos 4711 o 4712, utiliza valores largos y exclusivos para este
servicio.

### `webui_theme`

Selecciona el diseño de `amuleweb`:

- `responsive` (predeterminado): interfaz adaptada a móvil e Ingress.
- `default`: interfaz clásica incluida por el proyecto aMule.

El cambio se aplica al reiniciar el add-on. El tema responsive está incluido en
la imagen y no necesita descargar recursos desde Internet para renderizarse.

### `incoming_dir`

Directorio donde se guardan las descargas terminadas. Debe estar dentro de
`/media` o `/share`.

Valor predeterminado:

```text
/media/amule/incoming
```

### `temp_dir`

Directorio para archivos incompletos. Debe estar dentro de `/media` o `/share`
y ser diferente de `incoming_dir`.

Valor predeterminado:

```text
/media/amule/temp
```

Es recomendable que `incoming_dir` y `temp_dir` estén en el mismo volumen. Si
pertenecen a sistemas de archivos diferentes, completar una descarga puede
requerir copiar el archivo entero en lugar de moverlo.

### `puid` y `pgid`

UID y GID con los que se ejecuta aMule. Los valores predeterminados son `1000`.
Solo es necesario cambiarlos cuando las rutas elegidas tienen permisos
específicos, especialmente si apuntan a almacenamiento de red.

### `umask`

Máscara aplicada a los archivos nuevos. El valor predeterminado `0002` genera
archivos escribibles por el propietario y su grupo.

### `tz`

Zona horaria en formato de base de datos IANA, por ejemplo `Europe/Madrid`.

### `fix_permissions`

Permite que la imagen ajuste el propietario de los directorios de descarga al
arrancar. Desactívalo para montajes NFS o SMB que rechacen `chown` y configura
en el servidor los permisos correspondientes a `puid` y `pgid`.

### Reinicio automático

- `mod_auto_restart_enabled`: activa el reinicio programado de aMule.
- `mod_auto_restart_cron`: expresión cron. El valor `0 6 * * *` reinicia aMule
  diariamente a las 06:00.

### Compartición automática

- `mod_auto_share_enabled`: activa la actualización automática de carpetas
  compartidas.
- `mod_auto_share_directories`: lista de rutas separadas por punto y coma.

Ejemplo:

```text
/media/amule/incoming;/media/amule/shared
```

Comprueba cuidadosamente qué directorios compartes. No añadas `/media`,
`/share` ni ningún directorio que contenga información privada.

## Red e High ID

La interfaz web usa internamente el puerto TCP 4711, pero no se publica por
defecto porque Home Assistant accede a ella mediante Ingress.

Si quieres abrir la interfaz directamente desde otro equipo de la LAN, asigna
un puerto de host a `4711/tcp` en la pestaña **Red**. Del mismo modo, publica
`4712/tcp` para usar `amulegui` o `amulecmd`. Que estos puertos no estén
redirigidos en el router normalmente evita el acceso desde Internet, pero no
los protege frente a otros dispositivos de la red local ni frente a reglas de
NAT o UPnP añadidas posteriormente. Mantén las contraseñas y no redirijas 4711
hacia Internet.

Para obtener High ID deben llegar desde Internet hasta Home Assistant OS estos
puertos:

| Puerto | Protocolo | Uso |
| --- | --- | --- |
| 4662 | TCP | Conexiones eD2k entre clientes |
| 4665 | UDP | Búsquedas globales eD2k |
| 4672 | UDP | Protocolo extendido y red Kad |

Además de mantenerlos habilitados en la pestaña **Red** del add-on, debes
redirigirlos en el router hacia la dirección IP del equipo con Home Assistant.
No expongas el puerto web 4711 directamente a Internet.

El puerto TCP 4712 está desactivado por defecto. Asígnale un puerto en la
pestaña **Red** solamente si vas a utilizar `amulegui` o `amulecmd` desde otro
equipo. Protégelo siempre con `gui_pwd`.

Después de publicar 4711, la dirección habitual es
`http://IP_DE_HOME_ASSISTANT:4711`. Si eliges otro puerto de host, usa ese valor
en la dirección. Publicar estos puertos no sustituye la redirección de los
puertos eD2k/Kad necesaria para obtener High ID.

## Persistencia y copias de seguridad

La configuración interna de aMule se almacena en `/data/.aMule`. `/data` es el
volumen privado persistente del add-on y forma parte de sus copias de seguridad
de Home Assistant.

Los archivos descargados se guardan en las rutas configuradas bajo `/media` o
`/share`. Esos archivos no deben considerarse incluidos automáticamente en una
copia de seguridad del add-on; protege el almacenamiento por separado.

Para editar manualmente `amule.conf`, detén primero el add-on. aMule mantiene
la configuración en memoria y puede sobrescribir cambios realizados mientras
está funcionando.

## Solución de problemas

### La interfaz web todavía no responde

Revisa el registro. Durante el primer inicio o al compartir muchos archivos,
aMule puede tardar en escanear directorios antes de que `amuleweb` esté listo.

### El diseño responsive presenta algún problema

Cambia temporalmente `webui_theme` a `default`, reinicia el add-on y comunica
la pantalla afectada junto con la versión de Home Assistant y del add-on. El
acceso mediante Ingress y el acceso LAN por 4711 usan el mismo tema elegido.

### El add-on se detiene al arrancar

Comprueba que:

- `gui_pwd` y `webui_pwd` tengan un valor.
- Las rutas comiencen por `/media/` o `/share/`.
- `incoming_dir` y `temp_dir` sean diferentes.
- El usuario configurado mediante `puid` y `pgid` pueda escribir en las rutas.

### Las descargas no sobreviven a un reinicio

Verifica en el registro las rutas efectivas y confirma que pertenecen a
`/media` o `/share`. No utilices rutas internas como `/downloads` en las
opciones del add-on.

### aMule muestra Low ID

Comprueba la redirección TCP/UDP del router y que los puertos configurados en el
router coincidan con los publicados en la pestaña **Red** del add-on.

## Actualizaciones

La versión del contenedor está fijada para evitar que una modificación de la
imagen upstream rompa instalaciones existentes. Las futuras versiones del
add-on actualizarán explícitamente aMule después de validar arranque,
persistencia e Ingress.

## Recursos

- [Proyecto oficial aMule](https://github.com/amule-org/amule)
- [Documentación oficial de aMule](https://amule-org.github.io/docs)
- [Imagen Docker utilizada](https://github.com/ngosang/docker-amule)
- [Tema responsive amuleweb-adaptable](https://github.com/esaracho/amuleweb-adaptable)
- [Incidencias de este repositorio](https://github.com/GazKez/Gazlaxy-s-Addons/issues)

## Uso responsable

Las redes eD2k y Kad pueden distribuir material protegido o malicioso. Revisa
los archivos antes de abrirlos y comparte únicamente contenido autorizado.
