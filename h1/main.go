package main

import (
	"fmt"
	"os"
	"strings"
)

// decodeInstruction checks the bits of the data and returns the corresponding assembly instructions as a string.
func decodeInstruction(data []byte) string {
	instructions := []string{}
	for i := 0; i < len(data); i++ {
		if data[i] == 0b10001001 { // Opcode for "mov" between registers
			// Check the ModRM byte
			if i+1 < len(data) {
				modRM := data[i+1]

				destReg := (modRM >> 3) & 0b111 // Bits 3-5 for destination register
				srcReg := modRM & 0b111         // Bits 0-2 for source register

				// Map the register numbers to their names for 8086
				registers := []string{
					"ax", "cx", "dx", "bx", "sp", "bp", "si", "di",
				}

				// Append the corresponding assembly instruction
				if int(destReg) < len(registers) && int(srcReg) < len(registers) {
					instructions = append(instructions, fmt.Sprintf("mov %s, %s", registers[destReg], registers[srcReg]))
				}
			}
			i++ // Move to the next byte after the ModRM byte
		}
	}

	// Join the instructions with newlines and return
	result := strings.Join(instructions, "\n")
	return result
}

func main() {
	data, err := os.ReadFile("listing_0037_single_register_mov")
	if err != nil {
		panic(err)
	}

	for i := range data {
		b := data[i]
		fmt.Printf("%08b ", b)

		if (i+1)%2 == 0 {
			fmt.Println()
		}
	}

	decodeInstruction(data)
}

