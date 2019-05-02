# pcmtest
Sega Mega Drive PCM playback testing ROM

Compile with asm68k:  
  
    asm68k.exe /p pcm.asm, pcm.bin
With vasm:

    vasmm68k_mot -spaces -align pcm.asm -Fbin -o pcm.bin
