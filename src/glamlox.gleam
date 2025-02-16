import argv
import ast
import gleam/erlang
import gleam/io
import gleam/string
import interpreter
import parser
import scanner
import simplifile

type PromptConsumer =
  fn(String) -> Nil

pub fn main() {
  case argv.load().arguments {
    ["script", script] -> {
      run_file(script)
    }
    ["debug"] -> {
      repl_header("DEBUG")
      run_prompt(debug)
    }
    [] -> {
      repl_header("EVALUATE")
      run_prompt(run)
    }
    _ -> io.print("Usage: glamlox [script FILE]")
  }
}

fn repl_header(mode: String) {
  let title = "Entering REPL in " <> mode <> " mode. Type 'exit' to exit."
  let title_form = string.repeat("=", string.length(title))
  io.println("")
  io.println(title_form)
  io.println(title)
  io.println(title_form)
}

fn run_file(script: String) {
  let assert Ok(source) = simplifile.read(script)
  run(source)
}

fn debug(source: String) {
  scanner.scan_tokens(source) |> parser.parse |> ast.print_expr |> io.println
}

fn run(source: String) {
  scanner.scan_tokens(source)
  |> parser.parse
  |> interpreter.interpret
}

fn run_prompt(consumer: PromptConsumer) {
  let assert Ok(line) = erlang.get_line("~> ")
  case string.trim(line) {
    "exit" -> Nil
    _ -> {
      consumer(line)
      run_prompt(consumer)
    }
  }
}
