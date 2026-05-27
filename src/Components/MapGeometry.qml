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
}
