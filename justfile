default:
    echo 'Hello, world!'

run:
    zig run ./p2/main.zig

gen:
    zig run ./p2/generator.zig -- --seed 12345674 --count 1000

