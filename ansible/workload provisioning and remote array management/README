# Accelerate 2025 Demo: Ansible Scripts

These are the **Ansible scripts** used in the Accelerate 2025 demo.

---

## Requirements

- **FlashArray Ansible Galaxy Collection** `1.37.0` and above
  [View on Ansible Galaxy](https://galaxy.ansible.com/ui/repo/published/purestorage/flasharray/)
- **Purity** `6.10.2` and above

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

## Configuring Array Specification

The `array_config.yml` file specifies how you want each array to be configured:

- DNS
- NTP servers
- Syslog servers
- Default protection
- Hosts

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

Modify `provision_workload.yml` to specify:

- `preset` — Name of the Preset
- `name` — Name of the workload
- `context` — Name of the array to provision the workload
- `host` — Name of the host to connect to the workload

**Run:**

```shell
ansible-playbook provision_workload.yml
```

---

> _For more information, refer to the official documentation or the sample files provided in this package._
