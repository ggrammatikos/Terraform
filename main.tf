provider "azurerm" {
  features {}
}

#Create Azure Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}
#Create Azure Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}
#Create Azure VNet Subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}
#Create Azure Bastion Subnet
resource "azurerm_subnet" "AzureBastionSubnet" {
  name                ="AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/27"]
}
#Create Azure Network Interface Card
resource "azurerm_network_interface" "mytestnic" {
  name                = "mytestnic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}
#Create Azure Network Security Group With The Appropriate Security Rules
resource "azurerm_network_security_group" "mytestnsg" {
  name                          = "mytestnsg"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name

    security_rule {
        name                       = "AllowHttpsInbound"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "AllowGatewayManagerInbound"
        priority                   = 130
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "GatewayManager"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "AllowAzureLoadBalancerInbound"
        priority                   = 140
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "AllowBastionHostCommunication1"
        priority                   = 150
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     ="8080"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "AllowBastionHostCommunication2"
        priority                   = 160
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     ="5701"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "AllowSshRdpOutbound1"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     ="22"
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
    }


    security_rule {
        name                       = "AllowSshRdpOutbound2"
        priority                   = 110
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     ="3389"
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "AllowAzureCloudOutbound"
        priority                   = 120
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "AzureCloud"
    }

    security_rule {
        name                       = "AllowBastionCommunication1"
        priority                   = 130
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "AllowBastionCommunication2"
        priority                   = 140
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range    = "5701"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "AllowGetSessionInformation"
        priority                   = 150
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "Internet"
    }

}


#Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsgassoc" {
    network_interface_id      = azurerm_network_interface.mytestnic.id
    network_security_group_id = azurerm_network_security_group.mytestnsg.id
    
}
#Create Azure VM - Standard F2 size
resource "azurerm_windows_virtual_machine" "main" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_F2"
  admin_username                  = "myuser"
  admin_password                  = "P@sSW0rD12345!"
  network_interface_ids = [azurerm_network_interface.mytestnic.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}