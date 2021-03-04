/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  prefix       = "bce-applink"
  network_name = "bce-applink-net"
  target_tag   = "${local.prefix}-tag"
  # Port for the load balancer backend service provided by the MIG.
  service_port      = 19443
  service_port_name = "http"
  tunnel_port       = 18443
  grpc_hc_port      = 20443 # health check gRPC port for GCLB
  # List of all ports that need access via IAP TCP.
  request_gw_ports = ["22", local.tunnel_port, local.grpc_hc_port]
}

provider "google" {
  project = var.project_id
  version = "~> 3.0"
}

provider "google-beta" {
  project = var.project_id
  version = "~> 3.0"
}

# Setup the networking components needed for the gateway.
module "networking" {
  source           = "./modules/networking"
  project_id       = var.project_id
  network          = local.network_name
  prefix           = local.prefix
  request_gw_ports = local.request_gw_ports
  service_port     = local.service_port
  grpc_hc_port     = local.grpc_hc_port
  target_tag       = local.target_tag
  application_map  = var.application_map
}

# Create managed instance groups per application running the gateways.
module "migs" {
  source            = "./modules/mig"
  project_id        = var.project_id
  image             = var.image
  prefix            = local.prefix
  service_port      = local.service_port
  service_port_name = local.service_port_name
  target_tag        = local.target_tag
  application_map   = var.application_map
  subnetwork_map    = module.networking.subnetwork_map
  tunnel_port       = local.tunnel_port
}

# Create a tcp google_compute_health_check per application for use by google_compute_backend_service resources.
resource "google_compute_health_check" "tcp_healthcheck" {
  provider = google-beta
  project  = var.project_id

  for_each            = var.application_map
  name                = "${local.prefix}-${each.key}-tcp-hc"
  description         = "Health check via tcp for the backend service."
  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = local.service_port
  }

  log_config { enable = true }
}

# Create a http google_compute_health_check per application for use by google_compute_backend_service resources.
resource "google_compute_health_check" "http_healthcheck" {
  provider = google-beta
  project  = var.project_id

  for_each            = var.application_map
  name                = "${local.prefix}-${each.key}-http-hc"
  description         = "Health check via http for the backend service."
  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = local.service_port
    request_path = "/"
  }

  log_config { enable = true }
}

# Create a grpc google_compute_health_check per application for use by google_compute_backend_service resources.
resource "google_compute_health_check" "grpc_healthcheck" {
  provider = google-beta
  project  = var.project_id

  for_each    = var.application_map
  name        = "${local.prefix}-${each.key}-grpc-hc"
  description = "Health check via grpc for the backend service."

  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  grpc_health_check {
    port               = local.grpc_hc_port
    port_specification = "USE_FIXED_PORT"
  }

  log_config { enable = true }
}

# Create a backend service resource per application.
resource "google_compute_backend_service" "default" {
  provider = google-beta
  project  = var.project_id

  for_each = var.application_map
  name     = "${local.prefix}-${each.key}-be"

  port_name   = local.service_port_name
  protocol    = var.application_map[each.key].protocol
  timeout_sec = var.application_map[each.key].backend_service_timeout
  description = lookup(each.value, "description", null)
  health_checks = lookup(
    {
      "grpc" = [google_compute_health_check.grpc_healthcheck[each.key].self_link],
      "http" = [google_compute_health_check.http_healthcheck[each.key].self_link],
      "tcp"  = [google_compute_health_check.tcp_healthcheck[each.key].self_link]
    },
    var.healthcheck_type
  )

  backend {
    group = module.migs.mig_map[each.key].instance_group
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  dynamic "iap" {
    for_each = lookup(lookup(var.application_map[each.key], "iap_config", {}), "enable", false) ? [1] : []
    content {
      oauth2_client_id     = lookup(lookup(var.application_map[each.key], "iap_config", {}), "oauth2_client_id", "")
      oauth2_client_secret = lookup(lookup(var.application_map[each.key], "iap_config", {}), "oauth2_client_secret", "")
    }
  }

  depends_on = [
    google_compute_health_check.grpc_healthcheck,
    google_compute_health_check.http_healthcheck,
    google_compute_health_check.tcp_healthcheck,
    module.migs,
    module.networking
  ]
}

# Add IAP TCP IAM bindings for the instances created.
module "iam" {
  source          = "./modules/iam"
  project_id      = var.project_id
  application_map = var.application_map
}

# Add connection config files in connector storage buckets per associated application.
module "storage" {
  source           = "./modules/storage"
  project_id       = var.project_id
  application_map  = var.application_map
  prefix           = local.prefix
  tunnel_port      = local.tunnel_port
  tunnel_interface = "nic0"
  tunnels_per_gw   = var.tunnels_per_gw
}
