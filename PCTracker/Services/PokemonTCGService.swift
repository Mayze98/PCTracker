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
        
        if containsJapanese(trimmedName) || (trimmedSet != nil && containsJapanese(trimmedSet!)) {
            return try await searchTCGdex(name: trimmedName, set: trimmedSet, number: trimmedNumber, language: "ja", limit: limit)
        } else {
            // Try pokemontcg.io first (has market prices)
            let results = try await searchPokemonTCGio(name: trimmedName, set: trimmedSet, number: trimmedNumber, limit: limit)
            if !results.isEmpty { return results }
            
            // Fall back to TCGdex English
            let enResults = try await searchTCGdex(name: trimmedName, set: trimmedSet, number: trimmedNumber, language: "en", limit: limit)
            if !enResults.isEmpty { return enResults }
            
            // Final fallback: convert romaji to katakana and search TCGdex Japanese
            let katakana = romajiToKatakana(trimmedName)
            if katakana != trimmedName {
                return try await searchTCGdex(name: katakana, set: trimmedSet, number: trimmedNumber, language: "ja", limit: limit)
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
    
    /// Searches pokemontcg.io (English cards with market prices).
    private static func searchPokemonTCGio(name: String, set: String?, number: String?, limit: Int) async throws -> [CardSearchResult] {
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
        var urlString = "https://api.tcgdex.net/v2/\(language)/cards?name=\(encodedName)&pagination:itemsPerPage=\(limit)"
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
        
        // Filter by set name client-side if provided
        if let set, !set.isEmpty {
            let setLower = set.lowercased()
            return results.filter { $0.setName.lowercased().contains(setLower) }
        }
        
        return results
    }
    
    /// Searches for Pokemon TCG sets by name. Returns up to `limit` results.
    static func searchSets(query: String, limit: Int = 20) async throws -> [SetSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        
        let queryString = "name:\"\(trimmed)*\""
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
    
    /// Fetches the TCGPlayer market price for a card by name and optional number.
    static func fetchMarketPrice(name: String, number: String?) async throws -> Double? {
        guard let card = try await findCard(name: name, number: number) else { return nil }
        
        guard let price = card.tcgplayer?.prices?.bestPrice else { return nil }
        return try await adjustedPrice(price)
    }
    
    /// Multi-step search strategy to find the best matching card.
    private static func findCard(name: String, number: String?) async throws -> PokemonTCGCard? {
        let cleanedNumber = cleanNumber(number)
        let cleanedName = cleanName(name)
        
        var strategies: [[String]] = []
        
        if let num = cleanedNumber {
            strategies.append(["name:\"\(name)\"", "number:\(num)"])
        }
        if let num = cleanedNumber, cleanedName != name {
            strategies.append(["name:\"\(cleanedName)\"", "number:\(num)"])
        }
        strategies.append(["name:\"\(name)\""])
        if cleanedName != name {
            strategies.append(["name:\"\(cleanedName)\""])
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
