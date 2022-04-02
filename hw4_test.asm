############################ CHANGE THIS FILE AS YOU DEEM FIT ############################
############################ Add more names if needed ####################################
############################ Change network if needed ####################################
.data

Name1: .asciiz "Jane"
Name2: .asciiz "Joey"
Name3: .asciiz "Alit"
Name4: .asciiz "Veen"
Name5: .asciiz "Stan"

.align 2
Network:
  .word 3   #total_nodes
  .word 3   #total_edges
  .word 4   #size_of_node
  .word 12  #size_of_edge
  .word 0   #curr_num_of_nodes
  .word 0   #curr_num_of_edges
   # set of nodes
  .byte 0 0 0 0 0 0 0 0 0 0 0 0
   # set of edges
  .word 0 0 0 0 0 0 0 0 0
.text
main:
	  la $a0, Network
  	jal create_person
  	move $s0, $v0		# return person

  	#write test code



exit:
	li $v0, 10
	syscall
.include "hw4.asm"
