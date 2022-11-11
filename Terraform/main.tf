terraform {
  required_providers {
    nirmata = {
      source = "nirmata/nirmata"
      version = "1.1.8-rc2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

provider "nirmata" {

  # Nirmata address.
  url = "https://nirmata.io"

  // Nirmata API Key. Also configurable using the environment variable NIRMATA_TOKEN.
  token = "API-TOKEN-FROM-NIRMATA"

}
resource "nirmata_cluster_registered" "aks-registered" {
  // Name of the cluster to be created in Nirmata
  name         = "cluster-name"

  // Nmae of Cluster Type created in Nirmata
  cluster_type = "cluster-typ-name"
}

# Retrieve AKS cluster information
provider "azurerm" {
  features {}
}

data "azurerm_kubernetes_cluster" "cluster" {

  // Nmae of the cluster in Azure
  name                = "cluster-name-in-Azure"

  // Name of rescource group created in Azure
  resource_group_name = "resource-group-name-in-Azure"
}

provider "kubectl" {
  host = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host

  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)

}

data "kubectl_filename_list" "manifests" {
  pattern = "${nirmata_cluster_registered.aks-registered.controller_yamls_folder}/*"
}

// apply the controller YAMLs
resource "kubectl_manifest" "test" {
  count     = nirmata_cluster_registered.aks-registered.controller_yamls_count
  yaml_body = file(element(data.kubectl_filename_list.manifests.matches, count.index))
}
