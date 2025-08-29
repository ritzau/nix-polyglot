"""Main entry point for the Python console application."""

import datetime
from typing import Optional

import click


def get_greeting(name: Optional[str] = None) -> str:
    """Generate a greeting message."""
    if name:
        return f"Hello, {name} from Python! 🐍"
    return "Hello, World from Python! 🐍"


def get_description() -> str:
    """Get application description."""
    return "This is a Python console application created with nix-polyglot."


@click.command()
@click.option("--name", "-n", help="Name to greet")
@click.option("--count", "-c", default=1, help="Number of greetings")
def main(name: Optional[str], count: int) -> None:
    """Python console application with nix-polyglot integration."""
    print(get_greeting(name))
    print(get_description())
    print(f"Project created with nix-polyglot at {datetime.datetime.now()}")
    
    if count > 1:
        print(f"\nGreeting {count} times:")
        for i in range(count):
            print(f"{i + 1}: {get_greeting(name)}")


if __name__ == "__main__":
    main()