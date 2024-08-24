#!/bin/bash
echo "Updating DNF repository"
sudo dnf update
echo "Installing PostgreSQL 15"
sudo dnf install postgresql15.x86_64 postgresql15-server -y
echo "Init Database"
sudo postgresql-setup --initdb
echo "Starting and Enabling PostgreSQL Service"
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo systemctl status postgresql