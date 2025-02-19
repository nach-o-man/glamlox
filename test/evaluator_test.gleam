import ast
import evaluator
import gleam/list
import gleeunit/should
import lox
import parser
import scanner

type LoxType =
  lox.LoxType

fn assert_ok(input: String) -> LoxType {
  let assert Ok(stmt) =
    scanner.scan_tokens(input <> ";")
    |> parser.parse
    |> list.first
  case stmt {
    ast.Var(_a, _b) -> {
      should.fail()
      lox.LoxNil
    }
    ast.Print(expr) | ast.Expression(expr) -> {
      expr
      |> evaluator.evaluate
      |> should.be_ok
    }
  }
}

fn assert_number(input: String, expected: Float) {
  assert_ok(input) |> should.equal(lox.LoxNumber(expected))
}

fn assert_string(input: String, expected: String) {
  assert_ok(input) |> should.equal(lox.LoxString(expected))
}

fn assert_true(input: String) {
  assert_ok(input) |> should.equal(lox.LoxBoolean(True))
}

fn assert_false(input: String) {
  assert_ok(input) |> should.equal(lox.LoxBoolean(False))
}

pub fn evaluate_unary_test() {
  assert_number("-1", -1.0)
  assert_number("--1", 1.0)
  assert_number("-1.23", -1.23)
  assert_false("!1")
  assert_false("!1.23")
  assert_false("!true")
  assert_false("!0")
  assert_false("!!false")
  assert_true("!false")
  assert_true("!nil")
}

pub fn evaluate_binary_float_test() {
  assert_number("4.2 / 2.1", 2.0)
  assert_number("1.2 * 2", 2.4)
  assert_number("2-1", 1.0)
}

pub fn evaluate_binary_string_test() {
  assert_string("\"A\" + \"B\"", "AB")
  assert_string("\"A\" + 4", "A4.0")
  assert_string("\"A\" + 4.2", "A4.2")
}

pub fn evaluate_binary_bool_test() {
  assert_true("4.2 > 2.1")
  assert_true("1 == 1")
  assert_true("1 >= 1")
  assert_true("1 >= 0.9")
  assert_true("1 <= 1")
  assert_true("1 <= 1.1")
  assert_true("\"A\" < \"a\"")
  assert_true("\"A\" <= \"A\"")
  assert_true("\"A\" == \"A\"")
  assert_true("\"z\" >= \"A\"")
  assert_true("\"A\" < \"Z\"")
  assert_true("\"A\" != \"a\"")
  assert_true("nil == nil")
  assert_false("4.2 < 2.1")
  assert_false("1 >= 1.2")
  assert_false("1 <= 0.9")
  assert_false("1 != 1")
  assert_false("\"A\" == \"a\"")
  assert_false("\"A\" != \"A\"")
}
