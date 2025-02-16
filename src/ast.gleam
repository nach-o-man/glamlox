import gleam/bool
import gleam/float
import gleam/int
import gleam/string_tree
import token

pub type Expr {
  Binary(left: Expr, operator: token.Token, right: Expr)
  Grouping(expr: Expr)
  StringLiteral(value: String)
  FloatLiteral(value: Float)
  BoolLiteral(value: Bool)
  IntLiteral(value: Int)
  NilLiteral
  Unary(operator: token.Token, right: Expr)
}

pub type Stmt {
  Expression(expr: Expr)
  Print(expr: Expr)
}

pub fn print_expr(expr: Expr) -> String {
  case expr {
    NilLiteral -> "nil"
    StringLiteral(val) -> val
    FloatLiteral(val) -> float.to_string(val)
    IntLiteral(val) -> int.to_string(val)
    BoolLiteral(val) -> bool.to_string(val)
    Grouping(ex) -> parenthesise_recursive("(group", [ex])
    Unary(op, r) -> parenthesise_recursive("(" <> token.lexeme(op), [r])
    Binary(l, op, r) -> parenthesise_recursive("(" <> token.lexeme(op), [l, r])
  }
}

fn parenthesise_recursive(accumulator: String, exprs: List(Expr)) -> String {
  let accumulator = string_tree.from_string(accumulator)

  case exprs {
    [] -> accumulator |> string_tree.append(")") |> string_tree.to_string
    [first, ..rest] -> {
      let accumulator =
        accumulator
        |> string_tree.append(" ")
        |> string_tree.append(print_expr(first))
        |> string_tree.to_string
      parenthesise_recursive(accumulator, rest)
    }
  }
}
