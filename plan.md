# Mission Planning Refactor Plan

## Goal

Make mission planning safe, maintainable, and ready for multiple drones.

Key rules:

- Mission and fly state must belong to the correct drone.
- The map should mostly render state and emit user actions.
- All drone missions should eventually be visible at once.
- Selected drone missions should be prominent; other drone missions should be subdued.
- Avoid temporary adapter layers when UI can call the new model/controller directly.

---

## Progress Checklist

### Current foundation

- [x] Add MAVSDK mission upload/start/pause/clear/download backend.
- [x] Render mission waypoints and route on the map.
- [x] Add waypoint edit tools: add/select/drag/insert/delete/clear.
- [x] Add waypoint inspector/config editing.
- [x] Add mission overlay actions: upload/download/start/pause/clear.
- [x] Add local mission draft save/load/delete.
- [x] Add guided/fly commands: Go Here, Look Here, Set/Move Home.
- [x] Add `DroneMissionController` and move MAVSDK mission backend out of `DroneManager`.
- [x] Add first `MissionPlanModel` and move core mission item mutation/validation/distance logic out of `MapPanel.qml`.
- [x] Run `just format`.
- [x] Run `just build`.
- [x] Run `just lint`.

### Safety and per-drone state

- [x] Track mission operation state by drone in `MapPanel.qml` as an interim safety step.
- [x] Ensure mission async results are applied to the originating drone state, not blindly to the selected drone.
- [x] Do not clear local mission until drone clear succeeds.
- [x] Use mission plan signatures to detect uploaded/current plan mismatch.
- [ ] Move mission status/busy/uploaded/running/paused/error state fully out of `MapPanel.qml`.
- [ ] Expose mission state through a per-drone controller/property.
- [ ] Make selected-drone switching load that drone's own plan and mission state.
- [ ] Add explicit operation ids in the C++ mission controller/state layer.

### Mission plan model

- [x] Create `MissionPlanModel`.
- [x] Move add/insert/move/delete/clear waypoint operations into it.
- [x] Move selected waypoint field edits into it.
- [x] Move upload validation into it.
- [x] Move distance calculation into it.
- [x] Add plan signature.
- [ ] Add explicit serialization/deserialization API.
- [ ] Add stable version/hash separate from display JSON.
- [x] Attach one `MissionPlanModel` to each drone.
- [ ] Keep/view plans for non-selected drones without re-downloading.

### Multi-drone mission display

- [ ] Build a map-facing list/model of visible mission plans.
- [ ] Render all drone mission plans at once.
- [ ] Assign distinct colors per drone.
- [ ] Render unselected drone missions with lower opacity/smaller/subdued markers.
- [ ] Keep selected drone mission prominent and editable.
- [ ] Prevent editing non-selected drone plans unless explicitly selected or confirmed.

### Unified map targets

- [ ] Define one map target concept for mission waypoints, insert handles, Go, Look, and Home.
- [ ] Add owner drone uid to every target.
- [ ] Render generic target layers instead of duplicated mission/fly target layers.
- [ ] Hit-test generic targets in `MapInteractionArea.qml`.
- [ ] Emit generic target clicked/moved/dragged events.
- [ ] Route target events to the right mission/fly/home controller.

### Guided/fly command cleanup

- [ ] Move Go/Look/Home target state out of `MapPanel.qml`.
- [ ] Store Go/Look/Home targets per drone.
- [ ] Preserve home altitude correctly when moving home.
- [ ] Add safe operation ownership for `goToLocation`/home commands.
- [ ] Use unified map targets for Go/Look/Home.

### MapPanel cleanup

- [ ] Remove remaining mission business logic from `MapPanel.qml`.
- [ ] Remove fly target business logic from `MapPanel.qml`.
- [ ] Split overlays into components:
  - [ ] `MissionOverlay.qml`
  - [ ] `MissionLibraryPanel.qml`
  - [ ] `WaypointInspector.qml`
  - [ ] `WaypointConfigPanel.qml`
  - [ ] `FlyTargetOverlay.qml`
  - [ ] `MapContextMenu.qml`

### Later mission features

- [ ] Add explicit command types: waypoint, takeoff, land, loiter, ROI/look-at, final action.
- [ ] Clarify altitude reference: relative/home/MSL.
- [ ] Improve mission progress highlighting.
- [ ] Improve upload/download reconciliation.
- [ ] Add import/export JSON files.
- [ ] Later: QGroundControl `.plan` import/export.
- [ ] Later: survey/geofence/rally tools.

---

## Current Status

The code is now in a good intermediate state:

- MAVSDK mission logic is separated into `DroneMissionController`.
- Editable mission item logic is started in `MissionPlanModel`.
- `MapPanel.qml` still owns too much per-drone state and UI workflow, but less mission mutation logic than before.
- Multi-drone mission rendering is not implemented yet.

Known lint warnings that remain:

- `DroneManager::setupTelemetry()` cognitive complexity.
- `DroneManager::teardownTelemetry()` cognitive complexity.

---

## Next Step

Attach a `MissionPlanModel` to each `DroneManager`.

Why this next:

- It is the missing data shape for showing all missions at once.
- It lets each drone keep its own draft/current plan.
- It reduces selected-drone state leakage.
- It prepares the map to render `SwarmManager.droneList[*].missionPlan.items`.

Concrete next tasks:

- [x] Add `Q_PROPERTY(MissionPlanModel* missionPlan READ missionPlan CONSTANT)` to `DroneManager`.
- [x] Own one `MissionPlanModel` inside each `DroneManager`.
- [x] Update `MapPanel.qml` to use `selectedDrone.missionPlan` instead of one panel-level `MissionPlanModel`.
- [x] Keep upload/start/clear behavior working with the selected drone's plan.
- [x] Do not render all missions yet; just get per-drone plans working safely first.

Next concrete tasks:

- [ ] Move mission status/busy/uploaded/running/paused/error state from `MapPanel.qml` into a per-drone mission state object.
- [ ] Expose that state through `DroneManager` or `DroneMissionController`.
- [ ] Remove the interim `missionStateByDrone` JavaScript map from `MapPanel.qml`.
