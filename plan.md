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
- [x] Move mission status/busy/uploaded/running/paused/error state fully out of `MapPanel.qml`.
- [x] Expose mission state through a per-drone controller/property.
- [x] Make selected-drone switching load that drone's own plan and mission state.
- [x] Add explicit operation ids in the C++ mission controller/state layer.

### Mission plan model

- [x] Create `MissionPlanModel`.
- [x] Move add/insert/move/delete/clear waypoint operations into it.
- [x] Move selected waypoint field edits into it.
- [x] Move upload validation into it.
- [x] Move distance calculation into it.
- [x] Add plan signature.
- [x] Add explicit serialization/deserialization/store API.
- [x] Add versioned JSON documents for persisted/exported missions.
- [x] Attach one `MissionPlanModel` to each drone.
- [x] Keep/view plans for non-selected drones without re-downloading.

### Multi-drone mission display

- [x] Build a map-facing list/model of visible mission plans.
- [x] Render all drone mission plans at once.
- [x] Assign distinct colors per drone.
- [x] Render unselected drone missions with lower opacity/smaller/subdued markers.
- [x] Keep selected drone mission prominent and editable.
- [x] Prevent editing non-selected drone plans unless explicitly selected or confirmed.

### Unified map targets

- [x] Define one map target concept for mission waypoints, insert handles, Go, Look, and Home.
- [x] Add owner drone uid to every target.
- [x] Render generic target layers for point targets instead of duplicated point layers.
- [x] Hit-test generic targets in `MapInteractionArea.qml`.
- [ ] Emit fully generic target clicked/moved/dragged events.
- [x] Route current target events to the right mission/fly/home controller.

### Guided/fly command cleanup

- [x] Move Go/Look/Home target state out of `MapPanel.qml`.
- [x] Store Go/Look/Home targets per drone.
- [x] Preserve home altitude correctly when moving home.
- [x] Add safe operation ownership for `goToLocation`/home commands.
- [x] Use unified map targets for Go/Look/Home.

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

- [x] Add explicit basic command types: waypoint, takeoff, land.
- [x] Clarify initial altitude reference in mission items: relative.
- [x] Improve mission progress highlighting across rendered plans.
- [x] Improve upload/download reconciliation with operation ids/signatures.
- [x] Add import/export JSON files.
- [ ] Later: ROI/look-at/final action command UI.
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

- None from project code after the latest pass; third-party warnings are suppressed by tooling.

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

- [x] Move mission status/busy/uploaded/running/paused/error state from `MapPanel.qml` into a per-drone mission state object.
- [x] Expose that state through `DroneManager` or `DroneMissionController`.
- [x] Remove the interim `missionStateByDrone` JavaScript map from `MapPanel.qml`.

Next concrete tasks:

- [x] Add explicit monotonically increasing operation ids in `DroneMissionController`.
- [x] Ignore stale MAVSDK async callbacks whose operation id is no longer current.
- [x] Build the all-drone mission rendering data path.
- [ ] Manual test with one or more drones/SITL before further UI-only component extraction.
