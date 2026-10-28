// Copyright 2026 The Cobalt Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef COBALT_BROWSER_PROXY_SERVER_SUPPORT_H_
#define COBALT_BROWSER_PROXY_SERVER_SUPPORT_H_

#include <optional>

#include "base/command_line.h"
#include "net/proxy_resolution/proxy_config_with_annotation.h"

namespace network {
namespace mojom {
class NetworkContextParams;
}  // namespace mojom
}  // namespace network

namespace cobalt {
namespace browser {

// Builds a proxy configuration from the command line switches
// --proxy-server (or its legacy alias --proxy), --proxy-bypass-list and
// --proxy-pac-url. Returns nullopt when no proxy was requested.
std::optional<net::ProxyConfigWithAnnotation> GetProxyConfigFromCommandLine(
    const base::CommandLine& command_line);

// Parses proxy configuration from the command line and sets it on the
// NetworkContextParams. This is used by release builds as well, so users can
// configure a proxy for an installed app.
void ConfigureProxyFromCommandLineIfNeeded(
    network::mojom::NetworkContextParams* network_context_params);

}  // namespace browser
}  // namespace cobalt

#endif  // COBALT_BROWSER_PROXY_SERVER_SUPPORT_H_
