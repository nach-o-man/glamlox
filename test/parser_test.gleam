import ast
import gleeunit/should
import parser
import scanner

fn assert_equals(input: String, expected: String) {
  scanner.scan_tokens(input)
  |> parser.parse
  |> ast.print_expr
  |> should.equal(expected)
}

pub fn parse_primary_test() {
  assert_equals("((false))", "(group (group False))")
  assert_equals("(true)", "(group True)")
  assert_equals("nil", "nil")
  assert_equals("123", "123")
  assert_equals("\"abc\"", "abc")
  assert_equals("123.45", "123.45")
}

pub fn parse_unary_test() {
  assert_equals("-1", "(- 1)")
  assert_equals("!2", "(! 2)")
  assert_equals("!-3", "(! (- 3))")
}

pub fn parse_factor_test() {
  assert_equals("2 * -1", "(* 2 (- 1))")
  assert_equals("3 / !2", "(/ 3 (! 2))")
  assert_equals("1 * 2 * 3", "(* (* 1 2) 3)")
  assert_equals("1 * 2 / 3", "(/ (* 1 2) 3)")
  assert_equals("1 / 2 * 3", "(* (/ 1 2) 3)")
  assert_equals("1 / 2 / 3", "(/ (/ 1 2) 3)")
}

pub fn parse_term_test() {
  assert_equals("1 + 2 * -3", "(+ 1 (* 2 (- 3)))")
  assert_equals("1 + 2 + 3", "(+ (+ 1 2) 3)")
  assert_equals("1 + 2 - 3", "(- (+ 1 2) 3)")
  assert_equals("1 - 2 + 3", "(+ (- 1 2) 3)")
  assert_equals("1 - 2 - 3", "(- (- 1 2) 3)")
  assert_equals("(1 + 2) * 3", "(* (group (+ 1 2)) 3)")
  assert_equals("1 - 2 / !3", "(- 1 (/ 2 (! 3)))")
  assert_equals("(1 - 2) / 3", "(/ (group (- 1 2)) 3)")
}

pub fn parse_comparison_test() {
  assert_equals("1 > (2 * 3)", "(> 1 (group (* 2 3)))")
  assert_equals("1 < 2", "(< 1 2)")
  assert_equals("1 >= 2", "(>= 1 2)")
  assert_equals("1 <= 2", "(<= 1 2)")
  assert_equals("1 < 2 < 3", "(< (< 1 2) 3)")
}

pub fn parse_equality_test() {
  assert_equals("1 > (2 * 3) == 4", "(== (> 1 (group (* 2 3))) 4)")
  assert_equals("1 > (2 * 3) != 4", "(!= (> 1 (group (* 2 3))) 4)")
  assert_equals("1 == 2 == 3", "(== (== 1 2) 3)")
}
