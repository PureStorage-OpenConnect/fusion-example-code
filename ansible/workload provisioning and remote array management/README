# Accelerate 2026 Demo: Ansible Scripts

These are the **Ansible scripts** used in the Accelerate 2026 demo.

---

## Requirements

- **FlashArray Ansible Galaxy Collection** `1.42.0` and above
  [View on Ansible Galaxy](https://galaxy.ansible.com/ui/repo/published/purestorage/flasharray/)
- **Purity** `6.10.6` and above

---

## Getting Started

Pick an array in your fleet to use as the entrypoint.
Point your Ansible scripts to this array to manage the fleet.

### Generate API Token on Array

**Via GUI:**

1. Login to the array with an LDAP user.
2. Go to: `Settings → Users and Policies`.
3. In the top right of the "Users" table, click the **kebab menu** and select **Create API Token**.
4. Enter the name of the logged-in LDAP user.

**Via CLI:**

```shell
pureadmin create --api-token
```

---

## Pointing Ansible to the Array

1. Open `constants.yml`.
2. Enter the API token and the URL to the array.

---

## Configuring Topology Specification

The `topology_config.yml` file specifies how you want your topology groups to be structured

You can refer to `topology_config.yml.example` as an example on how to create `topology_config.yml`

**To apply `topology_config.yml` to all arrays in the fleet:**

```shell
ansible-playbook configure_topology.yml
```

---


## Configuring Array Specification

The `array_config.yml` file specifies how you want each array to be configured:

- DNS
- NTP servers
- Syslog servers
- Default protection
- Hosts

You can refer to `array_config.yml.example` as an example on how to create `array_config.yml`

**To apply `array_config.yml` to all arrays in the fleet:**

```shell
ansible-playbook configure_array.yml
```

---

## Provisioning Workloads with Preset

### Upload Presets

**Via GUI:**

1. Login as an LDAP user.
2. Go to: `Storage → Presets`.
3. In the top right of the "Presets" table, click the **kebab menu** and select **Upload Preset**.
4. Provide both `db-prod.json` and `vmfs.json`.

**Via CLI:**

```shell
purepreset workload upload --context <name-of-your-fleet> <name-of-preset>
```

You'll be prompted to enter the contents of the Preset.
Copy and paste the sample Presets provided.

---

## Provision Workloads

The `workload_config.yml` specifies how you want workloads to be configured

You can refer to `workload_config.yml.example` as an example on how to create `workload_config.yml`

**Run:**

```shell
ansible-playbook provision_workload.yml
```

---

> _For more information, refer to the official documentation or the sample files provided in this package._
