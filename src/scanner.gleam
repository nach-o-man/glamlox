import gleam/list
import gleam/option
import gleam/string
import token

type ScannedToken {
  Single(tp: token.TokenType)
  Double(tp: token.TokenType)
  Ignored
  NewLine
  Comment
  String
  Unknown
}

pub fn scan_tokens(source: String) -> List(token.Token) {
  let graphemes = string.to_graphemes(source)
  let #(scanned, line) = scan_tokens_inner(graphemes, [], 0)

  list.append(scanned, [token.eof(line)])
}

fn scan_tokens_inner(
  graphemes: List(String),
  scanned_tokens: List(token.Token),
  line: Int,
) -> #(List(token.Token), Int) {
  case graphemes {
    [] -> #(scanned_tokens, line)
    _ -> {
      let #(new_token, rest_graphemes, new_line) = scan_token(graphemes, line)

      let scanned_tokens = case new_token {
        option.Some(token) -> list.append(scanned_tokens, [token])
        _ -> scanned_tokens
      }
      scan_tokens_inner(rest_graphemes, scanned_tokens, new_line)
    }
  }
}

fn scan_token(
  graphemes: List(String),
  line: Int,
) -> #(option.Option(token.Token), List(String), Int) {
  let assert Ok(first) = list.first(graphemes)
  let scanned_token = case first {
    "(" -> Single(token.LeftParen)
    ")" -> Single(token.RightParen)
    "{" -> Single(token.LeftBrace)
    "}" -> Single(token.RightBrace)
    "," -> Single(token.Comma)
    "." -> Single(token.Dot)
    "-" -> Single(token.Minus)
    "+" -> Single(token.Plus)
    ";" -> Single(token.Semicolon)
    "*" -> Single(token.Star)
    "!" -> try_match_next(graphemes, "=", token.BangEqual, token.Bang)
    "=" -> try_match_next(graphemes, "=", token.EqualEqual, token.Equal)
    ">" -> try_match_next(graphemes, "=", token.GreaterEqual, token.Greater)
    "<" -> try_match_next(graphemes, "=", token.LessEqual, token.Less)
    "/" -> {
      case match_next(graphemes, "/") {
        True -> Comment
        False -> Single(token.Slash)
      }
    }
    " " | "\r" | "\t" -> Ignored
    "\n" -> NewLine
    "\"" -> String
    _ -> Unknown
  }

  process_scanned_token(scanned_token, graphemes, line)
}

fn process_scanned_token(
  scanned_token: ScannedToken,
  graphemes: List(String),
  line,
) -> #(option.Option(token.Token), List(String), Int) {
  case scanned_token {
    Single(token_type) -> {
      let #(left, right) = list.split(graphemes, 1)
      let token = token.single(token_type, string.join(left, ""), line)
      #(option.Some(token), right, line)
    }
    Double(token_type) -> {
      let #(left, right) = list.split(graphemes, 2)
      let token = token.double(token_type, string.join(left, ""), line)
      #(option.Some(token), right, line)
    }
    Comment -> {
      #(option.None, list.drop_while(graphemes, fn(gr) { gr != "\n" }), line)
    }
    NewLine -> {
      let new_line = line + 1
      #(option.None, list.drop(graphemes, 1), new_line)
    }
    String -> {
      let #(left_quote, rest) = list.split(graphemes, 1)
      let #(data, right) = list.split_while(rest, fn(gr) { gr != "\"" })
      case right {
        [] -> panic as "Unterminated string."
        _ -> {
          let #(right_quote, rest) = list.split(right, 1)
          let lexeme =
            list.append(left_quote, data)
            |> list.append(right_quote)
            |> string.join("")
          let value = string.join(data, "")
          let new_line = list.count(data, fn(gr) { gr == "\n" }) + line
          #(option.Some(token.string(lexeme, value, new_line)), rest, new_line)
        }
      }
    }
    _ -> #(option.None, list.drop(graphemes, 1), line)
  }
}

fn match_next(graphemes: List(String), expected: String) -> Bool {
  let graphemes = list.rest(graphemes)
  case graphemes {
    Error(_) -> False
    Ok(data) -> {
      let assert Ok(next) = list.first(data)
      next == expected
    }
  }
}

fn try_match_next(
  graphemes: List(String),
  expected: String,
  true_result: token.TokenType,
  false_result: token.TokenType,
) -> ScannedToken {
  let match_result = match_next(graphemes, expected)
  case match_result {
    True -> Double(true_result)
    False -> Single(false_result)
  }
}
