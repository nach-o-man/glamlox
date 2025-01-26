import ast
import gleeunit/should
import parser
import scanner

fn parse_and_print(input: String) -> String {
  scanner.scan_tokens(input) |> parser.parse |> ast.print_expr
}

pub fn parse_primary_test() {
  parse_and_print("((false))") |> should.equal("(group (group False))")
  parse_and_print("(true)") |> should.equal("(group True)")
  parse_and_print("nil") |> should.equal("nil")
  parse_and_print("123") |> should.equal("123")
  parse_and_print("\"abc\"") |> should.equal("abc")
  parse_and_print("123.45") |> should.equal("123.45")
}

pub fn parse_unary_test() {
  parse_and_print("-1") |> should.equal("(- 1)")
  parse_and_print("!2") |> should.equal("(! 2)")
  parse_and_print("!-3") |> should.equal("(! (- 3))")
}

pub fn parse_factor_test() {
  parse_and_print("2 * -1") |> should.equal("(* 2 (- 1))")
  parse_and_print("3 / !2") |> should.equal("(/ 3 (! 2))")
}

pub fn parse_term_test() {
  parse_and_print("1 + 2 * -3") |> should.equal("(+ 1 (* 2 (- 3)))")
  parse_and_print("(1 + 2) * 3") |> should.equal("(* (group (+ 1 2)) 3)")
  parse_and_print("1 - 2 / !3") |> should.equal("(- 1 (/ 2 (! 3)))")
  parse_and_print("(1 - 2) / 3") |> should.equal("(/ (group (- 1 2)) 3)")
}

pub fn parse_comparison_test() {
  parse_and_print("1 > (2 * 3)") |> should.equal("(> 1 (group (* 2 3)))")
  parse_and_print("1 < 2") |> should.equal("(< 1 2)")
  parse_and_print("1 >= 2") |> should.equal("(>= 1 2)")
  parse_and_print("1 <= 2") |> should.equal("(<= 1 2)")
}

pub fn parse_equality_test() {
  parse_and_print("1 > (2 * 3) == 4")
  |> should.equal("(== (> 1 (group (* 2 3))) 4)")
  parse_and_print("1 > (2 * 3) != 4")
  |> should.equal("(!= (> 1 (group (* 2 3))) 4)")
}
