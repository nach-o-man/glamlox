import ast
import gleeunit/should
import parser
import scanner

fn parse_and_print(input: String) -> String {
  scanner.scan_tokens(input) |> parser.parse |> ast.print_expr
}

pub fn parse_primary_test() {
  parse_and_print("((false))") |> should.equal("(group (group False))")
  parse_and_print("(true)") |> should.equal("(group True)")
  parse_and_print("nil") |> should.equal("nil")
  parse_and_print("123") |> should.equal("123")
  parse_and_print("\"abc\"") |> should.equal("abc")
  parse_and_print("123.45") |> should.equal("123.45")
}
