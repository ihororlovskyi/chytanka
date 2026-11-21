/// Compares plain dotted versions such as "0.0.4"; missing components count as 0.
public enum Version {
  public static func isNewer(_ candidate: String, than current: String) -> Bool {
    let lhs = components(candidate)
    let rhs = components(current)
    for index in 0..<max(lhs.count, rhs.count) {
      let a = index < lhs.count ? lhs[index] : 0
      let b = index < rhs.count ? rhs[index] : 0
      if a != b { return a > b }
    }
    return false
  }

  private static func components(_ version: String) -> [Int] {
    version.split(separator: ".").map { Int($0) ?? 0 }
  }
}
