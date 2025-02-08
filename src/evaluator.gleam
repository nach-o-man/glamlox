import error
import expr
import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/order
import token
import token_type

type Token =
  token.Token

type Expr =
  expr.Expr

type EvalResult =
  Result(Expr, error.ExpressionError)

type NumberPair =
  #(Float, Float)

type CustomOrder {
  Gt
  GtEq
  LtEq
  Lt
}

pub fn evaluate(expr: Expr) -> EvalResult {
  case expr {
    expr.BoolLiteral(_)
    | expr.FloatLiteral(_)
    | expr.IntLiteral(_)
    | expr.StringLiteral(_)
    | expr.NilLiteral -> Ok(expr)
    expr.Unary(op, r) -> evaluate_unary(op, r)
    expr.Binary(l, op, r) -> evaluate_binary(op, l, r)
    _ -> {
      io.debug(expr)
      todo
    }
  }
}

fn is_truthy(expr: Expr) -> Bool {
  case expr {
    expr.BoolLiteral(val) -> val
    expr.NilLiteral -> False
    _ -> True
  }
}

fn assert_number(expr: expr.Expr) -> Float {
  case expr {
    expr.FloatLiteral(value) -> value
    expr.IntLiteral(value) -> int.to_float(value)
    _ -> panic as "Number expected"
  }
}

fn assert_numbers(left: expr.Expr, right: expr.Expr) -> NumberPair {
  #(assert_number(left), assert_number(right))
}

fn division_by_zero_eq_zero(a: Float, b: Float) -> Float {
  case float.divide(a, b) {
    Ok(val) -> val
    _ -> 0.0
  }
}

fn pipe_to_func(pair: NumberPair, func: fn(Float, Float) -> Float) -> EvalResult {
  func(pair.0, pair.1) |> expr.FloatLiteral |> Ok
}

fn expected_order(pair: NumberPair, expected: CustomOrder) -> EvalResult {
  let result = case expected {
    Gt -> order.break_tie(float.compare(pair.0, pair.1), order.Eq) == order.Gt
    GtEq -> order.break_tie(float.compare(pair.0, pair.1), order.Gt) == order.Gt
    Lt -> order.break_tie(float.compare(pair.0, pair.1), order.Eq) == order.Lt
    LtEq -> order.break_tie(float.compare(pair.0, pair.1), order.Lt) == order.Lt
  }
  result |> expr.BoolLiteral |> Ok
}

fn evaluate_binary(operator: Token, left, right) -> EvalResult {
  let assert Ok(left) = evaluate(left)
  let assert Ok(right) = evaluate(right)

  case token.tp(operator) {
    token_type.Minus ->
      assert_numbers(left, right) |> pipe_to_func(float.subtract)
    token_type.Slash ->
      assert_numbers(left, right) |> pipe_to_func(division_by_zero_eq_zero)
    token_type.Star ->
      assert_numbers(left, right) |> pipe_to_func(float.multiply)
    token_type.Plus ->
      case left, right {
        expr.StringLiteral(s1), expr.StringLiteral(s2) ->
          expr.StringLiteral(s1 <> s2) |> Ok
        _, _ -> assert_numbers(left, right) |> pipe_to_func(float.add)
      }
    token_type.Greater -> assert_numbers(left, right) |> expected_order(Gt)
    token_type.GreaterEqual ->
      assert_numbers(left, right) |> expected_order(GtEq)
    token_type.EqualEqual -> { left == right } |> expr.BoolLiteral |> Ok
    token_type.BangEqual -> { left != right } |> expr.BoolLiteral |> Ok
    token_type.LessEqual -> assert_numbers(left, right) |> expected_order(LtEq)
    token_type.Less -> assert_numbers(left, right) |> expected_order(Lt)
    _ -> {
      io.debug(left)
      io.debug(operator)
      io.debug(right)
      todo
    }
  }
}

fn evaluate_unary(operator: Token, right: Expr) -> EvalResult {
  let assert Ok(right) = evaluate(right)
  case token.tp(operator) {
    token_type.Minus -> {
      case right {
        expr.IntLiteral(i) -> expr.IntLiteral(-i) |> Ok
        expr.FloatLiteral(f) -> f |> float.negate |> expr.FloatLiteral |> Ok
        _ -> operator |> error.Unary("Operand must be number.") |> Error
      }
    }
    token_type.Bang ->
      right |> is_truthy |> bool.negate |> expr.BoolLiteral |> Ok
    _ -> {
      io.debug(operator)
      io.debug(right)
      todo
    }
  }
}
