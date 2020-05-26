{%- from "nginx/map.jinja" import server with context %}
{%- if server.enabled %}

include:
  - nginx.server.users
  - nginx.server.sites

nginx_packages:
  pkg.installed:
  - names: {{ server.pkgs|yaml }}

{%- if server.get('extras', False) %}
nginx_extra_packages:
  pkg.installed:
  - name: nginx-extras
{%- endif %}

/etc/nginx/sites-enabled/default:
  file.absent:
  - require:
    - pkg: nginx_packages

/etc/nginx/sites-available/default:
  file.absent:
  - require:
    - pkg: nginx_packages

/etc/nginx/nginx.conf:
  file.managed:
  - source: salt://nginx/files/nginx.conf
  - template: jinja
  - require:
    - pkg: nginx_packages
  - watch_in:
    - service: nginx_service

{%- if not salt['file.directory_exists']('/etc/ssl/private') %}
/etc/ssl/private:
  file.directory:
  - mode: 0710
  - user: root
  - group: root
  - makedirs: true
  - require:
    - pkg: nginx_packages
{%- else %}
/etc/ssl/private:
  file.directory:
  - require:
    - pkg: nginx_packages
{%- endif %}

{%- if server.stream is defined %}
/etc/nginx/stream.conf:
  file.managed:
  - source: salt://nginx/files/stream.conf
  - template: jinja
  - require:
    - pkg: nginx_packages
  - watch_in:
    - service: nginx_service
{%- endif %}

{%- if server.upstream is defined %}
/etc/nginx/upstream.conf:
  file.managed:
  - source: salt://nginx/files/upstream.conf
  - template: jinja
  - require:
    - pkg: nginx_packages
  - watch_in:
    - service: nginx_service
{%- endif %}

nginx_service:
  service.running:
  - name: {{ server.service }}
  - require:
    - pkg: nginx_packages

nginx_generate_dhparams:
  cmd.run:
  - name: openssl dhparam -out /etc/ssl/dhparams.pem 2048
  - creates: /etc/ssl/dhparams.pem
  - require:
    - pkg: nginx_packages
  - watch_in:
    - service: nginx_service

{%- endif %}
