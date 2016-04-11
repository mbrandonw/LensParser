import Foundation

//
// Model example:
// typealias AppState = (theme: String, font: String)
//

struct Lens<A,B>{
    let get: A -> B
    let set: (B, A) -> A
}

//
// Lens Composition
//

infix operator • { associativity left precedence 250 }
func • <A,B,C> (left: Lens<A,B>, right: Lens<B,C>) -> Lens<A,C>{
    return Lens<A,C>(
        get: { a in
            let b = left.get(a)
            return right.get(b)
        },
        set: {c, a in
            let oldB = left.get(a)
            let newB = right.set(c, oldB)
            return left.set(newB, a)
        }
    )
}

// =================================================================
// ===================== L E N S - P A R S E R =====================
// =================================================================

//
// Primitives
//

private func characters(s: String) -> [String]{
    return s.characters.map{ String($0) }
}

private func tail<A>(xs: [A]) -> [A] {
    if xs.count == 0 { return [] }
    var ys = xs
    ys.removeFirst()
    return ys
}

private func couple<A>(xs: [A]) -> [(A?,A)]{
    return xs.enumerate().map{ i, a in
        if i == 0 { return (nil, a) }
        let previous = xs[i - 1]
        return (previous, a)
    }
}

//
// Token
//

private enum Category {
    case Insignificant
    case Colon
    case Unasigned
    case Key
    case WholeType
    case PartType
}

private struct Token {
    let lexeme: String
    let category: Category
}

private extension Token {
    func set(category: Category) -> Token {
        return Token(lexeme: self.lexeme, category: category)
    }
}

private func token(lexeme: String) -> Token{
    let category: Category
    switch lexeme {
    case "", " ", "(", ")", "=", "typealias", ",": category = .Insignificant
    case ":": category = .Colon
    default: category = .Unasigned
    }
    return Token(lexeme: lexeme, category: category)
}

//
// Parser
//

private func tokenizer(str: String) -> [Token]{
    func tokens(chars: [String], _ lexeme: String, _ xs: [Token]) -> [Token]{
        guard let char = chars.first else { return xs }
        let reminder = tail(chars)
        switch char {
        case " ", "=", ":", ",", "(", ")":
            return tokens(reminder, "", xs + [token(lexeme), token(char)])
        default:
            return tokens(reminder, lexeme + char, xs)
        }
    }
    let sequence = tokens(characters(str), "", []).filter{ $0.category != .Insignificant }
    return couple(sequence)
        .map{ previous, current  in
            guard current.category == .Unasigned else { return current }
            guard let previousToken = previous else { return current.set(.WholeType) }
            if previousToken.category == .Colon { return current.set(.PartType) }
            return current.set(.Key)
        }
        .filter{ $0.category != .Colon }
}

private typealias KeyTypeTuple = (key: String, partType: String)

private func keyTypeTuples(sequence: [Token]) -> [KeyTypeTuple]{
    return couple(sequence)
        .map{ previous, current in
            if previous?.category == .Key {
                return (previous?.lexeme ?? "", current.lexeme)
            }
            return nil
        }
        .flatMap{$0}
}

private func lensTemplate(sequence: [Token], _ part: KeyTypeTuple) -> String {
    let whole = sequence[0].lexeme
    let key = part.key
    let part = part.partType
    
    let setMethodTemplate = { (xs: [Token], key: String) -> String in
        var template = "{\(key), whole in ("
        let keys = xs.filter{$0.category == .Key}.map{$0.lexeme}
        for k in keys {
            if k == key       {template += key}
            else              {template += "whole." + k}
            if keys.last != k {template += ", "}
        }
        return template + ")}"
    }
    return "let \(key)Lens = Lens<\(whole), \(part)>(\nget: {$0.\(key)}, \nset: \(setMethodTemplate(sequence, key))\n)\n"
}

private func lensParser(string: String) -> String {
    let sequence = tokenizer(string)
    let tuples = keyTypeTuples(sequence)
    return tuples
        .map{ tuple in
            lensTemplate(sequence, tuple)
        }
        .reduce(""){ accum, lens in
            return accum + "\n" + lens
        }
}

//
// API
//

func main(model: String){
    print(lensParser(model))
}






