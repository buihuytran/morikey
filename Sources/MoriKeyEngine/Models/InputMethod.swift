import Foundation

public enum InputMethod: String, CaseIterable, Identifiable, Codable {
    case telex = "Telex"
    case simpleTelex = "Simple Telex"

    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .telex:
            return "Telex chuẩn (aa=â, aw=ă, ee=ê, oo=ô, ow=ơ, w=ư, dd=đ, s/f/r/x/j)"
        case .simpleTelex:
            return "Simple Telex (giảm thiểu gõ nhầm w, các phím gõ cơ bản)"
        }
    }
}

public enum ToneStyle: String, CaseIterable, Identifiable, Codable {
    case modern = "Kiểu mới"
    case classic = "Kiểu cũ"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .modern:
            return "Quy tắc mới: hòa, thúy, khỏe"
        case .classic:
            return "Quy tắc cũ: hoà, thuý, khoẻ"
        }
    }
}

public enum Tone: Int, CaseIterable {
    case none = 0
    case acute = 1      // Sắc (s)
    case grave = 2      // Huyền (f)
    case hook = 3       // Hỏi (r)
    case tilde = 4      // Ngã (x)
    case heavy = 5      // Nặng (j)
}

