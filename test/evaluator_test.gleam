import error
import evaluator
import expr
import gleam/dict
import gleeunit/should
import parser
import scanner

fn parse_and_evaluate(input: String) -> Result(expr.Expr, error.ExpressionError) {
  scanner.scan_tokens(input) |> parser.parse |> evaluator.evaluate
}

pub fn evaluate_unary_test() {
  parse_and_evaluate("-1")
  |> should.be_ok
  |> should.equal(expr.IntLiteral(-1))
  parse_and_evaluate("--1")
  |> should.be_ok
  |> should.equal(expr.IntLiteral(1))
  parse_and_evaluate("-1.23")
  |> should.be_ok
  |> should.equal(expr.FloatLiteral(-1.23))
  parse_and_evaluate("!1")
  |> should.be_ok
  |> should.equal(expr.BoolLiteral(False))
  parse_and_evaluate("!1.23")
  |> should.be_ok
  |> should.equal(expr.BoolLiteral(False))
  parse_and_evaluate("!nil")
  |> should.be_ok
  |> should.equal(expr.BoolLiteral(True))
  parse_and_evaluate("!true")
  |> should.be_ok
  |> should.equal(expr.BoolLiteral(False))
  parse_and_evaluate("!0")
  |> should.be_ok
  |> should.equal(expr.BoolLiteral(False))
  parse_and_evaluate("!!false")
  |> should.be_ok
  |> should.equal(expr.BoolLiteral(False))
  parse_and_evaluate("!false")
  |> should.be_ok
  |> should.equal(expr.BoolLiteral(True))
}

pub fn evaluate_binary_float_test() {
  let input =
    dict.from_list([#("2-1", 1.0), #("1.2 * 2", 2.4), #("4.2 / 2.1", 2.0)])

  dict.each(input, fn(k, v) {
    parse_and_evaluate(k)
    |> should.be_ok
    |> should.equal(expr.FloatLiteral(v))
  })
}

pub fn evaluate_binary_string_test() {
  let input =
    dict.from_list([
      #("\"A\" + \"B\"", "AB"),
      #("\"A\" + 4", "A4"),
      #("\"A\" + 4.2", "A4.2"),
    ])

  dict.each(input, fn(k, v) {
    parse_and_evaluate(k)
    |> should.be_ok
    |> should.equal(expr.StringLiteral(v))
  })
}

pub fn evaluate_binary_bool_test() {
  let input =
    dict.from_list([
      #("4.2 < 2.1", False),
      #("4.2 > 2.1", True),
      #("1 == 1", True),
      #("1 >= 1", True),
      #("1 >= 0.9", True),
      #("1 >= 1.2", False),
      #("1 <= 1", True),
      #("1 <= 1.1", True),
      #("1 <= 0.9", False),
      #("1 != 1", False),
      #("\"A\" == \"a\"", False),
      #("\"A\" < \"a\"", True),
      #("\"A\" <= \"A\"", True),
      #("\"A\" == \"A\"", True),
      #("\"z\" >= \"A\"", True),
      #("\"A\" < \"Z\"", True),
      #("\"A\" != \"a\"", True),
      #("\"A\" != \"A\"", False),
      #("nil == nil", True),
    ])

  dict.each(input, fn(k, v) {
    parse_and_evaluate(k)
    |> should.be_ok
    |> should.equal(expr.BoolLiteral(v))
  })
}
