import Foundation
import CoreFoundation

struct FuriganaHelper {
    static func containsJapanese(_ text: String) -> Bool {
        let pattern = "([\\p{script=Hiragana}\\p{script=Katakana}\\p{script=Han}])"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            return regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)) != nil
        }
        return false
    }
    
    static func getRomaji(for text: String) -> String {
        guard text.count < 300 else { return text }
        
        let range = CFRangeMake(0, text.utf16.count)
        let locale = Locale(identifier: "ja_JP") as CFLocale
        let tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, text as CFString, range, kCFStringTokenizerUnitWordBoundary, locale)
        
        var romajiParts: [String] = []
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        
        while tokenType.rawValue != 0 {
            let tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let tokenStr = (text as NSString).substring(with: NSRange(location: tokenRange.location, length: tokenRange.length))
            
            let type = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription)
            if let latinType = type as? String {
                let trimmed = latinType.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    romajiParts.append(trimmed)
                } else {
                    romajiParts.append(tokenStr)
                }
            } else {
                romajiParts.append(tokenStr)
            }
            
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        
        return romajiParts.joined(separator: " ").replacingOccurrences(of: "  ", with: " ")
    }
}
