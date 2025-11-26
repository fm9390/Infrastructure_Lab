external_url 'http://gitlab.homelab.lan'

gitlab_rails['time_zone'] = 'Europe/Berlin'

### Unbenutzte Features deaktivieren

# Monitoring
prometheus_monitoring['enable'] = false
gitlab_exporter['enable'] = false
node_exporter['enable'] = false
redis_exporter['enable'] = false
postgres_exporter['enable'] = false
alertmanager['enable'] = false

# Andere Dienste, falls du sie nicht brauchst
gitlab_pages['enable'] = false
registry['enable'] = false
mattermost_external_url nil

### Web (Puma) kleiner drehen
# (Namen je nach Version checken, bei neueren Releases ist Puma Standard)
puma['worker_processes'] = 1
puma['min_threads']      = 1
puma['max_threads']      = 4

### Sidekiq begrenzen
# je nach Version:
sidekiq['max_concurrency'] = 5
# oder:
# sidekiq['concurrency'] = 5

### PostgreSQL etwas konservativer
postgresql['shared_buffers'] = '256MB'

# Let’s Encrypt komplett abschalten (wichtig für .lan / Homelab)
letsencrypt['enable'] = false
letsencrypt['auto_renew'] = false
nginx['listen_port'] = 80
nginx['listen_https'] = false