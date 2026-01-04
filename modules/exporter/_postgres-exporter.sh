#!bin/bash

set -e

cat >>"$PROJECT/roles/prometheus/tasks/main.yml" <<'EOL'
# ---------------------
# PostgreSQL Exporter
# ---------------------

- name: Stop Prometheus and node exporter if installed
  ansible.builtin.systemd:
    name: "{{ item }}"
    state: stopped
  loop:
    - postgres_exporter
  when: ansible_facts.services[item] is defined

- name: Reload systemd
  command: systemctl daemon-reexec

- name: Install PostgreSQL client for exporter
  apt:
    name: postgresql-client
    state: present
    update_cache: yes

- name: Install psycopg2 Python dependency
  apt:
    name: python3-psycopg2
    state: present

- name: Set PostgreSQL exporter password
  set_fact:
    postgres_exporter_password: "changeme"

- name: Ensure PostgreSQL exporter user exists
  community.postgresql.postgresql_user:
    name: postgres_exporter
    password: "{{ postgres_exporter_password }}"
    role_attr_flags: NOINHERIT
    state: present
    login_user: postgres

- name: Grant CONNECT privilege to exporter on postgres database
  community.postgresql.postgresql_privs:
    database: postgres
    role: postgres_exporter
    type: database
    privs: CONNECT
    objs: postgres

- name: Grant USAGE on public schema
  community.postgresql.postgresql_privs:
    database: postgres
    role: postgres_exporter
    type: schema
    privs: USAGE
    objs: public

- name: Grant SELECT on all tables in public schema
  community.postgresql.postgresql_privs:
    type: table
    database: postgres
    role: postgres_exporter
    privs: SELECT
    objs: ALL_IN_SCHEMA
    schema: public
    login_user: postgres
    state: present

- name: Grant pg_monitor to postgres_exporter
  community.postgresql.postgresql_query:
    query: "GRANT pg_monitor TO postgres_exporter;"
    login_user: postgres

- name: Create .pgpass file for postgres_exporter
  copy:
    dest: /etc/postgresql_exporter.pgpass
    owner: prometheus
    group: prometheus
    mode: '0600'
    content: |
      localhost:5432:postgres:postgres_exporter:{{ postgres_exporter_password }}

- name: Download PostgreSQL Exporter
  get_url:
    url: "https://github.com/prometheus-community/postgres_exporter/releases/download/v0.18.1/postgres_exporter-0.18.1.linux-amd64.tar.gz"
    dest: /tmp/postgres_exporter.tar.gz

- name: Extract PostgreSQL Exporter
  unarchive:
    src: /tmp/postgres_exporter.tar.gz
    dest: /usr/local/bin/
    remote_src: yes
    extra_opts: [--strip-components=1]

- name: Create PostgreSQL Exporter systemd service
  copy:
    dest: /etc/systemd/system/postgres_exporter.service
    content: |
      [Unit]
      Description=Prometheus PostgreSQL Exporter
      After=network.target postgresql.service

      [Service]
      User=prometheus
      Group=prometheus
      Environment="DATA_SOURCE_NAME=postgresql://postgres_exporter:changeme@localhost:5432/postgres?sslmode=disable"
      ExecStart=/usr/local/bin/postgres_exporter --no-collector.wal
      Restart=always

      [Install]
      WantedBy=multi-user.target

- name: Reload systemd
  systemd:
    daemon_reload: yes

- name: Enable and start PostgreSQL Exporter
  systemd:
    name: postgres_exporter
    enabled: yes
    state: started

EOL
