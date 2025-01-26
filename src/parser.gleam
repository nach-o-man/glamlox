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

type ExpressionIteration =
  #(expr.Expr, ParseIteration)

fn next_iteration(
  left: List(token.Token),
  right: List(token.Token),
) -> ParseIteration {
  let assert [new_current, ..new_right] = right
  ParseIteration(left, new_current, new_right)
}

pub fn parse(tokens: List(token.Token)) -> expr.Expr {
  let first_iteration = next_iteration([], tokens)
  let #(result_expr, next_iter) = parse_recursive(first_iteration)
  case token.tp(next_iter.current) {
    token_type.Eof -> result_expr
    _ -> error.parse_error(next_iter.current, "Expecterd expression")
  }
}

fn parse_recursive(iteration: ParseIteration) -> ExpressionIteration {
  equality_expr(iteration)
}

fn equality_expr(iteration: ParseIteration) -> ExpressionIteration {
  iteration |> comparison_expr |> equality_expr_recursive
}

fn comparison_expr(iteration: ParseIteration) -> ExpressionIteration {
  iteration |> term_expr |> comparison_expr_recursive
}

fn term_expr(iteration: ParseIteration) -> ExpressionIteration {
  iteration |> factor_expr |> term_expr_recursive
}

fn factor_expr(iteration: ParseIteration) -> ExpressionIteration {
  iteration |> unary_expr |> factor_expr_recursive
}

fn equality_expr_recursive(
  iteration: ExpressionIteration,
) -> ExpressionIteration {
  let #(new_expr, next_iter) = iteration
  let ParseIteration(left, current, right) = next_iter
  case token.tp(current) {
    token_type.BangEqual | token_type.EqualEqual -> {
      let #(right_expr, next_iter) =
        comparison_expr(next_iteration(left, right))
      equality_expr_recursive(#(
        expr.Binary(new_expr, current, right_expr),
        next_iter,
      ))
    }
    _ -> #(new_expr, next_iter)
  }
}

fn comparison_expr_recursive(
  iteration: ExpressionIteration,
) -> ExpressionIteration {
  let #(new_expr, next_iter) = iteration
  let ParseIteration(left, current, right) = next_iter
  case token.tp(current) {
    token_type.Greater
    | token_type.GreaterEqual
    | token_type.Less
    | token_type.LessEqual -> {
      let #(right_expr, next_iter) = term_expr(next_iteration(left, right))
      comparison_expr_recursive(#(
        expr.Binary(new_expr, current, right_expr),
        next_iter,
      ))
    }
    _ -> #(new_expr, next_iter)
  }
}

fn term_expr_recursive(iteration: ExpressionIteration) -> ExpressionIteration {
  let #(new_expr, next_iter) = iteration
  let ParseIteration(left, current, right) = next_iter
  case token.tp(current) {
    token_type.Plus | token_type.Minus -> {
      let #(right_expr, next_iter) = factor_expr(next_iteration(left, right))
      term_expr_recursive(#(
        expr.Binary(new_expr, current, right_expr),
        next_iter,
      ))
    }
    _ -> #(new_expr, next_iter)
  }
}

fn factor_expr_recursive(iteration: ExpressionIteration) -> ExpressionIteration {
  let #(new_expr, next_iter) = iteration
  let ParseIteration(left, current, right) = next_iter
  case token.tp(current) {
    token_type.Slash | token_type.Star -> {
      let #(right_expr, next_iter) = unary_expr(next_iteration(left, right))
      factor_expr_recursive(#(
        expr.Binary(new_expr, current, right_expr),
        next_iter,
      ))
    }
    _ -> #(new_expr, next_iter)
  }
}

fn unary_expr(iteration: ParseIteration) -> ExpressionIteration {
  let ParseIteration(left, current, right) = iteration
  case token.tp(current) {
    token_type.Bang | token_type.Minus -> {
      let #(new_expr, next_iter) = unary_expr(next_iteration(left, right))
      #(expr.Unary(current, new_expr), next_iter)
    }
    _ -> primary_expr(iteration)
  }
}

fn primary_expr(iteration: ParseIteration) -> ExpressionIteration {
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
