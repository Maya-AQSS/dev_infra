---
layout: page
title: rabbitmq
subtitle: Servicios disponibles
menubar: services_menu
show_sidebar: false
hero_height: is-fullwidth
---

## Rabbit MQ

Agente de mensajes (message broker) de código abierto, distribuido y de alto rendimiento que facilita la comunicación asíncrona entre aplicaciones.

1. Comprobar que en el fichero _.services_ está descomentada la línea con el servicio _rabbitmq_.

2. Ejecutar _./up.sh_ desde la carpeta _odoodock_.

3. Abrir el navegador y acceder a la URL _http://locahost:15672_ que da aceso al panel de administración

4. En la página de login usar como credenciales por defecto:

        Username : admin 
        Password : admin

5. El puerto para la comunicación con las colas es por defecto el 5672 o el configurado en la variable `$RABBITMQ_PORT`

### Creación de colas

La creación de vhost, exchanges, usuarios, permisos, politicas y colas se puede realizar utilzando el fichero `definitions.json`. La forma más seniclla de crearlo es exportarlo desde la propia consoal de gestión de Rabbit 


> IMPORTANTE: el usuario debe tener permisos para crear colas en un _Virtual Host_ específico. No por ser administrador es posible crear colas en un _Virtual Host_ si no se ha espcificado explícitamente.

