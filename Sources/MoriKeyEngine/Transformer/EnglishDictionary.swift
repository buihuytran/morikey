import Foundation

public struct EnglishDictionary {
    /// Comprehensive list of common English words, prepositions, pronouns, tech words,
    /// and programming keywords that frequently conflict with Telex/VNI typing rules.
    public static let commonWords: Set<String> = [
        // 2-letter words frequently conflicted with Telex tone keys (s, f, r, x, j)
        "as", "is", "us", "if", "of", "or", "to", "do", "so", "no", "go",
        "he", "we", "me", "my", "by", "in", "on", "at", "it", "up", "an", "am",

        // 3-letter words
        "the", "and", "for", "are", "but", "not", "you", "all", "any", "can",
        "had", "her", "was", "one", "our", "out", "day", "get", "has", "him",
        "his", "how", "man", "new", "now", "old", "see", "two", "way", "who",
        "boy", "did", "its", "let", "put", "say", "she", "too", "use", "bad",
        "far", "few", "big", "end", "set", "run", "try", "ask", "men", "lot",
        "sun", "war", "job", "eye", "sir", "god", "law", "car", "cat", "dog",
        "row", "saw", "raw", "cow", "low", "few", "own", "red", "top", "arm",
        "art", "bar", "box", "cut", "fat", "fit", "fun", "gas", "hit", "hot",
        "key", "map", "net", "pay", "per", "sea", "son", "tax", "tea", "yes",
        "yet", "app", "dev", "api", "git", "cli", "sdk", "log", "bug", "tab",
        "cmd", "tag", "url", "uri", "ssh", "ssl", "sql", "css", "dom",

        // 4-letter words
        "that", "with", "have", "this", "will", "your", "from", "they", "know",
        "want", "been", "good", "much", "some", "time", "very", "when", "come",
        "here", "just", "like", "long", "make", "many", "more", "only", "over",
        "such", "take", "than", "them", "well", "were", "down", "show", "look",
        "help", "book", "back", "work", "part", "even", "most", "open", "stop",
        "fast", "post", "text", "test", "code", "data", "user", "view", "file",
        "menu", "mode", "form", "type", "page", "list", "item", "card", "case",
        "base", "size", "name", "home", "free", "true", "null", "void", "main",
        "loop", "read", "send", "call", "link", "pass", "path", "room", "door",
        "root", "cool", "keep", "feed", "need", "meet", "week", "seen", "seem",
        "feel", "deep", "tree", "line", "side", "word", "find", "give", "tell",
        "head", "hand", "high", "last", "left", "life", "live", "move", "next",
        "same", "tool", "cook", "pool", "foot", "boot", "hook", "wood", "wool",
        "zoom", "info", "site", "host", "port", "auth", "sync", "load", "save",
        "edit", "copy", "find", "font", "icon", "grid", "flex", "hero", "body",
        "head", "span", "href", "json", "yaml", "html", "http", "bash", "zsh",
        "node", "rust", "java", "dart", "ruby", "perl", "lisp", "unix", "sudo",
        "cron", "kill", "grep", "curl", "echo", "make", "docs", "feed", "mail",
        "note", "task", "todo", "done", "fail", "pass", "warn", "date", "time",
        "year", "hour", "step", "draw", "flow", "push", "pull", "fork", "drop",

        // 5-letter words
        "about", "after", "again", "below", "could", "every", "first", "found",
        "great", "house", "large", "never", "other", "place", "point", "right",
        "small", "sound", "still", "their", "there", "these", "thing", "think",
        "three", "water", "where", "which", "world", "would", "write", "class",
        "const", "style", "state", "start", "print", "input", "error", "reset",
        "clear", "click", "close", "count", "build", "setup", "table", "title",
        "token", "theme", "image", "index", "order", "event", "group", "modal",
        "panel", "block", "alert", "badge", "check", "radio", "value", "label",
        "field", "input", "query", "route", "param", "stack", "queue", "array",
        "fetch", "async", "await", "catch", "throw", "while", "break", "super",
        "final", "local", "scope", "parse", "patch", "merge", "clone", "stage",
        "apply", "shell", "spawn", "child", "apple", "linux", "react", "swift",
        "macos", "cloud", "drive", "share", "trash", "clean", "color", "width",
        "scale", "space", "align", "match", "split", "slice", "shift", "layer",
        "frame", "scene", "audio", "video", "media", "music", "photo", "track",
        "album", "voice", "sound", "light", "speed", "power", "level", "score",

        // 6+ letter programming & common words
        "server", "client", "string", "return", "system", "script", "number",
        "boolean", "object", "module", "import", "export", "switch", "struct",
        "static", "public", "private", "socket", "thread", "future", "stream",
        "buffer", "widget", "layout", "window", "syntax", "editor", "canvas",
        "cursor", "render", "toggle", "scroll", "parser", "schema", "bundle",
        "symbol", "vector", "matrix", "vertex", "shader", "action", "button",
        "screen", "device", "header", "footer", "border", "shadow", "radius",
        "center", "middle", "bottom", "format", "source", "target", "length",
        "active", "cancel", "remove", "delete", "update", "insert", "select",
        "create", "filter", "search", "result", "status", "config", "option",
        "custom", "method", "handle", "runner", "manage", "domain", "online",
        "author", "commit", "master", "branch", "origin", "remote", "deploy",
        "docker", "python", "github", "gitlab", "google", "chrome", "safari",
        "firefox", "terminal", "console", "package", "library", "project",
        "framework", "function", "interface", "component", "container",
        "controller", "middleware", "repository", "navigation", "background",
        "foreground", "environment", "application", "development", "production",
        "performance", "optimization", "configuration", "authentication",
        "authorization", "accessibility", "interceptor", "notification",
        "connection", "exception", "validation", "middleware", "subscriber",
        "publisher", "inspector", "generator", "simulator", "preference",
        "undefined", "statement", "expression", "declaration", "definition"
    ]

    /// Checks if a lowercase word is in the English dictionary
    public static func isCommonEnglishWord(_ word: String) -> Bool {
        return commonWords.contains(word.lowercased())
    }
}

