# SPDX-License-Identifier: Apache-2.0
# Copyright 2019 Western Digital Corporation or its affiliates.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

	

#Simple start up file for the reference design

	.section ".text.init"
	.global	_start
	.type _start, @function

_start:
	#clear minstret
	# 0xB82|0xB02 mistreth|minstret (64bit) the number of executed instructions
	# 0xB80|0xB00 mcycleh |  mcycle (64bit) the number of machine cycles	
#	csrw minstret, zero
#	csrw minstreth, zero

	# clear registers
	li  x1, 0
	li  x2, 0
	li  x3, 1
	li  x4, 0
	li  x5, 0
	li  x6, 0
	li  x7, 0
	li  x8, 0
	li  x9, 0
	li  x10,0
	li  x11,0
	li  x12,0
	li  x13,0
	li  x14,0
	li  x15,0

	# --- R/I 命令の最小確認シーケンス（分岐なし）---
	# I-type: addi/ori/xori/andi/slli/srli/srai
	addi x5, x0, 5        # x5 = 5
	addi x6, x0, 7        # x6 = 7
	ori  x7, x5, 0x3      # x7 = 5 | 3 = 7
	xori x8, x7, 0x1      # x8 = 7 ^ 1 = 6
	andi x9, x8, 0xF      # x9 = 6 & 15 = 6
	slli x10, x9, 2       # x10 = 6 << 2 = 24
	srli x11, x10, 1      # x11 = 24 >> 1 = 12 (logical)
	srai x12, x11, 1      # x12 = 12 >> 1 = 6 (arithmetic)

	# R-type: add/sub/sll/srl/sra/and/or/xor
	add  x13, x5, x6      # x13 = 5 + 7 = 12
	sub  x14, x13, x5     # x14 = 12 - 5 = 7
	sll  x15, x5, x0      # shift by 0 (no-op, uses R-type)
	srl  x15, x13, x0     # logical right shift by 0
	sra  x15, x13, x0     # arithmetic right shift by 0
	and  x13, x13, x8     # AND
	or   x14, x14, x9     # OR
	xor  x12, x12, x5     # XOR
	# --- ここまで ---
#	li  x16,0
#	li  x17,0
#	li  x18,0
#	li  x19,0
#	li  x20,0
#	li  x21,0
#	li  x22,0
#	li  x23,0
#	li  x24,0
#	li  x25,0
#	li  x26,0
#	li  x27,0
#	li  x28,0
#	li  x29,0
#	li  x30,0
#	li  x31,0

	#cache configuration
#	li t1, 0x55555555
#	csrw 0x7c0, t1		# 0x7c0 : user defined

	#setup MEIP and MTIP
#	li t0, (1<<7 | 1<<11)
#	csrw mie, t0		# 0x304:mie : machine interrupt enable register
#	li t0, (1<<3)
#	csrw mstatus, t0	# 0x300:mstatus : machine status register

	# initialize global pointer
	.option push
	.option norelax
	la gp, __global_pointer$
	.option pop
	la sp, _sp


#	#hart id
#	csrr a0, mhartid	# 0xf14:mhartid : core ID (0:master core)
#	li   a1, 1
#1:	bgeu a0, a1, 1b		# if ID>=1 then Loop 1 (busy wait)
	# argc = argv = 0 
	li a0, 0
	li a1, 0
	call main
	# Break point
	nop
	nop
	ebreak
