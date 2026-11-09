import Foundation

public enum InputMethod: String, CaseIterable, Identifiable, Codable {
    case telex = "Telex"
    case simpleTelex = "Simple Telex"
    case vni = "VNI"
    case viqr = "VIQR"

    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .telex:
            return "Telex chuẩn (aa=â, aw=ă, ee=ê, oo=ô, ow=ơ, w=ư, dd=đ, s/f/r/x/j, [=ơ, ]=ư)"
        case .simpleTelex:
            return "Simple Telex (giữ nguyên 'w' đầu từ tiếng Anh, tránh nhầm khi gõ web, win)"
        case .vni:
            return "VNI chuẩn (1:sắc, 2:huyền, 3:hỏi, 4:ngã, 5:nặng, 6:â/ê/ô, 7:ơ/ư, 8:ă, 9:đ, 0:xóa)"
        case .viqr:
            return "VIQR ký tự ('=sắc, `=huyền, ?=hỏi, ~=ngã, .=nặng, ^=mũ, +=móc, (=trăng, d-=đ)"
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
    case acute = 1      // Sắc (s, 1, ')
    case grave = 2      // Huyền (f, 2, `)
    case hook = 3       // Hỏi (r, 3, ?)
    case tilde = 4      // Ngã (x, 4, ~)
    case heavy = 5      // Nặng (j, 5, .)
}
