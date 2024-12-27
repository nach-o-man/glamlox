import gleam/list
import gleam/option
import gleam/string
import token

type ScannedToken {
  Single(tp: token.TokenType, lexeme: String)
  Double(tp: token.TokenType, lexeme: String)
  Ignored
  NewLine
  Comment
  String
  Unknown
}

pub fn scan_tokens(source: String) -> List(token.Token) {
  let #(scanned, line) = scan_tokens_inner(source, [], 0)

  list.append(scanned, [token.eof(line)])
}

fn scan_tokens_inner(
  source: String,
  scanned_tokens: List(token.Token),
  line: Int,
) -> #(List(token.Token), Int) {
  case source {
    "" -> #(scanned_tokens, line)
    _ -> {
      let #(new_token, rest_source, new_line) = scan_token(source, line)

      let scanned_tokens = case new_token {
        option.Some(token) -> list.append(scanned_tokens, [token])
        _ -> scanned_tokens
      }
      scan_tokens_inner(rest_source, scanned_tokens, new_line)
    }
  }
}

fn scan_token(
  source: String,
  line: Int,
) -> #(option.Option(token.Token), String, Int) {
  let assert Ok(#(first, rest)) = string.pop_grapheme(source)
  let scanned_token = case first {
    "(" -> Single(token.LeftParen, first)
    ")" -> Single(token.RightParen, first)
    "{" -> Single(token.LeftBrace, first)
    "}" -> Single(token.RightBrace, first)
    "," -> Single(token.Comma, first)
    "." -> Single(token.Dot, first)
    "-" -> Single(token.Minus, first)
    "+" -> Single(token.Plus, first)
    ";" -> Single(token.Semicolon, first)
    "*" -> Single(token.Star, first)
    "!" ->
      ternary(
        match_next(rest, "="),
        Double(token.BangEqual, "!="),
        Single(token.Bang, first),
      )
    "=" ->
      ternary(
        match_next(rest, "="),
        Double(token.EqualEqual, "=="),
        Single(token.Equal, first),
      )
    ">" ->
      ternary(
        match_next(rest, "="),
        Double(token.GreaterEqual, ">="),
        Single(token.Greater, first),
      )
    "<" ->
      ternary(
        match_next(rest, "="),
        Double(token.LessEqual, "<="),
        Single(token.Less, first),
      )
    "/" -> ternary(match_next(rest, "/"), Comment, Single(token.Slash, first))
    " " | "\r" | "\t" -> Ignored
    "\n" -> NewLine
    "\"" -> String
    _ -> Unknown
  }

  process_scanned_token(scanned_token, rest, line)
}

fn process_scanned_token(
  scanned_token: ScannedToken,
  source: String,
  line,
) -> #(option.Option(token.Token), String, Int) {
  case scanned_token {
    Single(tp, lex) -> {
      let token = token.single(tp, lex, line)
      #(option.Some(token), source, line)
    }
    Double(tp, lex) -> {
      let token = token.double(tp, lex, line)
      // since second symbol of token is in the source
      let new_rest = string.drop_start(source, 1)
      #(option.Some(token), new_rest, line)
    }
    Comment -> {
      case string.split_once(source, "\n") {
        Error(_) -> #(option.None, "", line)
        Ok(#(_left, right)) -> #(option.None, right, line + 1)
      }
    }
    NewLine -> {
      #(option.None, source, line + 1)
    }
    String -> {
      case string.split_once(source, "\"") {
        Error(_) -> panic as "Unterminated string"
        Ok(#(left, right)) -> {
          let new_line =
            list.count(string.to_graphemes(left), fn(str) { str == "\n" })
          let token = token.string("\"" <> left <> "\"", left, new_line)
          #(option.Some(token), right, new_line)
        }
      }
    }
    _ -> #(option.None, source, line)
  }
}

fn match_next(source: String, expected: String) -> Bool {
  case string.first(source) {
    Error(_) -> False
    Ok(data) -> data == expected
  }
}

fn ternary(condition: Bool, true_result: value, false_result: value) -> value {
  case condition {
    True -> true_result
    False -> false_result
  }
}
