import argv
import ast
import gleam/erlang
import gleam/io
import gleam/string
import parser
import scanner
import simplifile

pub fn main() {
  case argv.load().arguments {
    ["script", script] -> {
      run_file(script)
    }
    [] -> {
      repl_header()
      run_prompt()
    }
    _ -> io.print("Usage: glamlox [script FILE]")
  }
}

fn repl_header() {
  io.println("")
  io.println("========================================")
  io.println("Entering REPL mode. Type 'exit' to exit.")
  io.println("========================================")
}

fn run_file(script: String) {
  let assert Ok(source) = simplifile.read(script)
  run(source)
}

fn run(source: String) {
  scanner.scan_tokens(source) |> parser.parse |> ast.print_expr |> io.println
}

fn run_prompt() {
  let assert Ok(line) = erlang.get_line("> ")
  case string.trim(line) {
    "exit" -> Nil
    _ -> {
      run(line)
      run_prompt()
    }
  }
}
