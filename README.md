basically just a calculator where i wrote the main logic in arm64 assembly because i hate myself. swiftui for the frontend stuff, phosphor green apple ii aesthetic because it looks cool.

### aarch64 assemblyyyy UwU

most of the logic is in `calc_logic.s`. basic math like adding and subtracting is just one instruction each, but i spent way too long on the reciprocal (`1/x`) using neon. used `frecpe` and a newton-raphson step to get it accurate enough for the display, probably overkill but whatever...

hardest part was honestly the apple abi. if the stack pointer isn't 16-byte aligned when you call another function, the app just dies with a cryptic error. had to learn that the hard way. also wrote a circular buffer in `.bss` for the history log because i didn't want to deal with malloc in assembly. used `udiv` and `msub` for the index wrapping since arm doesn't have a modulo instruction.

-------- 

keyboard support works too (return for equals, esc for clear, etc)

needs an apple silicon mac or an ios device to run.

it works. i'm tired.


<img width="1768" height="1228" alt="CleanShot 2026-05-13 at 07 48 50" src="https://github.com/user-attachments/assets/dab671d2-08a8-4f43-9497-8991a1daf71d" />
