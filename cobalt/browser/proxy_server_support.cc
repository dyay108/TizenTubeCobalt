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

#include "cobalt/browser/proxy_server_support.h"

#include <optional>
#include <string>
#include <utility>

#include "base/command_line.h"
#include "base/logging.h"
#include "cobalt/browser/switches.h"
#include "net/proxy_resolution/proxy_config.h"
#include "net/traffic_annotation/network_traffic_annotation.h"
#include "services/network/public/mojom/network_context.mojom.h"
#include "url/gurl.h"

namespace cobalt {
namespace browser {
namespace {

// Kept as an alias so existing QA scripts using --proxy keep working.
constexpr char kLegacyProxySwitch[] = "proxy";

net::NetworkTrafficAnnotationTag ProxyTrafficAnnotation() {
  return net::DefineNetworkTrafficAnnotation(
      "cobalt_manual_proxy",
      "Routes app traffic through a proxy configured by the user.");
}

}  // namespace

std::optional<net::ProxyConfigWithAnnotation> GetProxyConfigFromCommandLine(
    const base::CommandLine& command_line) {
  const std::string pac_url =
      command_line.GetSwitchValueASCII(switches::kProxyPacUrl);
  if (!pac_url.empty()) {
    GURL parsed_pac_url(pac_url);
    if (parsed_pac_url.is_valid()) {
      net::ProxyConfig proxy_config;
      proxy_config.set_pac_url(parsed_pac_url);
      proxy_config.set_pac_mandatory(false);
      return net::ProxyConfigWithAnnotation(proxy_config,
                                            ProxyTrafficAnnotation());
    }

    LOG(WARNING) << "Ignoring invalid --" << switches::kProxyPacUrl << ": "
                 << pac_url;
  }

  std::string proxy_server =
      command_line.GetSwitchValueASCII(switches::kProxyServer);
  if (proxy_server.empty()) {
    proxy_server = command_line.GetSwitchValueASCII(kLegacyProxySwitch);
  }
  if (proxy_server.empty()) {
    return std::nullopt;
  }

  net::ProxyConfig proxy_config;
  proxy_config.proxy_rules().ParseFromString(proxy_server);
  const net::ProxyConfig::ProxyRules& proxy_rules = proxy_config.proxy_rules();
  if (proxy_rules.empty() || (proxy_rules.single_proxies.IsEmpty() &&
                              proxy_rules.proxies_for_http.IsEmpty() &&
                              proxy_rules.proxies_for_https.IsEmpty() &&
                              proxy_rules.proxies_for_ftp.IsEmpty() &&
                              proxy_rules.fallback_proxies.IsEmpty())) {
    LOG(WARNING) << "Ignoring invalid --" << switches::kProxyServer << ": "
                 << proxy_server;
    return std::nullopt;
  }

  if (command_line.HasSwitch(switches::kProxyBypassList)) {
    proxy_config.proxy_rules().bypass_rules.ParseFromString(
        command_line.GetSwitchValueASCII(switches::kProxyBypassList));
  }

  return net::ProxyConfigWithAnnotation(proxy_config, ProxyTrafficAnnotation());
}

void ConfigureProxyFromCommandLineIfNeeded(
    network::mojom::NetworkContextParams* network_context_params) {
  const base::CommandLine& command_line =
      *base::CommandLine::ForCurrentProcess();
  std::optional<net::ProxyConfigWithAnnotation> proxy_config =
      GetProxyConfigFromCommandLine(command_line);
  if (!proxy_config.has_value()) {
    return;
  }

  if (proxy_config->value().has_pac_url()) {
    LOG(INFO) << "Configuring Cobalt to use the PAC proxy from the command "
                 "line";
  } else {
    LOG(INFO) << "Configuring Cobalt to use the proxy from the command line";
  }

  network_context_params->initial_proxy_config = std::move(*proxy_config);
}

}  // namespace browser
}  // namespace cobalt
