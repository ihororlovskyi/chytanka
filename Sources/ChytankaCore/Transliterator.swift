import Foundation

/// Rewrites Latin-script words in Ukrainian letters, so the Ukrainian voice reads
/// them close to English pronunciation. Uses CMUdict pronunciations when known,
/// a small list of established spellings, and spelling rules as the last resort.
public struct Transliterator: Sendable {
  /// Lowercased word -> space-separated ARPAbet phones.
  private let pronunciations: [String: String]

  public init(pronunciations: [String: String]) {
    self.pronunciations = pronunciations
  }

  /// Parses cmudict.dict lines ("word P H O N E S # comment"); alternate
  /// pronunciations ("word(2) ...") are skipped.
  public static func parseCMUDict(_ text: String) -> [String: String] {
    var result: [String: String] = [:]
    result.reserveCapacity(130_000)
    text.enumerateLines { line, _ in
      guard let space = line.firstIndex(of: " ") else { return }
      let word = line[..<space]
      guard !word.contains("(") else { return }
      var phones = line[line.index(after: space)...]
      if let hash = phones.firstIndex(of: "#") { phones = phones[..<hash] }
      result[String(word)] = phones.trimmingCharacters(in: .whitespaces)
    }
    return result
  }

  public func transliterate(text: String) -> String {
    let ns = text as NSString
    var result = ""
    var last = 0
    for match in Self.wordPattern.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
      result += ns.substring(with: NSRange(location: last, length: match.range.location - last))
      result += word(ns.substring(with: match.range))
      last = match.range.location + match.range.length
    }
    result += ns.substring(from: last)
    return result
  }

  func word(_ word: String) -> String {
    let lower = word.lowercased().replacingOccurrences(of: "\u{2019}", with: "'")
    let converted: String
    if let known = Self.overrides[lower] {
      converted = known
    } else if word.count <= 4, word.count >= 2, word.allSatisfy(\.isUppercase) {
      converted = word.map { Self.letterNames[Character($0.lowercased())] ?? "" }.joined(separator: " ")
    } else if let phones = pronunciations[lower] {
      converted = Self.fromPhones(phones.split(separator: " ").map(String.init), spelling: lower)
    } else if let parts = Self.camelCaseParts(word), parts.count > 1 {
      converted = parts.map { self.word($0).lowercased() }.joined()
    } else {
      converted = Self.fromSpelling(lower)
    }
    guard let first = word.first, first.isUppercase else { return converted }
    return converted.prefix(1).uppercased() + converted.dropFirst()
  }

  // MARK: - Phones

  private static let labials: Set<Character> = ["б", "п", "в", "м", "ф", "р"]
  private static let ukrainianVowels: Set<Character> = ["а", "е", "є", "и", "і", "ї", "о", "у", "ю", "я"]
  private static let plosives: Set<String> = ["P", "B", "T", "D", "K", "G"]

  static func fromPhones(_ phones: [String], spelling: String = "") -> String {
    let vowelLetters = reducedVowelLetters(phones: phones, spelling: spelling)
    var vowelIndex = 0
    var out = ""
    var index = 0
    while index < phones.count {
      let phone = phones[index]
      let base = phone.filter(\.isLetter)
      let stress = phone.last?.wholeNumberValue ?? 0
      let next = index + 1 < phones.count ? phones[index + 1].filter(\.isLetter) : nil
      let afterNext = index + 2 < phones.count ? phones[index + 2].filter(\.isLetter) : nil

      if base == "Y", let vowel = next, let iotated = iotatedVowels[vowel] {
        // "computer" -> "компʼютер", "million" -> "мільйон"-like softening.
        if let previous = out.last, !ukrainianVowels.contains(previous) {
          out += labials.contains(previous) ? "\u{02BC}" : "ь"
        }
        out += iotated
        vowelIndex += 1
        index += 2
        continue
      }
      // Syllabic L after a plosive: "apple" -> "епл", "google" -> "ґуґл".
      if base == "AH", stress == 0, next == "L", afterNext == nil, index > 0,
         plosives.contains(phones[index - 1]) {
        index += 1
        continue
      }
      if phone.last?.isNumber == true { vowelIndex += 1 }
      if base == "AH", stress == 0, let letter = vowelLetters?[vowelIndex - 1], let vowel = spelledVowels[letter] {
        out += vowel
      } else {
        out += sound(base, stress: stress, next: next, previous: out.last)
      }
      index += 1
    }
    return out
  }

  /// The reduced vowel (schwa) follows the spelling when it says o, e or i:
  /// "commit" -> "коміт", "terminal" -> "термінал"; a or u stay "а" ("product" -> "продакт").
  private static let spelledVowels: [Character: String] = ["o": "о", "e": "е", "i": "і"]

  /// First letter of each vowel group in the spelling, when the groups line up
  /// one-to-one with the vowel phones; nil otherwise.
  static func reducedVowelLetters(phones: [String], spelling: String) -> [Character]? {
    var groups: [Character] = []
    var inGroup = false
    for (offset, character) in spelling.enumerated() {
      let isVowel = "aeiou".contains(character) || (character == "y" && offset > 0)
      if isVowel && !inGroup { groups.append(character) }
      inGroup = isVowel
    }
    let vowelPhones = phones.filter { $0.last?.isNumber == true }.count
    return groups.count == vowelPhones ? groups : nil
  }

  private static let iotatedVowels: [String: String] = [
    "UW": "ю", "UH": "ю", "AH": "я", "AA": "я", "AE": "я",
    "EH": "є", "EY": "єй", "IH": "ї", "IY": "ї", "AO": "йо", "OW": "йо", "ER": "єр",
  ]

  private static func sound(_ base: String, stress: Int, next: String?, previous: Character?) -> String {
    let afterVowel = previous.map { ukrainianVowels.contains($0) } ?? false
    switch base {
    case "AA": return next == "R" ? "а" : "о"
    case "AE": return "е"
    case "AH": return "а"
    case "AO": return "о"
    case "AW": return "ау"
    case "AY": return "ай"
    case "EH": return "е"
    case "ER": return "ер"
    case "EY": return "ей"
    case "IH", "IY": return afterVowel ? "ї" : "і"
    case "OW": return stress == 1 ? "оу" : "о"
    case "OY": return "ой"
    case "UH", "UW": return "у"
    case "B": return "б"
    case "CH": return "ч"
    case "D", "DH": return "д"
    case "F": return "ф"
    case "G": return "ґ"
    case "HH": return "х"
    case "JH": return "дж"
    case "K": return "к"
    case "L": return "л"
    case "M": return "м"
    case "N": return "н"
    case "NG": return "нг"
    case "P": return "п"
    case "R": return "р"
    case "S": return "с"
    case "SH": return "ш"
    case "T", "TH": return "т"
    case "V", "W": return "в"
    case "Y": return "й"
    case "Z": return "з"
    case "ZH": return "ж"
    default: return ""
    }
  }

  // MARK: - Fallbacks

  /// "GitHub" -> ["Git", "Hub"], "iPhone" -> ["i", "Phone"]; nil for a single-case word.
  static func camelCaseParts(_ word: String) -> [String]? {
    var parts: [String] = []
    var current = ""
    for character in word {
      if character.isUppercase, let last = current.last, last.isLowercase {
        parts.append(current)
        current = ""
      }
      current.append(character)
    }
    parts.append(current)
    return parts.count > 1 ? parts : nil
  }

  private static let digraphs: [(String, String)] = [
    ("tion", "шн"), ("sh", "ш"), ("ch", "ч"), ("th", "т"), ("ph", "ф"), ("ck", "к"),
    ("qu", "кв"), ("oo", "у"), ("ee", "і"), ("ea", "і"), ("ou", "ау"), ("ai", "ей"),
    ("ay", "ей"), ("oy", "ой"), ("ng", "нг"),
  ]
  private static let letters: [Character: String] = [
    "a": "а", "b": "б", "c": "к", "d": "д", "e": "е", "f": "ф", "g": "ґ", "h": "х",
    "i": "і", "j": "дж", "k": "к", "l": "л", "m": "м", "n": "н", "o": "о", "p": "п",
    "q": "к", "r": "р", "s": "с", "t": "т", "u": "у", "v": "в", "w": "в", "x": "кс",
    "y": "і", "z": "з",
  ]

  static func fromSpelling(_ word: String) -> String {
    var rest = Substring(word)
    // Silent final "e": "make" -> "мак".
    if rest.count > 3, rest.hasSuffix("e") { rest = rest.dropLast() }
    var out = ""
    outer: while let character = rest.first {
      for (latin, cyrillic) in digraphs where rest.hasPrefix(latin) {
        out += cyrillic
        rest = rest.dropFirst(latin.count)
        continue outer
      }
      let next = rest.dropFirst().first
      if character == "c", let n = next, "eiy".contains(n) {
        out += "с"
      } else if character == "y", out.isEmpty, let n = next, "aeiou".contains(n) {
        out += "й"
      } else {
        out += letters[character] ?? ""
      }
      rest = rest.dropFirst()
    }
    return out
  }

  /// Established Ukrainian spellings that pronunciation rules get wrong.
  static let overrides: [String: String] = [
    "youtube": "ютуб",
    "visual": "віжуал",
    "manager": "менеджер",
    "uber": "убер",
    "readme": "рідмі",
    "pizza": "піца",
    "iphone": "айфон",
    "ipad": "айпед",
    "macos": "мак о ес",
    "ios": "ай о ес",
  ]

  private static let letterNames: [Character: String] = [
    "a": "ей", "b": "бі", "c": "сі", "d": "ді", "e": "і", "f": "еф", "g": "джі",
    "h": "ейч", "i": "ай", "j": "джей", "k": "кей", "l": "ел", "m": "ем", "n": "ен",
    "o": "оу", "p": "пі", "q": "кʼю", "r": "ар", "s": "ес", "t": "ті", "u": "ю",
    "v": "ві", "w": "дабл ю", "x": "екс", "y": "вай", "z": "зі",
  ]

  // A Latin word, optionally with an apostrophe inside ("don't").
  private static let wordPattern = try! NSRegularExpression(pattern: "[A-Za-z]+(?:['\u{2019}][A-Za-z]+)?")
}
