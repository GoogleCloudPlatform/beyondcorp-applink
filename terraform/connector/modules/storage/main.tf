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
  # Create yaml encoded config files for connector.
  service-account-config-map = {
    for sa in keys(var.connector_map) : sa => templatefile("${path.module}/../templates/connector_config.tmpl", {
      project_id              = var.project_id
      service_account         = var.connector_map[sa].service_account_email
      pubsub_topic            = var.connector_pubsub_map[sa].topic
      pubsub_subscription     = var.connector_pubsub_map[sa].subscription
      bucket_url              = google_storage_bucket.buckets[sa].url
      config_folder_link      = google_storage_bucket_object.config_folders[sa].self_link
      connections_folder_link = google_storage_bucket_object.connections_folders[sa].self_link
      logs_folder_link        = google_storage_bucket_object.logs_folders[sa].self_link
      additional_metadata     = var.connector_map[sa].additional_metadata
    })
  }
}

# For fetching project_number
data "google_project" "project" {
  project_id = var.project_id
}

# SETUP storage buckets.

# Storage bucket per connector.
resource "google_storage_bucket" "buckets" {
  project                     = var.project_id
  for_each                    = var.connector_map
  name                        = "${data.google_project.project.number}-connector-${each.key}"
  uniform_bucket_level_access = true
}

# Config folder inside the bucket.
resource "google_storage_bucket_object" "config_folders" {
  for_each = var.connector_map
  bucket   = google_storage_bucket.buckets[each.key].name
  name     = "config/" # Declaring an object with a trailing '/' creates a directory
  content  = "foo"     # Note that the content string isn't actually used, but is only there since the resource requires it
}
# logs folder inside the bucket.
resource "google_storage_bucket_object" "logs_folders" {
  for_each = var.connector_map
  bucket   = google_storage_bucket.buckets[each.key].name
  name     = "logs/" # Declaring an object with a trailing '/' creates a directory
  content  = "foo"   # Note that the content string isn't actually used, but is only there since the resource requires it
}
# connections folder inside the bucket.
resource "google_storage_bucket_object" "connections_folders" {
  for_each = var.connector_map
  bucket   = google_storage_bucket.buckets[each.key].name
  name     = "connections/" # Declaring an object with a trailing '/' creates a directory
  content  = "foo"          # Note that the content string isn't actually used, but is only there since the resource requires it
}

# Grant SA IAM role for full control over objects, including listing, creating, viewing, and deleting objects.
resource "google_storage_bucket_iam_member" "bucket_iam" {
  for_each   = var.connector_map
  bucket     = google_storage_bucket.buckets[each.key].name
  role       = "roles/storage.objectAdmin"
  member     = format("serviceAccount:%s", var.connector_map[each.key].service_account_email)
  depends_on = [var.sa_depends_on]
}

# Upload initial config file needed by connector for being controlled remotely via pubsub.
resource "google_storage_bucket_object" "connector_config_file" {
  for_each = var.connector_map
  name     = "config/init-config.yaml"
  content  = local.service-account-config-map[each.key]
  bucket   = google_storage_bucket.buckets[each.key].name
}

# Storage buckets SETUP complete.
