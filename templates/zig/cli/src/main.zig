const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const CliError = error{
    MissingArgument,
    InvalidCount,
    MultipleNames,
    NoName,
};

fn greet(name: []const u8, count: u32) void {
    var i: u32 = 1;
    while (i <= count) : (i += 1) {
        print("Hello, {s}! (#{d})\n", .{ name, i });
    }
}

fn showHelp() void {
    print(
        \\Zig CLI Application
        \\
        \\Usage:
        \\  zig-project [options] <name>
        \\  
        \\Options:
        \\  -c, --count <n>    Number of greetings (default: 1)
        \\  -h, --help         Show this help message
        \\  
        \\Examples:
        \\  zig-project Alice                    # Greet Alice once
        \\  zig-project --count 3 Bob           # Greet Bob three times
        \\  zig-project -c 2 "World"            # Greet World twice
        \\  
        \\This project was created with nix-polyglot for reproducible development.
        \\Use 'glot build' to build and 'glot run' to run.
        \\
    , .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 1) {
        showHelp();
        return;
    }

    // Check for help flag
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            showHelp();
            return;
        }
    }

    var name: ?[]const u8 = null;
    var count: u32 = 1;
    var i: usize = 1;

    // Simple argument parsing
    while (i < args.len) {
        const arg = args[i];
        
        if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--count")) {
            if (i + 1 >= args.len) {
                print("Error: --count requires a value\n", .{});
                std.process.exit(1);
            }
            
            const count_str = args[i + 1];
            count = std.fmt.parseInt(u32, count_str, 10) catch {
                print("Error: invalid count value '{s}'\n", .{count_str});
                std.process.exit(1);
            };
            
            if (count == 0) {
                print("Error: count must be positive\n", .{});
                std.process.exit(1);
            }
            
            i += 2;
        } else {
            if (name != null) {
                print("Error: multiple names provided\n", .{});
                showHelp();
                std.process.exit(1);
            }
            name = arg;
            i += 1;
        }
    }

    if (name == null) {
        print("Error: no name provided\n", .{});
        showHelp();
        std.process.exit(1);
    }

    greet(name.?, count);
}

test "greet function" {
    // Basic test - just ensure it doesn't crash
    greet("Test", 1);
}

test "greet with multiple counts" {
    greet("Test", 3);
}

test "greet with zero count" {
    greet("Test", 0);
}