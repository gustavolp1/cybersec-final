# Terraform Project with Zabbix Monitoring

This repository contains a Terraform configuration to set up infrastructure in AWS with Zabbix monitoring for development and database instances. The setup includes:

- **Zabbix Server**: Monitors the infrastructure.
- **Development Instance**: Configured with FastAPI.
- **Database Instance**: Configured with MySQL.

## Prerequisites

1. **Terraform**: Install Terraform (version 1.5.0 or later) from [Terraform&#39;s website](https://www.terraform.io/downloads.html).
2. **AWS CLI**: Configure AWS credentials with the command:

   ```bash
   aws configure
   ```
3. **SSH Key**: Ensure you have an SSH private key (e.g., dev-keypair.pem) to connect to instances.

## Setup Instructions

### Step 1: Clone the Repository

```
git clone https://github.com/gustavolp1/cybersec-final
cd <repository-directory>
```

### Step 2: Initialize Terraform

Run the following command to download and initialize required providers:

```
terraform init
```

### Step 3: Modify Variables

Adjust the `variables.tf` and `main.tf` to override default values. For example:

```
region = "us-east-1"
private_key_path = "~/.ssh/dev-keypair.pem"
```

### Step 4: Plan the Infrastructure

To preview changes that Terraform will make:

```
terraform plan
```

### Step 5: Apply the Configuration

```
terraform apply
```

When prompted, type `yes` to confirm.

## Zabbix Monitoring Configuration

### Zabbix API Access

1. Open your browser and access the Zabbix UI at `http://<zabbix-server-ip>/zabbix`.
2. Log in with the the username `Admin` and the password `zabbix`.

### Add Development and Database Instances

1. Go to `Configuration -> Hosts` in the Zabbix UI.
2. Click on `Create Host`.
3. Enter a host name (e.g., `Development`), IP Adress (public IP of the instance) and Agent Interface Port (`10050`).
4. Assign the appropriate templates for monitoring (e.g., `Linux by Zabbix agent`).
5. Save and test connectivity.

## Destroying the Infrastructure

To destroy all resources created by Terraform, run:

```
terraform destroy
```

Type `yes` when prompted to confirm destruction.

## Authors

- Enzo Quental
- Gustavo Pacheco
- Sérgio Ramella

## Deliverables

A video demo can be found [here]().
The technical report is included in this repository (`Relatório PF Cyber`).