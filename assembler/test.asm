main:
  add $t0, $t1, $t2 # This is at memory address 0
  lw $s0, 4($t0)    # This is at memory address 4
loop:
  j main            # This is at memory address 8