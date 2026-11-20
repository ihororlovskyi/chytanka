public enum Language: Equatable, Sendable {
  case ukrainian
  case english
}

public struct Segment: Equatable, Sendable {
  public let text: String
  public let language: Language

  public init(text: String, language: Language) {
    self.text = text
    self.language = language
  }
}

/// Splits text into runs of Cyrillic and Latin script.
/// Characters without a script (spaces, digits, punctuation) stay in the run they follow,
/// so joining the segments gives back the original text.
public enum TextSegmenter {
  public static func segments(of text: String) -> [Segment] {
    var result: [Segment] = []
    var current = ""
    var language: Language?

    for character in text {
      if let script = classify(character) {
        if let active = language, active != script {
          result.append(Segment(text: current, language: active))
          current = ""
        }
        language = script
      }
      current.append(character)
    }

    if !current.isEmpty {
      result.append(Segment(text: current, language: language ?? .ukrainian))
    }
    return result
  }

  static func classify(_ character: Character) -> Language? {
    guard character.isLetter, let scalar = character.unicodeScalars.first else { return nil }
    switch scalar.value {
    case 0x0400...0x052F:
      return .ukrainian
    case 0x0041...0x024F:
      return .english
    default:
      return nil
    }
  }
}
