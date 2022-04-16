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
			lbu $t1 0($s0)      # Loads char of name
			lbu $t4 0($t9)      # Loads char of node name
			beqz $t4 fpnull        # If the name in node hits a null terminator
			bne $t1 $t4 fpinnerdone         # If chars are not equal, exit loop immediately to go to next node.
			addi $s0 $s0 1      # Increments addr counter (Goes to next char)
			addi $t9 $t9 1      # Increments addr counter (Goes to next char)
			addi $t5 $t5 -1     # Decrements counter (chars remaining in node)
			j findpersoninner
			
		fpinnerdone:
			move $t9 $t6     # Reset t9 to base addr.
			add $t9 $t9 $t0  # Increment addr by node size, goes to next node
			addi $t2 $t2 1   # Increment nodes used counter
			j findpersonloop

	fpnull:
		bnez $t1 fpinnerdone         # If name input is not also terminated at this point, not a match.
		j fpfound	                # If it IS terminated, then found.
		
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
	move $ra $s3                   # Restores return addr
	beqz $v0 relationerror         # Checks for valid person
	move $s0 $v0                   # Copies over node addr
	move $s2 $a1                   # Preserves name1
	move $a1 $a2
	jal get_person
	move $ra $s3                   # Restores return addr
	beqz $v0 relationerror         # Checks for valid person
	move $s1 $v0                   # Copies over node addr
	beq $s0 $s1 relationerror      # Checks if names are identical
	move $a1 $s2                   # Restores name1
	lw $t0 4($a0)                  # Total edges
	lw $t1 20($a0)                 # Current num of edges
	bge $t1 $t0 relationerror      # Checks if max relations is reached

	# Check for existing relations (Probably similar algorithm to part 3)
	jal get_relation               # Checks for existing relation
	move $ra $s3                   # Restores return addr
	bnez $v0 relationerror         # If relation exists, error
	addi $t0 $a0 24                 # Jump to start of node set.
	lw $t1 0($a0)                  # Load number of nodes
	lw $t2 8($a0)                  # Load size of nodes
	mul $t2 $t2 $t1                # Multiply num x size, to get offset from set of nodes
	add $t3 $t2 $t0                # Jump to start of edge set.
	lw $t1 20($a0)                 # Current num of edges
	li $t5 12
	mul $t2 $t1 $t5                 # x4 bytes per word, x3 words per edge
	add $t3 $t3 $t2                # Go to first unused edge space
	sw $s0 0($t3)                  # Save first person
	sw $s1 4($t3)                  # Save second person
	sw $0 8($t3)                   # Save 0 in third field
	lw $t9 20($a0)          	# Load current number of edges
	addi $t9 $t9 1          	# Increment
	sw $t9 20($a0)          	# Save back into Network

	lw $s0 0($sp)
	lw $s1 4($sp)
	lw $s2 8($sp)
	lw $s3 12($sp)
	addi $sp $sp 16               # Stack deallocation
	jr $ra
	
	relationerror:
		li $v0 0
		jr $ra

.globl get_relation
get_relation: #a0 = network addr, a1 = name1, a2 = name2
	addi $sp $sp -16               # Stack allocation
	sw $s0 0($sp)
	sw $s1 4($sp)
	sw $s2 8($sp)
	sw $s3 12($sp)
	addi $t0 $a0 24                 # Jump to start of node set.
	lw $t1 0($a0)                  # Load number of nodes
	lw $t2 8($a0)                  # Load size of nodes
	mul $t2 $t2 $t1                # Multiply num x size, to get offset from set of nodes
	add $s1 $t2 $t0                # Jump to start of edge set.
	move $s2 $a2                  # Copies addr of name2
	move $s3 $ra                  # Preserves return addr

	# Call get_person on the input names to get 2 addresses. Go through every node and check if their values are equal to the addresses returned
	jal get_person
	move $s0 $v0                  # Saves name1 addr into s0
	move $a1 $a2                  # Moves name2 to a1 for get_person
	jal get_person
	move $s2 $v0                  # Saves name2 addr into s1
	move $ra $s3
	lw $t1 20($a0)       # Num of edges used
	addi $t3 $t1 1       # Increment by one
	move $t9 $s1         # Copy of edge base pointer
	li $t2 0             # Counter for edges used
	# Outer loop, goes to every edge.
	findrelationloop:
		beq $t2 $t3 relationnotfound  # Since t3 is 1 greater than the amount of edges, if loop hits this, relation is not in Network.
		lw $t4 0($t9)     # Loads first field of this edge
		lw $t5 4($t9)     # Loads second field of this edge
		beq $s0 $t4 frmatch1     # First field match
		back1:
		beq $s0 $t5 frmatch2     # Second field match
		back2:
		addi $t9 $t9 12  # Increment addr by edge size, goes to next edge
		addi $t2 $t2 1   # Increment edges used counter
		j findrelationloop

	frmatch1:
		bne $s2 $t5 back1          # If the second field is not a match, skip this edge
		j frfound	                # If it IS terminated, then found.
		
	frmatch2:
		bne $s2 $t4 back2          # If the first field is not a match, skip this edge
		j frfound	 
	
	relationnotfound:
		lw $s0 0($sp)
		lw $s1 4($sp)
		lw $s2 8($sp)
		lw $s3 12($sp)
		addi $sp $sp 16               # Stack deallocation
		li $v0 0
		jr $ra
	
	frfound:
		lw $s0 0($sp)
		lw $s1 4($sp)
		lw $s2 8($sp)
		lw $s3 12($sp)
		addi $sp $sp 16               # Stack deallocation
		move $v0 $t9
		jr $ra

.globl add_relation_property
add_relation_property: #a0 = Network, a1 = name1, a2 = name2, a3 = propname, load from fp 1 = propval
	addi $sp $sp -12
	sw $s0 0($sp)                   # Save s0
	sw $s1 4($sp)                   # Save s1
	sw $fp 8($sp)                   # Save s1
	addi $fp $sp 12
	lw $s1 0($fp)                   # load arg5 into $t2
	li $t1 1
	bne $s1 $t1 addrelationerror    # Checks that prop_val is 1
	
	# Checks that propname is "FRIEND"
	lbu $t0 0($a3)       # Load first char
	li $t1 'F'    # 'F'
	bne $t0 $t1 addrelationerror
	lbu $t0 1($a3)       # Load char
	li $t1 'R'    # 'R'
	bne $t0 $t1 addrelationerror
	lbu $t0 2($a3)       # Load char
	li $t1 'I'    # 'I'
	bne $t0 $t1 addrelationerror
	lbu $t0 3($a3)       # Load char
	li $t1 'E'    # 'E'
	bne $t0 $t1 addrelationerror
	lbu $t0 4($a3)       # Load char
	li $t1 'N'    # 'N'
	bne $t0 $t1 addrelationerror
	lbu $t0 5($a3)       # Load char
	li $t1 'D'    # 'D'
	bne $t0 $t1 addrelationerror
	lbu $t0 6($a3)       # Check for null termination
	bnez $t0 addrelationerror
	
	# Handle name truncation, I think get_person already handles truncation innately?
	# Call get_relation
	# ???
	# Profit
	move $s0 $ra           # Preserve $ra
	jal get_relation
	move $ra $s0           # Restore $ra
	beqz $v0 addrelationerror           # If no relation is found, error.
	sw $s1 8($v0)             # Store prop_val into Network
	lw $s0 0($sp)                   # Restore s0
	lw $s1 4($sp)                   # Restore s1
	lw $fp 8($sp)                   # Save s1
	addi $sp $sp 12
	li $v0 1
	jr $ra
	
	addrelationerror:	
		lw $s0 0($sp)                   # Restore s0
		lw $s1 4($sp)                   # Restore s1
		lw $fp 8($sp)                   # Save s1
		addi $sp $sp 12
		li $v0 0
		jr $ra

.globl is_a_distant_friend
is_a_distant_friend: #a0 = Network, a1 = name1, a2 = name2
	addi $sp $sp -16
	sw $fp 0($sp)           # Preserve fp = start of "visited" array. When using this array, set the next value to 0 for null termination.
	sw $s0 4($sp)           # Preserve s0
	sw $s1 8($sp)           # Preserve s1
	sw $s2 12($sp)           # Preserve s1
	# Check the name1 and name2 exist in the network
	move $s2 $ra               # Preserve ra
	jal get_person             # Check if name1 exists
	beqz $v0 dferror2          # If person not found, error
	move $s0 $a1               # Preserve a1
	move $a1 $a2               # Make a1 the second name
	jal get_person             # Check if name2 exists
	beqz $v0 dferror2          # If person not found, error
	move $a1 $s0               # Restore a1
	move $ra $s2               # Restore ra
	# Checks for direct relations
	move $s2 $ra
	jal get_relation       # Gets direct relations
	move $ra $s2
	bne $0 $v0 directfound        # Found a direct relation, need to check if it is a friendship
	j dfnoterror
	directfound:
		lw $t0 8($v0)         # Loads the third field of the found edge
		li $t1 1
		beq $t1 $t0 dferror       # If the relation is a friendship, error.
		j dfnoterror
	dferror:
		li $v0 0
		jr $ra
	dferror2:
		li $v0 -1
		jr $ra
	dfnoterror:
		move $s2 $ra
		jal dfhelper              # Call dfhelper
		move $ra $s2
		beqz $v0 dferror
		li $v0 1
		jr $ra

.globl dfhelper
dfhelper: #a0 Network, a1 name1, a2, name2, v0 = 0 if not df, 1 if df.
	
	
	#
	#
	#
	#
	#
	#
	#
	#
	# Use stack as stack
	# Push first edge to stack
	# while (stack is not empty) {
	#	edge = stack.pop
	#   if edge is not discovered, then
	#       label it as discovered in heap storage
	#       push adjacent edges to stack (Involves checking relations from the one field to every other node in the network)
	#
	#
	#
	#
	#
	#
	#
	#
	#
	#



	jr $ra
