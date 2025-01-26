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
