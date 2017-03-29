include:
  - suse_manager_server.repos
  - suse_manager_server.firewall
  - suse_manager_server.postgres
  - suse_manager_server.pgpool
  - suse_manager_server.tomcat
  - suse_manager_server.taskomatic
  - suse_manager_server.rhn
  - suse_manager_server.iss
  - suse_manager_server.testsuite

{% if '2.1' in grains['version'] %}
# remove SLES product release package, it's replaced by SUSE Manager's
sles_release_fix:
  pkg.removed:
    - name: sles-release
    - require:
      - sls: suse_manager_server.repos
{% endif %}

suse_manager_packages:
  pkg.latest:
    {% if 'head' in grains['version'] %}
    - fromrepo: Devel_Galaxy_Manager_Head
    - name: patterns-suma_server
    {% elif '3-stable' in grains['version'] %}
    - fromrepo: SUSE-Manager-3.0-x86_64-Pool
    - name: patterns-suma_server
    {% elif '3-nightly' in grains['version'] %}
    - fromrepo: Devel_Galaxy_Manager_3.0
    - name: patterns-suma_server
    {% elif '3.1-stable' in grains['version'] %}
    - fromrepo: SUSE-Manager-3.1-x86_64-Pool
    - name: patterns-suma_server
    {% else %}
    - pkgs:
      - cyrus-sasl-digestmd5
      - perl-TimeDate
      - sm-network-discovery-client
      - smdba
      - spacecmd
      - spacewalk-reports
      - suse-manager-server-release
      - susemanager
      - susemanager-client-config_en-pdf
      - susemanager-install_en-pdf
      - susemanager-manuals_en
      - susemanager-proxy-quick_en-pdf
      - susemanager-reference_en-pdf
      - susemanager-tftpsync
      - susemanager-user_en-pdf
      - timezone
      {% if grains['database'] == 'oracle' %}
      - bc
      - oracle-server
      - spacewalk-oracle
      - susemanager-branding-non-oss
      {% else %}
      - spacewalk-postgresql
      - susemanager-branding-oss
      {% endif %}
    {% endif %}
    - require:
      - sls: suse_manager_server.repos
      - sls: suse_manager_server.firewall

environment_setup_script:
  file.managed:
    - name: /root/setup_env.sh
    - source: salt://suse_manager_server/setup_env.sh
    - template: jinja

suse_manager_setup:
  cmd.run:
    - name: /usr/lib/susemanager/bin/migration.sh -l /var/log/susemanager_setup.log -s
    - creates: /root/.MANAGER_SETUP_COMPLETE
    - require:
      - pkg: suse_manager_packages
      - file: environment_setup_script
      {% if grains['database'] == 'pgpool' %}
      - sls: suse_manager_server.pgpool
      {% endif %}

ca_cert_checksum:
  cmd.run:
    - name: sha512sum /srv/www/htdocs/pub/RHN-ORG-TRUSTED-SSL-CERT > /srv/www/htdocs/pub/RHN-ORG-TRUSTED-SSL-CERT.sha512
    - creates: /srv/www/htdocs/pub/RHN-ORG-TRUSTED-SSL-CERT.sha512
    - require:
      - cmd: suse_manager_setup

no_motd:
  file.absent:
    - name: /etc/motd
    - require:
      - cmd: suse_manager_setup