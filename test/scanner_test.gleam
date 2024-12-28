import gleam/list
import gleeunit/should
import scanner
import token

fn scan_and_map_to_string(input: String) -> List(String) {
  scanner.scan_tokens(input) |> list.map(token.to_string)
}

pub fn scan_single_tokens_test() {
  scan_and_map_to_string("     (){},.-+;=!<>/     ")
  |> should.equal([
    "LeftParen ( 0", "RightParen ) 0", "LeftBrace { 0", "RightBrace } 0",
    "Comma , 0", "Dot . 0", "Minus - 0", "Plus + 0", "Semicolon ; 0",
    "Equal = 0", "Bang ! 0", "Less < 0", "Greater > 0", "Slash / 0", "EOF 0",
  ])
}

pub fn scan_double_tokens_test() {
  scan_and_map_to_string("     !!====>=><<=   ")
  |> should.equal([
    "Bang ! 0", "BangEqual != 0", "EqualEqual == 0", "Equal = 0",
    "GreaterEqual >= 0", "Greater > 0", "Less < 0", "LessEqual <= 0", "EOF 0",
  ])
}

pub fn scan_single_line_comment_with_test() {
  scan_and_map_to_string(" // I am a comment! \n // So am I!")
  |> should.equal(["EOF 1"])
}

pub fn scan_newline_test() {
  scan_and_map_to_string(" \n \n ")
  |> should.equal(["EOF 2"])
}

pub fn scan_string_test() {
  scan_and_map_to_string(
    " \" I am terminated! \n Also \n I am Multiline! \" \n ",
  )
  |> should.equal([
    "String \" I am terminated! \n Also \n I am Multiline! \" 2", "EOF 3",
  ])
}

pub fn scan_integer_test() {
  scan_and_map_to_string("123a 456\n 7 8 9")
  |> should.equal([
    "Number 123 0", "Number 456 0", "Number 7 1", "Number 8 1", "Number 9 1",
    "EOF 1",
  ])
}

pub fn scan_float_test() {
  scan_and_map_to_string("12.3a 4.56\n .7 8.")
  |> should.equal([
    "Number 12.3 0", "Number 4.56 0", "Dot . 1", "Number 7 1", "Number 8 1",
    "Dot . 1", "EOF 1",
  ])
}
