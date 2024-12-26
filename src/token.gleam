import gleam/erlang
import gleam/option

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
  Token(
    tp: TokenType,
    lexeme: String,
    literal: option.Option(String),
    line: Int,
  )
}

pub fn new(
  tp: TokenType,
  lexeme: String,
  literal: option.Option(String),
  line: Int,
) -> Token {
  Token(tp, lexeme, literal, line)
}

pub fn to_string(token: Token) -> String {
  erlang.format(token.tp)
  <> " "
  <> token.lexeme
  <> " "
  <> option.unwrap(token.literal, erlang.format(Nil))
}
