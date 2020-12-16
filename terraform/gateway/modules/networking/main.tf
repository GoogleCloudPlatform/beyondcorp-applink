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

# Create a network for use by BCE Applink.
resource "google_compute_network" "applink_net" {
  name = var.network
  # Auto created subnets do not have private_ip_google_access enabled.
  auto_create_subnetworks = "false"
}

# Create a subnet per application for use by BCE Applink.
resource "google_compute_subnetwork" "applink_subnet" {
  for_each      = var.application_map
  name          = "bce-applink-subnet-${each.key}"
  ip_cidr_range = var.application_map[each.key].subnetwork_cidr
  network       = google_compute_network.applink_net.self_link
  region        = var.application_map[each.key].region
  # Needed for gcr access in the absence of public IP.
  private_ip_google_access = true
}

# Open firewall to allow ingress from IAP TCP ip range.
resource "google_compute_firewall" "allow_ingress_from_iap_tcp" {
  name          = "${var.prefix}-allow-ingress-from-iap-tcp"
  project       = var.project_id
  network       = google_compute_network.applink_net.self_link
  source_ranges = ["35.235.240.0/20"]
  target_tags   = [var.target_tag]
  direction     = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = var.request_gw_ports
  }
}

# Open firewall to allow ingress from IAP web.
resource "google_compute_firewall" "allow_ingress_from_iap" {
  name    = "${var.prefix}-allow-ingress-from-iap"
  project = var.project_id
  network = google_compute_network.applink_net.self_link
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  target_tags = [var.target_tag]

  allow {
    protocol = "tcp"
    ports    = [var.service_port, var.grpc_hc_port]
  }
}