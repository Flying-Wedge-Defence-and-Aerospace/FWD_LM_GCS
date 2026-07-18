#!/usr/bin/env python3
"""
Digital Sky Airspace Proxy Server

Fetches MVT (Mapbox Vector Tile) airspace data from digitalsky.aai.aero,
converts to GeoJSON, and serves it to QGroundControl over HTTP.

Usage:
    python3 server.py [--port 8090] [--host 127.0.0.1]

Environment variables:
    DIGITAL_SKY_COOKIE   Session cookie from digitalsky.aai.aero browser login
                         (e.g. "connect.sid=s%3Aabc123...")
"""

import sys
import math
import json
import http.server
import urllib.request
import urllib.parse
import urllib.error
import os
import logging
import argparse
import concurrent.futures
from concurrent.futures import ThreadPoolExecutor, as_completed

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
log = logging.getLogger('airspace-proxy')

# ---------------------------------------------------------------------------
# Tile coordinate math
# ---------------------------------------------------------------------------

def bbox_to_tiles(min_lat, min_lon, max_lat, max_lon, zoom):
    """Return sorted list of (z, x, y) tiles covering the given bounding box."""
    tiles = set()
    min_x, min_y = _latlon_to_tile(min_lat, min_lon, zoom)
    max_x, max_y = _latlon_to_tile(max_lat, max_lon, zoom)
    if min_x > max_x:
        min_x, max_x = max_x, min_x
    if min_y > max_y:
        min_y, max_y = max_y, min_y
    n = 1 << zoom
    min_x = max(0, min(min_x, n - 1))
    max_x = max(0, min(max_x, n - 1))
    min_y = max(0, min(min_y, n - 1))
    max_y = max(0, min(max_y, n - 1))
    for x in range(min_x, max_x + 1):
        for y in range(min_y, max_y + 1):
            tiles.add((zoom, x, y))
    return sorted(tiles)


def _latlon_to_tile(lat, lon, zoom):
    n = 1 << zoom
    x = (lon + 180.0) / 360.0 * n
    lat_rad = math.radians(lat)
    y = (1.0 - math.log(math.tan(lat_rad) + 1.0 / math.cos(lat_rad)) / math.pi) / 2.0 * n
    return int(math.floor(x)), int(math.floor(y))


def _tile_to_latlon(tx, ty, zoom):
    n = 1 << zoom
    lon = tx / n * 360.0 - 180.0
    lat_rad = math.atan(math.sinh(math.pi * (1.0 - 2.0 * ty / n)))
    lat = math.degrees(lat_rad)
    return lat, lon


def _local_to_latlon(tx, ty, local_x, local_y, zoom, extent=4096):
    fx = tx + local_x / extent
    fy = ty + local_y / extent
    return _tile_to_latlon(fx, fy, zoom)


# ---------------------------------------------------------------------------
# MVT decode
# ---------------------------------------------------------------------------

try:
    import mapbox_vector_tile
    HAS_MVT = True
except ImportError:
    HAS_MVT = False
    log.warning("mapbox-vector-tile not installed — run: pip install mapbox-vector-tile")


LAYER_TYPE_MAP = {
    "red_zones":        "RED",
    "airport_yellow":   "YELLOW",
    "green_zones":      "GREEN",
    "tem_red_zones":    "RED",
}


def decode_mvt(data, zoom, tile_x, tile_y, url_layer_name):
    """Decode MVT protobuf bytes into a list of GeoJSON-like feature dicts."""
    if not HAS_MVT:
        return []

    zone_type = LAYER_TYPE_MAP.get(url_layer_name, "UNKNOWN")

    try:
        decoded = mapbox_vector_tile.decode(data)
    except Exception as e:
        log.warning(f"MVT decode error at tile {zoom}/{tile_x}/{tile_y}: {e}")
        return []

    features = []
    for layer_name, layer_data in decoded.items():
        if not isinstance(layer_data, dict):
            continue
        for feature in layer_data.get('features', []):
            props = feature.get('properties', {})
            geometry = feature.get('geometry', {})
            geom_type = geometry.get('type', '')
            coords = geometry.get('coordinates', [])
            if not coords:
                continue

            if geom_type == 'Point':
                if len(coords) == 2:
                    lat, lon = _local_to_latlon(tile_x, tile_y, coords[0], coords[1], zoom)
                    features.append(_make_feature(lat, lon, zone_type, props))
            elif geom_type == 'Polygon':
                centroid, radius = _polygon_to_circle(coords, tile_x, tile_y, zoom)
                if centroid:
                    features.append(_make_feature(centroid[0], centroid[1], zone_type, props, radius))
            elif geom_type == 'MultiPolygon':
                for polygon_coords in coords:
                    centroid, radius = _polygon_to_circle(polygon_coords, tile_x, tile_y, zoom)
                    if centroid:
                        features.append(_make_feature(centroid[0], centroid[1], zone_type, props, radius))
    return features


def _make_feature(lat, lon, zone_type, props, radius=None):
    return {
        "type": "Feature",
        "geometry": {
            "type": "Point",
            "coordinates": [round(lon, 6), round(lat, 6)]
        },
        "properties": {
            "type": zone_type,
            "name": str(props.get("name", props.get("Name", ""))),
            "designator": str(props.get("designator", props.get("id", ""))),
            "radius": int(radius) if radius else int(props.get("radius", 500)),
            "lowerLimit": float(props.get("lowerLimit", 0)),
            "upperLimit": float(props.get("upperLimit", 400)),
            "reason": str(props.get("reason", props.get("description", "")))
        }
    }


def _polygon_to_circle(coords, tile_x, tile_y, zoom):
    all_pts = []
    ring = coords[0]
    for pt in ring:
        lat, lon = _local_to_latlon(tile_x, tile_y, pt[0], pt[1], zoom)
        all_pts.append((lat, lon))
    if not all_pts:
        return None, 0

    n = len(all_pts)
    c_lat = sum(p[0] for p in all_pts) / n
    c_lon = sum(p[1] for p in all_pts) / n

    max_dist = 0.0
    for lat, lon in all_pts:
        d = _haversine(c_lat, c_lon, lat, lon)
        if d > max_dist:
            max_dist = d

    return (c_lat, c_lon), max_dist


def _haversine(lat1, lon1, lat2, lon2):
    R = 6371000
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


# ---------------------------------------------------------------------------
# Tile fetcher
# ---------------------------------------------------------------------------

DEFAULT_ZOOM = 14
TILE_FETCH_TIMEOUT = 3
TILE_FETCH_WORKERS = 8
TOTAL_FETCH_DEADLINE = 8
MAX_TILES = 32
MARGIN_MAX_DEG = 2.0  # max absolute bbox expansion in degrees (~220km)


def _bbox_to_zoom(bbox):
    min_lat, min_lon, max_lat, max_lon = bbox
    dlat = max_lat - min_lat
    dlon = max_lon - min_lon
    if dlat <= 0 or dlon <= 0:
        return DEFAULT_ZOOM
    diag_deg = math.sqrt(dlat ** 2 + dlon ** 2)
    target_tiles = 1.5
    zoom = int(round(math.log2(360.0 / diag_deg * target_tiles)))
    return max(2, min(zoom, 14))


TILE_URLS = {
    "red_zones":      "https://digitalsky.aai.aero/maps/dataserver_5000/{layer}/{z}/{x}/{y}",
    "airport_yellow": "https://digitalsky.aai.aero/maps/{layer}/{z}/{x}/{y}",
}
LAYERS = ["red_zones", "airport_yellow"]


def _tile_url(layer, z, x, y):
    tmpl = TILE_URLS.get(layer, TILE_URLS["red_zones"])
    return tmpl.format(layer=layer, z=z, x=x, y=y)


def fetch_tile(z, x, y, layer, cookie):
    url = _tile_url(layer, z, x, y)
    headers = {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
        'Accept': '*/*',
    }
    if cookie:
        headers['Cookie'] = cookie

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=TILE_FETCH_TIMEOUT) as resp:
            return resp.read()
    except urllib.error.HTTPError as e:
        if e.code != 404:
            log.warning(f"HTTP {e.code} for {url}")
        return None
    except Exception as e:
        log.warning(f"Failed to fetch {url}: {e}")
        return None


def _fetch_single_tile(args):
    z, x, y, layer, cookie = args
    data = fetch_tile(z, x, y, layer, cookie)
    return (z, x, y, layer, data)


def fetch_airspace(bbox, zoom, cookie):
    min_lat, min_lon, max_lat, max_lon = bbox
    features = []
    tiles_fetched = 0

    tiles = bbox_to_tiles(min_lat, min_lon, max_lat, max_lon, zoom)
    while len(tiles) > MAX_TILES and zoom > 2:
        zoom -= 1
        tiles = bbox_to_tiles(min_lat, min_lon, max_lat, max_lon, zoom)
    if not tiles:
        log.info("No tiles in bounding box")
        return _empty_result("no tiles in bbox")

    import time
    work = [(z, x, y, layer, cookie) for z, x, y in tiles for layer in LAYERS]

    with ThreadPoolExecutor(max_workers=TILE_FETCH_WORKERS) as pool:
        futs = {pool.submit(_fetch_single_tile, w): w for w in work}
        deadline = time.monotonic() + TOTAL_FETCH_DEADLINE
        try:
            for fut in as_completed(futs, timeout=TOTAL_FETCH_DEADLINE):
                try:
                    z, x, y, layer, data = fut.result(timeout=0)
                    if data:
                        tiles_fetched += 1
                        feat = decode_mvt(data, z, x, y, layer)
                        features.extend(feat)
                except Exception:
                    pass
                if time.monotonic() >= deadline:
                    for f in futs:
                        f.cancel()
                    break
        except concurrent.futures.TimeoutError:
            pass

    # Deduplicate by coordinate (both red_zones and tem_red_zones may return same zones)
    seen = set()
    deduped = []
    for f in features:
        c = tuple(round(v, 4) for v in f.get("geometry", {}).get("coordinates", []))
        if c not in seen:
            seen.add(c)
            deduped.append(f)
    features = deduped

    tile_size_deg = 360.0 / (1 << zoom) if zoom > 0 else 0
    bbox_dim = max(max_lat - min_lat, max_lon - min_lon, 0.001)
    adaptive_margin = max(tile_size_deg * 2.0 / bbox_dim, 1.0)
    margin_cap = MARGIN_MAX_DEG / bbox_dim
    margin = min(adaptive_margin, margin_cap)
    features = _filter_bbox(features, bbox, margin=margin)
    status = "ok" if features else "no data"
    return {
        "type": "FeatureCollection",
        "features": features,
        "source": "digitalsky-proxy",
        "status": status,
        "tiles_fetched": tiles_fetched,
        "tiles_in_bbox": len(tiles)
    }


def _filter_bbox(features, bbox, margin=0.0):
    min_lat, min_lon, max_lat, max_lon = bbox
    dlat = max_lat - min_lat
    dlon = max_lon - min_lon
    min_lat -= dlat * margin
    max_lat += dlat * margin
    min_lon -= dlon * margin
    max_lon += dlon * margin
    out = []
    for f in features:
        coords = f.get("geometry", {}).get("coordinates")
        if coords and len(coords) >= 2:
            lon, lat = coords[0], coords[1]
            if min_lat <= lat <= max_lat and min_lon <= lon <= max_lon:
                out.append(f)
    return out


def _empty_result(reason):
    return {
        "type": "FeatureCollection",
        "features": [],
        "source": "digitalsky-proxy",
        "status": reason,
        "tiles_fetched": 0,
        "tiles_in_bbox": 0
    }


# ---------------------------------------------------------------------------
# HTTP server
# ---------------------------------------------------------------------------

class AirspaceHandler(http.server.BaseHTTPRequestHandler):

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)

        if parsed.path == '/airspace':
            self._handle_airspace(params)
        elif parsed.path == '/health':
            self._handle_health()
        else:
            self._send_json(404, {"error": "not found"})

    def _handle_airspace(self, params):
        try:
            min_lat = float(params.get('minLat', [None])[0])
            min_lon = float(params.get('minLng', [None])[0] or params.get('minLon', [None])[0])
            max_lat = float(params.get('maxLat', [None])[0])
            max_lon = float(params.get('maxLng', [None])[0] or params.get('maxLon', [None])[0])
            if 'zoom' in params:
                zoom = int(params['zoom'][0])
            else:
                zoom = None
        except (TypeError, ValueError) as e:
            self._send_json(400, {"error": f"invalid params: {e}"})
            return

        # Normalize bbox: QGC may send minLat > maxLat (thinks minLat = north)
        if min_lat > max_lat:
            min_lat, max_lat = max_lat, min_lat
        if min_lon > max_lon:
            min_lon, max_lon = max_lon, min_lon
        bbox = (min_lat, min_lon, max_lat, max_lon)
        if zoom is None:
            zoom = _bbox_to_zoom(bbox)
        cookie = self.headers.get('Cookie', '') or os.environ.get('DIGITAL_SKY_COOKIE', '')
        result = fetch_airspace(bbox, zoom, cookie)
        self._send_json(200, result)

    def _handle_health(self):
        self._send_json(200, {
            "status": "ok",
            "mvt_library": "ok" if HAS_MVT else "missing",
            "layers": LAYERS,
            "cookie_configured": bool(os.environ.get('DIGITAL_SKY_COOKIE', ''))
        })

    def _send_json(self, status, data):
        body = json.dumps(data).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        try:
            self.wfile.write(body)
        except BrokenPipeError:
            pass

    def log_message(self, format, *args):
        log.info("%s - %s" % (self.client_address[0], format % args))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description='Digital Sky Airspace Proxy')
    parser.add_argument('--port', type=int, default=8090, help='Port to listen on')
    parser.add_argument('--host', default='127.0.0.1', help='Host to bind to')
    args = parser.parse_args()

    if not HAS_MVT:
        log.error("mapbox-vector-tile not installed. Run: pip install mapbox-vector-tile")
        sys.exit(1)

    server = http.server.HTTPServer((args.host, args.port), AirspaceHandler)
    log.info(f"Airspace proxy listening on http://{args.host}:{args.port}")
    log.info(f"Cookie configured via env: {bool(os.environ.get('DIGITAL_SKY_COOKIE', ''))}")
    log.info(f"Layers: {LAYERS}")
    log.info(f"Default zoom: {DEFAULT_ZOOM}")
    log.info("Press Ctrl+C to stop")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log.info("Shutting down")
        server.server_close()


if __name__ == '__main__':
    main()
