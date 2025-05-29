const std = @import("std");
const math = std.math;

pub const PointPair = struct {
    x0: f64,
    y0: f64,
    x1: f64,
    y1: f64,
};

pub fn refenenceHaversineDistance(pair: PointPair) f64 {

    // Convert degrees to radians
    const lat1 = pair.y0 * math.pi / 180.0;
    const lon1 = pair.x0 * math.pi / 180.0;
    const lat2 = pair.y1 * math.pi / 180.0;
    const lon2 = pair.x1 * math.pi / 180.0;
    const EARTH_RADIUS: f64 = 6371.0;
    // Differences in coordinates
    const dLat = lat2 - lat1;
    const dLon = lon2 - lon1;

    // Haversine formula
    const a = math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLon / 2.0) * math.sin(dLon / 2.0);

    // In Zig, atan2 takes only y and x parameters
    const c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    const distance = EARTH_RADIUS * c;

    return distance;
}
