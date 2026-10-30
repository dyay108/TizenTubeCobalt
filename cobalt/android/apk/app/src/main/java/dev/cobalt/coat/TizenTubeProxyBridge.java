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

import dev.cobalt.coat.javabridge.CobaltJavaScriptAndroidObject;
import dev.cobalt.coat.javabridge.CobaltJavaScriptInterface;

/** JavaScript bridge used by the TizenTube settings proxy entry. */
public final class TizenTubeProxyBridge implements CobaltJavaScriptAndroidObject {
  private final CobaltActivity mActivity;

  public TizenTubeProxyBridge(CobaltActivity activity) {
    mActivity = activity;
  }

  @Override
  public String getJavaScriptInterfaceName() {
    return "TizenTubeProxy";
  }

  @CobaltJavaScriptInterface
  public String getProxy() {
    return ProxySettings.get(mActivity);
  }

  @CobaltJavaScriptInterface
  public void openSettings() {
    mActivity.runOnUiThread(mActivity::showProxySettingsDialog);
  }

  @CobaltJavaScriptInterface
  public String testProxy(String proxy) {
    return ProxySettings.test(proxy);
  }

  @CobaltJavaScriptInterface
  public boolean saveProxy(String proxy) {
    String normalized = ProxySettings.normalize(proxy);
    if (normalized == null) {
      return false;
    }
    ProxySettings.save(mActivity, normalized);
    return true;
  }
}
