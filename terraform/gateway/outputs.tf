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

output "application_info" {
  description = "Map from application keys to it's relevant information."
  value = { for key in keys(google_compute_backend_service.default) :
    key =>
    {
      backend_service : google_compute_backend_service.default[key].self_link
      backend_service_name : google_compute_backend_service.default[key].name
    }
  }
}

output "connections" {
  value = module.storage.connections
}