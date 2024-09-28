# Tech1 - Terraform repository files - Core Infrastructure

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Description](#description)
- [How to use](#how-to-use)
- [Infrastructure resources](#infrastructure-resources)
- [Other infrastructure resources](#other-infrastructure-resources)

## Description

The Tech Challenge 1 aims to do a solution for a Fast Food restaurant. This project is part of the entire solution. Here we have all the `Terraform` files to the **core infrastructure** to the `AWS` cloud.

## How to use

To build the infractructure, just run the `Github Actions manual Workflow (Build Infrastructure)` on `Actions` tab. This will take some time (between 24 to 28 minutes). To destroy the infractructure, just run the `Github Actions manual Workflow (Destroy Infrastructure)` on `Actions` tab. This will take some time (between 8 to 14 minutes).

## Infrastructure resources

The main infrastructure will be created by this project. The core resources are:

- VPC (with private and public subnets)
- EKS
- Cognito

## Other infrastructure resources

To use the Fastfood Project, we have to build other infrastructure resources within `AWS`. These other resources are:

- RDS (with Postgres)
- API Gateway
- Lambda

These other resources will be created in **separete Github Projects**.
