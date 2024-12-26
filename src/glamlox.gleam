import argv
import gleam/erlang
import gleam/io
import gleam/list
import gleam/string
import scanner
import simplifile

pub fn main() {
  case argv.load().arguments {
    ["script", script] -> {
      run_file(script)
    }
    [] -> {
      io.println("")
      io.println("========================================")
      io.println("Entering REPL mode. Type 'exit' to exit.")
      io.println("========================================")
      run_prompt()
    }
    _ -> io.print("Usage: glamlox [script FILE]")
  }
}

fn run_file(script: String) {
  let assert Ok(source) = simplifile.read(script)
  run(source)
}

fn run(source: String) {
  let tokens = scanner.scan_tokens(source)
  list.each(tokens, fn(token) { io.println(token.src) })
}

fn run_prompt() {
  let assert Ok(line) = erlang.get_line("glamlox > ")
  case string.trim(line) {
    "exit" -> Nil
    _ -> {
      run(line)
      run_prompt()
    }
  }
}
