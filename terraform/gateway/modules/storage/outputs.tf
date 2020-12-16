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

output "connections" {
  description = "Map from application keys to connector keys to it's gcs id."
  value = {
    for key in keys(google_storage_bucket_object.connections_folders) :
    split("_", key)[0] =>
    {
      "${split("_", key)[1]}" : "gs://${google_storage_bucket_object.connections_folders[key].bucket}/${google_storage_bucket_object.connections_folders[key].output_name}"
    }
  }
}