//
//  PokemonTCGService.swift
//  PCTracker
//
//  Fetches market prices from the Pokemon TCG API (pokemontcg.io).
//  Free tier: 1,000 requests/day without an API key.
//

import Foundation

// MARK: - Response Models

struct PokemonTCGResponse: Codable {
    let data: [PokemonTCGCard]
}

struct PokemonTCGCard: Codable {
    let id: String
    let name: String
    let number: String
    let set: PokemonTCGSet?
    let images: PokemonTCGImages?
    let tcgplayer: TCGPlayerData?
}

struct PokemonTCGSet: Codable {
    let name: String
}

struct PokemonTCGImages: Codable {
    let small: String?
    let large: String?
}

struct TCGPlayerData: Codable {
    let url: String?
    let updatedAt: String?
    let prices: TCGPlayerPrices?
}

struct TCGPlayerPrices: Codable {
    let holofoil: PriceVariant?
    let reverseHolofoil: PriceVariant?
    let normal: PriceVariant?
    let unlimitedHolofoil: PriceVariant?
    // swiftlint:disable:next identifier_name
    let _1stEditionHolofoil: PriceVariant?
    let unlimited: PriceVariant?
    // swiftlint:disable:next identifier_name
    let _1stEdition: PriceVariant?
    
    enum CodingKeys: String, CodingKey {
        case holofoil, reverseHolofoil, normal, unlimitedHolofoil, unlimited
        case _1stEditionHolofoil = "1stEditionHolofoil"
        case _1stEdition = "1stEdition"
    }
    
    /// Returns the best available price across all variants.
    var bestPrice: Double? {
        let variants = [holofoil, reverseHolofoil, normal, unlimitedHolofoil, _1stEditionHolofoil, unlimited, _1stEdition]
        return variants.compactMap { $0?.bestPrice }.first
    }
}

struct PriceVariant: Codable {
    let low: Double?
    let mid: Double?
    let high: Double?
    let market: Double?
    let directLow: Double?
    
    /// Best available price: market first, then mid, then low.
    /// Some rare cards have no market price when there aren't enough recent sales.
    var bestPrice: Double? {
        market ?? mid ?? low
    }
}

struct FrankfurterResponse: Codable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
}

// MARK: - TCGdex Response Models (Japanese card support)

struct TCGdexCardBrief: Codable {
    let id: String?
    let localId: String?
    let name: String?
    let image: String?
}

struct TCGdexCardDetail: Codable {
    let id: String?
    let localId: String?
    let name: String?
    let image: String?
    let set: TCGdexSetInfo?
}

struct TCGdexSetInfo: Codable {
    let name: String?
}

// MARK: - Card Search Result

struct CardSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let number: String
    let setName: String
    let marketPrice: Double?
    let imageURL: String?
}

// MARK: - eBay Response Models

struct EbayAvgPriceResponse: Codable {
    let average_price: Double?
    let median_price: Double?
    let response_url: String?
    let products: [EbayRawSoldProduct]?
}

struct EbayRawSoldProduct: Codable {
    let title: String?
    let sale_price: FlexiblePrice?
    let date_sold: String?
    let link: String?
    let condition: String?  // eBay condition: "New", "New (Other)", "Pre-Owned", etc.
}

/// A sold eBay listing for display in the UI.
struct EbaySoldItem: Identifiable {
    let id = UUID()
    let title: String
    let price: Double       // USD (raw from eBay)
    let priceCad: Double    // Converted to CAD
    let dateSold: String
    let url: String?        // Individual listing URL or search results page
}

/// Handles eBay sale_price that can be either a String ("$125.00") or a number (125.0).
enum FlexiblePrice: Codable {
    case string(String)
    case number(Double)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            self = .number(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(FlexiblePrice.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected String or Double"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .number(let d): try container.encode(d)
        }
    }
    
    /// Returns the numeric value, parsing from string if needed.
    var doubleValue: Double? {
        switch self {
        case .number(let d): return d
        case .string(let s):
            let cleaned = s.replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            return Double(cleaned)
        }
    }
}

// MARK: - Market Price Result

struct MarketPriceResult {
    let price: Double           // Already in CAD
    let source: String          // "tcgplayer" or "ebay"
    let ebaySoldItems: [EbaySoldItem]   // Last 5 sold items (empty for tcgplayer)
}

// MARK: - Set Search Result

struct SetSearchResult: Identifiable {
    let id = UUID()
    let setId: String
    let name: String
    let series: String
    let logoURL: String?
    let symbolURL: String?
    let releaseDate: String?
    let totalCards: Int?
}

// MARK: - Set Response Models

struct PokemonTCGSetResponse: Codable {
    let data: [PokemonTCGSetData]
}

struct PokemonTCGSetData: Codable {
    let id: String
    let name: String
    let series: String?
    let total: Int?
    let releaseDate: String?
    let images: PokemonTCGSetImages?
}

struct PokemonTCGSetImages: Codable {
    let symbol: String?
    let logo: String?
}

// MARK: - Service

struct PokemonTCGService {
    
    /// Searches for a card and returns full card data (name, number, set, price, image).
    static func searchCard(name: String, number: String?) async throws -> CardSearchResult? {
        guard let card = try await findCard(name: name, number: number) else { return nil }
        
        let rawPrice = card.tcgplayer?.prices?.bestPrice
        var price: Double? = nil
        if let rawPrice {
            price = try await adjustedPrice(rawPrice)
        }
        
        return CardSearchResult(
            name: card.name,
            number: card.number,
            setName: card.set?.name ?? "",
            marketPrice: price,
            imageURL: card.images?.small
        )
    }
    
    /// Searches for cards matching filters. Returns up to `limit` results.
    /// Automatically detects Japanese text and routes to TCGdex API for Japanese cards.
    /// English/romaji queries try pokemontcg.io first, then TCGdex English, then TCGdex Japanese.
    static func searchCards(name: String, set: String? = nil, number: String? = nil, limit: Int = 20) async throws -> [CardSearchResult] {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedSet = set?.trimmingCharacters(in: .whitespaces)
        let trimmedNumber = number?.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return [] }
        
        let nameIsJapanese = containsJapanese(trimmedName)
        let setIsJapanese = trimmedSet != nil && containsJapanese(trimmedSet!)
        
        if nameIsJapanese {
            // Japanese card name → search TCGdex Japanese directly
            let jaResults = try await searchTCGdex(name: trimmedName, set: trimmedSet, number: trimmedNumber, language: "ja", limit: limit)
            if !jaResults.isEmpty { return jaResults }
            // Also try TCGdex English in case it's a card with a Japanese name variant
            return try await searchTCGdex(name: trimmedName, set: trimmedSet, number: trimmedNumber, language: "en", limit: limit)
        } else {
            // English card name — full fallback chain
            
            // 1. pokemontcg.io (has market prices) — skip if set is Japanese since it won't match
            if !setIsJapanese {
                let results = try await searchPokemonTCGio(name: trimmedName, set: trimmedSet, number: trimmedNumber, limit: limit)
                if !results.isEmpty { return results }
            }
            
            // 2. TCGdex English
            let enResults = try await searchTCGdex(name: trimmedName, set: trimmedSet, number: trimmedNumber, language: "en", limit: limit)
            if !enResults.isEmpty { return enResults }
            
            // 3. TCGdex Japanese with English name (some JP cards use English names in their data)
            let jaEnResults = try await searchTCGdex(name: trimmedName, set: trimmedSet, number: trimmedNumber, language: "ja", limit: limit)
            if !jaEnResults.isEmpty { return jaEnResults }
            
            // 4. Convert romaji to katakana and search TCGdex Japanese
            let katakana = romajiToKatakana(trimmedName)
            if katakana != trimmedName {
                let katakanaResults = try await searchTCGdex(name: katakana, set: trimmedSet, number: trimmedNumber, language: "ja", limit: limit)
                if !katakanaResults.isEmpty { return katakanaResults }
            }
            
            // 5. If set is Japanese, also try pokemontcg.io without the set filter
            //    (user may be searching for the English version of a card from a JP set)
            if setIsJapanese {
                let fallbackResults = try await searchPokemonTCGio(name: trimmedName, set: nil, number: trimmedNumber, limit: limit)
                if !fallbackResults.isEmpty { return fallbackResults }
            }
            
            return []
        }
    }
    
    /// Checks if the string contains Japanese characters (Hiragana, Katakana, or CJK).
    private static func containsJapanese(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            // Hiragana
            (scalar.value >= 0x3040 && scalar.value <= 0x309F) ||
            // Katakana
            (scalar.value >= 0x30A0 && scalar.value <= 0x30FF) ||
            // CJK Unified Ideographs
            (scalar.value >= 0x4E00 && scalar.value <= 0x9FFF) ||
            // Katakana half-width
            (scalar.value >= 0xFF65 && scalar.value <= 0xFF9F)
        }
    }
    
    /// Converts romaji text to katakana for Japanese card name lookup.
    /// Pokemon card names in Japanese are typically in katakana.
    private static func romajiToKatakana(_ text: String) -> String {
        let map: [(String, String)] = [
            // Long vowels and double consonants first
            ("sha", "シャ"), ("shi", "シ"), ("shu", "シュ"), ("sho", "ショ"),
            ("cha", "チャ"), ("chi", "チ"), ("chu", "チュ"), ("cho", "チョ"),
            ("tsu", "ツ"),
            ("kya", "キャ"), ("kyu", "キュ"), ("kyo", "キョ"),
            ("nya", "ニャ"), ("nyu", "ニュ"), ("nyo", "ニョ"),
            ("hya", "ヒャ"), ("hyu", "ヒュ"), ("hyo", "ヒョ"),
            ("mya", "ミャ"), ("myu", "ミュ"), ("myo", "ミョ"),
            ("rya", "リャ"), ("ryu", "リュ"), ("ryo", "リョ"),
            ("gya", "ギャ"), ("gyu", "ギュ"), ("gyo", "ギョ"),
            ("bya", "ビャ"), ("byu", "ビュ"), ("byo", "ビョ"),
            ("pya", "ピャ"), ("pyu", "ピュ"), ("pyo", "ピョ"),
            ("ja", "ジャ"), ("ji", "ジ"), ("ju", "ジュ"), ("jo", "ジョ"),
            ("fu", "フ"),
            ("ka", "カ"), ("ki", "キ"), ("ku", "ク"), ("ke", "ケ"), ("ko", "コ"),
            ("sa", "サ"), ("si", "シ"), ("su", "ス"), ("se", "セ"), ("so", "ソ"),
            ("ta", "タ"), ("ti", "チ"), ("tu", "ツ"), ("te", "テ"), ("to", "ト"),
            ("na", "ナ"), ("ni", "ニ"), ("nu", "ヌ"), ("ne", "ネ"), ("no", "ノ"),
            ("ha", "ハ"), ("hi", "ヒ"), ("hu", "フ"), ("he", "ヘ"), ("ho", "ホ"),
            ("ma", "マ"), ("mi", "ミ"), ("mu", "ム"), ("me", "メ"), ("mo", "モ"),
            ("ya", "ヤ"), ("yu", "ユ"), ("yo", "ヨ"),
            ("ra", "ラ"), ("ri", "リ"), ("ru", "ル"), ("re", "レ"), ("ro", "ロ"),
            ("wa", "ワ"), ("wi", "ヰ"), ("we", "ヱ"), ("wo", "ヲ"),
            ("ga", "ガ"), ("gi", "ギ"), ("gu", "グ"), ("ge", "ゲ"), ("go", "ゴ"),
            ("za", "ザ"), ("zi", "ジ"), ("zu", "ズ"), ("ze", "ゼ"), ("zo", "ゾ"),
            ("da", "ダ"), ("di", "ヂ"), ("du", "ヅ"), ("de", "デ"), ("do", "ド"),
            ("ba", "バ"), ("bi", "ビ"), ("bu", "ブ"), ("be", "ベ"), ("bo", "ボ"),
            ("pa", "パ"), ("pi", "ピ"), ("pu", "プ"), ("pe", "ペ"), ("po", "ポ"),
            ("a", "ア"), ("i", "イ"), ("u", "ウ"), ("e", "エ"), ("o", "オ"),
            ("n", "ン"),
        ]
        
        var result = ""
        var input = text.lowercased()
        
        while !input.isEmpty {
            // Handle double consonants (っ/ッ) — e.g. "kk" in "Rekkuuza"
            if input.count >= 2 {
                let first = input[input.startIndex]
                let second = input[input.index(after: input.startIndex)]
                if first == second && first.isLetter && !"aiueon".contains(first) {
                    result += "ッ"
                    input.removeFirst()
                    continue
                }
            }
            
            // Handle long vowels with "ー"
            if input.hasPrefix("aa") || input.hasPrefix("uu") || input.hasPrefix("oo") {
                // Already converted the first vowel; add long mark for the double
                input.removeFirst()
                result += "ー"
                continue
            }
            
            var matched = false
            for (romaji, katakana) in map {
                if input.hasPrefix(romaji) {
                    result += katakana
                    input.removeFirst(romaji.count)
                    matched = true
                    break
                }
            }
            
            if !matched {
                // Keep non-romaji characters as-is (spaces, numbers, etc.)
                result.append(input.removeFirst())
            }
        }
        
        return result
    }
    
    /// Normalizes search text for the pokemontcg.io API:
    /// - Replaces curly/smart quotes with straight quotes
    /// - Expands common ASCII to accented variants used in Pokemon card names (e.g. "Poke" → "Poké")
    /// - Replaces " & " and " and " with wildcards (API uses literal & in card names which breaks URLs)
    /// - Replaces space before GX/EX/V/VMAX/VSTAR/BREAK with wildcard (matches both hyphen and space formats)
    private static func normalizeSearchText(_ text: String) -> String {
        var result = text
        // Normalize curly/smart quotes and apostrophes
        result = result.replacingOccurrences(of: "\u{2018}", with: "'")  // '
        result = result.replacingOccurrences(of: "\u{2019}", with: "'")  // '
        result = result.replacingOccurrences(of: "\u{201C}", with: "\"") // "
        result = result.replacingOccurrences(of: "\u{201D}", with: "\"") // "
        // Expand "Poke" to "Poké" (case-insensitive replacement preserving original case)
        if let range = result.range(of: "poke", options: .caseInsensitive) {
            let original = String(result[range])
            let isUpperE = original.last?.isUppercase ?? false
            let replacement = String(original.dropLast()) + (isUpperE ? "É" : "é")
            result = result.replacingCharacters(in: range, with: replacement)
        }
        // Replace " & " and " and " with wildcard (& breaks URL query params)
        result = result.replacingOccurrences(of: #"\s+&\s+"#, with: "*", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\s+and\s+"#, with: "*", options: [.regularExpression, .caseInsensitive])
        // Replace space before GX/EX/V/VMAX/VSTAR/BREAK suffix with wildcard (matches both "Eevee & Snorlax-GX" and "Charizard VMAX")
        result = result.replacingOccurrences(of: #"\s+(GX|EX|V|VMAX|VSTAR|BREAK)\s*$"#, with: "*$1", options: [.regularExpression, .caseInsensitive])
        return result
    }
    
    /// Searches pokemontcg.io (English cards with market prices).
    /// Tries the original query first, then a normalized version if no results found.
    private static func searchPokemonTCGio(name: String, set: String?, number: String?, limit: Int) async throws -> [CardSearchResult] {
        // Try original query first
        let results = try await searchPokemonTCGioQuery(name: name, set: set, number: number, limit: limit)
        if !results.isEmpty { return results }
        
        // Try normalized query as fallback
        let normalizedName = normalizeSearchText(name)
        let normalizedSet = set.map { normalizeSearchText($0) }
        if normalizedName != name || normalizedSet != set {
            return try await searchPokemonTCGioQuery(name: normalizedName, set: normalizedSet, number: number, limit: limit)
        }
        
        return []
    }
    
    /// Executes a single pokemontcg.io search query.
    private static func searchPokemonTCGioQuery(name: String, set: String?, number: String?, limit: Int) async throws -> [CardSearchResult] {
        var queryParts = ["name:\"\(name)*\""]
        if let set, !set.isEmpty {
            queryParts.append("set.name:\"\(set)*\"")
        }
        if let number, !number.isEmpty {
            let cleaned = cleanNumber(number)
            if let cleaned {
                queryParts.append("number:\(cleaned)")
            }
        }
        let queryString = queryParts.joined(separator: " ")
        
        guard let encoded = queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.pokemontcg.io/v2/cards?q=\(encoded)&pageSize=\(limit)&orderBy=name") else {
            return []
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
        
        let decoded = try JSONDecoder().decode(PokemonTCGResponse.self, from: data)
        
        var results: [CardSearchResult] = []
        for card in decoded.data {
            let rawPrice = card.tcgplayer?.prices?.bestPrice
            var price: Double? = nil
            if let rawPrice {
                price = try await adjustedPrice(rawPrice)
            }
            results.append(CardSearchResult(
                name: card.name,
                number: card.number,
                setName: card.set?.name ?? "",
                marketPrice: price,
                imageURL: card.images?.small
            ))
        }
        
        return results
    }
    
    /// Searches TCGdex API for cards in a given language (supports Japanese, English, etc.).
    /// TCGdex doesn't provide market prices but has international card data.
    private static func searchTCGdex(name: String, set: String?, number: String?, language: String, limit: Int) async throws -> [CardSearchResult] {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        // When a set filter is provided, fetch more results since filtering is client-side
        let fetchLimit = (set != nil && !set!.isEmpty) ? max(limit, 100) : limit
        var urlString = "https://api.tcgdex.net/v2/\(language)/cards?name=\(encodedName)&pagination:itemsPerPage=\(fetchLimit)"
        if let number, !number.isEmpty,
           let encodedNumber = cleanNumber(number)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "&localId=\(encodedNumber)"
        }
        guard let url = URL(string: urlString) else {
            return []
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
        
        let briefs = try JSONDecoder().decode([TCGdexCardBrief].self, from: data)
        
        // Extract unique set IDs from card IDs (format: "setId-localId")
        var setIds: Set<String> = []
        for brief in briefs {
            if let cardId = brief.id, let dashIndex = cardId.lastIndex(of: "-") {
                setIds.insert(String(cardId[cardId.startIndex..<dashIndex]))
            }
        }
        
        // Batch-fetch set names for all unique sets concurrently
        var setNames: [String: String] = [:]
        await withTaskGroup(of: (String, String).self) { group in
            for setId in setIds {
                group.addTask {
                    guard let setURL = URL(string: "https://api.tcgdex.net/v2/\(language)/sets/\(setId)") else {
                        return (setId, "")
                    }
                    if let (setData, setResponse) = try? await URLSession.shared.data(from: setURL),
                       let setHttp = setResponse as? HTTPURLResponse, setHttp.statusCode == 200,
                       let setInfo = try? JSONDecoder().decode(TCGdexSetInfo.self, from: setData) {
                        return (setId, setInfo.name ?? "")
                    }
                    return (setId, "")
                }
            }
            for await (setId, name) in group {
                setNames[setId] = name
            }
        }
        
        // Build results
        var results: [CardSearchResult] = []
        for brief in briefs {
            guard let cardId = brief.id, let name = brief.name else { continue }
            
            let imageURL: String? = brief.image.map { $0 + "/low.webp" }
            
            // Look up set name from the batch fetch
            var setName = ""
            if let dashIndex = cardId.lastIndex(of: "-") {
                let setId = String(cardId[cardId.startIndex..<dashIndex])
                setName = setNames[setId] ?? ""
            }
            
            results.append(CardSearchResult(
                name: name,
                number: brief.localId ?? "",
                setName: setName,
                marketPrice: nil,
                imageURL: imageURL
            ))
        }
        
        // Filter by set name client-side if provided, then apply limit
        if let set, !set.isEmpty {
            let setLower = set.lowercased()
            let filtered = results.filter { $0.setName.lowercased().contains(setLower) }
            return Array(filtered.prefix(limit))
        }
        
        return Array(results.prefix(limit))
    }
    
    /// Searches for Pokemon TCG sets by name. Returns up to `limit` results.
    /// Tries the original query first, then a normalized version if no results found.
    static func searchSets(query: String, limit: Int = 20) async throws -> [SetSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        
        // Try original query first
        let results = try await searchSetsQuery(name: trimmed, limit: limit)
        if !results.isEmpty { return results }
        
        // Try normalized query as fallback
        let normalized = normalizeSearchText(trimmed)
        if normalized != trimmed {
            return try await searchSetsQuery(name: normalized, limit: limit)
        }
        
        return []
    }
    
    /// Executes a single set search query against pokemontcg.io.
    private static func searchSetsQuery(name: String, limit: Int) async throws -> [SetSearchResult] {
        let queryString = "name:\"\(name)*\""
        guard let encoded = queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.pokemontcg.io/v2/sets?q=\(encoded)&pageSize=\(limit)&orderBy=-releaseDate") else {
            return []
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
        
        let decoded = try JSONDecoder().decode(PokemonTCGSetResponse.self, from: data)
        
        return decoded.data.map { setData in
            SetSearchResult(
                setId: setData.id,
                name: setData.name,
                series: setData.series ?? "",
                logoURL: setData.images?.logo,
                symbolURL: setData.images?.symbol,
                releaseDate: setData.releaseDate,
                totalCards: setData.total
            )
        }
    }
    
    /// Fetches the market price for a card.
    /// For graded cards with a RapidAPI key, fetches eBay sold prices.
    /// Otherwise falls back to TCGPlayer via pokemontcg.io.
    /// Strips PSA grade suffix from a card name for clean API lookups.
    /// e.g. "Mewtwo VSTAR PSA 10" → "Mewtwo VSTAR"
    private static func stripGradeFromName(_ name: String) -> String {
        // Remove trailing "PSA X" or "PSA XX" (case-insensitive)
        let trimmed = name.replacingOccurrences(of: #"\s+PSA\s+\d{1,2}\s*$"#, with: "", options: [.regularExpression, .caseInsensitive])
        return trimmed.trimmingCharacters(in: .whitespaces)
    }
    
    static func fetchMarketPrice(name: String, number: String?, cardSet: String? = nil, graded: Bool = false, gradeLevel: Int? = nil, condition: String? = nil) async throws -> MarketPriceResult? {
        // Strip PSA grade from name if present (condition text gets appended to name on save)
        let cleanName = graded ? stripGradeFromName(name) : name
        
        let apiKey = UserDefaults.standard.string(forKey: "rapidApiKey") ?? ""
        let hasApiKey = !apiKey.isEmpty
        
        // Try eBay for graded cards when API key is available
        if graded, let grade = gradeLevel, hasApiKey {
            print("[PriceService] Attempting eBay lookup for '\(cleanName)' PSA \(grade)")
            do {
                if let result = try await fetchEbayGradedPrice(name: cleanName, number: number, cardSet: cardSet, gradeLevel: grade, apiKey: apiKey) {
                    print("[PriceService] eBay price found: \(result.price) CAD, \(result.soldItems.count) sold items")
                    return MarketPriceResult(price: result.price, source: "ebay", ebaySoldItems: result.soldItems)
                } else {
                    print("[PriceService] eBay returned no results, falling back to TCGPlayer")
                }
            } catch {
                print("[PriceService] eBay lookup failed: \(error), falling back to TCGPlayer")
            }
        }
        
        // Try eBay for non-graded cards with condition filtering when API key is available
        if !graded, hasApiKey, let cond = condition, !cond.isEmpty {
            print("[PriceService] Attempting eBay condition lookup for '\(cleanName)' condition: \(cond)")
            do {
                if let result = try await fetchEbayConditionPrice(name: cleanName, number: number, cardSet: cardSet, condition: cond, apiKey: apiKey) {
                    print("[PriceService] eBay condition price found: \(result.price) CAD, \(result.soldItems.count) sold items")
                    return MarketPriceResult(price: result.price, source: "ebay", ebaySoldItems: result.soldItems)
                } else {
                    print("[PriceService] eBay condition returned no results, falling back to TCGPlayer")
                }
            } catch {
                print("[PriceService] eBay condition lookup failed: \(error), falling back to TCGPlayer")
            }
        }
        
        if !hasApiKey {
            print("[PriceService] No RapidAPI key configured, using TCGPlayer")
        }
        
        // Fall back to TCGPlayer
        guard let card = try await findCard(name: cleanName, number: number) else {
            print("[PriceService] TCGPlayer: no card found for '\(cleanName)' number: \(number ?? "nil")")
            return nil
        }
        guard let price = card.tcgplayer?.prices?.bestPrice else {
            print("[PriceService] TCGPlayer: card found but no price data")
            return nil
        }
        let cadPrice = try await adjustedPrice(price)
        return MarketPriceResult(price: cadPrice, source: "tcgplayer", ebaySoldItems: [])
    }
    
    /// Fetches average sold price from eBay for a PSA-graded card via RapidAPI.
    /// Returns the price (in CAD) and last 5 sold items, or nil if no data available.
    private static func fetchEbayGradedPrice(name: String, number: String?, cardSet: String?, gradeLevel: Int, apiKey: String) async throws -> (price: Double, soldItems: [EbaySoldItem])? {
        guard let url = URL(string: "https://ebay-average-selling-price.p.rapidapi.com/findCompletedItems") else {
            return nil
        }
        
        // Build keywords: "{name} {number} {set} PSA {grade}"
        var keywordParts = [name]
        if let number, !number.isEmpty {
            keywordParts.append(number)
        }
        if let cardSet, !cardSet.isEmpty {
            keywordParts.append(cardSet)
        }
        keywordParts.append("PSA \(gradeLevel)")
        let keywords = keywordParts.joined(separator: " ")
        
        print("[eBay] Search keywords: \(keywords)")
        
        let body: [String: Any] = [
            "keywords": keywords,
            "max_search_results": "60",
            "category_id": "183454",
            "remove_outliers": true
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("ebay-average-selling-price.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            print("[eBay] No HTTP response")
            return nil
        }
        print("[eBay] HTTP status: \(http.statusCode)")
        if http.statusCode != 200 {
            if let body = String(data: data, encoding: .utf8) {
                print("[eBay] Error body: \(body.prefix(500))")
            }
            return nil
        }
        
        let decoded = try JSONDecoder().decode(EbayAvgPriceResponse.self, from: data)
        let searchURL = decoded.response_url
        
        guard let products = decoded.products, !products.isEmpty else {
            print("[eBay] No products in response")
            return nil
        }
        
        // Filter products: must match exact PSA grade and card number in the title.
        // Grade filter: "PSA 8" must not match "PSA 8.5", "PSA 80", or "PSA 10"
        // Also reject titles containing a DIFFERENT PSA grade (e.g. title has both "PSA 9" and "PSA 10")
        let gradePattern = "\\bPSA\\s*\(gradeLevel)\\b(?!\\.)"
        let gradeRegex = try? NSRegularExpression(pattern: gradePattern, options: .caseInsensitive)
        
        // Regex to find ANY PSA grade in a title
        let anyGradeRegex = try? NSRegularExpression(pattern: "\\bPSA\\s*(\\d+)\\b(?!\\.)", options: .caseInsensitive)
        
        // Clean the card number for matching (strip set denominator, leading zeros)
        let cleanedNum = number.flatMap { cleanNumber($0) }
        
        let matchedProducts = products.filter { product in
            guard let title = product.title else { return false }
            let range = NSRange(title.startIndex..., in: title)
            
            // Must contain our exact PSA grade
            guard gradeRegex?.firstMatch(in: title, range: range) != nil else { return false }
            
            // Reject if title also contains a DIFFERENT PSA grade
            if let anyRegex = anyGradeRegex {
                let allMatches = anyRegex.matches(in: title, range: range)
                for match in allMatches {
                    if let numRange = Range(match.range(at: 1), in: title),
                       let foundGrade = Int(title[numRange]),
                       foundGrade != gradeLevel {
                        return false  // Title mentions a different PSA grade
                    }
                }
            }
            
            // Must contain the card number if we have one
            if let num = cleanedNum, !num.isEmpty {
                let titleUpper = title.uppercased()
                let numUpper = num.uppercased()
                // Match the number with common eBay title formats
                let numPatterns = ["#\(numUpper)", "/\(numUpper)", " \(numUpper) ", " \(numUpper)/", " \(numUpper),", " \(numUpper)-"]
                let hasNumber = numPatterns.contains { titleUpper.contains($0) }
                    || titleUpper.hasSuffix(" \(numUpper)")
                if !hasNumber { return false }
            }
            return true
        }
        
        print("[eBay] \(products.count) total, \(matchedProducts.count) match PSA \(gradeLevel) + number \(cleanedNum ?? "n/a")")
        for item in matchedProducts.suffix(5) {
            print("[eBay]   -> \(item.title ?? "?"): \(item.sale_price?.doubleValue ?? 0)")
        }
        
        guard !matchedProducts.isEmpty else {
            print("[eBay] No products matched filters, skipping unfiltered average")
            return nil
        }
        
        // Take last 5 matched products
        let last5 = Array(matchedProducts.suffix(5))
        let rate = try await getUsdToCadRate()
        
        let soldItems: [EbaySoldItem] = last5.compactMap { product in
            guard let usdPrice = product.sale_price?.doubleValue else { return nil }
            return EbaySoldItem(
                title: product.title ?? "Unknown",
                price: usdPrice,
                priceCad: usdPrice * rate,
                dateSold: product.date_sold ?? "",
                url: product.link ?? searchURL
            )
        }
        
        // Average the prices of the sold items
        let prices = soldItems.map(\.priceCad)
        guard !prices.isEmpty else { return nil }
        let average = prices.reduce(0, +) / Double(prices.count)
        
        return (price: average, soldItems: soldItems)
    }
    
    /// Maps a TCG card condition to acceptable eBay condition strings for filtering.
    /// Returns nil for DMG or unknown conditions (no filtering).
    private static func ebayConditionsForCardCondition(_ condition: String) -> [String]? {
        switch condition.uppercased() {
        case "NM":
            return ["new", "new (other)", "like new", "near mint", "nm"]
        case "LP":
            return ["very good", "light played", "lightly played", "lp"]
        case "MP":
            return ["good", "moderately played", "mp"]
        case "HP":
            return ["acceptable", "heavily played", "hp"]
        case "DMG":
            return nil
        default:
            return nil
        }
    }
    
    /// Fetches average sold price from eBay for a raw (non-graded) card filtered by condition.
    /// Returns the price (in CAD) and last 5 sold items, or nil if no data available.
    private static func fetchEbayConditionPrice(name: String, number: String?, cardSet: String?, condition: String, apiKey: String) async throws -> (price: Double, soldItems: [EbaySoldItem])? {
        guard let url = URL(string: "https://ebay-average-selling-price.p.rapidapi.com/findCompletedItems") else {
            return nil
        }
        
        // Build keywords: "{name} {number} {set}" (no PSA grade for raw cards)
        var keywordParts = [name]
        if let number, !number.isEmpty {
            keywordParts.append(number)
        }
        if let cardSet, !cardSet.isEmpty {
            keywordParts.append(cardSet)
        }
        let keywords = keywordParts.joined(separator: " ")
        
        print("[eBay-Condition] Search keywords: \(keywords), condition: \(condition)")
        
        let body: [String: Any] = [
            "keywords": keywords,
            "max_search_results": "60",
            "category_id": "183454",
            "remove_outliers": true
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("ebay-average-selling-price.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            print("[eBay-Condition] No HTTP response")
            return nil
        }
        print("[eBay-Condition] HTTP status: \(http.statusCode)")
        if http.statusCode != 200 {
            if let body = String(data: data, encoding: .utf8) {
                print("[eBay-Condition] Error body: \(body.prefix(500))")
            }
            return nil
        }
        
        let decoded = try JSONDecoder().decode(EbayAvgPriceResponse.self, from: data)
        let searchURL = decoded.response_url
        
        guard let products = decoded.products, !products.isEmpty else {
            print("[eBay-Condition] No products in response")
            return nil
        }
        
        // Get allowed eBay conditions for this card condition
        let allowedConditions = ebayConditionsForCardCondition(condition)
        
        // Clean the card number for matching
        let cleanedNum = number.flatMap { cleanNumber($0) }
        
        // Regex to detect PSA-graded listings (exclude them from raw card results)
        let psaRegex = try? NSRegularExpression(pattern: "\\bPSA\\s*\\d+\\b", options: .caseInsensitive)
        
        let matchedProducts = products.filter { product in
            guard let title = product.title else { return false }
            let range = NSRange(title.startIndex..., in: title)
            
            // Reject PSA-graded listings — we only want raw cards
            if psaRegex?.firstMatch(in: title, range: range) != nil {
                return false
            }
            
            // Filter by condition if we have allowed conditions
            if let allowed = allowedConditions {
                guard let ebayCondition = product.condition?.lowercased() else { return false }
                if !allowed.contains(where: { ebayCondition.contains($0) }) {
                    return false
                }
            }
            
            // Must contain the card number if we have one
            if let num = cleanedNum, !num.isEmpty {
                let titleUpper = title.uppercased()
                let numUpper = num.uppercased()
                let numPatterns = ["#\(numUpper)", "/\(numUpper)", " \(numUpper) ", " \(numUpper)/", " \(numUpper),", " \(numUpper)-"]
                let hasNumber = numPatterns.contains { titleUpper.contains($0) }
                    || titleUpper.hasSuffix(" \(numUpper)")
                if !hasNumber { return false }
            }
            return true
        }
        
        print("[eBay-Condition] \(products.count) total, \(matchedProducts.count) match condition '\(condition)' + number \(cleanedNum ?? "n/a")")
        for item in matchedProducts.suffix(5) {
            print("[eBay-Condition]   -> \(item.title ?? "?"): \(item.sale_price?.doubleValue ?? 0) [\(item.condition ?? "?")]")
        }
        
        guard !matchedProducts.isEmpty else {
            print("[eBay-Condition] No products matched filters")
            return nil
        }
        
        // Take last 5 matched products
        let last5 = Array(matchedProducts.suffix(5))
        let rate = try await getUsdToCadRate()
        
        let soldItems: [EbaySoldItem] = last5.compactMap { product in
            guard let usdPrice = product.sale_price?.doubleValue else { return nil }
            return EbaySoldItem(
                title: product.title ?? "Unknown",
                price: usdPrice,
                priceCad: usdPrice * rate,
                dateSold: product.date_sold ?? "",
                url: product.link ?? searchURL
            )
        }
        
        // Average the prices of the sold items
        let prices = soldItems.map(\.priceCad)
        guard !prices.isEmpty else { return nil }
        let average = prices.reduce(0, +) / Double(prices.count)
        
        return (price: average, soldItems: soldItems)
    }
    
    /// Multi-step search strategy to find the best matching card.
    private static func findCard(name: String, number: String?) async throws -> PokemonTCGCard? {
        let cleanedNumber = cleanNumber(number)
        let cleanedName = cleanName(name)
        let normalizedName = normalizeSearchText(name)
        let normalizedCleanedName = cleanName(normalizedName)
        
        var strategies: [[String]] = []
        
        if let num = cleanedNumber {
            strategies.append(["name:\"\(name)\"", "number:\(num)"])
        }
        if let num = cleanedNumber, cleanedName != name {
            strategies.append(["name:\"\(cleanedName)\"", "number:\(num)"])
        }
        // Try normalized name with number
        if let num = cleanedNumber, normalizedName != name {
            strategies.append(["name:\"\(normalizedName)\"", "number:\(num)"])
        }
        strategies.append(["name:\"\(name)\""])
        if cleanedName != name {
            strategies.append(["name:\"\(cleanedName)\""])
        }
        // Try normalized names without number
        if normalizedName != name {
            strategies.append(["name:\"\(normalizedName)\""])
        }
        if normalizedCleanedName != cleanedName && normalizedCleanedName != normalizedName {
            strategies.append(["name:\"\(normalizedCleanedName)\""])
        }
        
        for queryParts in strategies {
            if let card = try await searchAPI(queryParts: queryParts) {
                return card
            }
        }
        
        return nil
    }
    
    // MARK: - Private

    private static let currencyCodeKey = "currencyCode"
    private static let usdToCadRateKey = "usdToCadRate"
    private static let usdToCadRateUpdatedAtKey = "usdToCadRateUpdatedAt"
    private static let defaultUsdToCadRate: Double = 1.35
    private static let rateStaleInterval: TimeInterval = 12 * 60 * 60
    
    /// Always converts USD API prices to CAD for storage.
    /// All prices are stored in CAD as the canonical currency.
    private static func adjustedPrice(_ price: Double) async throws -> Double {
        let rate = try await getUsdToCadRate()
        return price * rate
    }

    /// Fetches and caches the USD→CAD exchange rate.
    /// Returns a cached rate if fresh (< 12 hours old), otherwise fetches a new one.
    @discardableResult
    static func getUsdToCadRate() async throws -> Double {
        let defaults = UserDefaults.standard
        let storedRate = defaults.double(forKey: usdToCadRateKey)
        let lastUpdated = defaults.double(forKey: usdToCadRateUpdatedAtKey)
        let now = Date().timeIntervalSince1970

        let hasFreshRate = storedRate > 0 && (now - lastUpdated) < rateStaleInterval
        if hasFreshRate {
            return storedRate
        }

        if let fetchedRate = try await fetchUsdToCadRate() {
            defaults.set(fetchedRate, forKey: usdToCadRateKey)
            defaults.set(now, forKey: usdToCadRateUpdatedAtKey)
            return fetchedRate
        }

        return storedRate > 0 ? storedRate : defaultUsdToCadRate
    }

    private static func fetchUsdToCadRate() async throws -> Double? {
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=USD&to=CAD") else {
            return nil
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }

        let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        return decoded.rates["CAD"]
    }
    
    /// Executes a single API search and returns the first matching card.
    private static func searchAPI(queryParts: [String]) async throws -> PokemonTCGCard? {
        let query = queryParts.joined(separator: " ")
        
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.pokemontcg.io/v2/cards?q=\(encoded)&pageSize=1") else {
            return nil
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }
        
        let decoded = try JSONDecoder().decode(PokemonTCGResponse.self, from: data)
        return decoded.data.first
    }
    
    /// Cleans the card number for API matching:
    /// - Strips set denominator ("074/073" -> "074")
    /// - Removes leading zeros ("074" -> "74")
    /// - Preserves non-numeric prefixes ("TG22" stays "TG22", "SV107" stays "SV107")
    private static func cleanNumber(_ number: String?) -> String? {
        guard let number, !number.isEmpty else { return nil }
        
        // Strip denominator
        let base = number.components(separatedBy: "/").first ?? number
        
        // Split into prefix (letters) and numeric suffix
        let letters = base.prefix(while: { $0.isLetter })
        let digits = base.drop(while: { $0.isLetter })
        
        // Strip leading zeros from the numeric part
        if let numericValue = Int(digits) {
            return letters.isEmpty ? "\(numericValue)" : "\(letters)\(numericValue)"
        }
        
        // Fallback: return as-is without denominator
        return base
    }
    
    /// Strips common collector suffixes that the API doesn't use in card names.
    /// e.g. "Giratina V Alt Art" -> "Giratina V"
    private static func cleanName(_ name: String) -> String {
        let suffixes = [
            "Alt Art", "Alternate Art", "Full Art", "Secret Rare",
            "Special Art", "Illustration Rare", "Ultra Rare",
            "(Alt Art)", "(Full Art)", "(Secret)",
        ]
        
        var cleaned = name
        for suffix in suffixes {
            if cleaned.hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Also strip trailing parenthetical content like "(Alternate Art Rare)"
        if let parenRange = cleaned.range(of: #"\s*\([^)]*\)\s*$"#, options: .regularExpression) {
            cleaned = String(cleaned[cleaned.startIndex..<parenRange.lowerBound])
        }
        
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
}
