// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed.
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// Put your code here.

(LOOP_KEYBOARD)
  @8192
  D=A
  @screen_counter
  M=D // set screen counter to 32 words / row * 256 rows
  @SCREEN
  D=A
  @current_screen_memory_address
  M=D // initial screen memory address

  @KBD // memory address of keyboard
  D=M
  @LOOP_WHITE_SCREEN
  D;JEQ // if no keyboard is pressed goto LOOP_WHITE_SCREEN
  @LOOP_BLACK_SCREEN
  0;JMP // else goto LOOP_BLACK_SCREEN

(LOOP_WHITE_SCREEN)
  @screen_counter  // set D to the counter
  D=M
  @LOOP_KEYBOARD
  D;JEQ // if D == 0 goto LOOP_KEYBOARD

  @current_screen_memory_address
  A=M
  M=0

  @screen_counter
  M=M-1 // decrement of screen_counter (screen counter)
  @current_screen_memory_address
  M=M+1

  @LOOP_WHITE_SCREEN
  0;JMP // goto LOOP_WHITE_SCREEN

(LOOP_BLACK_SCREEN)
  @screen_counter  // set D to the counter
  D=M
  @LOOP_KEYBOARD
  D;JEQ // if D == 0 goto LOOP_KEYBOARD

  @current_screen_memory_address
  A=M
  M=-1

  @screen_counter
  M=M-1 // decrement of screen_counter (screen counter)
  @current_screen_memory_address
  M=M+1

  @LOOP_BLACK_SCREEN
  0;JMP // goto LOOP_BLACK_SCREEN



