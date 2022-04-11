############## Kevin Tao ##############
############## 170154879 #################
############## ktao ################

############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
.text:
.globl create_person
create_person:	#a0 = network
	lw $t0 0($a0)           # Total Nodes
	lw $t1 16($a0)          # Current Nodes
	bgeu $t1 $t0 createerror
	li $t0 24               # Go to base of node addr.
	lw $t2 8($a0)           # Node size
	mul $t2 $t1 $t2         # Multipy current nodes by node size 
	add $t2 $t0 $t2         # Go to first free node.
	add $v0 $t2 $a0         # Store into return the start of the first node.
	move $t3 $v0            # Create copy of base addr
	lw $t2 8($a0)           # Load node size.
	createloop:
		beqz $t2 createdone
		sb $0 0($t3)        # Save 0 into memory
		addi $t2 $t2 -1     # Decrement bytes remaining
		addi $t3 $t3 1      # Increment addr counter
		j createloop
	createdone:
		lw $t0 16($a0)      # Increment current used nodes
		addi $t0 $t0 1      
		sw $t0 16($a0)
		jr $ra
	createerror:
		li $v0 -1
		jr $ra

.globl add_person_property
add_person_property:    #a0: network addr, $a1: person addr, $a2: propname, $a3: propval          #454D414E = EMAN (NAME)
	addi $sp $sp -8
	sw $s0 0($sp)        # Stack allocation
	sw $s1 4($sp)        # Stack allocation

	# Checks that propname is "NAME"
	lbu $t0 0($a2)       # Load first char
	li $t1 0x0000004E    # 'N'
	bne $t0 $t1 addpersonerror
	lbu $t0 1($a2)       # Load first char
	li $t1 0x00000041    # 'A'
	bne $t0 $t1 addpersonerror
	lbu $t0 2($a2)       # Load first char
	li $t1 0x0000004D    # 'M'
	bne $t0 $t1 addpersonerror
	lbu $t0 3($a2)       # Load first char
	li $t1 0x00000045    # 'E'
	bne $t0 $t1 addpersonerror
	lbu $t0 4($a2)       # Check for null termination
	bnez $t0 addpersonerror
	
	# Checks that person addr is aligned properly.
	lw $t0 8($a0)        # Size of node
	lw $t1 16($a0)       # Num of nodes used
	addi $t3 $t1 1       # Increment by one
	move $t9 $a0         # Copy of base pointer
	addi $t9 $t9 24      # Jump to start of Node set
	li $t2 0             # Counter for nodes used
	addpersonloop:
		beq $t2 $t3 addpersonerror  # Since t3 is 1 greater than the amount of nodes, if it reaches this, error.
		beq $a1 $t9 addpersondone   # If it finds a matching addr, this loop is done.
		add $t9 $t9 $t0  # Increment addr by node size
		addi $t2 $t2 1   # Increment nodes used counter
		j addpersonloop

	# Checks the length of prop_val
	addpersondone:
		li $t2 0         # prop_val length counter
		move $t3 $a3     # Copy of prop_val addr
		lbu $t1 0($t3)   # Loads first char of prop_val into t0
	addpersonloop2:
		beqz $t1 addpersondone2
		addi $t2 $t2 1   # Increments length counter
		addi $t3 $t3 1   # Increments prop_val addr counter
		lbu $t1 0($t3)   # Loads next char
		j addpersonloop2
		
	# Checks if name already exists
	addpersondone2:
		blt $t0 $t2 addpersonerror     # If length is greater than max size, error
		move $s1 $a1                   # Saves this function's a1
		move $a1 $a3                   # a1 arg = name
		move $s0 $ra
		jal get_person
		move $ra $s0                   # Restores ra
		move $a1 $s1                   # Restores a1
		bnez $v0 addpersonerror            # If person already exists, error
		lw $t0 8($a0)        # Size of node
		move $t1 $a1
	
	# Zero the node
	zeroloop:
		beqz $t0 zerodone
		sb $0 0($t1)         # Saves 0 into node
		addi $t1 $t1 1       # Increments addr
		addi $t0 $t0 -1      # Decrements size of node as counter
		j zeroloop
		
	# Copy name into node.
	zerodone:
		move $t0 $a1
		move $t1 $a3
		lbu $t2 0($t1)         # Loads char of name
	copyloop:
		beqz $t2 copydone      # End when hitting zero termination.
		sb $t2 0($t0)          # Stores into memory
		addi $t0 $t0 1         # Increments addr counter
		addi $t1 $t1 1         # Increments name addr.
		lbu $t2 0($t1)         # Loads char of name
		j copyloop
		
	copydone:
		lw $s0 0($sp)
		lw $s1 4($sp)
		addi $sp $sp 8          # Stack deallocation
		li $v0 1
		jr $ra

	addpersonerror:
		lw $s0 0($sp)
		lw $s1 4($sp)
		addi $sp $sp 8          # Stack deallocation
		li $v0 0
		jr $ra

.globl get_person
get_person: #a0 = network addr, a1 = name
	addi $sp $sp -8               # Stack allocation
	sw $s0 0($sp)
	sw $s1 4($sp)
	move $s0 $a1                  # Copies addr of name
	addi $s1 $a0 24               # Jumps to start of Network node set

	# Checks that person addr is aligned properly.
	lw $t0 8($a0)        # Size of node
	lw $t1 16($a0)       # Num of nodes used
	addi $t3 $t1 1       # Increment by one
	move $t9 $s1         # Copy of node base pointer
	li $t2 0             # Counter for nodes used
	# Outer loop, goes to every node.
	findpersonloop:
		beq $t2 $t3 personnotfound  # Since t3 is 1 greater than the amount of nodes, if loop hits this, person is not in Network.
		move $t5 $t0       # Copy of node size to use as counter for inner loop
		move $t6 $t9       # Copy of base addr of node, incase a match is found.
		move $s0 $a1       # Resets base addr of name arg.
		
		#Inner loop, matches name with node name.
		findpersoninner:
			beqz $t5 fpfound       # If the entire loop is successful, the name is found.
			lbu $t1 0($s0)      # Loads first char of name
			lbu $t4 0($t9)      # Loads first char of node name
			bne $t1 $t4 fpinnerdone         # If chars are not equal, exit loop immediately to go to next node.
			addi $s0 $s0 1      # Increments addr counter (Goes to next char)
			addi $t9 $t9 1      # Increments addr counter (Goes to next char)
			addi $t5 $t5 -1     # Decrements counter (chars remaining in node)
			j findpersoninner
			
		fpinnerdone:
			add $t9 $t9 $t0  # Increment addr by node size, goes to next node
			addi $t2 $t2 1   # Increment nodes used counter
			j findpersonloop

	personnotfound:
		lw $s0 0($sp)
		lw $s1 4($sp)
		addi $sp $sp 8               # Stack deallocation
		li $v0 0
		jr $ra
	
	fpfound:
		lw $s0 0($sp)
		lw $s1 4($sp)
		addi $sp $sp 8               # Stack deallocation
		move $v0 $t6
		jr $ra

.globl add_relation
add_relation:         #a0 = Network addr, a1 = name1, a2 = name2
	addi $sp $sp -16               # Stack allocation
	sw $s0 0($sp)
	sw $s1 4($sp)
	sw $s2 8($sp)
	sw $s3 12($sp)
	move $s3 $ra                   # Preserves ra
	jal get_person
	beqz $v0 relationerror         # Checks for valid person
	move $s0 $v0                   # Copies over node addr
	move $s2 $a1                   # Preserves name1
	move $a1 $a2
	jal get_person
	beqz $v0 relationerror         # Checks for valid person
	move $s1 $v0                   # Copies over node addr
	beq $s0 $s1 relationerror      # Checks if names are identical
	move $a1 $s2                   # Restores name1
	move $ra $s3
	lw $t0 4($a0)                  # Total edges
	lw $t1 20($a0)                 # Current num of edges
	bge $t1 $t0 relationerror      # Checks if max relations is reached
	#
	#
	# Check for existing relations (Probably similar algorithm to part 3)
	#
	#
	lw $s0 0($sp)
	lw $s1 4($sp)
	lw $s2 8($sp)
	lw $s3 12($sp)
	addi $sp $sp 16               # Stack deallocation
	jr $ra
	
	relationerror:
		li $v0 0
		jr $ra

.globl add_relation_property
add_relation_property:
	jr $ra

.globl is_a_distant_friend
is_a_distant_friend:
	jr $ra
