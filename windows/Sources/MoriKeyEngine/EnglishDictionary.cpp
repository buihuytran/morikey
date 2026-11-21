#include "EnglishDictionary.h"
#include <cwctype>

static std::wstring toLowerStr(const std::wstring& str) {
    std::wstring lower = str;
    for (auto& c : lower) {
        c = static_cast<wchar_t>(std::towlower(c));
    }
    return lower;
}

static const std::unordered_set<std::wstring> s_commonWords = {
    // 2-letter words frequently conflicted with Telex tone keys (s, f, r, x, j)
    L"as", L"is", L"us", L"if", L"of", L"or", L"to", L"do", L"so", L"no", L"go",
    L"he", L"we", L"me", L"my", L"by", L"in", L"on", L"at", L"it", L"up", L"an", L"am",

    // 3-letter words
    L"the", L"and", L"for", L"are", L"but", L"not", L"you", L"all", L"any", L"can",
    L"had", L"her", L"was", L"one", L"our", L"out", L"get", L"him",
    L"how", L"man", L"new", L"now", L"old", L"see", L"two", L"way", L"who",
    L"boy", L"did", L"let", L"put", L"she", L"too", L"use", L"bad",
    L"far", L"few", L"big", L"end", L"set", L"run", L"try", L"ask", L"men", L"lot",
    L"sun", L"war", L"job", L"eye", L"sir", L"god", L"law", L"cat", L"dog",
    L"saw", L"raw", L"own", L"red", L"top", L"arm",
    L"art", L"cut", L"fat", L"fit", L"fun", L"hit", L"hot",
    L"key", L"map", L"net", L"pay", L"per", L"sea", L"son", L"tea", L"yes",
    L"yet", L"app", L"dev", L"api", L"git", L"cli", L"sdk", L"log", L"bug", L"tab",
    L"cmd", L"tag", L"url", L"uri", L"ssh", L"ssl", L"sql", L"css", L"dom",

    // 4-letter words
    L"that", L"with", L"have", L"this", L"will", L"your", L"from", L"they", L"know",
    L"want", L"been", L"good", L"goods", L"much", L"some", L"time", L"very", L"when", L"come",
    L"here", L"just", L"like", L"long", L"make", L"many", L"more", L"only", L"over",
    L"such", L"take", L"than", L"them", L"well", L"were", L"down", L"show", L"look",
    L"help", L"book", L"back", L"work", L"part", L"even", L"most", L"open", L"stop",
    L"fast", L"post", L"text", L"test", L"code", L"data", L"user", L"view", L"file",
    L"menu", L"mode", L"form", L"type", L"page", L"list", L"item", L"card", L"case",
    L"base", L"size", L"name", L"home", L"free", L"true", L"null", L"void", L"main",
    L"loop", L"read", L"send", L"call", L"link", L"pass", L"path", L"room", L"door",
    L"root", L"cool", L"keep", L"feed", L"need", L"meet", L"week", L"seen", L"seem",
    L"feel", L"deep", L"tree", L"line", L"side", L"word", L"find", L"give", L"tell",
    L"head", L"hand", L"high", L"last", L"left", L"life", L"live", L"move", L"next",
    L"same", L"tool", L"cook", L"pool", L"foot", L"boot", L"hook", L"wood", L"wool",
    L"zoom", L"info", L"site", L"host", L"port", L"auth", L"sync", L"load", L"save",
    L"edit", L"copy", L"font", L"icon", L"grid", L"flex", L"hero", L"body",
    L"span", L"href", L"json", L"yaml", L"html", L"http", L"bash", L"zsh",
    L"node", L"rust", L"java", L"dart", L"ruby", L"perl", L"lisp", L"unix", L"sudo",
    L"cron", L"kill", L"grep", L"curl", L"echo", L"make", L"docs", L"mail",
    L"note", L"task", L"todo", L"done", L"fail", L"warn", L"date",
    L"year", L"hour", L"step", L"draw", L"flow", L"push", L"pull", L"fork", L"drop",
    L"morn", L"hard", L"yard", L"dark", L"park", L"mark", L"cost", L"best", L"past",
    L"west", L"east", L"lost",

    // 5-letter words
    L"about", L"after", L"again", L"below", L"could", L"every", L"first", L"found",
    L"great", L"house", L"large", L"never", L"other", L"place", L"point", L"right",
    L"small", L"sound", L"still", L"their", L"there", L"these", L"thing", L"think",
    L"three", L"water", L"where", L"which", L"world", L"would", L"write", L"class",
    L"const", L"style", L"state", L"start", L"print", L"input", L"error", L"reset",
    L"clear", L"click", L"close", L"count", L"build", L"setup", L"table", L"title",
    L"token", L"theme", L"image", L"index", L"order", L"event", L"group", L"modal",
    L"panel", L"block", L"alert", L"badge", L"check", L"radio", L"value", L"label",
    L"field", L"query", L"route", L"param", L"stack", L"queue", L"array",
    L"fetch", L"async", L"await", L"catch", L"throw", L"while", L"break", L"super",
    L"final", L"local", L"scope", L"parse", L"patch", L"merge", L"clone", L"stage",
    L"apply", L"shell", L"spawn", L"child", L"apple", L"linux", L"react", L"swift",
    L"macos", L"cloud", L"drive", L"share", L"trash", L"clean", L"color", L"width",
    L"scale", L"space", L"align", L"match", L"split", L"slice", L"shift", L"layer",
    L"frame", L"scene", L"audio", L"video", L"media", L"music", L"photo", L"track",
    L"album", L"voice", L"light", L"speed", L"power", L"level", L"score",
    L"night", L"today", L"party", L"phone", L"mouse", L"email", L"thank", L"sorry",
    L"hello",

    // 6+ letter programming & common words
    L"morning", L"mornings", L"evening", L"tonight", L"tomorrow", L"yesterday",
    L"welcome", L"friend", L"family", L"doctor", L"student", L"teacher", L"school",
    L"company", L"market", L"service", L"computer", L"mobile", L"laptop", L"screen",
    L"keyboard", L"message", L"letter", L"process", L"thanks", L"please",
    L"monday", L"tuesday", L"wednesday", L"thursday", L"friday", L"saturday", L"sunday",
    L"server", L"client", L"string", L"return", L"system", L"script", L"number",
    L"boolean", L"object", L"module", L"import", L"export", L"switch", L"struct",
    L"static", L"public", L"private", L"socket", L"thread", L"future", L"stream",
    L"buffer", L"widget", L"layout", L"window", L"syntax", L"editor", L"canvas",
    L"cursor", L"render", L"toggle", L"scroll", L"parser", L"schema", L"bundle",
    L"symbol", L"vector", L"matrix", L"vertex", L"shader", L"action", L"button",
    L"device", L"header", L"footer", L"border", L"shadow", L"radius",
    L"center", L"middle", L"bottom", L"format", L"source", L"target", L"length",
    L"active", L"cancel", L"remove", L"delete", L"update", L"insert", L"select",
    L"create", L"filter", L"search", L"result", L"status", L"config", L"option",
    L"custom", L"method", L"handle", L"runner", L"manage", L"domain", L"online",
    L"author", L"commit", L"master", L"branch", L"origin", L"remote", L"deploy",
    L"docker", L"python", L"github", L"gitlab", L"google", L"chrome", L"safari",
    L"firefox", L"terminal", L"console", L"package", L"library", L"project",
    L"framework", L"function", L"interface", L"component", L"container",
    L"controller", L"middleware", L"repository", L"navigation", L"background",
    L"foreground", L"environment", L"application", L"development", L"production",
    L"performance", L"optimization", L"configuration", L"authentication",
    L"authorization", L"accessibility", L"interceptor", L"notification",
    L"connection", L"exception", L"validation", L"subscriber",
    L"publisher", L"inspector", L"generator", L"simulator", L"preference",
    L"undefined", L"statement", L"expression", L"declaration", L"definition"
};

const std::unordered_set<std::wstring>& EnglishDictionary::getCommonWords() {
    return s_commonWords;
}

bool EnglishDictionary::isCommonEnglishWord(const std::wstring& word) {
    return s_commonWords.find(toLowerStr(word)) != s_commonWords.end();
}

