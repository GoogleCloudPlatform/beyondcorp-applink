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
  boot_disk = [
    {
      source_image = data.google_compute_image.image.self_link
      disk_size_gb = var.disk_size_gb
      disk_type    = var.disk_type
      auto_delete  = var.auto_delete
      boot         = "true"
    },
  ]
}

# Get the compute engine default service account.
# Used as the identity running the compute instances.
# Also used for fetching gateway docker image from gcr.
data "google_compute_default_service_account" "default" {
  project = var.project_id
}

# Handles the generation of metadata for deploying containers on GCE instances.
module "gce-container" {
  source = "terraform-google-modules/container-vm/google"
  container = {
    image = var.image,
    env = [
      {
        name  = "TUNNEL_ADDR"
        value = ":${var.tunnel_port}"
      },
      {
        name  = "USER_ADDR"
        value = ":${var.service_port}"
      }
    ],
  }
}

# Container-Optimized OS with the Applink Gateway docker image.
data "google_compute_image" "image" {
  project = "cos-cloud"
  name    = reverse(split("/", module.gce-container.source_image))[0]
}

# Create instance templates for use by the managed instance group instances.
resource "google_compute_instance_template" "instance_templates" {
  project  = var.project_id
  for_each = var.application_map

  name_prefix  = "${var.prefix}-${each.key}"
  machine_type = var.machine_type
  region       = var.application_map[each.key].region

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  dynamic "disk" {
    for_each = local.boot_disk
    content {
      auto_delete  = lookup(disk.value, "auto_delete", null)
      boot         = lookup(disk.value, "boot", null)
      device_name  = lookup(disk.value, "device_name", null)
      disk_name    = lookup(disk.value, "disk_name", null)
      disk_size_gb = lookup(disk.value, "disk_size_gb", null)
      disk_type    = lookup(disk.value, "disk_type", null)
      interface    = lookup(disk.value, "interface", null)
      mode         = lookup(disk.value, "mode", null)
      source       = lookup(disk.value, "source", null)
      source_image = lookup(disk.value, "source_image", null)
      type         = lookup(disk.value, "type", null)
    }
  }

  network_interface {
    subnetwork = var.subnetwork_map[each.key].name
  }

  metadata = merge(
    var.application_map[each.key].additional_metadata,
    {
      gce-container-declaration : module.gce-container.metadata_value
      # Stackdriver logging and monitoring.
      google-logging-enabled    = "true"
      google-monitoring-enabled = "true"
    }
  )
  tags = [
    var.target_tag, "http-server", "https-server"
  ]
  can_ip_forward = false
  labels = {
    "container-vm" = module.gce-container.vm_container_label
  }

  lifecycle {
    create_before_destroy = "true"
  }
}

# Create a regional MIG per backend_service_config.
resource "google_compute_region_instance_group_manager" "migs" {
  provider = google-beta
  project  = var.project_id
  for_each = var.application_map

  region             = var.application_map[each.key].region
  base_instance_name = "${var.prefix}-${each.key}-mig"
  name               = "${var.prefix}-${each.key}-mig"

  version {
    name              = "${var.prefix}-mig-version-0"
    instance_template = google_compute_instance_template.instance_templates[each.key].self_link
  }

  named_port {
    name = var.service_port_name
    port = var.service_port
  }

  target_size        = var.application_map[each.key].mig_instance_count
  wait_for_instances = true

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [distribution_policy_zones]
  }

  depends_on = [google_compute_instance_template.instance_templates]
}