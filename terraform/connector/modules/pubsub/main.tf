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

# SETUP PUBSUB

# Pubsub topic per connector.
resource "google_pubsub_topic" "connector_topic" {
  project  = var.project_id
  for_each = var.connector_map
  name     = "connector-${each.key}"
}

# Grant viewer role to the connector SA.
resource "google_pubsub_topic_iam_member" "connector_member" {
  project    = var.project_id
  for_each   = var.connector_map
  topic      = google_pubsub_topic.connector_topic[each.key].name
  role       = "roles/viewer"
  member     = format("serviceAccount:%s", var.connector_map[each.key].service_account_email)
  depends_on = [var.sa_depends_on]
}

# Subscription to the topic for the connector.
resource "google_pubsub_subscription" "connector_subscription" {
  project  = var.project_id
  for_each = var.connector_map
  name     = "connector-${each.key}"
  topic    = google_pubsub_topic.connector_topic[each.key].name
}