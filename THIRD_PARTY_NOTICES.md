# Third-Party Notices

GroundControl is licensed under the GNU Affero General Public License version 3. The license for GroundControl does not replace the licenses and copyright notices of the third-party components listed below.

## Components included or linked by GroundControl

### KDDockWidgets

- Copyright: Klarälvdalens Datakonsult AB (KDAB) and contributors
- Upstream: <https://github.com/KDAB/KDDockWidgets>
- Version used: v2.4.0, pinned as a Git submodule
- License option used by GroundControl: GNU GPL version 3 only
- License copies: `LICENSES/GPL-2.0-or-GPL-3.0-KDDockWidgets.txt` and `LICENSES/GPL-3.0-only.txt`
- Source: `third_party/KDDockWidgets`

KDDockWidgets also contains permissively licensed third-party code documented in `third_party/KDDockWidgets/3RDPARTY.md`.

### MAVSDK

- Copyright: 2016-2023 MAVSDK Development Team and contributors
- Upstream: <https://github.com/mavlink/MAVSDK>
- Revision used: `5518b8cd38b0e24ff4a8feb8b1b5c9d40ce083e6`, pinned as a Git submodule
- License: BSD 3-Clause
- License copy: `LICENSES/BSD-3-Clause-MAVSDK.txt`
- Source: `third_party/MAVSDK`

MAVSDK's nested MAVSDK-Proto dependency is included in the recursive submodule checkout and carries its own notices in that source tree.

### KDE Breeze Icons

- Copyright: 2014 Uri Herrera and other Breeze contributors
- Upstream: <https://github.com/KDE/breeze-icons>
- License: GNU LGPL version 3 or, at your option, any later version, with the artwork-library clarification supplied by the authors
- License and clarification: `LICENSES/LGPL-3.0-or-later-Breeze-icons.txt`
- Source artwork: `third_party/breeze-icons`

### QMapLibre and MapLibre Native

- Copyright: MapLibre contributors and other copyright holders identified in the supplied notices
- Upstreams: <https://github.com/maplibre/maplibre-native-qt> and <https://github.com/maplibre/maplibre-native>
- QMapLibre license: BSD 2-Clause
- MapLibre Native and bundled-component licenses: BSD 2-Clause and the other permissive licenses identified in `LICENSES/MapLibre-Native-Third-Party-Licenses.md`
- License copies: `LICENSES/BSD-2-Clause-QMapLibre.txt` and `LICENSES/MapLibre-Native-Third-Party-Licenses.md`
- Prebuilt artifacts: `third_party/maplibre-prebuilt`

### Ultralytics and YOLO model weights

- Copyright: Ultralytics and contributors
- Upstream: <https://github.com/ultralytics/ultralytics>
- Locked package version: 8.4.70
- License: GNU Affero General Public License version 3, unless used under a separately purchased Ultralytics enterprise license
- License copy: `LICENSE`
- Integration: `src/Detection/detector.py`

The documented `just setup` command downloads the Python object-detection environment and model. Python packages downloaded by `uv` include their own license metadata and notices. The repository's YOLO weight files are used under the applicable Ultralytics model license.

## System/runtime dependencies

GroundControl also uses Qt 6 and GStreamer supplied by the user's system or platform package manager. Their exact license terms depend on the modules and plugins installed. Open-source Qt is generally offered under LGPLv3/GPLv3 terms, and GStreamer core and many plugins are LGPL-licensed; individual GStreamer plugins may use different licenses. Distributors must audit the exact binaries and plugins they ship.

## Corresponding source

The preferred form for modifying GroundControl, its build scripts, and its pinned source submodules is available from:

<https://github.com/ORAO-AVIATION-IUS/GroundControl>

A distributor of GroundControl binaries must provide Corresponding Source in a manner permitted by AGPLv3 section 6 and preserve all applicable third-party notices.
