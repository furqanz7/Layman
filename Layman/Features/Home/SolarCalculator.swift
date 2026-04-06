import CoreLocation
import Foundation

struct SolarCalculator {
    let date: Date
    let coordinate: CLLocationCoordinate2D

    var sunrise: Date? { compute(isSunrise: true) }
    var sunset: Date? { compute(isSunrise: false) }

    private func compute(isSunrise: Bool) -> Date? {
        let tz = TimeZone(secondsFromGMT: 0)!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        guard let dayDate = cal.date(from: comps) else { return nil }

        let N = Double(cal.ordinality(of: .day, in: .year, for: dayDate) ?? 1)
        let lngHour = coordinate.longitude / 15.0
        let t = isSunrise ? (N + ((6 - lngHour) / 24)) : (N + ((18 - lngHour) / 24))
        let M = (0.9856 * t) - 3.289

        var L = M + (1.916 * sin(deg2rad(M))) + (0.020 * sin(deg2rad(2 * M))) + 282.634
        L = normalizeDegrees(L)

        var RA = rad2deg(atan(0.91764 * tan(deg2rad(L))))
        RA = normalizeDegrees(RA)
        let Lquadrant  = floor(L / 90) * 90
        let RAquadrant = floor(RA / 90) * 90
        RA = RA + (Lquadrant - RAquadrant)
        RA /= 15

        let sinDec = 0.39782 * sin(deg2rad(L))
        let cosDec = cos(asin(sinDec))

        let zenith = 90.833
        let cosH = (cos(deg2rad(zenith)) - (sinDec * sin(deg2rad(coordinate.latitude)))) / (cosDec * cos(deg2rad(coordinate.latitude)))
        if cosH < -1 || cosH > 1 { return nil }

        var H = isSunrise ? (360 - rad2deg(acos(cosH))) : rad2deg(acos(cosH))
        H /= 15

        let T = H + RA - (0.06571 * t) - 6.622
        let UT = normalizeHours(T - lngHour)

        let hours = Int(floor(UT))
        let minutes = Int(floor((UT - Double(hours)) * 60))
        let seconds = Int(((UT - Double(hours)) * 60 - Double(minutes)) * 60)

        var result = cal.date(bySettingHour: hours, minute: minutes, second: seconds, of: dayDate)
        let userTZ = TimeZone.current
        let delta = TimeInterval(userTZ.secondsFromGMT(for: result ?? dayDate))
        result = result?.addingTimeInterval(delta)
        return result
    }

    private func deg2rad(_ deg: Double) -> Double { deg * .pi / 180 }
    private func rad2deg(_ rad: Double) -> Double { rad * 180 / .pi }
    private func normalizeDegrees(_ x: Double) -> Double {
        var v = x.truncatingRemainder(dividingBy: 360)
        if v < 0 { v += 360 }
        return v
    }
    private func normalizeHours(_ x: Double) -> Double {
        var v = x.truncatingRemainder(dividingBy: 24)
        if v < 0 { v += 24 }
        return v
    }
}
