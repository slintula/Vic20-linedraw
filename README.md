# Vic20-linedraw
Buffered line-drawing routine for unexpanded Vic-20

Compiler: acme

This routine defines character data dynamically instead of using static character mapped "hi-res"-screen;
128 custom chars are splitted to two char-buffers which are alternately copied to visible screen. 
Buffer swaps can be seen in action by commenting out custom chars init at line 128.
