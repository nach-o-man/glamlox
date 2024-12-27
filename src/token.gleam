import gleam/int
import gleam/string

pub type TokenType {
  // Single-character tokens.
  LeftParen
  RightParen
  LeftBrace
  RightBrace

  Comma
  Dot
  Minus
  Plus
  Semicolon
  Slash
  Star

  // One or two character tokens.
  Bang
  BangEqual
  Equal
  EqualEqual
  Greater
  GreaterEqual
  Less
  LessEqual

  // Literals.
  Identifier
  String
  Number

  // Keywords.
  And
  Class
  Else
  False
  Fun
  For
  If
  Nil
  Or
  Print
  Return
  Super
  This
  True
  Var
  While

  Eof
}

pub opaque type Token {
  SingleToken(tp: TokenType, lexeme: String, line: Int)
  DoubleToken(tp: TokenType, lexeme: String, line: Int)
  NumberToken(tp: TokenType, lexeme: String, literal: Float, line: Int)
  StringToken(tp: TokenType, lexeme: String, literal: String, line: Int)
  EofToken(tp: TokenType, line: Int)
}

pub fn single(tp: TokenType, lexeme: String, line: Int) -> Token {
  case tp {
    LeftParen
    | RightParen
    | LeftBrace
    | RightBrace
    | Comma
    | Dot
    | Minus
    | Plus
    | Semicolon
    | Slash
    | Bang
    | Equal
    | Greater
    | Less
    | Star -> SingleToken(tp, lexeme, line)
    _ ->
      panic as {
        "Unable to build single token with type: " <> string.inspect(tp)
      }
  }
}

pub fn double(tp: TokenType, lexeme: String, line: Int) -> Token {
  case tp {
    BangEqual | EqualEqual | GreaterEqual | LessEqual ->
      DoubleToken(tp, lexeme, line)
    _ ->
      panic as {
        "Unable to build double token with type: " <> string.inspect(tp)
      }
  }
}

pub fn eof(line: Int) -> Token {
  EofToken(Eof, line)
}

pub fn string(lexeme: String, literal: String, line: Int) -> Token {
  StringToken(String, lexeme, literal, line)
}

pub fn to_string(token: Token) -> String {
  case token {
    SingleToken(tp, lexeme, line)
    | DoubleToken(tp, lexeme, line)
    | NumberToken(tp, lexeme, _literal, line)
    | StringToken(tp, lexeme, _literal, line) ->
      string.inspect(tp) <> " " <> lexeme <> " " <> int.to_string(line)
    EofToken(_, line) -> "EOF " <> int.to_string(line)
  }
}
