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

package dev.cobalt.coat;

import android.content.Context;
import android.content.SharedPreferences;
import androidx.annotation.Nullable;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.net.URI;
import java.net.URL;

/** Stores and validates the optional proxy used only by this application. */
final class ProxySettings {
  private static final String PREFS_NAME = "tizentube_proxy";
  private static final String PROXY_KEY = "proxy";
  private static final String TEST_URL = "https://www.youtube.com/generate_204";

  private ProxySettings() {}

  @Nullable
  static String get(Context context) {
    return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        .getString(PROXY_KEY, "");
  }

  static void save(Context context, String proxy) {
    SharedPreferences preferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    if (proxy.isEmpty()) {
      preferences.edit().remove(PROXY_KEY).apply();
    } else {
      preferences.edit().putString(PROXY_KEY, proxy).apply();
    }
  }

  /**
   * Accepts host:port or an http(s):// URL and returns a normalized host:port value.
   *
   * @return the normalized proxy, an empty string to clear it, or {@code null} if invalid.
   */
  @Nullable
  static String normalize(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    if (trimmed.isEmpty()) {
      return "";
    }

    String parseable = trimmed;
    if (!parseable.contains("://")) {
      parseable = "http://" + parseable;
    }

    URI uri;
    try {
      uri = URI.create(parseable);
    } catch (IllegalArgumentException e) {
      return null;
    }

    String host = uri.getHost();
    int port = uri.getPort();
    if (host == null || host.isEmpty() || port <= 0 || port > 0xFFFF) {
      return null;
    }
    if (uri.getUserInfo() != null) {
      return null;
    }

    if (host.startsWith("[") && host.endsWith("]")) {
      host = host.substring(1, host.length() - 1);
    }
    if (host.indexOf(':') >= 0) {
      host = "[" + host + "]";
    }
    return host + ":" + port;
  }

  @Nullable
  static String test(String value) {
    String normalized = normalize(value);
    if (normalized == null) {
      return "Invalid proxy. Use host:port.";
    }
    if (normalized.isEmpty()) {
      return "Enter a proxy address.";
    }

    URI uri = URI.create("http://" + normalized);
    String host = uri.getHost();
    int port = uri.getPort();
    if (host == null || port <= 0) {
      return "Invalid proxy. Use host:port.";
    }

    long start = System.currentTimeMillis();
    HttpURLConnection connection = null;
    try {
      Proxy proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress(host, port));
      connection = (HttpURLConnection) new URL(TEST_URL).openConnection(proxy);
      connection.setConnectTimeout(5000);
      connection.setReadTimeout(5000);
      connection.setInstanceFollowRedirects(false);
      connection.setRequestProperty("Cache-Control", "no-cache");
      int status = connection.getResponseCode();
      long elapsed = System.currentTimeMillis() - start;
      return "HTTP " + status + " in " + elapsed + " ms";
    } catch (IOException e) {
      return "Failed: " + e.getMessage();
    } finally {
      if (connection != null) {
        connection.disconnect();
      }
    }
  }
}
