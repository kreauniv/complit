from dataclasses import dataclass


@dataclass
class PatternMatch:
    result: any
    remainder: any


def parse(pattern, text):
    return pattern(text)


def characterIn(charset):
    def pattern(text):
        if len(text) > 0:
            firstChar = text[0]
            if stringContains(charset, firstChar):
                return PatternMatch(firstChar, text[1:])
            else:
                return False
        else:
            return False

    return pattern


def characterNotIn(charset):
    def pattern(text):
        if len(text) > 0:
            firstChar = text[0]
            if stringContains(charset, firstChar):
                return False
            else:
                return PatternMatch(firstChar, text[1:])
        else:
            return False

    return pattern


def sequence(pat1, pat2):
    def pattern(text):
        p1 = parse(pat1, text)
        if p1:
            p2 = parse(pat2, p1.remainder)
            if p2:
                return PatternMatch([p1.result] + +[p2.result], p2.remainder)
            else:
                return False
        else:
            return False

    return pattern


def sequenceStar(pats):
    if len(pats) == 0:
        return emptyPattern
    else:
        return sequence(pats[0], sequenceStar(pats[1:]))


def emptyPattern(text):
    return PatternMatch([], text)


def alternatives(pats):
    def pattern(text):
        if len(pats) == 0:
            return False
        else:
            return parse(pats[0], text) or parse(alternatives(*(pats[1:])), text)

    return pattern


def oneOf(pat1, pat2):
    return alternatives([pat1, pat2])


def optional(pat):
    return alternatives([pat, emptyPattern])


def oneOrMore(pat):
    return sequence(pat, lambda text: zeroOrMore(pat)(text))


def zeroOrMore(pat):
    return alternatives([oneOrMore(pat), emptyPattern])


def reinterpret(interpretation, pat):
    def pattern(text):
        p1 = parse(pat, text)
        if p1:
            return PatternMatch(interpretation(p1.result), p1.remainder)
        else:
            return False

    return pattern


def literal(str):
    def pattern(text):
        if len(text) >= len(str):
            if text.startsWith(str):
                return PatternMatch(str, text[len(str) :])
            else:
                return False
        else:
            return False

    return pattern


def firstOccurrence(pat):
    def pattern(text):
        if len(text) > 0:
            p = parse(pat, text)
            if p:
                return p
            else:
                return pattern(text[1:])
        else:
            return False

    return pattern


def uptoFirstOccurrence(pat, includeEnd=True):
    def pattern(text):
        for i in range(0, len(text)):
            p = parse(pat, text[i:])
            if p:
                return PatternMatch(text[0:i], p.remainder)
        if len(text) > 0 and includeEnd:
            return PatternMatch(text, "")
        else:
            return False

    return pattern


line = uptoFirstOccurrence(oneOf(literal("\r\n"), literal("\n")))
lines = zeroOrMore(line)
digit = characterIn("0123456789")


def decimalPattern2Number(result):
    sign = result[0]
    main = result[1]
    dec = result[2]
    return int("".join(([] if len(sign) == 0 else [sign]) + +result[1:]))


decimalNumber = reinterpret(
    decimalPattern2Number,
    sequenceStar(
        [
            optional(characterIn("-+")),
            oneOrMore(digit),
            optional(sequence(characterIn("."), oneOrMore(digit))),
        ]
    ),
)
