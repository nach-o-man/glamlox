import ast
import env
import error
import gleam/bool
import gleam/float
import gleam/int
import gleam/order
import gleam/result
import gleam/string
import lox
import token
import token_type

type Token =
  token.Token

type Expr =
  ast.Expr

type Env =
  env.Environment

type LoxType =
  lox.LoxType

type LoxTypeWithEnv =
  #(LoxType, Env)

type LoxResult =
  Result(LoxType, error.ExpressionError)

type LoxResultWithEnv =
  Result(LoxTypeWithEnv, error.ExpressionError)

fn return_with_env(lox_value: LoxType, environment: Env) -> LoxTypeWithEnv {
  #(lox_value, environment)
}

pub fn evaluate(expr: Expr, environment: Env) -> LoxResultWithEnv {
  case expr {
    ast.BoolLiteral(bool) ->
      lox.LoxBoolean(bool) |> return_with_env(environment) |> Ok
    ast.FloatLiteral(fl) ->
      lox.LoxNumber(fl) |> return_with_env(environment) |> Ok
    ast.IntLiteral(i) ->
      lox.LoxNumber(int.to_float(i)) |> return_with_env(environment) |> Ok
    ast.StringLiteral(s) ->
      lox.LoxString(s) |> return_with_env(environment) |> Ok
    ast.NilLiteral -> lox.LoxNil |> return_with_env(environment) |> Ok
    ast.Unary(op, r) -> evaluate_unary(environment, op, r)
    ast.Binary(l, op, r) -> evaluate_binary(environment, op, l, r)
    ast.Variable(tkn) -> evaluate_variable(environment, tkn)
    ast.Assign(name, value) -> evaluate_assign(environment, name, value)
    _ -> error.UnsupportedExpression("Unsupported expression", expr) |> Error
  }
}

fn is_truthy(value: LoxType) -> Bool {
  case value {
    lox.LoxBoolean(val) -> val
    lox.LoxNil -> False
    _ -> True
  }
}

fn evaluate_variable(environment: Env, tkn: Token) -> LoxResultWithEnv {
  env.get(environment, tkn)
  |> result.map(return_with_env(_, environment))
  |> result.try_recover(fn(msg) { error.JustMessage(msg) |> Error })
}

fn evaluate_assign(
  environment: Env,
  name: Token,
  value: Expr,
) -> LoxResultWithEnv {
  let maybe_value = evaluate(value, environment)
  case maybe_value {
    Ok(#(evaluated, new_env)) -> {
      env.assign(new_env, token.lexeme(name), evaluated)
      |> result.map(fn(e) { #(evaluated, e) })
      |> result.try_recover(fn(msg) { error.JustMessage(msg) |> Error })
    }
    Error(err) -> Error(err)
  }
}

fn evaluate_binary(
  environment: Env,
  operator: Token,
  left: Expr,
  right: Expr,
) -> LoxResultWithEnv {
  let maybe_left_and_right = case evaluate(left, environment) {
    Ok(#(new_left, left_env)) -> {
      case evaluate(right, left_env) {
        Ok(#(new_right, right_env)) -> {
          #(new_left, new_right, right_env) |> Ok
        }
        Error(right_err) -> right_err |> Error
      }
    }
    Error(err) -> Error(err)
  }

  case maybe_left_and_right {
    Ok(#(left, right, environment)) -> {
      let return_value = case left, right {
        lox.LoxNumber(left), lox.LoxNumber(right) ->
          evaluate_binary_number_number(operator, left, right)
        lox.LoxString(left), lox.LoxString(right) ->
          evaluate_binary_string_string(operator, left, right)
        lox.LoxString(left), lox.LoxNumber(right) ->
          evaluate_binary_string_number(operator, left, right)
        left, right -> {
          case token.tp(operator) {
            token_type.EqualEqual -> { left == right } |> lox.LoxBoolean |> Ok
            token_type.BangEqual -> { left != right } |> lox.LoxBoolean |> Ok
            _ ->
              error.OperationError(
                "Operation is not applicable for arguments",
                operator,
              )
              |> Error
          }
        }
      }
      result.map(return_value, fn(v) { return_with_env(v, environment) })
    }
    Error(err) -> Error(err)
  }
}

fn evaluate_binary_string_number(
  operator: Token,
  left: String,
  right: Float,
) -> LoxResult {
  case token.tp(operator) {
    token_type.Plus -> { left <> float.to_string(right) } |> lox.LoxString |> Ok
    _ ->
      error.OperationError(
        "Operation is not applicable for arguments string-number",
        operator,
      )
      |> Error
  }
}

fn evaluate_binary_number_number(
  operator: Token,
  left: Float,
  right: Float,
) -> LoxResult {
  case token.tp(operator) {
    token_type.Minus -> { left -. right } |> lox.LoxNumber |> Ok
    token_type.Slash -> { left /. right } |> lox.LoxNumber |> Ok
    token_type.Star -> { left *. right } |> lox.LoxNumber |> Ok
    token_type.Plus -> { left +. right } |> lox.LoxNumber |> Ok
    token_type.Greater -> { left >. right } |> lox.LoxBoolean |> Ok
    token_type.GreaterEqual -> { left >=. right } |> lox.LoxBoolean |> Ok
    token_type.Less -> { left <. right } |> lox.LoxBoolean |> Ok
    token_type.LessEqual -> { left <=. right } |> lox.LoxBoolean |> Ok
    token_type.EqualEqual -> { left == right } |> lox.LoxBoolean |> Ok
    token_type.BangEqual -> { left != right } |> lox.LoxBoolean |> Ok
    _ ->
      error.OperationError(
        "Operation is not applicable for arguments number-number",
        operator,
      )
      |> Error
  }
}

fn evaluate_binary_string_string(
  operator: Token,
  left: String,
  right: String,
) -> LoxResult {
  case token.tp(operator) {
    token_type.Plus -> { left <> right } |> lox.LoxString |> Ok
    token_type.Greater ->
      { string.compare(left, right) == order.Gt }
      |> lox.LoxBoolean
      |> Ok
    token_type.GreaterEqual ->
      { order.break_tie(string.compare(left, right), order.Gt) == order.Gt }
      |> lox.LoxBoolean
      |> Ok
    token_type.Less ->
      { string.compare(left, right) == order.Lt }
      |> lox.LoxBoolean
      |> Ok
    token_type.LessEqual ->
      { order.break_tie(string.compare(left, right), order.Lt) == order.Lt }
      |> lox.LoxBoolean
      |> Ok
    token_type.EqualEqual -> { left == right } |> lox.LoxBoolean |> Ok
    token_type.BangEqual -> { left != right } |> lox.LoxBoolean |> Ok
    _ ->
      error.OperationError(
        "Operation is not applicable for arguments string-string",
        operator,
      )
      |> Error
  }
}

fn evaluate_unary(
  environment: Env,
  operator: Token,
  right: Expr,
) -> LoxResultWithEnv {
  let maybe_right = evaluate(right, environment)
  case maybe_right {
    Ok(#(right, new_environment)) -> {
      case token.tp(operator) {
        token_type.Minus -> {
          case right {
            lox.LoxNumber(f) ->
              f
              |> float.negate
              |> lox.LoxNumber
              |> return_with_env(new_environment)
              |> Ok
            _ ->
              error.OperationError("Operand must be number.", operator) |> Error
          }
        }
        token_type.Bang ->
          right
          |> is_truthy
          |> bool.negate
          |> lox.LoxBoolean
          |> return_with_env(new_environment)
          |> Ok
        _ -> error.unreacheable_code()
      }
    }
    Error(err) -> err |> Error
  }
}
