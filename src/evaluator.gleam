import error
import expr
import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/order
import gleam/string
import token
import token_type

type Token =
  token.Token

type Expr =
  expr.Expr

type EvalResult =
  Result(Expr, error.ExpressionError)

type AllowedOperands {
  NumberPair(Float, Float)
  StringPair(String, String)
  StringNumber(String, Float)
}

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

fn assert_number(expr: Expr) -> Float {
  case expr {
    expr.FloatLiteral(value) -> value
    expr.IntLiteral(value) -> int.to_float(value)
    _ -> panic as "Number expected"
  }
}

fn assert_numbers(left: Expr, right: Expr) -> AllowedOperands {
  NumberPair(assert_number(left), assert_number(right))
}

fn assert_allowed(left: Expr, right: Expr) -> AllowedOperands {
  case left, right {
    expr.FloatLiteral(l), expr.FloatLiteral(r) -> NumberPair(l, r)
    expr.FloatLiteral(l), expr.IntLiteral(r) -> NumberPair(l, int.to_float(r))
    expr.IntLiteral(l), expr.FloatLiteral(r) -> NumberPair(int.to_float(l), r)
    expr.IntLiteral(l), expr.IntLiteral(r) ->
      NumberPair(int.to_float(l), int.to_float(r))
    expr.StringLiteral(l), expr.FloatLiteral(r) -> StringNumber(l, r)
    expr.StringLiteral(l), expr.IntLiteral(r) ->
      StringNumber(l, int.to_float(r))
    expr.StringLiteral(l), expr.StringLiteral(r) -> StringPair(l, r)
    _, _ -> panic as "Allowed only strings and number"
  }
}

fn division_by_zero_eq_zero(a: Float, b: Float) -> Float {
  case float.divide(a, b) {
    Ok(val) -> val
    _ -> 0.0
  }
}

fn pipe_to_func(
  pair: AllowedOperands,
  func: fn(Float, Float) -> Float,
) -> EvalResult {
  case pair {
    NumberPair(l, r) -> func(l, r) |> expr.FloatLiteral |> Ok
    _ -> panic as "Shoul be only called for the pair of numbers."
  }
}

fn expected_order(pair: AllowedOperands, expected: CustomOrder) -> EvalResult {
  let result = case pair {
    NumberPair(l, r) -> float.compare(l, r)
    StringPair(l, r) -> string.compare(l, r)
    _ -> panic as "Allowed only for strings or numbers"
  }
  let result = case expected {
    Gt -> order.break_tie(result, order.Eq) == order.Gt
    GtEq -> order.break_tie(result, order.Gt) == order.Gt
    Lt -> order.break_tie(result, order.Eq) == order.Lt
    LtEq -> order.break_tie(result, order.Lt) == order.Lt
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
      case assert_allowed(left, right) {
        StringPair(l, r) -> { l <> r } |> expr.StringLiteral |> Ok
        NumberPair(l, r) -> NumberPair(l, r) |> pipe_to_func(float.add)
        StringNumber(l, r) ->
          { l <> float.to_string(r) } |> expr.StringLiteral |> Ok
      }
    token_type.Greater -> assert_allowed(left, right) |> expected_order(Gt)
    token_type.GreaterEqual ->
      assert_allowed(left, right) |> expected_order(GtEq)
    token_type.EqualEqual -> { left == right } |> expr.BoolLiteral |> Ok
    token_type.BangEqual -> { left != right } |> expr.BoolLiteral |> Ok
    token_type.LessEqual -> assert_allowed(left, right) |> expected_order(LtEq)
    token_type.Less -> assert_allowed(left, right) |> expected_order(Lt)
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
