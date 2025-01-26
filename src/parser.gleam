import error
import expr
import token
import token_type

type ParseIteration {
  ParseIteration(
    left: List(token.Token),
    current: token.Token,
    rigth: List(token.Token),
  )
}

fn next_iteration(
  left: List(token.Token),
  right: List(token.Token),
) -> ParseIteration {
  let assert [new_current, ..new_right] = right
  ParseIteration(left, new_current, new_right)
}

pub fn parse(tokens: List(token.Token)) -> expr.Expr {
  let assert [first, ..rest] = tokens
  let first_iteration = ParseIteration([], first, rest)
  let #(res, _) = parse_recursive(first_iteration)
  res
}

fn parse_recursive(iteration: ParseIteration) -> #(expr.Expr, ParseIteration) {
  term_expr(iteration)
}

fn term_expr(iteration: ParseIteration) -> #(expr.Expr, ParseIteration) {
  let #(new_expr, next_iter) = factor_expr(iteration)
  let ParseIteration(left, current, right) = next_iter
  case token.tp(current) {
    token_type.Plus | token_type.Minus -> {
      let #(right_expr, next_iter) = factor_expr(next_iteration(left, right))
      #(expr.Binary(new_expr, current, right_expr), next_iter)
    }
    _ -> #(new_expr, next_iter)
  }
}

fn factor_expr(iteration: ParseIteration) -> #(expr.Expr, ParseIteration) {
  let #(new_expr, next_iter) = unary_expr(iteration)
  let ParseIteration(left, current, right) = next_iter
  case token.tp(current) {
    token_type.Slash | token_type.Star -> {
      let #(right_expr, next_iter) = unary_expr(next_iteration(left, right))
      #(expr.Binary(new_expr, current, right_expr), next_iter)
    }
    _ -> #(new_expr, next_iter)
  }
}

fn unary_expr(iteration: ParseIteration) -> #(expr.Expr, ParseIteration) {
  let ParseIteration(left, current, right) = iteration
  case token.tp(current) {
    token_type.Bang | token_type.Minus -> {
      let #(new_expr, next_iter) = unary_expr(next_iteration(left, right))
      #(expr.Unary(current, new_expr), next_iter)
    }
    _ -> primary_expr(iteration)
  }
}

fn primary_expr(iteration: ParseIteration) -> #(expr.Expr, ParseIteration) {
  let ParseIteration(left, current, right) = iteration
  case token.tp(current) {
    token_type.False -> #(expr.BoolLiteral(False), next_iteration(left, right))
    token_type.True -> #(expr.BoolLiteral(True), next_iteration(left, right))
    token_type.Nil -> #(expr.NilLiteral, next_iteration(left, right))
    token_type.Number -> {
      case token.get_value(current) {
        #(Ok(int), Error(_), Error(_)) -> #(
          expr.IntLiteral(int),
          next_iteration(left, right),
        )
        #(Error(_), Ok(fl), Error(_)) -> #(
          expr.FloatLiteral(fl),
          next_iteration(left, right),
        )
        #(_, _, _) ->
          error.parse_error(
            current,
            "Illegal call to the token.get_value function",
          )
      }
    }
    token_type.String -> {
      case token.get_value(current) {
        #(Error(_), Error(_), Ok(str)) -> #(
          expr.StringLiteral(str),
          next_iteration(left, right),
        )
        #(_, _, _) ->
          error.parse_error(
            current,
            "Illegal call to the token.get_value function",
          )
      }
    }
    token_type.LeftParen -> {
      let assert [new_current, ..rest] = right
      let #(inner, next_iter) =
        parse_recursive(ParseIteration([], new_current, rest))
      let maybe_right_paren = next_iter.current
      case token.tp(maybe_right_paren) {
        token_type.RightParen -> #(
          expr.Grouping(inner),
          next_iteration(next_iter.left, next_iter.rigth),
        )
        _ ->
          error.parse_error(maybe_right_paren, "Expect ')' after expression.")
      }
    }
    _ -> todo
  }
}
