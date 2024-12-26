import gleam/list
import gleam/option
import gleeunit/should
import scanner
import token

pub fn scan_single_tokens_test() {
  scanner.scan_tokens("     (){},.-+;=!<>/     ")
  |> list.map(fn(token) { token.tp })
  |> should.equal([
    token.LeftParen,
    token.RightParen,
    token.LeftBrace,
    token.RightBrace,
    token.Comma,
    token.Dot,
    token.Minus,
    token.Plus,
    token.Semicolon,
    token.Equal,
    token.Bang,
    token.Less,
    token.Greater,
    token.Slash,
    token.Eof,
  ])
}

pub fn scan_double_tokens_test() {
  scanner.scan_tokens("     !!====>=><<=   ")
  |> list.map(fn(token) { token.tp })
  |> should.equal([
    token.Bang,
    token.BangEqual,
    token.EqualEqual,
    token.Equal,
    token.GreaterEqual,
    token.Greater,
    token.Less,
    token.LessEqual,
    token.Eof,
  ])
}

pub fn scan_single_line_comment_test() {
  scanner.scan_tokens(" // I am a comment! \n")
  |> list.map(fn(token) { #(token.tp, token.line) })
  |> should.equal([#(token.Eof, 1)])
}

pub fn scan_newline_test() {
  scanner.scan_tokens(" \n \n ")
  |> list.map(fn(token) { #(token.tp, token.line) })
  |> should.equal([#(token.Eof, 2)])
}

// pub fn scan_unterminated_string_test() {
//   scanner.scan_tokens("\"I am unterminated! ")
// }

pub fn scan_string_test() {
  scanner.scan_tokens(" \" I am terminated! \n Also \n I am Multiline! \" \n ")
  |> should.equal([
    token.Token(
      token.String,
      "\" I am terminated! \n Also \n I am Multiline! \"",
      option.Some(" I am terminated! \n Also \n I am Multiline! "),
      2,
    ),
    token.Token(token.Eof, "", option.None, 3),
  ])
}
