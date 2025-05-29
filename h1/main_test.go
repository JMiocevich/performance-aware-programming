package main

import (
	"os"
	"testing"
)

func Test_decodeInstruction(t *testing.T) {
	// Read the binary file
	data, err := os.ReadFile("listing_0037_single_register_mov")
	if err != nil {
		t.Fatalf("Failed to read file: %v", err)
	}

	output := decodeInstruction(data)

	// Check the output
	expectedOutput := "\nmov bx, cx"
	if output != expectedOutput {
		t.Errorf("Expected output:\n%s\nGot:\n%s", expectedOutput, output)
	}
}

func Test_decodeInstructionmultiple(t *testing.T) {
	// Read the binary file
	data, err := os.ReadFile("listing_0038_many_register_mov")
	if err != nil {
		t.Fatalf("Failed to read file: %v", err)
	}

	output := decodeInstruction(data)

	expectedOutput := "mov cx, bx\n" +
		"mov ch, ah\n" +
		"mov dx, bx\n" +
		"mov si, bx\n" +
		"mov bx, di\n" +
		"mov al, cl\n" +
		"mov ch, ch\n" +
		"mov bx, ax\n" +
		"mov bx, si\n" +
		"mov sp, di\n" +
		"mov bp, ax\n"
	if output != expectedOutput {
		t.Errorf("Expected output:\n%s\nGot:\n%s", expectedOutput, output)
	}
}
