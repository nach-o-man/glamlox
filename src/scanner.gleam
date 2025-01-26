import error
import gleam/list
import gleam/string
import gleam/string_tree
import token
import token_type

type TokenType =
  token_type.TokenType

type Token =
  token.Token

type TokenList =
  List(Token)

type TokenScanResult =
  #(Result(Token, Nil), String, Int)

type ScannedToken {
  Single(tp: TokenType, lexeme: String)
  Double(tp: TokenType, lexeme: String)
  Ignored
  NewLine
  Comment
  CommentBlock
  String
  Number(first: String)
  Identifier(first: String)
  Unexpected(value: String, line: Int)
}

pub fn scan_tokens(source: String) -> TokenList {
  let #(scanned, line) = scan_tokens_recursive(source, [], 0)

  list.reverse([token.eof(line), ..scanned])
}

fn scan_tokens_recursive(
  source: String,
  scanned_tokens: List(token.Token),
  line: Int,
) -> #(TokenList, Int) {
  case source {
    "" -> #(scanned_tokens, line)
    _ -> {
      let #(new_token, rest_source, new_line) = scan_token(source, line)

      let scanned_tokens = case new_token {
        Ok(token) -> [token, ..scanned_tokens]
        _ -> scanned_tokens
      }
      scan_tokens_recursive(rest_source, scanned_tokens, new_line)
    }
  }
}

fn scan_token(source: String, line: Int) -> TokenScanResult {
  let assert Ok(#(first, rest)) = string.pop_grapheme(source)
  let scanned_token = case first {
    "(" -> Single(token_type.LeftParen, first)
    ")" -> Single(token_type.RightParen, first)
    "{" -> Single(token_type.LeftBrace, first)
    "}" -> Single(token_type.RightBrace, first)
    "," -> Single(token_type.Comma, first)
    "." -> Single(token_type.Dot, first)
    "-" -> Single(token_type.Minus, first)
    "+" -> Single(token_type.Plus, first)
    ";" -> Single(token_type.Semicolon, first)
    "*" -> Single(token_type.Star, first)
    "!" ->
      ternary(
        match_next(rest, "="),
        Double(token_type.BangEqual, "!="),
        Single(token_type.Bang, first),
      )
    "=" ->
      ternary(
        match_next(rest, "="),
        Double(token_type.EqualEqual, "=="),
        Single(token_type.Equal, first),
      )
    ">" ->
      ternary(
        match_next(rest, "="),
        Double(token_type.GreaterEqual, ">="),
        Single(token_type.Greater, first),
      )
    "<" ->
      ternary(
        match_next(rest, "="),
        Double(token_type.LessEqual, "<="),
        Single(token_type.Less, first),
      )
    "/" ->
      ternary(
        match_next(rest, "/"),
        Comment,
        ternary(
          match_next(rest, "*"),
          CommentBlock,
          Single(token_type.Slash, first),
        ),
      )
    " " | "\r" | "\t" -> Ignored
    "\n" -> NewLine
    "\"" -> String
    _ as other -> {
      case is_digit(other) {
        True -> Number(other)
        False -> {
          case is_alpha(other) {
            True -> Identifier(other)
            False -> Unexpected(first, line)
          }
        }
      }
    }
  }

  process_scanned_token(scanned_token, rest, line)
}

fn line_shift(source: String) -> Int {
  list.count(string.to_graphemes(source), fn(str) { str == "\n" })
}

fn process_scanned_token(
  scanned_token: ScannedToken,
  source: String,
  line,
) -> TokenScanResult {
  case scanned_token {
    Single(tp, lex) -> {
      let token = token.single(tp, lex, line)
      #(Ok(token), source, line)
    }
    Double(tp, lex) -> {
      let token = token.double(tp, lex, line)
      // since second symbol of token is in the source
      let new_rest = string.drop_start(source, 1)
      #(Ok(token), new_rest, line)
    }
    Comment -> {
      case string.split_once(source, "\n") {
        Error(_) -> #(Error(Nil), "", line)
        Ok(#(_left, right)) -> #(Error(Nil), right, line + 1)
      }
    }
    CommentBlock -> {
      case string.split_once(source, "*/") {
        Error(_) -> error.error(line, "Unterminated comment block")
        Ok(#(left, right)) -> {
          let new_line = line_shift(left) + line
          #(Error(Nil), right, new_line)
        }
      }
    }
    NewLine -> {
      #(Error(Nil), source, line + 1)
    }
    String -> {
      case string.split_once(source, "\"") {
        Error(_) -> error.error(line, "Unterminated string")
        Ok(#(left, right)) -> {
          let new_line = line_shift(left) + line
          let token = token.string("\"" <> left <> "\"", left, new_line)
          #(Ok(token), right, new_line)
        }
      }
    }
    Number(start) -> {
      let #(result, rest_source) =
        read_number(source, string_tree.from_string(start))
      let token = token.number(result, line)
      #(Ok(token), rest_source, line)
    }
    Identifier(start) -> {
      let #(maybe_keyword, rest_source) =
        read_identifier(source, string_tree.from_string(start))
      let token = case check_keyword(maybe_keyword) {
        Ok(keyword_type) -> token.keyword(keyword_type, maybe_keyword, line)
        Error(_) -> token.identifier(maybe_keyword, line)
      }
      #(Ok(token), rest_source, line)
    }
    Ignored -> #(Error(Nil), source, line)
    Unexpected(value, line) ->
      error.error(line, "Unexpected character " <> value <> ".")
  }
}

fn read_identifier(
  source: String,
  accumulator: string_tree.StringTree,
) -> #(String, String) {
  let tested = string.pop_grapheme(source)
  case tested {
    Error(_) -> #(string_tree.to_string(accumulator), source)
    Ok(#(maybe_alphanumeric, rest_source)) -> {
      case is_alphanumeric(maybe_alphanumeric) {
        True ->
          read_identifier(
            rest_source,
            string_tree.append(accumulator, maybe_alphanumeric),
          )
        False -> #(string_tree.to_string(accumulator), source)
      }
    }
  }
}

fn read_number(
  source: String,
  accumulator: string_tree.StringTree,
) -> #(String, String) {
  let tested = string.pop_grapheme(source)
  case tested {
    Error(_) -> #(string_tree.to_string(accumulator), source)
    Ok(#(maybe_digit, rest_source)) -> {
      case is_digit(maybe_digit) {
        True ->
          read_number(rest_source, string_tree.append(accumulator, maybe_digit))
        False -> {
          case maybe_digit {
            "." ->
              case string.first(rest_source) {
                Error(_) -> #(string_tree.to_string(accumulator), source)
                Ok(_) ->
                  read_number(
                    rest_source,
                    string_tree.append(accumulator, maybe_digit),
                  )
              }
            _ -> #(string_tree.to_string(accumulator), source)
          }
        }
      }
    }
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

fn is_digit(source: String) -> Bool {
  case assert_single_character(source) {
    "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "0" -> True
    _ -> False
  }
}

fn is_alpha(source: String) -> Bool {
  case assert_single_character(source) {
    "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z"
    | "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z"
    | "_" -> True
    _ -> False
  }
}

fn is_alphanumeric(source: String) -> Bool {
  is_digit(source) || is_alpha(source)
}

fn check_keyword(source: String) -> Result(TokenType, Nil) {
  case source {
    "and" -> Ok(token_type.And)
    "class" -> Ok(token_type.Class)
    "else" -> Ok(token_type.Else)
    "false" -> Ok(token_type.False)
    "for" -> Ok(token_type.For)
    "fun" -> Ok(token_type.Fun)
    "if" -> Ok(token_type.If)
    "nil" -> Ok(token_type.Nil)
    "or" -> Ok(token_type.Or)
    "print" -> Ok(token_type.Print)
    "return" -> Ok(token_type.Return)
    "super" -> Ok(token_type.Super)
    "this" -> Ok(token_type.This)
    "true" -> Ok(token_type.True)
    "var" -> Ok(token_type.Var)
    "while" -> Ok(token_type.While)
    _ -> Error(Nil)
  }
}

fn assert_single_character(maybe_single: String) -> String {
  case string.length(maybe_single) {
    1 -> maybe_single
    _ -> panic as "function should be called with with single length string"
  }
}
