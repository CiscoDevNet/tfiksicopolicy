#get the data fro the global vars WS
data "terraform_remote_state" "global" {
  backend = "remote"
  config = {
    organization = var.org
    workspaces = {
      name = var.globalwsname
    }
  }
}

variable "org" {
  type        = string
}
variable "globalwsname" {
  type        = string
  description = "TFCB workspace name that has all of the global variables"
}
variable "api_key" {
  type        = string
  description = "API key for Intersight user"
}

variable "secretkey" {
  type        = string
  description = "Secret key for Intersight user"
}

terraform {
  required_providers {
    intersight = {
      source = "ciscodevnet/intersight"
      version = "1.0.26"
    }
  }
}

provider "intersight" {
  apikey    = base64decode(var.api_key)
  secretkey = base64decode(var.secretkey)
  endpoint = "https://intersight.com"
}

module "infra_config_policy" {
  source           = "terraform-cisco-modules/iks/intersight//modules/infra_config_policy"
  name             = local.infra_config_policy 
  device_name      = local.device_name
  vc_portgroup     = local.portgroup
  vc_datastore     = local.datastore
  vc_cluster       = local.vspherecluster
  vc_resource_pool = local.resource_pool
  vc_password      = local.password
  org_name         = local.organization
  version          = "1.0.1"
}

module "ip_pool_policy" {
  source           = "terraform-cisco-modules/iks/intersight//modules/ip_pool"
  name             = local.ip_pool_policy 
  starting_address = local.starting_address
  pool_size        = local.pool_size
  netmask          = local.netmask
  gateway          = local.gateway
  primary_dns      = local.primary_dns
  version          = "1.0.1"

  org_name = local.organization
}

module "network" {
  source      = "terraform-cisco-modules/iks/intersight//modules/k8s_network"
  policy_name = "sbcluster" 
  #policy_name = local.clustername
  dns_servers = [local.primary_dns]
  ntp_servers = [local.primary_dns]
  timezone    = local.timezone
  domain_name = local.domain_name
  org_name    = local.organization
  version     = "1.0.1"
}

module "k8s_version" {
  source           = "terraform-cisco-modules/iks/intersight//modules/version"
  policyName     = local.k8s_version_name
  iksVersionName = local.k8s_version
  org_name = local.organization
  version = "=2.1.2"
}

#module "version_1-21-11-iks-2" {
#  source           = "terraform-cisco-modules/iks/intersight//modules/version"
#  version = "=2.1.2"
#  policyName     = local.k8s_version_name
#  # policyName     = "1.19.15-iks.3"
#  iksVersionName = "1.21.11-iks.2"
#  org_name = local.organization
##  tags     = var.tags
#} 

data "intersight_organization_organization" "organization" {
  name = local.organization
}
resource "intersight_kubernetes_virtual_machine_instance_type" "masterinstance" {
  name      = local.masterinstance
  cpu       = local.cpu
  disk_size = local.disk_size
  memory    = local.memory
  organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.organization.results.0.moid
  }
}

output "ver" {
    value = local.k8s_version
}

locals {
  masterinstance = yamldecode(data.terraform_remote_state.global.outputs.masterinstance)
  cpu = yamldecode(data.terraform_remote_state.global.outputs.cpu)
  disk_size = yamldecode(data.terraform_remote_state.global.outputs.disk_size)
  memory = yamldecode(data.terraform_remote_state.global.outputs.memory)
  organization= yamldecode(data.terraform_remote_state.global.outputs.organization)
  k8s_version = yamldecode(data.terraform_remote_state.global.outputs.k8s_version)
  k8s_version_name = yamldecode(data.terraform_remote_state.global.outputs.k8s_version_name)
  clustername = yamldecode(data.terraform_remote_state.global.outputs.clustername)
  primary_dns = yamldecode(data.terraform_remote_state.global.outputs.primary_dns)
  timezone = yamldecode(data.terraform_remote_state.global.outputs.timezone)
  domain_name = yamldecode(data.terraform_remote_state.global.outputs.domain_name)
  ip_pool_policy = yamldecode(data.terraform_remote_state.global.outputs.ip_pool_policy)
  starting_address = yamldecode(data.terraform_remote_state.global.outputs.starting_address)
  pool_size = yamldecode(data.terraform_remote_state.global.outputs.pool_size)
  netmask = yamldecode(data.terraform_remote_state.global.outputs.netmask)
  gateway = yamldecode(data.terraform_remote_state.global.outputs.gateway)
  infra_config_policy = yamldecode(data.terraform_remote_state.global.outputs.infra_config_policy)
  device_name = yamldecode(data.terraform_remote_state.global.outputs.device_name)
  portgroup = data.terraform_remote_state.global.outputs.portgroup 
  password = yamldecode(data.terraform_remote_state.global.outputs.password) 
#  portgroup = "VM Network" 
  datastore = yamldecode(data.terraform_remote_state.global.outputs.datastore)
  vspherecluster = yamldecode(data.terraform_remote_state.global.outputs.vspherecluster)
  resource_pool = yamldecode(data.terraform_remote_state.global.outputs.resource_pool)

}




















