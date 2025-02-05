import error
import evaluator
import expr
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

pub fn evaluate_binary_test() {
  parse_and_evaluate("2-1")
  |> should.be_ok
  |> should.equal(expr.IntLiteral(1))
  parse_and_evaluate("1.2 * 2")
  |> should.be_ok
  |> should.equal(expr.FloatLiteral(2.4))
  parse_and_evaluate("4.2 / 2.1")
  |> should.be_ok
  |> should.equal(expr.FloatLiteral(2.0))
}
