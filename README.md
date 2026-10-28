# 💠 TizenTube Cobalt

<p align="center">
    <img width="600px" src=".github/assets/TizenTube Cobalt Banner.png">
    <br>
</p>

**TizenTube Cobalt** is an app based on [Cobalt](https://cobalt.dev) that enhances your favourite streaming website viewing experience by removing ads, adding [SponsorBlock](https://sponsor.ajay.app/) support, and providing useful features like video speed control.

<details>
<summary><strong>What is Cobalt?</strong></summary>

Cobalt is a lightweight, cross-platform application container and runtime for HTML5-based apps, originally developed by Google for embedded and resource-constrained devices (like smart TVs, set-top boxes, and game consoles). It implements a subset of the W3C HTML5 standard and runs web apps with high performance on a wide range of hardware.

</details>

## ✨ Features

- 🛑 **Ad Blocker**: Enjoy your favourite streaming website without interruptions from ads.
- ❗ **SponsorBlock Support**: Automatically skip sponsored segments in videos.
- ⏭️ **Video Speed Control**: Adjust playback speed to your preference.
- 🔺 **[DeArrow](https://dearrow.ajay.app/) Support**: Remove clickbait and misleading video titles.
- 🌐 **HTTP Proxy Support**: Use the proxy configured in your device's network settings, or an explicit proxy passed to QA/devel builds.
- ➕ **More to come!** Request features via [issues](https://github.com/reisxd/TizenTube/issues/new).

## ⬇️ Download

Get the latest release for your platform:

<p align="left">
    <a href="https://github.com/reisxd/TizenTubeCobalt/releases/latest">
        <picture>
            <img width="250px"
                src=".github/assets/TizenTube Download Latest Release Button.png" />
        </picture>
    </a>
</p>


**AFTVNews code:** `6366500`
> 💡 For a better experience, preferably use TizenTube Cobalt on a [**Google TV certified device.**](https://www.androidtv-guide.com/)

## ❓ How to Install

1. Download the latest release from the link above.
2. Sideload or install the app on your device (using a file manager, ADB, or platform-specific method).
3. Open the app and enjoy an enhanced streaming experience!

## 🌐 HTTP Proxy

TizenTube Cobalt uses the HTTP proxy configured for the active network in the
device's network settings. On Android TV, this is usually found under
**Settings → Network & Internet → (network) → Proxy**. Fixed HTTP proxies, PAC
scripts and bypass lists are supported. Restart the app after changing the
network proxy.

When running a QA or devel build, you can override the system proxy from the
command line:

```sh
--proxy-server=proxy.example.com:8080
--proxy-bypass-list=localhost;*.example.com
# Or use a PAC script instead of a fixed proxy:
--proxy-pac-url=https://proxy.example.com/proxy.pac
```

The `--proxy` flag is accepted as a legacy alias for `--proxy-server`.

## 🌐 Community & Support

| Links |
| ------------- |
| [r/TizenTube Subreddit](https://www.reddit.com/r/TizenTube/)  |
| [Discord Server](https://discord.gg/m2P7v8Y2qR)  | 
| [Telegram](https://t.me/tizentubeofficial)  |
| [Matrix Space](https://matrix.to/#/!BLE5ubNYktI30e8K0j:matrix.6513006.xyz)  |
| [Report Issues / Request Features](https://github.com/reisxd/tizenTubeCobalt/issues)  |
