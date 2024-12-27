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
    "left_paren ( 0", "right_paren ) 0", "left_brace { 0", "right_brace } 0",
    "comma , 0", "dot . 0", "minus - 0", "plus + 0", "semicolon ; 0",
    "equal = 0", "bang ! 0", "less < 0", "greater > 0", "slash / 0", "EOF 0",
  ])
}

pub fn scan_double_tokens_test() {
  scan_and_map_to_string("     !!====>=><<=   ")
  |> should.equal([
    "bang ! 0", "bang_equal != 0", "equal_equal == 0", "equal = 0",
    "greater_equal >= 0", "greater > 0", "less < 0", "less_equal <= 0", "EOF 0",
  ])
}

pub fn scan_single_line_comment_test() {
  scan_and_map_to_string(" // I am a comment! \n")
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
    "string \" I am terminated! \n Also \n I am Multiline! \" 2", "EOF 3",
  ])
}
