#########################################################################################
#
# CSCB58 Winter 2025 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Ajay Narayanan Anantha Subramanian, 1010130537, anant115, ajay.ananthasubramaniann@mail.utoronto.ca
# # Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submissiodn?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 4 
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 	1. Double Jump
# 	2. Multiple levels (3 levels)
# 	3. Start menu
# 
# # Link to video demonstration for final submission:
# - https://www.youtube.com/watch?v=oSCdUD3iP0A
# # Are you OK with us sharing the video with people outside course staff? 
# - no
# # Any additional information that the TA needs to know:
# - (keyboard controls are:
#	w for jump, and move selector up
#   a for left
#   s for move selector down
#	d for right
#   g for select
#	q for left jump,
#	e for right jump,
#	t for quit game, and
#	r for restart level.
#
# Win Condition: Reach the winning platform on all levels, each level is a checkpoint
# Lose Condition: Running out of health
#########################################################################################

.data
    # Screen MACROS
    .eqv BASE_ADDRESS     0x10008000
    .eqv END_ADDRESS      0x10010000
    .eqv FRAME_DELAY      40

    # Colour MACROS
    .eqv BLACK_COLOR     0x00000000   # BLACK
    .eqv PLATFORM_COLOR  0x00FF7700   # ORANGE
    .eqv PURPLE_COLOR    0x00FF00FF
    .eqv YELLOW_COLOR    0xFFFFFF00   # YELLOW
    .eqv GREEN_COLOR     0x0000FF00   # GREEN
    .eqv RED_COLOR       0x00FF0000   # RED
    .eqv CYAN_COLOR      0x0000FFFF   # CYAN
    .eqv WHITE_COLOR     0x00FFFFFF   # WHITE

    # Keyboard
    .eqv KEY_LEFT 0x61 # 'a'
    .eqv KEY_RIGHT 0x64 # 'd'
    .eqv KEY_JUMP 0x77 # 'w'
    .eqv KEY_LEFT_JUMP 0x71 # 'q'
    .eqv KEY_RIGHT_JUMP 0x65 # 'e'
    .eqv KEY_RESTART  0x72	      # ASCII for 'r'
    .eqv KEY_QUIT  0x74           # ASCII for 't'
    .eqv KEYBOARD_ADDRESS 0xffff0000

    # Player Data (START)
    .eqv START_POS_X  2
    .eqv START_POS_Y  45
    .eqv START_WIDTH  3
    .eqv START_HEIGHT 5
    .eqv START_VEL_Y 0
    .eqv START_VEL_X 0
    .eqv START_JUMP_FORCE -5
    .eqv START_JUMP_FORCE_X 4

    # Health Data (START)
    .eqv START_HEALTH 3

    # Player Data (Current)
    player_x:      .word START_POS_X       # X position (0-63)
    player_y:      .word START_POS_Y       # Y position (0-63)
    player_width:  .word START_WIDTH        # Width (units)
    player_height: .word START_HEIGHT        # Height (units)
    player_color: .word PURPLE_COLOR
    player_vel_y:  .word START_VEL_Y        # Vertical velocity
    player_vel_x:   .word START_VEL_X	      # Horizontal velocity
    gravity:       .word 1        # Gravity strength
    jump_force_vertical:    .word START_JUMP_FORCE       # Jump strength
    jump_horizontal_force: .word START_JUMP_FORCE_X     # Horizontal push during diagonal jumps
    single_jump: .word 0 # 0 = single jump can occur, 1 = single jump cannot occur
    double_jump: .word 0 # 0 = double jump can occur, 1 = double jump cannot occur

    
    health_bar_count:      .word   START_HEALTH

    # Game state
    current_level:    .word 0          # 0=menu, 1=level1, 2=level2, 3=level3
    game_state:       .word 0          # 0=menu, 1=playing, 2=win, 3=lose
    menu_selection:   .word 0          # 0=start, 1=exit

    # Level platform data
    # Format for each level:
    # - word: platform count
    # - followed by platform data (x, y, width, height)
    # - last platform is the win platform (will be colored green)

level1_platforms:
    .word 5                  # platform count
    # Regular platforms (x, y, width, height)
    .word 0, 50, 20, 3       # floor
    .word 30, 40, 10, 3      # middle platform
    .word 15, 30, 10, 3      # left platform
    .word 40, 20, 15, 3      # high right platform
    # Win platform (will be colored green)
    .word 10, 10, 5, 3       # top left - win platform

level2_platforms:
    .word 6                  # platform count

    .word 0, 55, 15, 3       # partial floor
    .word 25, 55, 15, 3      # other partial floor
    .word 10, 40, 8, 3       # floating left
    .word 35, 40, 8, 3       # floating right
    .word 20, 25, 10, 3      # middle high
    # Win platform
    .word 45, 15, 8, 3       # top right - win platform

level3_platforms:
    .word 7                  # platform count

    .word 0, 50, 10, 3       # small left floor
    .word 15, 50, 10, 3      # middle floor
    .word 30, 50, 10, 3      # right floor
    .word 5, 35, 5, 3        # left pillar
    .word 25, 35, 5, 3       # middle pillar
    .word 45, 35, 5, 3       # right pillar
    # Win platform
    .word 20, 15, 10, 3      # top center - win platform

    # Current platform arrays (active level)
    platform_x_array:     .space 28   # 7 platforms max * 4 bytes
    platform_y_array:     .space 28
    platform_width_array: .space 28
    platform_height_array:.space 28
    platform_count:       .word 0
    win_platform_index:   .word 0     # index of win platform in arrays

    # win and lose conditions
    win_condition:	.word 0
    lose_condition:	.word 0

.text
main:
    li $sp, 0x7ffffffc
    jal clear_screen
    jal reset_player
    jal reset_health_bar

    # Start at menu
    sw $zero, current_level
    sw $zero, game_state

game_loop:
    lw $t1, game_state
    beqz $t1, handle_menu_state
    li $t2, 1
    beq $t1, $t2, handle_play_state
    li $t2, 2
    beq $t1, $t2, handle_win_state
    li $t2, 3
    beq $t1, $t2, handle_lose_state

    j game_loop_end

handle_menu_state:
    jal draw_start_menu
    
    jal handle_menu_input
    
    j game_loop_end

handle_play_state:
    jal input_handler
    jal update_player
    jal draw_screen
    jal check_win_condition
    j game_loop_end

handle_win_state:
    jal win_screen
    j game_loop_end

handle_lose_state:
    jal lose_screen

game_loop_end:
    li $v0, 32
    li $a0, FRAME_DELAY
    syscall

    j game_loop


draw_start_menu:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    jal clear_screen

    # Draw "START GAME" box (now wider)
    li $s1, 10          # x position (left-aligned)
    li $s2, 20          # y position
    li $s3, 30          # width (30 units = 120 pixels)
    li $s4, 5           # height
    li $s5, WHITE_COLOR
    jal draw_rectangle

    # Draw "EXIT GAME" box (now wider)
    li $s1, 10
    li $s2, 30
    li $s3, 24          # width (24 units = 96 pixels)
    li $s4, 5
    jal draw_rectangle

    # Draw selection indicator (keep existing code)
    lw $t1, menu_selection
    beqz $t1, draw_start_selected
    # Draw exit selected
    li $s1, 7           # Adjusted position for wider boxes
    li $s2, 30
    li $s3, 3
    li $s4, 5
    li $s5, GREEN_COLOR
    j draw_selection

draw_start_selected:
    li $s1, 7           # Adjusted position for wider boxes
    li $s2, 20
    li $s3, 3
    li $s4, 5
    li $s5, GREEN_COLOR

draw_selection:
    jal draw_rectangle

    # Draw "START GAME" text
    li $a0, 12          # x start (10 + 2 padding)
    li $a1, 20          # y position
    li $a2, BLACK_COLOR # text color
    
    # Draw each letter in "START GAME"
    jal draw_letter_S
    addi $a0, $a0, 6    # Move right 3 units
    jal draw_letter_T
    addi $a0, $a0, 6
    jal draw_letter_A
    addi $a0, $a0, 6
    jal draw_letter_R
    addi $a0, $a0, 6
    jal draw_letter_T
    addi $a0, $a0, 6    # Space between words (3 units * 2)

    # Draw "EXIT GAME" text
    li $a0, 12          # x start (10 + 2 padding)
    li $a1, 30          # y position
    li $a2, BLACK_COLOR
    
    # Draw each letter in "EXIT GAME"
    jal draw_letter_E
    addi $a0, $a0, 6
    jal draw_letter_X
    addi $a0, $a0, 6
    jal draw_letter_I
    addi $a0, $a0, 6
    jal draw_letter_T
    addi $a0, $a0, 6    # Space between words
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
# Letter drawing functions
# Parameters:
# $a0 = x position (unit)
# $a1 = y position (unit)
# $a2 = color

draw_letter_S:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    # Top horizontal
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 3            # width
    li $s4, 1            # height
    move $s5, $a2        # color
    jal draw_rectangle
    
    # Left vertical (top)
    move $s1, $a0        # x
    addi $s2, $a1, 1     # y
    li $s3, 1            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    # Middle horizontal
    move $s1, $a0        # x
    addi $s2, $a1, 2     # y
    li $s3, 3            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    # Right vertical (bottom)
    addi $s1, $a0, 2     # x
    addi $s2, $a1, 3     # y
    li $s3, 1            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    # Bottom horizontal
    move $s1, $a0        # x
    addi $s2, $a1, 4     # y
    li $s3, 3            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

draw_letter_T:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    # Top horizontal
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 3            # width
    li $s4, 1            # height
    move $s5, $a2        # color
    jal draw_rectangle
    
    # Vertical bar
    addi $s1, $a0, 1     # x
    addi $s2, $a1, 1     # y
    li $s3, 1            # width
    li $s4, 4            # height
    jal draw_rectangle
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

draw_letter_A:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    # Left vertical
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 1            # width
    li $s4, 5            # height
    move $s5, $a2        # color
    jal draw_rectangle
    
    # Right vertical
    addi $s1, $a0, 2     # x
    move $s2, $a1        # y
    li $s3, 1            # width
    li $s4, 5            # height
    jal draw_rectangle
    
    # Top horizontal
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 3            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    # Middle horizontal
    move $s1, $a0        # x
    addi $s2, $a1, 2     # y
    li $s3, 3            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

draw_letter_R:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    # Left vertical
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 1            # width
    li $s4, 5            # height
    move $s5, $a2        # color
    jal draw_rectangle
    
    # Top horizontal
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 3            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    # Right top vertical
    addi $s1, $a0, 2     # x
    move $s2, $a1        # y
    li $s3, 1            # width
    li $s4, 2            # height
    jal draw_rectangle
    
    # Middle horizontal
    move $s1, $a0        # x
    addi $s2, $a1, 2     # y
    li $s3, 2            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    # Diagonal
    addi $s1, $a0, 1     # x
    addi $s2, $a1, 3     # y
    li $s3, 1            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    addi $s1, $a0, 2     # x
    addi $s2, $a1, 4     # y
    li $s3, 1            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

draw_letter_E:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    # Left vertical
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 1            # width
    li $s4, 5            # height
    move $s5, $a2        # color
    jal draw_rectangle
    
    # Top horizontal
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 3            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    # Middle horizontal
    move $s1, $a0        # x
    addi $s2, $a1, 2     # y
    li $s3, 2            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    # Bottom horizontal
    move $s1, $a0        # x
    addi $s2, $a1, 4     # y
    li $s3, 3            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

draw_letter_X:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    # Diagonal top-left to bottom-right
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 1            # width
    li $s4, 1            # height
    move $s5, $a2        # color
    jal draw_rectangle
    
    addi $s1, $a0, 1     # x
    addi $s2, $a1, 1     # y
    jal draw_rectangle
    
    addi $s1, $a0, 2     # x
    addi $s2, $a1, 2     # y
    jal draw_rectangle
    
    addi $s1, $a0, 1     # x
    addi $s2, $a1, 3     # y
    jal draw_rectangle
    
    addi $s1, $a0, 0     # x
    addi $s2, $a1, 4     # y
    jal draw_rectangle
    
    # Diagonal top-right to bottom-left
    addi $s1, $a0, 2     # x
    move $s2, $a1        # y
    jal draw_rectangle
    
    addi $s1, $a0, 1     # x
    addi $s2, $a1, 1     # y
    jal draw_rectangle
    
    addi $s1, $a0, 0     # x
    addi $s2, $a1, 2     # y
    jal draw_rectangle
    
    addi $s1, $a0, 1     # x
    addi $s2, $a1, 3     # y
    jal draw_rectangle
    
    addi $s1, $a0, 2     # x
    addi $s2, $a1, 4     # y
    jal draw_rectangle
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

draw_letter_I:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    # Top horizontal
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 3            # width
    li $s4, 1            # height
    move $s5, $a2        # color
    jal draw_rectangle
    
    # Middle vertical
    addi $s1, $a0, 1     # x
    addi $s2, $a1, 1     # y
    li $s3, 1            # width
    li $s4, 3            # height
    jal draw_rectangle
    
    # Bottom horizontal
    move $s1, $a0        # x
    addi $s2, $a1, 4     # y
    li $s3, 3            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
draw_letter_G:
    # Save registers
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    # Top horizontal
    move $s1, $a0        # x
    move $s2, $a1        # y
    li $s3, 3            # width
    li $s4, 1            # height
    move $s5, $a2        # color
    jal draw_rectangle
    
    # Left vertical
    move $s1, $a0        # x
    addi $s2, $a1, 1     # y
    li $s3, 1            # width
    li $s4, 3            # height
    jal draw_rectangle
    
    # Bottom horizontal
    move $s1, $a0        # x
    addi $s2, $a1, 4     # y
    li $s3, 3            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    # Right vertical (bottom half)
    addi $s1, $a0, 2     # x
    addi $s2, $a1, 2     # y
    li $s3, 1            # width
    li $s4, 3            # height
    jal draw_rectangle
    
    # Middle horizontal extension
    addi $s1, $a0, 1     # x
    addi $s2, $a1, 2     # y
    li $s3, 2            # width
    li $s4, 1            # height
    jal draw_rectangle
    
    # Restore registers
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

handle_menu_input:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $t1, KEYBOARD_ADDRESS
    lw $t2, 0($t1)
    beqz $t2, menu_input_done

    lw $t3, 4($t1)        # Get key code

    beq $t3, 0x77, menu_up    # 'w'
    beq $t3, 0x73, menu_down  # 's'
    beq $t3, 0x67, menu_select # 'g'

    j menu_input_done

menu_up:
    sw $zero, menu_selection
    j menu_input_done

menu_down:
    li $t4, 1
    sw $t4, menu_selection
    j menu_input_done

menu_select:
    lw $t4, menu_selection
    beqz $t4, start_game
    # Else exit
    li $v0, 10
    syscall

start_game:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $t4, 1
    sw $t4, current_level
    jal load_level

    lw $ra, 0($sp)
    addi $sp, $sp, 4

    j menu_input_done

menu_input_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

    # ----------------------------
    # draw_screen
    # ----------------------------
draw_screen:
    addi $sp, $sp, -4
    sw $ra, 0 ($sp)

    lw $s1, win_condition
    bnez $s1, draw_win_screen

    lw $s2, lose_condition
    bnez $s2, draw_loss_screen

    jal clear_screen
    jal update_player
    jal draw_platforms
    jal draw_player
    jal draw_health_bar
    j draw_screen_end


draw_win_screen:
    jal win_screen
    j draw_screen_end

draw_loss_screen:
    jal lose_screen
    j draw_screen_end

draw_screen_end:
    lw $ra, 0 ($sp)
    addi $sp, $sp, 4
    jr $ra
# Level loading funcs
load_level:

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t1, current_level
    beqz $t1, load_menu

    # Level 1
    li $t2, 1
    beq $t1, $t2, load_level1

    # Level 2
    li $t2, 2
    beq $t1, $t2, load_level2

    # Level 3
    li $t2, 3
    beq $t1, $t2, load_level3

load_level1:
    
    la $t3, level1_platforms
    j load_level_done

load_level2:
    la $t3, level2_platforms
    j load_level_done

load_level3:
    la $t3, level3_platforms

load_level_done:
    # Copy platform data to active platform arrays
    lw $t2, 0($t3)            
    sw $t2, platform_count     
    addi $t3, $t3, 4           

    # Set win platform index (last platform)
    addi $t0, $t2, -1
    sw $t0, win_platform_index

    # Initialize array pointers
    la $t4, platform_x_array
    la $t5, platform_y_array
    la $t6, platform_width_array
    la $t7, platform_height_array

    li $t1, 0                  # index

    copy_loop:
    beq $t1, $t2, copy_done    # If copied all platforms

    # Copy x coordinate
    lw $t8, 0($t3)
    sw $t8, 0($t4)
    addi $t3, $t3, 4
    addi $t4, $t4, 4

    # Copy y coordinate
    lw $t8, 0($t3)
    sw $t8, 0($t5)
    addi $t3, $t3, 4
    addi $t5, $t5, 4

    # Copy width
    lw $t8, 0($t3)
    sw $t8, 0($t6)
    addi $t3, $t3, 4
    addi $t6, $t6, 4

    # Copy height
    lw $t8, 0($t3)
    sw $t8, 0($t7)
    addi $t3, $t3, 4
    addi $t7, $t7, 4

    addi $t1, $t1, 1           
    j copy_loop

copy_done:
    
    jal reset_player      
    li $t1, 1
    sw $t1, game_state         

    lw $ra, 0($sp)            
    addi $sp, $sp, 4
    jr $ra                    


load_menu:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    reset_player:

    	li $t1, START_POS_X      
    	sw $t1, player_x             

    	
    	li $t1, START_POS_Y       
    	sw $t1, player_y             

    	
    	li $t1, START_WIDTH       
    	sw $t1, player_width        

    	
    	li $t1, START_HEIGHT      
    	sw $t1, player_height        

    	
    	li $t1, START_VEL_Y       
    	sw $t1, player_vel_y         

    	
    	li $t1, START_VEL_X       
    	sw $t1, player_vel_x         


    	li $t1, 0                    
    	sw $t1, single_jump          


    	li $t1, 0                    
    	sw $t1, double_jump          


    	li $t1, PURPLE_COLOR
    	sw $t1, player_color

    	
    	li $t1, START_JUMP_FORCE       
    	sw $t1, jump_force_vertical		  


    	li $t1, START_JUMP_FORCE_X      
    	sw $t1, jump_horizontal_force        


    	jr $ra

    draw_player:
    	lw $a0, player_x
    	lw $a1, player_y
    	lw $a2, player_width
    	lw $a3, player_height
    	lw $t1, player_color


    	sub $sp, $sp, 4
    	sw $ra, 0($sp)


    	move $s1, $a0
    	move $s2, $a1
    	move $s3, $a2
    	move $s4, $a3
    	move $s5, $t1
    	jal draw_rectangle


    	lw $ra, 0($sp)
    	add $sp, $sp, 4
    	jr $ra

    update_player:

    	lw $t1, player_vel_y
    	lw $t2, gravity
    	add $t1, $t1, $t2
    	sw $t1, player_vel_y


    	lw $t1, player_vel_x
    	lw $t2, player_x
    	add $t2, $t2, $t1


    	bgez $t2, right_check
    	li $t2, 0
    right_check:

    	lw $t3, player_width
    	add $t4, $t2, $t3
    	li $t5, 63
    	ble $t4, $t5, store_x
    	li $t2, 63
    	sub $t2, $t2, $t3
    store_x:
    	sw $t2, player_x


    	lw $t1, player_vel_y
    	lw $t2, player_y
    	add $t2, $t2, $t1


    	li $t3, 2
    	bge $t2, $t3, platform_check


    	li $t2, 3
    	lw $t1, player_vel_y
    	bgez $t1, platform_check

    	
    	j platform_check

    platform_check:

    	move $t0, $t2              
    	
    	lw $t1, player_vel_y
    	blez $t1, floor_check       

    	lw $t3, player_x            
    	lw $t4, player_width
    	add $t5, $t3, $t4           
    	lw $t6, player_height
    	add $t7, $t0, $t6           

    	li $t1, 0                   
    	lw $t2, platform_count

    platform_loop:
    	beq $t1, $t2, floor_check   

    	
    	sll $t8, $t1, 2             

    	
    	la $t9, platform_x_array
    	add $t9, $t9, $t8
    	lw $s1, 0($t9)              

    	la $t9, platform_width_array
    	add $t9, $t9, $t8
    	lw $s2, 0($t9)              
    	add $s3, $s1, $s2           

    	la $t9, platform_y_array
    	add $t9, $t9, $t8
    	lw $s4, 0($t9)              

    	
    	bge $t3, $s3, next_platform 
    	ble $t5, $s1, next_platform 


    	sub $s5, $s4, 2             
    	bgt $t0, $s4, next_platform 
    	bgt $s5, $t7, next_platform 

    	sub $t0, $s4, $t6           
    	sw $zero, player_vel_y      
    	sw $zero, single_jump       
    	sw $zero, double_jump
    	j store_updated_y

    next_platform:
    	addi $t1, $t1, 1            
    	j platform_loop

    floor_check:

    	lw $t6, player_height
    	add $t7, $t0, $t6           
    	li $t3, 64                  
    	ble $t7, $t3, store_updated_y

    	

    	
    	addi $sp, $sp, -4
    	sw $ra, 0($sp)

    	jal health_decrease


    	lw $ra, 0($sp)
    	addi $sp, $sp, 4

    	
    	jr $ra

    store_updated_y:
    	sw $t0, player_y

    	
    	lw $t1, player_vel_x
    	beqz $t1, no_friction
    	blt $t1, 0, friction_neg
    	addi $t1, $t1, -1           
    	bgez $t1, store_friction
    	li $t1, 0
    	j store_friction
    friction_neg:
    	addi $t1, $t1, 1            
    	blez $t1, store_friction
    	li $t1, 0
    store_friction:
    	sw $t1, player_vel_x
    no_friction:
    	jr $ra



    input_handler:
    	li $t1, KEYBOARD_ADDRESS       
    	lw $t2, 0($t1)               # Ready for reading  
    	beqz $t2, input_done             

    	# Only process key if ready bit was 1
    	lw $t3, 4($t1)                 # Get key code

    	beq $t3, KEY_LEFT, move_left        # 'a'
    	beq $t3, KEY_RIGHT, move_right      # 'd'
    	beq $t3, KEY_JUMP, jump		# "w"
    	beq $t3, KEY_LEFT_JUMP, left_jump   # 'q'
    	beq $t3, KEY_RIGHT_JUMP, right_jump   # 'e'
    	beq $t3, KEY_RESTART, restart_game   # 'r'
    	beq $t3, KEY_QUIT, quit_game   # 't'

    input_done:
    	jr $ra
    move_left:
    	lw $t1, player_x
    	li $t2, 1        # Left boundary
    	ble $t1, $t2, no_move
    	addi $t1, $t1, -3
    	sw $t1, player_x
    no_move:
    	j input_done
    move_right:
    	lw $t1, player_x
    	lw $t2, player_width
    	li $t3, 63       # Right boundary
    	add $t4, $t1, $t2
    	bge $t4, $t3, no_move
    	addi $t1, $t1, 3
    	sw $t1, player_x
    	j input_done

    jump:
    	lw $t1, single_jump
    	beqz $t1, first_jump      

    	lw $t2, double_jump
    	beqz $t2, second_jump     
    	j input_done              # Already used both jumps so skip

    first_jump:
    	lw $t3, jump_force_vertical
    	sw $t3, player_vel_y
    	li $t4, 1
    	sw $t4, single_jump       # Mark first jump used
    	j input_done

    second_jump:
    	lw $t3, jump_force_vertical
    	sw $t3, player_vel_y
    	li $t4, 1
    	sw $t4, double_jump       # Mark double jump used
    	j input_done


    left_jump:
    	lw $t1, single_jump
    	beqz $t1, left_first_jump

    	lw $t2, double_jump
    	beqz $t2, left_second_jump

    	j input_done

    left_first_jump:
    	lw $t3, jump_force_vertical
    	sw $t3, player_vel_y

    	lw $t3, jump_horizontal_force
    	neg $t3, $t3
    	sw $t3, player_vel_x

    	li $t4, 1
    	sw $t4, single_jump
    	j input_done

    left_second_jump:
    	lw $t3, jump_force_vertical
    	sw $t3, player_vel_y

    	lw $t3, jump_horizontal_force
    	neg $t3, $t3
    	sw $t3, player_vel_x

    	li $t4, 1
    	sw $t4, double_jump
    	j input_done

    right_jump:
    	lw $t1, single_jump
    	beqz $t1, right_first_jump     
    	lw $t2, double_jump
    	beqz $t2, right_second_jump    

    	j input_done                   

    right_first_jump:

    	lw $t3, jump_force_vertical
    	sw $t3, player_vel_y

    	lw $t3, jump_horizontal_force
    	sw $t3, player_vel_x

    	li $t4, 1
    	sw $t4, single_jump            
    	j input_done

    right_second_jump:

    	lw $t3, jump_force_vertical
    	sw $t3, player_vel_y


    	lw $t3, jump_horizontal_force
    	sw $t3, player_vel_x

    	li $t4, 1
    	sw $t4, double_jump            
    	j input_done

restart_game:
    addi $sp, $sp, -4
    sw $ra, 0($sp)


    jal reset_player
    jal reset_health_bar


    sw $zero, win_condition
    sw $zero, lose_condition


    li $t1, 1
    sw $t1, game_state


    jal load_level

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

quit_game:
    jal clear_screen
    li $v0, 10 # exit condition
    syscall


draw_platforms:
    # Save return address
    sub $sp, $sp, 4
    sw $ra, 0($sp)

    # Initi vars
    li $t1, 0                  # amt
    lw $t2, platform_count     
    lw $t3, win_platform_index 

    # Load temp array addresses
    la $t4, platform_x_array
    la $t5, platform_y_array
    la $t6, platform_width_array
    la $t7, platform_height_array

platform_loop_start:

    beq $t1, $t2, platform_loop_end


    sll $t8, $t1, 2


    add $t9, $t4, $t8
    lw $s1, 0($t9)            

    add $t9, $t5, $t8
    lw $s2, 0($t9)            

    add $t9, $t6, $t8
    lw $s3, 0($t9)            

    add $t9, $t7, $t8
    lw $s4, 0($t9)            


    bne $t1, $t3, not_win_platform
    li $s5, GREEN_COLOR      
    j draw_current_platform

not_win_platform:
    li $s5, PLATFORM_COLOR   

draw_current_platform:
    jal draw_rectangle

    # Move to next platform
    addi $t1, $t1, 1
    j platform_loop_start

platform_loop_end:
    # Restore and return
    lw $ra, 0($sp)
    add $sp, $sp, 4
    jr $ra

    draw_rectangle:
    	# Save all $t registers before proceeding
    	sub $sp, $sp, 36       
    	sw $t1, 0($sp)
    	sw $t2, 4($sp)
    	sw $t3, 8($sp)
    	sw $t4, 12($sp)
    	sw $t5, 16($sp)
    	sw $t6, 20($sp)
    	sw $t7, 24($sp)
    	sw $t8, 28($sp)
    	sw $t9, 32($sp)

    	li $t2, 64   
    	move $t1, $s5  

    	move $t3, $s2           
    	add  $t4, $s2, $s4      
    y_loop:
    	bge $t3, $t4, end_draw_rect

    	move $t5, $s1           
    	add  $t6, $s1, $s3      
    x_loop:
    	bge $t5, $t6, end_x_loop

    	# offset calc
    	mult $t3, $t2
    	mflo $t7
    	add  $t7, $t7, $t5
    	sll  $t7, $t7, 2        # word to byte
    	li   $t8, BASE_ADDRESS
    	add  $t7, $t7, $t8      # final address

    	# bounds check
    	li   $t9, END_ADDRESS
    	blt  $t7, BASE_ADDRESS, skip_pixel
    	bge  $t7, $t9, skip_pixel

    	sw   $t1, 0($t7)        # write color
    skip_pixel:
    	addi $t5, $t5, 1
    	j x_loop
    end_x_loop:
    	addi $t3, $t3, 1
    	j y_loop
    end_draw_rect:
    	# Restore $t registers
    	lw $t1, 0($sp)
    	lw $t2, 4($sp)
    	lw $t3, 8($sp)
    	lw $t4, 12($sp)
    	lw $t5, 16($sp)
    	lw $t6, 20($sp)
    	lw $t7, 24($sp)
    	lw $t8, 28($sp)
    	lw $t9, 32($sp)
    	add $sp, $sp, 36         # Deallocate stack space

    	jr $ra


reset_health_bar:
    li $t0, START_HEALTH
    sw $t0, health_bar_count
    jr $ra



health_decrease:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t1, health_bar_count
    addi $t1, $t1, -1

    blez $t1, player_death

    sw $t1, health_bar_count
    jal reset_player

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
player_death:
    addi $t2, $zero, 1
    sw $t2, lose_condition

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_health_bar:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $t1, 0 # index = 0
    lw $t2, health_bar_count # array length
    	
draw_health_bar_loop:
    beq $t1, $t2, draw_health_bar_end

    sll $t3, $t1, 3 # offset = index * 6
    addi $t3, $t3, 3

    move $a0, $t3 # x pos
   	li $a1, 3 # y pos
   	jal draw_plus

   	addi $t1, $t1, 1
   	j draw_health_bar_loop

draw_health_bar_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


draw_plus:
    # Save registers
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)

    # Vertical rectangle (3x5)
    move $s1, $a0        # x-center
    addi $s2, $a1, -2    # y-start (2 units above center)
    li $s3, 1            # width
    li $s4, 5            # height
    li $s5, RED_COLOR
    jal draw_rectangle

    # Horizontal rectangle (5x3)
    addi $s1, $a0, -2    # x-start (2 units left of center)
    move $s2, $a1        # y-center
    li $s3, 5            # width
    li $s4, 1            # height
    jal draw_rectangle

    # Restore registers and return
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra
    # clear_screen
    #
    clear_screen:
    	li $t1, BASE_ADDRESS
    	li $t2, BLACK_COLOR
    	li $t3, END_ADDRESS
    clear_loop:
    	sw $t2, 0($t1)
    	addi $t1, $t1, 4
    	blt $t1, $t3, clear_loop
    	jr $ra

    # W and L screens
reset_end_conditions:
    sw $zero, win_condition
    sw $zero, lose_condition

    jr $ra

check_win_condition:
    addi $sp, $sp, -4
    sw $ra, 0($sp)


    lw $t1, player_x            
    lw $t2, player_width
    add $t3, $t1, $t2           
    lw $t4, player_y            
    lw $t5, player_height
    add $t6, $t4, $t5           

    
    lw $t7, win_platform_index
    sll $t7, $t7, 2

    la $t8, platform_x_array
    add $t8, $t8, $t7
    lw $t9, 0($t8)              

    la $t8, platform_width_array
    add $t8, $t8, $t7
    lw $t0, 0($t8)
    add $t0, $t9, $t0           

    la $t8, platform_y_array
    add $t8, $t8, $t7
    lw $s1, 0($t8)              

    la $t8, platform_height_array
    add $t8, $t8, $t7
    lw $s2, 0($t8)
    add $s2, $s1, $s2           
    
    bge $t1, $t0, no_collision   
    ble $t3, $t9, no_collision   
    bge $t4, $s2, no_collision   
    ble $t6, $s1, no_collision   

    
    lw $t1, current_level
    addi $t1, $t1, 1            

    
    li $t2, 3
    bgt $t1, $t2, game_complete

    
    sw $t1, current_level
    jal load_level

    j no_collision

game_complete:
    
    li $t1, 2
    sw $t1, game_state

    no_collision:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

    win_screen:
        addi $sp, $sp, -4
        sw $ra, 0($sp)

        jal clear_screen

        li $s5, GREEN_COLOR

        
        li $s1, 100
        li $s2, 20
        li $s3, 5
        li $s4, 25
        jal draw_rectangle

        li $s1, 120
        li $s2, 20
        li $s3, 5
        li $s4, 25
        jal draw_rectangle

        li $s1, 105
        li $s2, 40
        li $s3, 15
        li $s4, 5
        jal draw_rectangle

        li $s1, 110
        li $s2, 30
        li $s3, 5
        li $s4, 10
        jal draw_rectangle

        li $v0, 32
        li $a0, 1000
        syscall

        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra

    lose_screen:
        addi $sp, $sp, -4
        sw $ra, 0($sp)

        jal clear_screen

        li $s5, RED_COLOR

        li $s1, 100
        li $s2, 22
        li $s3, 3
        li $s4, 17
        jal draw_rectangle


        li $s1, 100
        li $s2, 39
        li $s3, 12
        li $s4, 3
        jal draw_rectangle


        li $v0, 32
        li $a0, 1000
        syscall

        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
