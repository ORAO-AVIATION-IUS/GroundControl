pragma ComponentBehavior: Bound

import QtPositioning
import QtQml

QtObject {
	id: root

	readonly property var emptyFeatureCollection: ({
			"type": "FeatureCollection",
			"features": []
		})

	function coordinateFor(drone) {
		if (!drone)
			return null;
		return QtPositioning.coordinate(drone.latitude, drone.longitude);
	}

	function hasPosition(drone) {
		return drone && (drone.latitude !== 0 || drone.longitude !== 0);
	}

	function featureCollection(features) {
		return {
			"type": "FeatureCollection",
			"features": features
		};
	}

	function polygonFeature(ring, properties) {
		return {
			"type": "Feature",
			"properties": properties || {},
			"geometry": {
				"type": "Polygon",
				"coordinates": [ring]
			}
		};
	}

	function offset(c, alongM, perpM, hdg) {
		const d = Math.sqrt(alongM * alongM + perpM * perpM);
		if (d === 0)
			return c;
		const a = Math.atan2(perpM, alongM) * 180 / Math.PI;
		return c.atDistanceAndAzimuth(d, hdg + a);
	}

	function polyRect(c, halfA, halfP, hdg) {
		const p1 = offset(c, halfA, halfP, hdg);
		const p2 = offset(c, halfA, -halfP, hdg);
		const p3 = offset(c, -halfA, -halfP, hdg);
		const p4 = offset(c, -halfA, halfP, hdg);
		return [[p1.longitude, p1.latitude], [p2.longitude, p2.latitude], [p3.longitude, p3.latitude], [p4.longitude, p4.latitude], [p1.longitude, p1.latitude]];
	}

	function circleRing(c, radiusM, steps) {
		const ring = [];
		for (let i = 0; i <= steps; ++i) {
			const p = c.atDistanceAndAzimuth(radiusM, i * 360 / steps);
			ring.push([p.longitude, p.latitude]);
		}
		return ring;
	}

	function segmentRect(a, b, halfWidthM) {
		const distance = a.distanceTo(b);
		if (distance <= 0.1)
			return [];
		const bearing = a.azimuthTo(b);
		const p1 = a.atDistanceAndAzimuth(halfWidthM, bearing + 90);
		const p2 = b.atDistanceAndAzimuth(halfWidthM, bearing + 90);
		const p3 = b.atDistanceAndAzimuth(halfWidthM, bearing - 90);
		const p4 = a.atDistanceAndAzimuth(halfWidthM, bearing - 90);
		return [[p1.longitude, p1.latitude], [p2.longitude, p2.latitude], [p3.longitude, p3.latitude], [p4.longitude, p4.latitude], [p1.longitude, p1.latitude]];
	}

	function droneBodyGeoJson(drones, revision) {
		void revision;
		const features = [];
		for (let i = 0; i < (drones || []).length; ++i) {
			const drone = drones[i];
			if (!hasPosition(drone))
				continue;
			const c = coordinateFor(drone);
			const hdg = drone.heading || 0;
			const alt = drone.altitude || 0;
			const props = {
				"base": alt,
				"height": alt + 1.67
			};
			features.push(polygonFeature(polyRect(c, 6, 0.67, hdg), props));
			features.push(polygonFeature(polyRect(c, 0.67, 6, hdg), props));
			features.push(polygonFeature(polyRect(c, 2, 2, hdg), props));
		}
		return featureCollection(features);
	}

	function rotorGeoJson(drones, revision) {
		void revision;
		const features = [];
		for (let i = 0; i < (drones || []).length; ++i) {
			const drone = drones[i];
			if (!hasPosition(drone))
				continue;
			const c = coordinateFor(drone);
			const hdg = drone.heading || 0;
			const alt = drone.altitude || 0;
			const props = {
				"base": alt + 1,
				"height": alt + 2.33
			};
			const ring = function (alongM, perpM) {
				return polyRect(offset(c, alongM, perpM, hdg), 1.33, 1.33, hdg);
			};
			features.push(polygonFeature(ring(7.33, 0), props));
			features.push(polygonFeature(ring(-7.33, 0), props));
			features.push(polygonFeature(ring(0, 7.33), props));
			features.push(polygonFeature(ring(0, -7.33), props));
		}
		return featureCollection(features);
	}

	function tetherSegmentsGeoJson(drones, revision) {
		void revision;
		const features = [];
		const pitch = 25;
		const onLength = 18;
		for (let i = 0; i < (drones || []).length; ++i) {
			const drone = drones[i];
			if (!hasPosition(drone) || (drone.altitude || 0) <= 0)
				continue;
			const poly = polyRect(coordinateFor(drone), 0.83, 0.83, 0);
			const altitude = drone.altitude;
			for (let base = 0; base < altitude; base += pitch) {
				const top = Math.min(base + onLength, altitude);
				if (top - base < 2)
					break;
				features.push(polygonFeature(poly, {
					"base": base,
					"height": top
				}));
			}
		}
		return featureCollection(features);
	}

	function groundMarkerGeoJson(drones, selectedUid, zoomLevel, revision) {
		void revision;
		const features = [];
		for (let i = 0; i < (drones || []).length; ++i) {
			const drone = drones[i];
			if (!hasPosition(drone))
				continue;
			const c = coordinateFor(drone);
			const hdg = drone.heading || 0;
			const selected = drone.droneUid === selectedUid;
			const z = zoomLevel;
			const scale = z > 15 ? Math.pow(2, (18 - z) * 0.7) : Math.pow(2, 17.1 - z);
			const tip = c.atDistanceAndAzimuth(6 * scale, hdg);
			const bl = c.atDistanceAndAzimuth(4.8 * scale, hdg + 140);
			const br = c.atDistanceAndAzimuth(4.8 * scale, hdg - 140);
			const ring = [[tip.longitude, tip.latitude], [bl.longitude, bl.latitude], [br.longitude, br.latitude], [tip.longitude, tip.latitude]];
			features.push(polygonFeature(ring, {
				"fill": selected ? "#ffaa00" : "#ff3030",
				"outlineWidth": Math.max(1, 3 / Math.sqrt(scale))
			}));
		}
		return featureCollection(features);
	}

	function flightPathGeoJson(paths) {
		const features = [];
		for (let i = 0; i < (paths || []).length; ++i) {
			const path = paths[i];
			if (!path || path.length < 2)
				continue;
			const coords = [];
			for (let j = 0; j < path.length; ++j)
				coords.push([path[j].longitude, path[j].latitude]);
			features.push({
				"type": "Feature",
				"geometry": {
					"type": "LineString",
					"coordinates": coords
				}
			});
		}
		return featureCollection(features);
	}

	function missionPathGeoJson(items, revision) {
		void revision;
		if (!items || items.length < 2)
			return emptyFeatureCollection;
		const coords = [];
		for (let i = 0; i < items.length; ++i) {
			if (!items[i])
				continue;
			coords.push([items[i].longitude, items[i].latitude]);
		}
		if (coords.length < 2)
			return emptyFeatureCollection;
		return featureCollection([
			{
				"type": "Feature",
				"geometry": {
					"type": "LineString",
					"coordinates": coords
				}
			}
		]);
	}

	function missionInsertHandleGeoJson(items, visible, revision) {
		void revision;
		if (!visible || !items || items.length < 2)
			return emptyFeatureCollection;
		const features = [];
		for (let i = 0; i < items.length - 1; ++i) {
			const aItem = items[i];
			const bItem = items[i + 1];
			if (!aItem || !bItem)
				continue;
			const a = QtPositioning.coordinate(aItem.latitude, aItem.longitude);
			const b = QtPositioning.coordinate(bItem.latitude, bItem.longitude);
			const mid = a.atDistanceAndAzimuth(a.distanceTo(b) * 0.5, a.azimuthTo(b));
			features.push({
				"type": "Feature",
				"properties": {
					"segmentIndex": i,
					"label": "+"
				},
				"geometry": {
					"type": "Point",
					"coordinates": [mid.longitude, mid.latitude]
				}
			});
		}
		return featureCollection(features);
	}

	function missionInsertCrossGeoJson(items, visible, revision) {
		void revision;
		if (!visible || !items || items.length < 2)
			return emptyFeatureCollection;
		const features = [];
		for (let i = 0; i < items.length - 1; ++i) {
			const aItem = items[i];
			const bItem = items[i + 1];
			if (!aItem || !bItem)
				continue;
			const a = QtPositioning.coordinate(aItem.latitude, aItem.longitude);
			const b = QtPositioning.coordinate(bItem.latitude, bItem.longitude);
			const mid = a.atDistanceAndAzimuth(a.distanceTo(b) * 0.5, a.azimuthTo(b));
			const north = mid.atDistanceAndAzimuth(5, 0);
			const south = mid.atDistanceAndAzimuth(5, 180);
			const east = mid.atDistanceAndAzimuth(5, 90);
			const west = mid.atDistanceAndAzimuth(5, 270);
			features.push({
				"type": "Feature",
				"geometry": {
					"type": "LineString",
					"coordinates": [[south.longitude, south.latitude], [north.longitude, north.latitude]]
				}
			});
			features.push({
				"type": "Feature",
				"geometry": {
					"type": "LineString",
					"coordinates": [[west.longitude, west.latitude], [east.longitude, east.latitude]]
				}
			});
		}
		return featureCollection(features);
	}

	function missionWaypointGeoJson(items, selectedIndex, currentIndex, mapMode, revision) {
		void revision;
		const flyMode = mapMode === 2;
		const features = [];
		for (let i = 0; i < (items || []).length; ++i) {
			const item = items[i];
			if (!item)
				continue;
			const selected = !flyMode && i === selectedIndex;
			const current = currentIndex > 0 && i === currentIndex - 1;
			features.push({
				"type": "Feature",
				"properties": {
					"index": i,
					"label": String(i + 1),
					"selected": selected,
					"current": current,
					"fill": current ? "#ffaa00" : (selected ? "#ffaa00" : "#00d0ff"),
					"radius": flyMode ? (current ? 5 : 3.5) : (selected ? 8 : 6),
					"strokeWidth": flyMode ? 1.5 : (selected ? 3 : 2)
				},
				"geometry": {
					"type": "Point",
					"coordinates": [item.longitude, item.latitude]
				}
			});
		}
		return featureCollection(features);
	}

	function missionWaypointExtrusionGeoJson(items, revision) {
		void revision;
		const features = [];
		for (let i = 0; i < (items || []).length; ++i) {
			const item = items[i];
			if (!item)
				continue;
			const c = QtPositioning.coordinate(item.latitude, item.longitude);
			const alt = Math.max(0, item.altitude || 0);
			features.push(polygonFeature(circleRing(c, 3.5, 18), {
				"base": Math.max(0, alt - 1.5),
				"height": alt + 1.5
			}));
		}
		return featureCollection(features);
	}

	function missionTetherGeoJson(items, revision) {
		void revision;
		const features = [];
		for (let i = 0; i < (items || []).length; ++i) {
			const item = items[i];
			if (!item || (item.altitude || 0) <= 0)
				continue;
			const c = QtPositioning.coordinate(item.latitude, item.longitude);
			features.push(polygonFeature(circleRing(c, 1.1, 10), {
				"base": 0,
				"height": item.altitude
			}));
		}
		return featureCollection(features);
	}

	function missionSegmentExtrusionGeoJson(items, revision) {
		void revision;
		const features = [];
		const dashLengthM = 4;
		const gapLengthM = 9;
		for (let i = 1; i < (items || []).length; ++i) {
			const aItem = items[i - 1];
			const bItem = items[i];
			if (!aItem || !bItem)
				continue;
			const a = QtPositioning.coordinate(aItem.latitude, aItem.longitude);
			const b = QtPositioning.coordinate(bItem.latitude, bItem.longitude);
			const distance = a.distanceTo(b);
			if (distance <= 0.1)
				continue;
			const bearing = a.azimuthTo(b);
			const aAlt = Math.max(0, aItem.altitude || 0);
			const bAlt = Math.max(0, bItem.altitude || 0);
			for (let startM = 0; startM < distance; startM += dashLengthM + gapLengthM) {
				const endM = Math.min(startM + dashLengthM, distance);
				if (endM - startM < 1)
					continue;
				const start = a.atDistanceAndAzimuth(startM, bearing);
				const end = a.atDistanceAndAzimuth(endM, bearing);
				const ring = segmentRect(start, end, 0.9);
				if (ring.length === 0)
					continue;
				const midT = ((startM + endM) * 0.5) / distance;
				const alt = aAlt + (bAlt - aAlt) * midT;
				features.push(polygonFeature(ring, {
					"base": Math.max(0, alt - 0.35),
					"height": alt + 0.35
				}));
			}
		}
		return featureCollection(features);
	}

	function returnHomePathGeoJson(items, homeLatitude, homeLongitude, homeValid, enabled, revision) {
		void revision;
		if (!enabled || !homeValid || !items || items.length < 1)
			return emptyFeatureCollection;
		const last = items[items.length - 1];
		if (!last)
			return emptyFeatureCollection;
		return featureCollection([
			{
				"type": "Feature",
				"geometry": {
					"type": "LineString",
					"coordinates": [[last.longitude, last.latitude], [homeLongitude, homeLatitude]]
				}
			}
		]);
	}

	function returnHomeSegmentExtrusionGeoJson(items, homeLatitude, homeLongitude, homeValid, enabled, revision) {
		void revision;
		if (!enabled || !homeValid || !items || items.length < 1)
			return emptyFeatureCollection;
		const last = items[items.length - 1];
		if (!last)
			return emptyFeatureCollection;
		return missionSegmentExtrusionGeoJson([last,
			{
				"latitude": homeLatitude,
				"longitude": homeLongitude,
				"altitude": 0
			}
		], revision);
	}

	function multiMissionPathGeoJson(plans, revision) {
		void revision;
		const features = [];
		for (let p = 0; p < (plans || []).length; ++p) {
			const plan = plans[p];
			const items = plan && plan.items ? plan.items : [];
			if (items.length < 2)
				continue;
			const coords = [];
			for (let i = 0; i < items.length; ++i) {
				if (!items[i])
					continue;
				coords.push([items[i].longitude, items[i].latitude]);
			}
			if (coords.length < 2)
				continue;
			features.push({
				"type": "Feature",
				"properties": {
					"droneUid": plan.droneUid || -1,
					"color": plan.color || "#ff9d00",
					"opacity": plan.selected ? 0.92 : 0.36,
					"width": plan.selected ? 4 : 2.4
				},
				"geometry": {
					"type": "LineString",
					"coordinates": coords
				}
			});
		}
		return featureCollection(features);
	}

	function multiMissionWaypointGeoJson(plans, mapMode, revision) {
		void revision;
		const flyMode = mapMode === 2;
		const features = [];
		for (let p = 0; p < (plans || []).length; ++p) {
			const plan = plans[p];
			const items = plan && plan.items ? plan.items : [];
			const planSelected = plan && plan.selected === true;
			for (let i = 0; i < items.length; ++i) {
				const item = items[i];
				if (!item)
					continue;
				const selected = planSelected && !flyMode && i === plan.selectedIndex;
				const current = plan.currentIndex > 0 && i === plan.currentIndex - 1;
				features.push({
					"type": "Feature",
					"properties": {
						"droneUid": plan.droneUid || -1,
						"index": i,
						"label": String(i + 1),
						"selectedPlan": planSelected,
						"selected": selected,
						"current": current,
						"fill": current ? "#ffaa00" : (selected ? "#ffaa00" : (plan.color || "#00d0ff")),
						"radius": planSelected ? (flyMode ? (current ? 5 : 3.5) : (selected ? 8 : 6)) : 4,
						"strokeWidth": planSelected ? (flyMode ? 1.5 : (selected ? 3 : 2)) : 1,
						"opacity": planSelected ? (flyMode ? 0.78 : 0.95) : 0.46
					},
					"geometry": {
						"type": "Point",
						"coordinates": [item.longitude, item.latitude]
					}
				});
			}
		}
		return featureCollection(features);
	}

	function multiMissionInsertHandleGeoJson(plans, visible, revision) {
		void revision;
		if (!visible)
			return emptyFeatureCollection;
		const features = [];
		for (let p = 0; p < (plans || []).length; ++p) {
			const plan = plans[p];
			if (!plan || plan.selected !== true)
				continue;
			const items = plan.items || [];
			if (items.length < 2)
				continue;
			for (let i = 0; i < items.length - 1; ++i) {
				const aItem = items[i];
				const bItem = items[i + 1];
				if (!aItem || !bItem)
					continue;
				const a = QtPositioning.coordinate(aItem.latitude, aItem.longitude);
				const b = QtPositioning.coordinate(bItem.latitude, bItem.longitude);
				const mid = a.atDistanceAndAzimuth(a.distanceTo(b) * 0.5, a.azimuthTo(b));
				features.push({
					"type": "Feature",
					"properties": {
						"droneUid": plan.droneUid || -1,
						"segmentIndex": i,
						"label": "+",
						"color": plan.color || "#ff9d00"
					},
					"geometry": {
						"type": "Point",
						"coordinates": [mid.longitude, mid.latitude]
					}
				});
			}
		}
		return featureCollection(features);
	}

	function multiMissionWaypointExtrusionGeoJson(plans, revision) {
		void revision;
		const features = [];
		for (let p = 0; p < (plans || []).length; ++p) {
			const plan = plans[p];
			const items = plan && plan.items ? plan.items : [];
			for (let i = 0; i < items.length; ++i) {
				const item = items[i];
				if (!item)
					continue;
				const c = QtPositioning.coordinate(item.latitude, item.longitude);
				const alt = Math.max(0, item.altitude || 0);
				features.push(polygonFeature(circleRing(c, 3.5, 18), {
					"base": Math.max(0, alt - 1.5),
					"height": alt + 1.5,
					"color": plan.color || "#ffb000",
					"opacity": plan.selected ? 0.95 : 0.38
				}));
			}
		}
		return featureCollection(features);
	}

	function multiMissionTetherGeoJson(plans, revision) {
		void revision;
		const features = [];
		for (let p = 0; p < (plans || []).length; ++p) {
			const plan = plans[p];
			const items = plan && plan.items ? plan.items : [];
			for (let i = 0; i < items.length; ++i) {
				const item = items[i];
				if (!item || (item.altitude || 0) <= 0)
					continue;
				const c = QtPositioning.coordinate(item.latitude, item.longitude);
				features.push(polygonFeature(circleRing(c, 1.1, 10), {
					"base": 0,
					"height": item.altitude,
					"color": plan.color || "#8fe8ff",
					"opacity": plan.selected ? 0.55 : 0.22
				}));
			}
		}
		return featureCollection(features);
	}

	function multiMissionSegmentExtrusionGeoJson(plans, revision) {
		void revision;
		const features = [];
		const dashLengthM = 4;
		const gapLengthM = 9;
		for (let p = 0; p < (plans || []).length; ++p) {
			const plan = plans[p];
			const items = plan && plan.items ? plan.items : [];
			for (let i = 1; i < items.length; ++i) {
				const aItem = items[i - 1];
				const bItem = items[i];
				if (!aItem || !bItem)
					continue;
				const a = QtPositioning.coordinate(aItem.latitude, aItem.longitude);
				const b = QtPositioning.coordinate(bItem.latitude, bItem.longitude);
				const distance = a.distanceTo(b);
				if (distance <= 0.1)
					continue;
				const bearing = a.azimuthTo(b);
				const aAlt = Math.max(0, aItem.altitude || 0);
				const bAlt = Math.max(0, bItem.altitude || 0);
				for (let startM = 0; startM < distance; startM += dashLengthM + gapLengthM) {
					const endM = Math.min(startM + dashLengthM, distance);
					if (endM - startM < 1)
						continue;
					const start = a.atDistanceAndAzimuth(startM, bearing);
					const end = a.atDistanceAndAzimuth(endM, bearing);
					const ring = segmentRect(start, end, 0.9);
					if (ring.length === 0)
						continue;
					const midT = ((startM + endM) * 0.5) / distance;
					const alt = aAlt + (bAlt - aAlt) * midT;
					features.push(polygonFeature(ring, {
						"base": Math.max(0, alt - 0.35),
						"height": alt + 0.35,
						"color": plan.color || "#ff9d00",
						"opacity": plan.selected ? 0.92 : 0.32
					}));
				}
			}
		}
		return featureCollection(features);
	}

	function multiReturnHomePathGeoJson(plans, revision) {
		void revision;
		const features = [];
		for (let p = 0; p < (plans || []).length; ++p) {
			const plan = plans[p];
			const items = plan && plan.items ? plan.items : [];
			if (!plan || !plan.returnHomeAfterMission || !plan.homeValid || items.length < 1)
				continue;
			const last = items[items.length - 1];
			if (!last)
				continue;
			features.push({
				"type": "Feature",
				"properties": {
					"droneUid": plan.droneUid || -1,
					"color": plan.color || "#ff9d00",
					"opacity": plan.selected ? 0.82 : 0.26,
					"width": plan.selected ? 4 : 2
				},
				"geometry": {
					"type": "LineString",
					"coordinates": [[last.longitude, last.latitude], [plan.homeLongitude, plan.homeLatitude]]
				}
			});
		}
		return featureCollection(features);
	}

	function multiReturnHomeSegmentExtrusionGeoJson(plans, revision) {
		const convertedPlans = [];
		for (let p = 0; p < (plans || []).length; ++p) {
			const plan = plans[p];
			const items = plan && plan.items ? plan.items : [];
			if (!plan || !plan.returnHomeAfterMission || !plan.homeValid || items.length < 1)
				continue;
			const last = items[items.length - 1];
			if (!last)
				continue;
			convertedPlans.push({
				"selected": plan.selected,
				"color": plan.color,
				"items": [last,
					{
						"latitude": plan.homeLatitude,
						"longitude": plan.homeLongitude,
						"altitude": 0
					}
				]
			});
		}
		return multiMissionSegmentExtrusionGeoJson(convertedPlans, revision);
	}

	function flyTargetGeoJson(valid, latitude, longitude) {
		if (!valid)
			return emptyFeatureCollection;
		return featureCollection([
			{
				"type": "Feature",
				"geometry": {
					"type": "Point",
					"coordinates": [longitude, latitude]
				}
			}
		]);
	}

	function flyTargetLineGeoJson(valid, droneLatitude, droneLongitude, latitude, longitude) {
		if (!valid || (droneLatitude === 0 && droneLongitude === 0))
			return emptyFeatureCollection;
		return featureCollection([
			{
				"type": "Feature",
				"geometry": {
					"type": "LineString",
					"coordinates": [[droneLongitude, droneLatitude], [longitude, latitude]]
				}
			}
		]);
	}

	function flyTargetTetherGeoJson(valid, latitude, longitude, altitude) {
		if (!valid || altitude <= 0)
			return emptyFeatureCollection;
		const c = QtPositioning.coordinate(latitude, longitude);
		return featureCollection([polygonFeature(circleRing(c, 1.1, 10), {
				"base": 0,
				"height": altitude
			})]);
	}

	function flyTargetExtrusionGeoJson(valid, latitude, longitude, altitude, heading) {
		if (!valid)
			return emptyFeatureCollection;
		const c = QtPositioning.coordinate(latitude, longitude);
		const alt = Math.max(0, altitude || 0);
		const features = [];
		features.push(polygonFeature(circleRing(c, 3.5, 18), {
			"base": Math.max(0, alt - 1.2),
			"height": alt + 1.2
		}));
		features.push(polygonFeature(polyRect(c, 7, 0.8, heading || 0), {
			"base": Math.max(0, alt - 0.5),
			"height": alt + 0.5
		}));
		return featureCollection(features);
	}

	function mapTargetGeoJson(targets, revision) {
		void revision;
		const features = [];
		for (let i = 0; i < (targets || []).length; ++i) {
			const target = targets[i];
			if (!target || target.valid === false)
				continue;
			features.push({
				"type": "Feature",
				"properties": {
					"id": target.id || "",
					"type": target.type || "",
					"droneUid": target.droneUid || -1,
					"missionItemIndex": target.missionItemIndex === undefined ? -1 : target.missionItemIndex,
					"segmentIndex": target.segmentIndex === undefined ? -1 : target.segmentIndex,
					"selected": target.selected === true,
					"editable": target.editable === true,
					"draggable": target.draggable === true,
					"fill": target.fill || "#00d0ff",
					"radius": target.radius || 6,
					"stroke": target.stroke || "#ffffff",
					"strokeWidth": target.strokeWidth || 2,
					"opacity": target.opacity === undefined ? 0.95 : target.opacity
				},
				"geometry": {
					"type": "Point",
					"coordinates": [target.longitude, target.latitude]
				}
			});
		}
		return featureCollection(features);
	}

	function homeGeoJson(latitude, longitude, valid) {
		if (!valid)
			return emptyFeatureCollection;
		return featureCollection([
			{
				"type": "Feature",
				"geometry": {
					"type": "Point",
					"coordinates": [longitude, latitude]
				}
			}
		]);
	}
}
