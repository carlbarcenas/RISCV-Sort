# NOTES:
# This is RISC-V version; 2020
# @author Carl Barcenas

.data
lenY1:	.word 13 #Size of array
Y1:	.word 13, 101, 79, 23, 154, 4, 11, 38, 89, 45, 17, 94, 62 #Array vals
newli:	.asciz "\n"	# ASCII Newline char
space:	.asciz " "	# ASCII Space char

.globl main
.text
# MAIN--------------------------------------------------------------------------------------------------
main: 
  lw	s0, lenY1	# s0 gets length of Y1
  li	s1, 4		# s1 gets word size
  la	a1, Y1		# a1 gets Y1 address
  li	a2, 0		# a2 gets left index (0)
  addi	a3, s0,	-1	# a3 gets right index (13 - 1)
  jal	ra, mergesort	# Jump to mergesort
  li	s7, 0		# Initialize i to 0 for printloop

printloop:
  bge	s7, s0, printloopexit	# Check exit condition (i >= lenY1)
  li	a7, 1		# Prime a7 to print int
  
  mul	t0, s1, s7	# t0 gets i * wordlength
  add	t0, t0, a1	# t0 gets &Y1[i]
  lw	a0, 0(t0)	# a0 gets Y1[i]
  ecall			# Print Y1[i]
  
  li	a7, 4		# Prime a7 to print string
  la	a0, space	# Print space
  ecall
  
  addi	s7, s7, 1	# Increment i
  j	printloop	# Continue loop

printloopexit:
  la	a0, newli	# a0 gets newline addr
  ecall			# Print New Line
  j	exit		# Close program
  

# MERGESORT----------------------------------------------------------------------------------------
# Params:	a1 = &x
#		a2 = left
#		a3 = right

mergesort:
  # Stack Management
  addi	sp, sp, -16	# Initialize stack to store ra, left, right, and middle
  sw	ra, 12(sp)	# Store return address
  sw	a2, 8(sp)	# Store left
  sw	a3, 4(sp)	# Store right

  bge	a2, a3, mergesort_return	  # Check if left >= right, return if true
  
  # Calculate Middle
  sub	t0, a3, a2	# t0 gets right - left
  addi	t0, t0, 1	# t0 gets right - left + 1
  srai	t0, t0, 1	# t0 gets (right-left+1)>>1
  add	t0, a2, t0	# t0 gets left+((right-left+1)>>1)
  sw	t0, 0(sp)	# Store middle to stack
  
  # Recursive call left half
  addi	a3, t0, -1	# a3(right) gets middle-1
  jal	ra, mergesort	# Rec Call mergesort
  
  # Recursive call right half
  lw	a2, 0(sp)	# a2 = middle
  lw	a3, 4(sp)	# a3 = right
  jal	ra, mergesort	# Rec Call mergesort
  
  # Merge call
  lw	a2, 8(sp)	# a2 = left
  lw	a3, 4(sp)	# a3 = right
  lw	a4, 0(sp)	# a4 = middle
  jal	merge 		# Merge call
  
mergesort_return:
  lw	ra, 12(sp)	# Load the return address from stack
  addi	sp, sp, 16	# Pop the stack
  jalr	zero, 0(ra)	# Return to caller
  
  
# MERGE -------------------------------------------------------------------------------------------
# Params:	a1 = &Y1
#		a2 = left
#		a3 = right
#		a4 = middle
merge:
  # Stack Management
  addi	sp, sp, -16	# Initialize stack for 4 entries
  sw	ra, 12(sp)	# Store return address to stack
  sw	a1, 8(sp)	# Store left to stack
  sw	a2, 4(sp)	# Store right to stack
  sw	a3, 0(sp)	# Store middle to stack

  # Initialize merge variables
  mv	s2, a2		# s2 = leftind gets left
  mv	s3, a4		# s3 = rightind gets middle
  addi	s4, a4, -1	# s4 = endleft gets middle - 1
  mv	s5, a3		# s5 = endright gets right
  
whileloop:
  # Conditional check to end loop
  bgt	s2, s4, endwhileloop	# End loop if leftind > endleft
  bgt	s3, s5, endwhileloop	# AND End loop if rightind > endright
  
  # Check x[leftind] > x[rightind]
  mul	t0, s2, s1	# t0 gets wordsize * leftind
  add	t0, t0, a1	# t0 gets &Y1[leftind]
  lw	t2, 0(t0)	# t2 gets Y1[leftind]
  
  mul	t1, s3, s1	# t1 gets wordsize * rightind
  add	t1, t1, a1	# t1 gets &Y1[rightind]
  lw	t3, 0(t1)	# t3 gets Y1[rightind]
  
  bgt	t2, t3, merge_else	# If Y1[leftind] > Y1[rightind], do else statement
  
  # Increment leftind and continue
  addi	s2, s2, 1	# Increment leftindex
  j	whileloop	# Continue while loop
  
endwhileloop:
  lw	ra, 12(sp)	# restore return address
  addi sp, sp, 16	# Pop stack
  jalr	zero, 0(ra)	# Return to caller

merge_else:
  mv	s6, t3		# s6(temp) gets Y1[rightind]
  addi	s7, s3, -1	# s7(i) gets rightind-1

forloop:
  blt	s7, s2, endforloop	# Conditional check for end (i >= leftind)
  
  mul	t0, s7, s1	# t0 gets i * wordlength
  add	t0, t0, a1	# t0 gets &Y1[i]
  lw	t1, 0(t0)	# t1 gets Y1[i]
  
  add	t0, t0, s1	# t0 gets &Y1[i+1]
  sw	t1, 0(t0)	# Y1[i+1] = Y1[i]
  
  addi	s7, s7, -1	# Decrement i
  j	forloop		# Continue loop
  
endforloop:
  mul	t0, s2, s1	# t0 gets leftind * wordlength
  add	t0, t0, a1	# t0 gets &Y1[leftind]
  sw	s6, 0(t0)	# Store s6(temp) to Y1[leftind]
  addi	s2, s2, 1	# Increment s2(leftind)
  addi	s4, s4, 1	# Increment s4(endleft)
  addi	s3, s3, 1	# Increment s3(rightind)
  j	whileloop	# Return to while loop
  

exit:
