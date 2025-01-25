import token

pub type Expr {
  Binary(left: Expr, operator: token.Token, right: Expr)
  Grouping(expr: Expr)
  StringLiteral(value: String)
  FloatLiteral(value: Float)
  IntLiteral(value: Int)
  NilLiteral
  Unary(operator: token.Token, right: Expr)
}
