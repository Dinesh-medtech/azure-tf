provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "example-aks-rds-resources"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for PostgreSQL
resource "azurerm_subnet" "postgres_subnet" {
  name                 = "postgres-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "example-aks-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "exampleaks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }
}

# Azure Database for PostgreSQL Server
resource "azurerm_postgresql_server" "postgres_server" {
  name                = "examplepgserver"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku {
    name     = "B_Gen5_1"  # Choose the desired SKU for your server
    tier     = "Basic"
    capacity = 1
  }
  version            = "12"  # Specify the version you want
  ssl_enforcement    = "Enabled"
  administrator_login = "pgadmin"
  administrator_login_password = "YourSecurePassword123!"  
  storage_mb         = 5120  # Size in MB

}

# PostgreSQL Database
resource "azurerm_postgresql_database" "postgres_database" {
  name                = "exampledb"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.postgres_server.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# Network Rules for PostgreSQL Server
resource "azurerm_postgresql_server_firewall_rule" "allow_aks" {
  name                = "allow-aks"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.postgres_server.name
  start_ip_address    = "10.0.1.0"  # IP of AKS subnet
  end_ip_address      = "10.0.1.255"  # IP range of AKS subnet
}
