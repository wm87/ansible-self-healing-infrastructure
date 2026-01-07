#!bin/bash

set -e

cat >>"$PROJECT_MT/roles/prometheus/vars/main.yml" <<EOL
# MySQL Defaults
mysql_root_password: "hugo"
mysql_exporter_password: "changeme"
EOL

cat >>"$PROJECT_MT/roles/prometheus/tasks/main.yml" <<'EOL'
# ---------------------
# MySQL Exporter
# ---------------------

- name: Stop mysqld exporter if installed
  ansible.builtin.systemd:
    name: "{{ item }}"
    state: stopped
  loop:
    - mysqld_exporter
  when: ansible_facts.services[item] is defined


- name: Remove mysqld service file
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - /etc/systemd/system/mysqld_exporter.service

- name: Reload systemd
  command: systemctl daemon-reexec

- name: Install mysql-client
  apt:
    name:
      - mysql-client
    state: present
    update_cache: yes

- name: Install PyMySQL for Ansible
  apt:
    name: python3-pymysql
    state: present
    update_cache: yes

- name: Download MySQL Exporter (v0.18.0)
  get_url:
    url: "https://github.com/prometheus/mysqld_exporter/releases/download/v0.18.0/mysqld_exporter-0.18.0.linux-amd64.tar.gz"
    dest: /tmp/mysqld_exporter.tar.gz

- name: Extract MySQL Exporter
  unarchive:
    src: /tmp/mysqld_exporter.tar.gz
    dest: /usr/local/bin/
    remote_src: yes
    extra_opts: [--strip-components=1]

- name: Ensure mysqld_exporter user exists (CLI fallback)
  ansible.builtin.shell: |
    mysql -u root -p'{{ mysql_root_password }}' <<SQL
    CREATE USER IF NOT EXISTS 'mysqld_exporter'@'localhost'
        IDENTIFIED WITH mysql_native_password BY '{{ mysql_exporter_password }}';
    GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'mysqld_exporter'@'localhost';
    GRANT SELECT ON performance_schema.* TO 'mysqld_exporter'@'localhost';
    FLUSH PRIVILEGES;
    SQL
  args:
    executable: /bin/bash
  no_log: true

- name: Create mysqld_exporter config
  copy:
    dest: /etc/mysql/mysqld_exporter.cnf
    owner: prometheus
    group: prometheus
    mode: '0600'
    content: |
      [client]
      user=mysqld_exporter
      password={{ mysql_exporter_password }}
      host=localhost

- name: Create MySQL Exporter systemd service
  copy:
    dest: /etc/systemd/system/mysqld_exporter.service
    content: |
      [Unit]
      Description=Prometheus MySQL Exporter
      After=network.target mysql.service

      [Service]
      User=prometheus
      Group=prometheus
      ExecStart=/usr/local/bin/mysqld_exporter --config.my-cnf=/etc/mysql/mysqld_exporter.cnf
      Restart=always

      [Install]
      WantedBy=multi-user.target

- name: Reload systemd
  systemd:
    daemon_reload: yes

- name: Enable and start MySQL Exporter
  systemd:
    name: mysqld_exporter
    enabled: yes
    state: started

EOL
