s|href="/stat/img/|href="stat/img/|g
s|href="/statplugin"|href="statplugin"|g
s|href="/stat"|href="stat"|g
s|fetch('/stat/|fetch('stat/|g
s|fetch('/statplugin|fetch('statplugin|g
s|fetch(`/statplugin|fetch(`statplugin|g
s|href="/${handler}"|href="${handler}"|g
s|'/stat/img/shesterenka.png'|'stat/img/shesterenka.png'|g
s|"/stat/img/shesterenka.png"|"stat/img/shesterenka.png"|g
s|window.location.origin + '/' + handler|new URL(handler, window.location.href).href|g
