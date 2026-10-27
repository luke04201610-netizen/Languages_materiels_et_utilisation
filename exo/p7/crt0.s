# Startup code, at address 0 (the processor starts here after reset)
_start:
    li     sp, 0x4000      # stack at the top of the quadram: 4 x 1024 words = 16 KB
    call   main            # main(); the result is returned in a0
    ebreak                 # stop: the processor is halted
