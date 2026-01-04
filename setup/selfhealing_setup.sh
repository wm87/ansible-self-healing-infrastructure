#!/bin/bash
set -e

# Basisverzeichnisse
BASE_DIR=${PWD}/selfhealing

mkdir -p $BASE_DIR/roles/services/{tasks,defaults,vars}
mkdir -p $BASE_DIR/roles/selfheal_preflight/{tasks,defaults,vars,templates}
mkdir -p $BASE_DIR/roles/selfheal_state_machine/{tasks,states,defaults}
mkdir -p $BASE_DIR/playbooks
mkdir -p $BASE_DIR/inventory

# ansible.cfg
cat >"$BASE_DIR/ansible.cfg" <<EOL
[defaults]
inventory = inventory/hosts.ini
roles_path = roles
host_key_checking = False
retry_files_enabled = False
result_format = yaml
EOL

# Preflight vars
cat >"$BASE_DIR/roles/selfheal_preflight/vars/main.yml" <<EOL
pushgateway_enabled: true
pushgateway_url: "http://localhost:9091"
EOL

# Preflight defaults
cat >"$BASE_DIR/roles/selfheal_preflight/defaults/main.yml" <<'EOL'
preflight_min_free_ram_pct: 10
preflight_max_swap_pct: 80
preflight_max_cpu_load_factor: 2
preflight_min_root_free_mb: 1024
preflight_max_iowait_pct: 30
preflight_fail_fast: true
selfheal_service_profiles:
  apache2:
    min_free_ram_pct: 5
    max_cpu_load_factor: 3
  mysql:
    min_free_ram_pct: 20
    max_iowait_pct: 20
    min_root_free_mb: 5120
  postgresql:
    min_free_ram_pct: 15
    max_cpu_load_factor: 2
  docker:
    min_free_ram_pct: 10
    max_cpu_load_factor: 2
EOL

# State Machine defaults
cat >"$BASE_DIR/roles/selfheal_state_machine/defaults/main.yml" <<'EOL'
selfheal_services:
  - name: apache2
    initial_state: restart
    severity: critical
    states:
      restart: cleanup
      cleanup: reload
      reload: scale_service
      scale_service: network_heal
      network_heal: memory_recovery
      memory_recovery: fsck_approval
      fsck_approval: done
  - name: mysql
    initial_state: restart
    severity: high
    states:
      restart: cleanup
      cleanup: reload
      reload: scale_service
      scale_service: network_heal
      network_heal: memory_recovery
      memory_recovery: fsck_approval
      fsck_approval: done
  - name: postgresql
    initial_state: restart
    severity: high
    states:
      restart: cleanup
      cleanup: reload
      reload: scale_service
      scale_service: network_heal
      network_heal: memory_recovery
      memory_recovery: fsck_approval
      fsck_approval: done
  - name: docker
    initial_state: restart
    severity: medium
    states:
      restart: cleanup
      cleanup: scale_service
      scale_service: network_heal
      network_heal: memory_recovery
      memory_recovery: fsck_approval
      fsck_approval: done

selfheal_state_dir: /var/lib/selfheal
selfheal_cooldown: 600
selfheal_terminal_states: [done, failed]
selfheal_pushgateway: http://localhost:9091
selfheal_state_map:
  restart: 1
  cleanup: 2
  reload: 3
  scale_service: 4
  network_heal: 5
  memory_recovery: 6
  fsck_approval: 9
  done: 10
  failed: 99
EOL

# Preflight tasks
cat >"$BASE_DIR/roles/selfheal_preflight/tasks/main.yml" <<'EOL'
- import_tasks: checks.yml
- import_tasks: policy.yml
EOL

cat >"$BASE_DIR/roles/selfheal_preflight/tasks/checks.yml" <<'EOL'
- name: Gather facts
  setup:

- set_fact:
    preflight_errors: []

- name: Check free RAM
  set_fact:
    preflight_errors: "{{ preflight_errors + ['low_ram'] }}"
  when: (ansible_memfree_mb / ansible_memtotal_mb * 100) < preflight_min_free_ram_pct

- name: Check swap usage
  set_fact:
    preflight_errors: "{{ preflight_errors + ['swap_full'] }}"
  when: (ansible_swaptotal_mb > 0) and (((ansible_swaptotal_mb - ansible_swapfree_mb)/ansible_swaptotal_mb*100) > preflight_max_swap_pct)

- name: Check CPU load
  set_fact:
    preflight_errors: "{{ preflight_errors + ['cpu_overload'] }}"
  when:
    - ansible_loadavg is defined
    - ansible_loadavg['1m'] is defined
    - ansible_processor_vcpus is defined
    - ansible_loadavg['1m'] > (ansible_processor_vcpus * preflight_max_cpu_load_factor)

- name: Check root filesystem
  set_fact:
    preflight_errors: "{{ preflight_errors + ['disk_full'] }}"
  when: (ansible_mounts|selectattr('mount','equalto','/')|map(attribute='size_available')|first/1024/1024) < preflight_min_root_free_mb

- name: Check default route
  command: ip route
  register: routes
  changed_when: false

- set_fact:
    preflight_errors: "{{ preflight_errors + ['no_network'] }}"
  when: "'default' not in routes.stdout"
EOL

cat >"$BASE_DIR/roles/selfheal_preflight/tasks/policy.yml" <<'EOL'
- name: Abort if preflight failed
  meta: end_play
  when: preflight_errors | length > 0 and preflight_fail_fast
EOL

# State Machine tasks
for file in main.yml service_loop.yml load_state.yml run_state.yml cooldown.yml; do
	touch "$BASE_DIR/roles/selfheal_state_machine/tasks/$file"
done

# main.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/tasks/main.yml" <<'EOL'
- import_tasks: cooldown.yml
- import_tasks: service_loop.yml
EOL

# cooldown.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/tasks/cooldown.yml" <<'EOL'
- name: Ensure state directory exists
  file:
    path: "{{ selfheal_state_dir }}"
    state: directory
    mode: '0755'
EOL

cat >"$BASE_DIR/roles/selfheal_state_machine/tasks/push_success.yml" <<'EOL'
- name: DEBUG service_name scope
  debug:
    var: service_name

- name: Push repair success metric
  ansible.builtin.uri:
    url: "{{ selfheal_pushgateway }}/metrics/job/selfheal/host/{{ inventory_hostname }}/service/{{ service_name }}"
    method: POST
    body: |
      selfheal_repair_success{host="{{ inventory_hostname }}",service="{{ service_name }}"} 1
    status_code: [200, 202]
  delegate_to: localhost
  when:
    - selfheal_push_metrics | default(true)

EOL

# service_loop.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/tasks/service_loop.yml" <<'EOL'
# service_loop.yml
- name: Filter target services
  set_fact:
    target_services_filtered: >
      {{ selfheal_services if selfheal_service == 'all'
         else selfheal_services | selectattr('name','equalto', selfheal_service) | list }}

- name: Loop over filtered services
  include_tasks: load_state.yml
  loop: "{{ target_services_filtered }}"
  loop_control:
    loop_var: target_service_item
EOL

# load_state.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/tasks/load_state.yml" <<'EOL'
# load_state.yml
- name: Set service and initial state
  set_fact:
    service_name: "{{ target_service_item.name }}"
    current_state: "{{ target_service_item.initial_state }}"
    service_success: false
    service_finalized: false
    service_states: []

- import_tasks: run_state.yml
EOL

# run_state.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/tasks/run_state.yml" <<'EOL'
# run_state.yml
- name: Debug current service and state
  debug:
    msg:
      - "Service: {{ service_name }}"
      - "Executing state: {{ current_state }}"

# -------------------------------------------------
# Execute current state
# -------------------------------------------------
- name: Execute current state
  include_tasks: "../states/{{ current_state }}.yml"
  vars:
    target_service: "{{ service_name }}"
  register: svc_result
  ignore_errors: true

# -------------------------------------------------
# Persist current state
# -------------------------------------------------
- name: Persist current state
  copy:
    content: "{{ current_state }}"
    dest: "{{ selfheal_state_dir }}/{{ service_name }}"

# -------------------------------------------------
# Record state execution
# -------------------------------------------------
- name: Record state execution
  set_fact:
    service_states: >-
      {{
        service_states + [
          {
            'state': current_state,
            'skipped': svc_result.skipped | default(false),
            'success': (svc_result.rc is defined and svc_result.rc == 0) or
                       (svc_result.skipped | default(false) == false)
          }
        ]
      }}

# -------------------------------------------------
# Mark service success if any executed state succeeded
# -------------------------------------------------
- name: Mark service success
  set_fact:
    service_success: true
  when:
    - not service_success
    - service_states | selectattr('success','equalto',true) | list | length > 0

# -------------------------------------------------
# Determine next state
# -------------------------------------------------
- name: Determine next state
  set_fact:
    current_state: "{{ target_service_item.states[current_state] | default('done') }}"

- name: Debug next state
  debug:
    msg: "Next state for {{ service_name }} → {{ current_state }}"

# -------------------------------------------------
# Continue state machine recursively
# -------------------------------------------------
- name: Continue state machine
  include_tasks: run_state.yml
  when:
    - current_state not in selfheal_terminal_states
    - not service_success
    - not service_finalized

# ----------------------------
# Debugging / Service Info
# ----------------------------
- name: Debug service details
  debug:
    msg:
      - "inventory_hostname: {{ inventory_hostname }}"
      - "service_name: {{ service_name }}"
      - "service_success: {{ service_success }}"
  when: service_finalized

# ----------------------------
# Push Metrics to Prometheus
# ----------------------------
# Push success metric (nur, wenn erfolgreich)
- name: Push success metric to Prometheus Pushgateway
  uri:
    url: "{{ pushgateway_url }}/metrics/job/selfheal_success/host/{{ inventory_hostname }}/service/{{ service_name }}"
    method: POST
    body: |
      # HELP selfheal_service_success_total Total number of successful self-healing actions for the service.
      # TYPE selfheal_service_success_total counter
      selfheal_service_success_total{host="{{ inventory_hostname }}",job="selfheal",service="{{ service_name }}"} 1
    headers:
      Content-Type: text/plain
  when: service_success
  ignore_errors: true
  failed_when: false

# Push failure metric (nur, wenn fehlgeschlagen)
- name: Push failure metric to Prometheus Pushgateway
  uri:
    url: "{{ pushgateway_url }}/metrics/job/selfheal_failure/host/{{ inventory_hostname }}/service/{{ service_name }}"
    method: POST
    body: |
      # HELP selfheal_service_failure_total Total number of failed self-healing actions for the service.
      # TYPE selfheal_service_failure_total counter
      selfheal_service_failure_total{host="{{ inventory_hostname }}",job="selfheal",service="{{ service_name }}"} 1
    headers:
      Content-Type: text/plain
  when: not service_success
  ignore_errors: true
  failed_when: false

# Push service result gauge (immer)
- name: Push service result gauge to Prometheus Pushgateway
  uri:
    url: "{{ pushgateway_url }}/metrics/job/selfheal_result/host/{{ inventory_hostname }}/service/{{ service_name }}"
    method: POST
    body: |
      # HELP selfheal_service_result Result of the self-healing action (1 for success, 0 for failure).
      # TYPE selfheal_service_result gauge
      selfheal_service_result{host="{{ inventory_hostname }}",job="selfheal",service="{{ service_name }}"} {{ 1 if service_success else 0 }}
    headers:
      Content-Type: text/plain
  ignore_errors: true
  failed_when: false

# ----------------------------
# Optional: Push Last Executed State
# ----------------------------
- name: Push last executed state to Prometheus
  uri:
    url: "{{ pushgateway_url }}/metrics/job/selfheal/host/{{ inventory_hostname }}/service/{{ service_name }}"
    method: POST
    headers:
      Content-Type: text/plain
    status_code: [200, 202]
    body: |
      # HELP selfheal_service_last_state Last executed state
      # TYPE selfheal_service_last_state gauge
      selfheal_service_last_state{host="{{ inventory_hostname }}",service="{{ service_name }}",state="{{ service_states[-1].state if service_states is defined and service_states|length > 0 else 'unknown' }}"} 1
  when:
    - service_finalized
    - service_states is defined
    - pushgateway_url is defined
    - pushgateway_enabled | default(true)
  ignore_errors: true
  failed_when: false


- name: Mark service as finalized
  set_fact:
    service_finalized: true
EOL

# States
mkdir -p "$BASE_DIR/roles/selfheal_state_machine/states"

# restart.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/states/restart.yml" <<'EOL'
# Restart state for self-healing state machine

- name: Debug current service and state
  debug:
    msg:
      - "Service: {{ target_service }}"
      - "Executing state: restart"

# ------------------------------
# Restart systemd service
- name: Restart systemd service
  service:
    name: "{{ target_service }}"
    state: restarted
  register: svc_result
  ignore_errors: true

# ------------------------------
# Optional: Restart PostgreSQL if target_service matches
- name: Restart PostgreSQL service
  service:
    name: postgresql
    state: restarted
  when: target_service in ['postgresql', 'postgres']
  register: svc_result
  ignore_errors: true

# ------------------------------
# Optional: Wait for PostgreSQL connections
- name: Wait for PostgreSQL to accept connections
  wait_for:
    host: localhost
    port: 5432
    timeout: 10
  when: target_service in ['postgresql', 'postgres']

# ------------------------------
# Optional: Verify PostgreSQL is running
- name: Verify PostgreSQL is running
  command: systemctl is-active postgresql
  register: pg_status
  changed_when: false
  failed_when: pg_status.stdout != "active"
  when: target_service in ['postgresql', 'postgres']

# ------------------------------
# Log service status
- name: Log service status
  command: systemctl status "{{ target_service }}"
  register: svc_log
  changed_when: false
  ignore_errors: true

- name: Debug service log
  debug:
    msg: "{{ svc_log.stdout if svc_log is defined else 'No status available' }}"

EOL

# cleanup.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/states/cleanup.yml" <<'EOL'
# cleanup.yml

- name: Cleanup old files in /tmp (safe)
  shell: >
    find /tmp -mindepth 1 -xdev -type f -mtime +1 -delete
  ignore_errors: true

- name: Cleanup old empty directories in /tmp (safe)
  shell: >
    find /tmp -mindepth 1 -xdev -type d -empty -mtime +1 -delete
  ignore_errors: true

- name: Ensure /tmp permissions
  file:
    path: /tmp
    state: directory
    mode: '1777'
EOL

# reload.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/states/reload.yml" <<'EOL'
- name: Check if systemd service supports reload
  shell: |
    systemctl show {{ target_service }} --property=CanReload --value
  register: reload_capable
  changed_when: false
  failed_when: false

- name: Debug reload capability
  debug:
    msg: "Service {{ target_service }} CanReload={{ reload_capable.stdout }}"

- name: Reload systemd service if supported
  systemd:
    name: "{{ target_service }}"
    state: reloaded
  register: reload_result
  ignore_errors: true
  when: reload_capable.stdout == "yes"

- name: Fallback to restart if reload not supported
  systemd:
    name: "{{ target_service }}"
    state: restarted
  register: reload_result
  ignore_errors: true
  when: reload_capable.stdout != "yes"

- name: Debug reload/restart result
  debug:
    msg:
      - "Reload fallback executed for {{ target_service }}"
      - "{{ reload_result }}"
EOL

# scale_service.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/states/scale_service.yml" <<'EOL'
- name: Scale / restart Docker container
  docker_container:
    name: "{{ target_service }}"
    state: started
    restart: yes
  register: docker_result
  ignore_errors: true
  when: target_service == "docker"

- name: Debug Docker scale result
  debug:
    msg:
      - "Docker scale/restart executed for {{ target_service }}"
      - "{{ docker_result }}"
  when: target_service == "docker"

- name: Skip scale_service for non-docker services
  debug:
    msg: "scale_service skipped for {{ target_service }}"
  when: target_service != "docker"
EOL

# network_heal.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/states/network_heal.yml" <<'EOL'
# network_heal.yml

- name: Detect primary network interface
  shell: |
    ip -o link show | awk -F': ' '{print $2}' | grep -Ev 'lo|docker|veth|br-' | head -n1
  register: net_iface
  changed_when: false

- name: Debug detected interface
  debug:
    msg: "Detected network interface: {{ net_iface.stdout }}"

- name: Bring network interface up
  command: ip link set {{ net_iface.stdout }} up
  register: net_result
  ignore_errors: true
  when: net_iface.stdout != ""

- name: Fail state if interface not found or command failed
  set_fact:
    current_state: "failed"
  when:
    - net_iface.stdout == "" or net_result.rc != 0

EOL

# memory_recovery.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/states/memory_recovery.yml" <<'EOL'
# memory_recovery.yml

- name: Drop Linux filesystem caches
  shell: |
    sync
    echo 3 > /proc/sys/vm/drop_caches
  become: true
  register: mem_result
  ignore_errors: true

- name: Debug memory recovery result
  debug:
    msg:
      - "Memory recovery executed"
      - "RC: {{ mem_result.rc | default('n/a') }}"
EOL

# fsck_approval.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/states/fsck_approval.yml" <<'EOL'
- name: Debug FSCK approval flag
  debug:
    msg: "FSCK approval is: {{ selfheal_approval | default(false) | bool }}"

- name: Skip FSCK if not approved
  set_fact:
    current_state: "done"
  when: not (selfheal_approval | default(false) | bool)

- name: Check for mounted filesystems (excluding root)
  shell: |
    mount | awk '{print $3}' | grep -Ev '^/$'
  register: mounted_fs
  changed_when: false
  when: selfheal_approval | bool

- name: Log mounted filesystems
  debug:
    var: mounted_fs.stdout_lines
  when:
    - selfheal_approval | bool
    - mounted_fs.stdout != ""

- name: Defer FSCK because filesystems are mounted
  set_fact:
    current_state: "done"
  when:
    - selfheal_approval | bool
    - mounted_fs.stdout != ""

- name: Run FSCK on unmounted filesystems
  command: fsck -AR -y
  become: true
  register: fsck_result
  ignore_errors: true
  when:
    - selfheal_approval | bool
    - mounted_fs.stdout == ""

- name: Log FSCK result
  debug:
    msg:
      - "FSCK executed"
      - "RC: {{ fsck_result.rc | default('n/a') }}"
EOL

# done.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/states/done.yml" <<'EOL'
- name: Mark service successfully healed
  debug:
    msg: "Service {{ target_service }} successfully healed"

- name: Push repair success metric
  include_tasks: ../tasks/push_success.yml
  vars:
    current_service: "{{ target_service }}"
EOL

# failed.yml
cat >"$BASE_DIR/roles/selfheal_state_machine/states/failed.yml" <<'EOL'
- name: Mark service failed
  debug:
    msg: "Service {{ target_service }} failed self-healing"
EOL

# Playbook
cat >"$BASE_DIR/playbooks/selfheal.yml" <<'EOL'
- hosts: all
  become: true

  vars_prompt:
    - name: "selfheal_approval"
      prompt: "Do you approve FSCK / risky actions? (yes/no)"
      private: no
      default: "no"

  vars:
    selfheal_approval: "{{ selfheal_approval | bool }}"
  
  roles:
    - services
    - selfheal_preflight
    - selfheal_state_machine
EOL

# Inventory
CURRENT_USER=$(whoami)
cat >"$BASE_DIR/inventory/hosts.ini" <<EOL
[all]
$CURRENT_USER ansible_connection=local
EOL

# Preflight tasks
cat >"$BASE_DIR/roles/services/tasks/main.yml" <<'EOL'
- import_tasks: selfheal-webhook.yml
- import_tasks: pushgateway.yml
EOL

cat >"$BASE_DIR/roles/services/tasks/selfheal-webhook.yml" <<'EOL'
# -------------------------------------------------
# selfheal-webhook service for Self-Healing
# -------------------------------------------------
- name: Create selfheal-webhook systemd service
  copy:
    dest: /etc/systemd/system/selfheal-webhook.service
    mode: '0644'
    content: |
      [Unit]
      Description=Selfheal Webhook Service
      After=network.target
      
      [Service]
      Type=simple
      ExecStart=/usr/bin/python3 /bigdata/tmp/ansible-self-healing-infrastructure/setup/selfheal_webhook.py
      WorkingDirectory=/bigdata/tmp/ansible-self-healing-infrastructure
      Restart=always
      User=weideman
      Environment=PYTHONUNBUFFERED=1
      
      [Install]
      WantedBy=multi-user.target

- name: Reload systemd
  systemd:
    daemon_reload: yes

- name: Enable and start selfheal-webhook
  systemd:
    name: selfheal-webhook
    enabled: yes
    state: started
EOL

cat >"$BASE_DIR/roles/services/tasks/pushgateway.yml" <<'EOL'
- name: Create temporary working directory
  tempfile:
    state: directory
    prefix: pushgateway_
  register: tmpdir

- name: Download Pushgateway archive
  get_url:
    url: "https://github.com/prometheus/pushgateway/releases/download/v1.11.2/pushgateway-1.11.2.linux-amd64.tar.gz"
    dest: "/tmp/pushgateway-1.11.2.linux-amd64.tar.gz"

- name: Extract Pushgateway archive
  unarchive:
    src: "/tmp/pushgateway-1.11.2.linux-amd64.tar.gz"
    dest: "/tmp"
    remote_src: true

- name: Copy Pushgateway binary to /usr/local/bin
  copy:
    src: "/tmp/pushgateway-1.11.2.linux-amd64/pushgateway"
    dest: "/usr/local/bin/pushgateway"
    mode: '0755'

- name: Create systemd service for Pushgateway
  copy:
    dest: "/etc/systemd/system/pushgateway.service"
    content: |
      [Unit]
      Description=Prometheus Pushgateway
      After=network.target

      [Service]
      ExecStart=/usr/local/bin/pushgateway
      Restart=always
      User=pushgateway
      Group=nogroup

      [Install]
      WantedBy=multi-user.target

- name: Reload systemd daemon
  systemd:
    daemon_reload: yes

- name: Enable and start pushgateway service
  systemd:
    name: pushgateway
    enabled: yes
    state: started
EOL
