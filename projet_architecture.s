.data
##YOU WILL NOT EAT MY VARIABLES!!! (change at your own risk)
	no_eating_variables: .space 65536
##for image
	larg_image: .word 256
	haut_image: .word 256
	larg_unit: .word 8
	haut_unit: .word 8
	I_buff: .word 0 ##will change to address of image space
	larg_in_units: .word 0 #we will need these a lot and they don't change once the game starts/
	haut_in_units: .word 0 # /so it's more efficient to calculate them once and store them here
	I_visu: .word 0x10010000
## for keyboard
	RCR: .word 0xffff0000
	RDR: .word 0xffff0004
	ascii_i: .word 105
	ascii_p: .word 112
	ascii_o: .word 111
## for joueur
	x_joueur: .word 12
	y_joueur: .word 29
	larg_joueur: .word 5
	haut_joueur: .word 2
	col_joueur: .word 0x0000ff
	j_addr: .word 0
	vies_joueur_init: .word 3 
#for envahisseurs
	nr_env: .word 20
	larg_env: .word 3
	haut_env: .word 1
	col_env: .word 0xff0000
	esp_hor_env: .word 1
	esp_hor_row: .word 2
	aug_ord_env: .word 1
	rythme_tirs: .word 50
	vec_env: .word 0 # address of envahisseur vector, will change
	#how many rows of envahisseurs
	no_rows_env : .word 4
	# direction of movement for all of them : droit = 0, gauche = 1
	dir_env: .word 0
#for obstacles
	no_obs: .word 4
	larg_obs: .word 4
	haut_obs: .word 2
	esp_hor_obs: .word 2
	col_obs: .word 0xfff000
	vec_obs: .word 0 #address of obstacle vector, will change
#for missiles
	col_mis: .word 0xffffff
	vit_mis: .word 1
	long_mis: .word 3
	ep_mis: .word 1
	no_max_mis: .word 5
	vec_mis: .word 0 
	no_cur_mis: .word 0
## for tests
newline: .asciz "\n"
space: .asciz " "
.text
j main
## fonctions image ##############################################################################################
I_largeur:
	lw t0, larg_image
	lw t1, larg_unit
	div a0, t0, t1
	la t0, larg_in_units
	sw a0, (t0)
	jr ra
I_hauteur:
	lw t0, haut_image
	lw t1, haut_unit
	div a0, t0, t1
	la t0, haut_in_units
	sw a0, (t0)
	jr ra
I_creer:
##prologue
	addi sp sp -12
	sw ra (sp)
	sw s0 4(sp)
	sw s1 8(sp)
##corps
	jal I_largeur
	mv s0, a0
	jal I_hauteur
	mv s1, a0
	mul s0, s0, s1 #s0 is total nr of units allocated
	li t0 4 # size of word in bytes
	mul a0, s0, t0 # a0 = nr bytes allocated
	li a7 9
	ecall
	la t0 I_buff
	sw a0 (t0)
	lw s1 8(sp)
	lw s0 4(sp)
	lw ra(sp)
	addi sp sp 12
	jr ra
I_xy_to_addr: # a0 = abs, a1 = ord
	lw t0, larg_in_units
	mul t0, t0, a1
	add t0, t0, a0
	li t1 4
	mul a0, t0, t1
	lw t1 I_buff
	add a0 a0 t1
	jr ra
I_addr_to_xy: #a0 = address of unit
	lw t0, I_buff
	sub a0 a0 t0 #a0 = decalage in bytes
	li t0 4
	div a0 a0 t0 #a0 = decalage in units
	mv t0 a0
	lw t1 larg_in_units
	div t0 t0 t1 #t0 = abscisse
	mul t2 t0 t1 #t2 = decalage - ordonee
	sub a1 a0 t2 # a1 = ordonee
	mv a0 t0 # a0 = abscisse
	jr ra
I_plot:
#prologue
# this function does not modify any a register
	addi sp sp -12
	sw ra (sp)
	sw a0 4(sp)
	sw a1 8(sp)
#corps
# a0 = abscisse, a1 = ordonee, a2 = couleur
	jal I_xy_to_addr
	sw a2 (a0)
#epilogue
	lw ra (sp)
	lw a0 4(sp)
	lw a1 8(sp)
	addi sp sp 12
	jr ra
I_effacer:
	lw t1 I_buff
	lw t2 larg_in_units
	lw t3 haut_in_units
	mul t2 t2 t3 #t2 is now total number of units
loop_effacer:
	beqz t2 exit_loop_effacer
	sw zero (t1)
	addi t1 t1 4
	addi t2 t2 -1
	j loop_effacer
exit_loop_effacer:
	jr ra
I_rectangle:
# a0, a1 = abs, ord coin gauche
# a2 = hauteur , a3 = largeur, a4 = couleur
# prologue
	addi sp sp -44
	sw ra (sp)
	sw s0 4(sp)
	sw s1 8(sp)
	sw s2 12(sp)
	sw s3 16(sp)
	sw s4 20(sp)
## i am also saving the a registers for animation purposes
	sw a0 24(sp)
	sw a1 28(sp)
	sw a2 32(sp)
	sw a3 36(sp)
	sw a4 40(sp)
#corps
	mv s0 a0
	mv s1 a1
	mv s2 a2
	mv s3 a3
	mv s4 a4
rectangle_loop_ext:
	beqz s2 exit_rectangle_loop_ext
	mv a3 s3
rectangle_loop_int:
	beqz a3 exit_rectangle_loop_int
	mv a2 s4
	jal I_plot
	addi a1 a1 1
	addi a3 a3 -1
	j rectangle_loop_int
exit_rectangle_loop_int:
	addi s2 s2 -1
	addi a0 a0 1
	mv a1 s1
	j rectangle_loop_ext
exit_rectangle_loop_ext:
#epilogue
	lw ra (sp)
	lw s0 4(sp)
	lw s1 8(sp)
	lw s2 12(sp)
	lw s3 16(sp)
	lw s4 20(sp)
## restoring a registers too
	lw a0 24(sp)
	lw a1 28(sp)
	lw a2 32(sp)
	lw a3 36(sp)
	lw a4 40(sp)
	addi sp sp 44
	jr ra
I_buff_to_visu:
#prologue
#corps	
	lw t0 I_buff # t0 is buffer start address
	lw t1 I_visu # t1 is display start address
	lw t2 larg_in_units # t2 is largeur in units of screen
	lw t3 haut_in_units # t3 is hauteur in units of screen
	mul t2 t2 t3 # t2 is number of units on screen
	#we will use t2 as counter and t3 as aux from buff to visu
btv_loop:
	beqz t2 end_btv_loop
	lw t3 (t0)
	sw t3 (t1)
	addi t2 t2 -1
	addi t0 t0 4
	addi t1 t1 4
	j btv_loop
end_btv_loop:	
#epilogue
	jr ra
## functions for gestion de donnees
# obstacles #############################################################################################
O_creer:
#variables locales pour obstacles:
#coordonees pour chaque obstacle --> 2 integers/obstacle --> size = 8 octets
#prologue:
	addi sp sp -4
	sw ra (sp)
#corps:
	lw t0 no_obs
	li t1 8
	mul a0 t0 t1 # a0 is now the nr of octets we need to allocate
	li a7 9
	ecall
	#a0 is now address of where we allocated the memory
	la t0 vec_obs
	sw a0 (t0) # we saved the address of the vector as a global variable
	lw t0 haut_image
	lw t1 haut_unit
	div t0 t0 t1 # t0 is now haut in units
	li t1 5
	div t0 t0 t1 # t0 is now 1/5th of screen in units
	li t1 4
	mul t0 t0 t1 # t0 is now 4/5 of screen in units -> lower 1/5th of screen -> ordonee de tous les obstacles
	mv t1 zero #t1 will be abscisse of each obstacle
	lw t2 larg_obs # t2 is now largeur of obstacle
	lw t3 esp_hor_obs #t3 is now the space around an obstacle
	lw t4 larg_in_units #t4 = largeur de l'ecran en units
O_creer_loop:
	ble t4 zero end_o_creer_loop
	add t1 t1 t3
	sw t1 (a0)
	addi a0 a0 4
	sw t0 (a0)
	addi a0 a0 4
	add t1 t1 t2
	add t1 t1 t3
	# next abscisse
	# advance counter too
	sub t4 t4 t3
	sub t4 t4 t3
	sub t4 t4 t2
	j O_creer_loop
end_o_creer_loop:
#epilogue:
	lw ra (sp)
	addi sp sp 4
	jr ra
### affichage #################################
O_afficher:
#prologue
	addi sp sp -16
	sw ra (sp)
	sw s0 4(sp)
	sw s1 8(sp)
	sw s2 12(sp)
#corps
	lw s0 no_obs  # s0 = iterator nr obstacles
	lw s1 I_buff # s1 = buffer address
	lw s2 vec_obs # s2 = obstacle structs address
O_afficher_loop:
	beqz s0 end_o_afficher_loop
	lw a0 (s2) # a0 = abscisse obs
	lw a1 4(s2) # a1 = ordonee obs
	lw a2 larg_obs # a2 = largeur obstacle
	lw a3 haut_obs # a3 = hauteur obstacle
	lw a4 col_obs # a4 = couleur obstacle
	jal I_rectangle
	addi s0 s0 -1
	addi s2 s2 8
	j O_afficher_loop
end_o_afficher_loop:
#epilogue
	lw ra (sp)
	lw s0 4(sp)
	lw s1 8(sp)
	lw s2 12(sp)
	addi sp sp 16
	jr ra
# envahisseurs ############################################################################
E_creer:
# variables locales pour envahisseurs:
# abscisse, ordonee, status (dead = 0/alive = 1) --> size = 12 octets
#prologue
	addi sp sp -4
	sw ra (sp)
#corps
	lw t0 nr_env
	li t1 12
	mul a0 t0 t1 # a0 is now the nr of octets we need to allocate
	li a7 9
	ecall
	#a0 is now address of where we allocated the memory
	la t0 vec_env
	sw a0 (t0) # we saved the address of the vector as a global variable
	###
	li t0 1 # t0 is abcisse of each env
	li t1 1 # t1 is ordonee of each env
	li t2 1 # t2 is dead/alive status for each env
	lw t3 no_rows_env # t3 is number of rows of envahisseurs
	lw t4 nr_env # t4 is env number
	div t5 t4 t3 #t5 is nr of envahisseurs on a row
	mv t4 t5 # we will use t4 as inner counter and t3 as outer counter
E_creer_loop:
	beqz t3 end_E_creer_loop
	li t0 1 # abscisse resets to 1 for each row
	mv t4 t5 # inner counter resets to no env/counter
inner_E_loop:
	beqz t4 exit_inner_E_loop
	li t2 1 #dead or alive is 1 at the start
	sw t0 (a0)
	sw t1 4(a0)
	sw t2 8(a0)
	addi a0 a0 12
	lw t2 esp_hor_env
	add t0 t0 t2
	lw t2 larg_env
	add t0 t0 t2
	addi t4 t4 -1
	j inner_E_loop
exit_inner_E_loop:
	addi t3 t3 -1
	addi t1 t1 1
	lw t2 esp_hor_row
	add t1 t1 t2
	j E_creer_loop
end_E_creer_loop:
#epilogue
	lw ra (sp)
	addi sp sp 4
	jr ra
### affichage ##################
E_afficher:
#prologue
	addi sp sp -16
	sw ra (sp)
	sw s0 4(sp)
	sw s1 8(sp)
	sw s2 12(sp)
#corps
	lw s0 nr_env  # s0 = iterator nr envahisseurs
	lw s1 I_buff # s1 = buffer address
	lw s2 vec_env # s2 = obstacle structs address
E_afficher_loop:
	beqz s0 end_e_afficher_loop
	### check if envahisseur is alive, if not skip him ##
	lw t0 8(s2)
	beqz t0 skip_env_aff
	###
	lw a0 (s2) # a0 = abscisse env
	lw a1 4(s2) # a1 = ordonee env
	lw a2 larg_env # a2 = largeur env
	lw a3 haut_env # a3 = hauteur env
	lw a4 col_env # a4 = couleur env
	jal I_rectangle
skip_env_aff:
	addi s0 s0 -1
	addi s2 s2 12
	j E_afficher_loop	
end_e_afficher_loop:
#epilogue
	lw ra (sp)
	lw s0 4(sp)
	lw s1 8(sp)
	lw s2 12(sp)
	addi sp sp 16
	jr ra
## joueur ##############################################################
J_creer:
#prologue
	addi sp, sp, -4
	sw ra, (sp)
#corps
	li a0, 12 # 12B (x, y, vies)
	li a7, 9
	ecall

	la t0, j_addr
	sw a0, (t0) # sauvegarder l'adresse dans j_addr
	
	lw t1, x_joueur
	lw t2, y_joueur
	lw t3, vies_joueur_init
	
	sw t1, (a0)
	sw t2, 4(a0)
	sw t3, 8(a0)
#epilogue
	lw ra, (sp)
	addi sp, sp, 4
	jr ra

J_afficher:
#prologue
	addi sp, sp, -8
	sw ra, (sp)
	sw t0, 4(sp)
#corps
	lw t0, j_addr
	lw a0, (t0) # a0 = j_addr->x
	lw a1, 4(t0) # a1 = j_addr->y
	
	lw a2, larg_joueur 
	lw a3, haut_joueur  
	lw a4, col_joueur
	
	jal I_rectangle # Appel requis
#epilogue
	lw t0, 4(sp)
	lw ra, (sp)
	addi sp, sp, 8
	jr ra
## missil ##############################################################################
M_creer:

# structure du missil: 16 bytes/missil (x, y, address, status)
#prologue
	addi sp, sp, -16
	sw ra, (sp)
	sw s0, 4(sp) # s0 = no_max_mis counter
	sw s1, 8(sp) # s1 = direction (0=up/joueur, 1=down)
	sw s2, 12(sp) # s2 = (0=mort, 1=vivant)
#corps
	lw s0, no_max_mis
	li s2, 16
	mul a0, s0, s2 #a0 = no_max_mis * grandeur du missil
	
	li a7, 9
	ecall
	
	la t0, vec_mis
	sw a0, (t0)
	mv s1, a0
	
M_creer_loop:
	beqz s0, end_M_creer_loop
	
	sw zero, (s1) # x=0
	sw zero, 4(s1) # y=0
	sw zero, 8(s1) # direction=0 (par default, up/joeur)
	sw zero, 12(s1) # status=0 (par default, mort)
	
	addi s1, s1, 16 # Prochain missil à créer
	addi s0, s0, -1 
	j M_creer_loop

end_M_creer_loop:
#epilogue
	lw ra, (sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	addi sp, sp, 16
	jr ra
	
## affichage #####################################
M_afficher:
#prologue
	addi sp, sp, -20
	sw ra, (sp)
	sw s0, 4(sp) # s0 = counter (no_max_mis)
	sw s1, 8(sp) # s1 = missil actuel
	sw s2, 12(sp) # s2 = status du missil (=0 mort, =1 vivant)
	sw s3, 16(sp) # s3 = grandeur du missil (16 B)
#corps
	lw s0, no_max_mis
	lw s1, vec_mis
	li s3, 16

M_afficher_loop:
	beqz s0, end_M_afficher_loop 
	
	lw s2, 12(s1) 
	beqz s2, M_afficher_skip 
	
	lw a0, (s1) # a0 = x
	lw a1, 4(s1) # a1 = y
	lw a2, ep_mis   
	lw a3, long_mis 
	lw a4, col_mis   
	
	jal I_rectangle
	
M_afficher_skip:
	add s1, s1, s3 # prochain missil
	addi s0, s0, -1  # on a 1 missil moins
	j M_afficher_loop

end_M_afficher_loop:
#epilogue
	lw ra, (sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s3, 16(sp)
	addi sp, sp, 20
	jr ra

## deplacement #################################################################################
## envahisseur ##################################################
E_deplacer:
#prologue
	addi sp sp -4
	sw ra (sp)
#corps
	lw t0 vec_env
# 1. check that they haven't reached the ending
	lw t1 (t0) #abs of farthest left env
	beqz t1 E_switch_right #check it hasn't reached left side of screen
	lw t2 nr_env
	lw t3 no_rows_env
	div t2 t2 t3 # t2 is now nr. of env on a row
	addi t2 t2 -1
	li t3 12
	mul t2 t2 t3 # t2 is now nr of bytes to the last env on the row
	add t0 t0 t2
	lw t2 (t0) #abs of farthest right env
	lw t1 larg_in_units
	addi t1 t1 -1
	lw t3 larg_env
	add t2 t2 t3
	beq t1 t2 E_switch_left
	j E_deplace_one
# 2. switch direction if they have reached the ending and lower them by 1
E_switch_right:
	li t1 0
	la t2 dir_env
	sw t1 (t2)
	j E_vertical
E_switch_left:
	li t1 1
	la t2 dir_env
	sw t1 (t2)
	j E_vertical
E_vertical:
	lw t0 vec_env
	lw t1 nr_env
E_vertical_loop:
	beqz t1 E_deplace_one
	li t2 1
	lw t3 4(t0)
	add t3 t3 t2
	sw t3 4(t0)
	addi t0 t0 12
	addi t1 t1 -1
	j E_vertical_loop
# 3. deplace
E_deplace_one:
	lw t1 dir_env
	beqz t1 E_deplace_right
	j E_deplace_left
E_deplace_right:
	lw t0 vec_env
	lw t1 nr_env
E_right_loop:
	beqz t1 E_end_deplace
	li t2 1
	lw t3 (t0)
	add t3 t3 t2
	sw t3 (t0)
	addi t0 t0 12
	addi t1 t1 -1
	j E_right_loop
E_deplace_left:
	lw t0 vec_env
	lw t1 nr_env
E_left_loop:
	beqz t1 E_end_deplace
	li t2 -1
	lw t3 (t0)
	add t3 t3 t2
	sw t3 (t0)
	addi t0 t0 12
	addi t1 t1 -1
	j E_left_loop
E_end_deplace:
#epilogue
	lw ra(sp)
	addi sp sp 4
	jr ra
####### fonction pour verifier si les envahisseurs atteint le sol ##########
E_check_att_sol:
	lw t0 nr_env
	addi t0 t0 -1
	li t1 12
	mul t0 t0 t1 #t0 is nr of bytes to last env
	lw t1 vec_env
	add t0 t1 t0 #t0 is the address of last env
	lw t2 4(t0) #t2 is the ordonee of last env
	lw t0 vec_obs
	lw t1 4(t0) # t1 is the ordonee of first obs
	lw t0 haut_env
	add t2 t2 t0
	bge t2 t1 E_att_sol
	li a0 0
	j E_end_check_sol
E_att_sol:
	li a0 1
E_end_check_sol:
	jr ra
### joueur ####################################
J_deplacer:
#prologue
	addi sp sp -4
	sw ra (sp)
#corps
	lw t3 RDR # address of key that was pressed
	lw t1 ascii_i
	lw t2 ascii_p
	lw t0 (t3)
	beq t0 t1 J_deplace_left
	beq t0 t2 J_deplace_right
	j J_end_deplace
J_deplace_left:
	lw t0 j_addr
	lw t1 (t0) # t1 is joueur abs
	beqz t1 J_end_deplace
	addi t1 t1 -1 #decrease abs
	sw t1 (t0) #update abs
	j J_end_deplace
J_deplace_right:
	lw t0 j_addr
	lw t1 (t0) #t1 is joueur abs
	lw t2 larg_in_units
	lw t3 larg_joueur
	add t3 t3 t1
	bge t3 t2 J_end_deplace #check joueur is not already farthest right
	addi t1 t1 1
	sw t1 (t0)
J_end_deplace:
#epilogue
	lw ra (sp)
	addi sp sp 4
	jr ra
## missil #################################################
	
M_deplacer:
#prologue
	addi sp, sp, -16
	sw ra, (sp)
	sw s0, 4(sp) # s0 = counter (no_max_mis)
	sw s1, 8(sp) # s1 = missil actuel (address)
	sw s2, 12(sp) # s2 = grandeur du missil (16 B)
#corps
	lw s0, no_max_mis # s0 = nombre max de missiles
	lw s1, vec_mis # s1 = adresse de vec_mis (dbut du tableau)
	li s2, 16 # s2 = taille d'une structure missile (16 bytes)
	
	lw t0, vit_mis # t0 = vitesse du missile (combien d'units on se dplace)
	lw t4, haut_in_units # t4 = limite basse de l'cran -----
	lw t1 long_mis
	sub t4 t4 t1
	li t1, 0 # t1 = ordonne de la base de l'image (y=0)

M_deplacer_loop:
	beqz s0, end_M_deplacer_loop # Fin si tous les missiles ont t vus
	
	lw t2, 12(s1) 
	beqz t2, M_deplacer_skip # Si status = 0 (mort), on saute au suivant
	
	lw t5, 8(s1) # t5 = direction
	lw t3, 4(s1) # t3 = y 
	
	beqz t5, M_deplacer_UP # par default, deplacer up
	add t3, t3, t0 # si t=1: y=y+vitesse
	
	bge t4, t3, M_deplacer_save # si y dans limite basse: sauvegarder
	j M_deplacer_deactivate
	
	# bge t3, t1, M_deplacer_move # Si y >= 0, il est encore visible, on le dplace
	
	# sw zero, 12(s1) # status = 0 (mort)
	# j M_deplacer_skip

M_deplacer_UP:
	sub t3, t3, t0 # y=y-vitesse
	bge t3,t1, M_deplacer_save # si y dans limite: sauvegarder
	j M_deplacer_deactivate # si sorti de la limite

M_deplacer_save:
	sw t3, 4(s1)
	j M_deplacer_skip

M_deplacer_deactivate:
	sw zero, 12(s1) # status=0 (mort)

# M_deplacer_move: 
#	sub t3, t3, t0 # y = y - vitesse
#	sw t3, 4(s1) 
	
M_deplacer_skip:
	add s1, s1, s2 # Passer au prochain missile
	addi s0, s0, -1 # Dcrmenter le compteur
	j M_deplacer_loop

end_M_deplacer_loop:
#epilogue
	lw ra, (sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	addi sp, sp, 16
	jr ra
	
############# INTERSECT FUNCTION ###############################
M_intersecteRectangle:
# a0 = addresse missile
# a1 = addresse rectangle
# a2 = largeur rectangle
# a3 = hauteur rectangle
#prologue
	addi sp sp -4
	sw ra (sp)
#corps
#1. check x axis
check_x:
	lw t0 (a0) # t0 is abscisse of missile
	lw t1 (a1) # t1 is abscisse of rectangle
	mv t2 t1
	add t2 t3 a2 # t2 is right limit of rectangle
	blt t0 t1 pas_de_intersection
	bgt t0 t2 pas_de_intersection
check_y:
	lw t0 4(a0) # t0 = ordonee du missil
	lw t1 long_mis # longueur missil
	add t1 t1 t0 # t1 = lower bound of missile
	lw t2 4(a1) # t2 = ordonee du rectangle
	add t3 t2 a3 # t3 = lower limit of rectangle
	bgt t0 t3 pas_de_intersection
	blt t1 t2 pas_de_intersection 
	li a0 1
	j end_missile_intersecte_rectangle
pas_de_intersection:
	li a0 0
	j end_missile_intersecte_rectangle
end_missile_intersecte_rectangle:
#epilogue
	lw ra (sp)
	addi sp sp 4
	jr ra
######### AUXILIARES #######################
## missile launch function ##
M_lancer:
# a0 = 0 if the missile was launched from the joueur, 1 if it was launched from the envahisseurs
#prologue
#corps
	lw t0 vec_mis
#search for free spot for my missile
search_free_spot_loop:
	lw t1 12(t0)
	beqz t1 found_free_spot
	addi t0 t0 16
	j search_free_spot_loop
found_free_spot:
	bgt a0 zero enemy_launch
	lw t1 RDR
	lw t3 (t1)
	lw t2 ascii_o	
	beq t2 t3 launch_from_me
	j end_lancer
launch_from_me:
# launch a missile with UP direction from the player's current coords
# t0 = missile address
	li a7 1
	ecall
	lw t1 j_addr # joueur address
	lw t2 (t1) # joueur abscisse
	lw t3 4(t1) # joueur ordonee
	sw t2 (t0)
	sw t3 4(t0)
	sw zero 8(t0)
	li t1 1
	sw t1 12(t0)
	j end_lancer
enemy_launch:
	lw t1 vec_env # env address
	lw t2 (t1) # env abscisse
	lw t3 4(t1) # env ordonee
	sw t2 (t0)
	sw t3 4(t0)
	li t1 1
	sw t1 8(t0)
	li t1 1
	sw t1 12(t0)
end_lancer:
	la t0 no_cur_mis
	lw t1 (t0)
	addi t1 t1 1
	sw t1 (t0)
#epilogue
	jr ra
###############
########### CHECK SI JOEUR HIT ##########################

Check_Joueur_Hit:
# Checks all active missiles against the player's position
# Returns: a0 = remaining lives of the player
# a0 is an output register here, its input value is not used.

#prologue
	addi sp, sp, -20
	sw ra, (sp)
	sw s0, 4(sp) # s0 = counter (no_max_mis)
	sw s1, 8(sp) # s1 = current missile address
	sw s2, 12(sp) # s2 = missile struct size (16 B)
	sw s3, 16(sp) # s3 = player address
#corps
	lw s0, no_max_mis 
	lw s1, vec_mis  # s1 = start address of missile vector
	li s2, 16   # s2 = size of missile structure
	lw s3, j_addr   # s3 = player address
	
	lw a2, larg_joueur # a2 = player width (for intersect function)
	lw a3, haut_joueur # a3 = player height (for intersect function)
	
Check_Joueur_Hit_Loop:
	beqz s0, Check_Joueur_Hit_End_Loop # Done checking all missiles
	
	lw t0, 12(s1) # t0 = missile status
	beqz t0, Check_Joueur_Hit_Skip # Skip if missile is not active (status=0)

	lw t1, 8(s1) # t1 = missile direction
	beqz t1, Check_Joueur_Hit_Skip # Skip if direction is UP (0), only check DOWN (1) missiles (envahisseur)
	
	mv a0, s1 # a0 = current missile address (1st arg for intersect)
	mv a1, s3 # a1 = player address (2nd arg for intersect)
	
	jal M_intersecteRectangle # Check for collision
	
	bnez a0, Check_Joueur_Hit_Hit # If a0 is 1, a hit occurred!
	
Check_Joueur_Hit_Skip:
	add s1, s1, s2 # Next missile
	addi s0, s0, -1 # Decrement counter
	j Check_Joueur_Hit_Loop

Check_Joueur_Hit_Hit:
	# 1. Deactivate the missile that hit
	sw zero, 12(s1)
	
	# 2. Decrement player's lives
	lw t2, 8(s3) # t2 = current lives (vies_joueur)
	addi t2, t2, -1 # Decrement by 1
	sw t2, 8(s3) # Save new life count
	
	mv a0, t2 # Set return value (remaining lives)
	j Check_Joueur_Hit_End_Function # Exit function immediately
	
Check_Joueur_Hit_End_Loop:
	# If no hit occurred, we need to return the current life count
	lw a0, 8(s3) # Load current life count
	
Check_Joueur_Hit_End_Function:
#epilogue
	lw ra, (sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s3, 16(sp)
	addi sp, sp, 20
	jr ra

#####################
main:
	
	jal I_creer
	jal O_creer
	jal E_creer
	jal J_creer
	jal M_creer
	## testing missil ##
	lw t0 vec_mis
	li t1 20
	sw t1 (t0)
	sw t1 4(t0)
	li t1 1
	sw t1 8(t0)
	li t1 1
	sw t1 12(t0)
	## end test ##
game_loop:
	li a0 50
	li a7 32
	ecall
	#check if key was pressed
	lw t0 RCR
	lw t1 (t0)
	andi t1 t1 1
	beqz t1 no_key_pressed
key_pressed:
	li a0 0
	jal M_lancer
	jal J_deplacer
no_key_pressed:
#deplace envahisseurs
	jal E_deplacer
#deplace missiles
	jal M_deplacer
# clear previous frame
	jal I_effacer
# affiche tout
	jal O_afficher
	jal E_afficher
	jal J_afficher
	jal M_afficher
	jal I_buff_to_visu
#check if envahisseurs touch sol
	jal E_check_att_sol
	bgt a0 zero end_game
# check if ennahisseur was hit by missile
	lw s0 vec_env # s0 = addr env 
	lw s1 nr_env# s1 = env count
	lw s2 vec_mis# s2 = addr mis
	lw s3 no_max_mis# s3 = mis count
env_hit_loop:
	beqz s1 exit_env_hit_loop
	lw s3 no_max_mis
mis_hit_loop:
	beqz s3 exit_mis_hit_loop
	mv a0 s2
	mv a1 s0
	lw t0 12(s2)
	#beqz t0 skip_mis_hit
	lw t0 8(s2)
	#bgt t0 zero skip_mis_hit
	lw t0 8(s0)
	#beqz t0 skip_mis_hit
	lw a2 larg_env
	lw a3 haut_env
	jal M_intersecteRectangle
	bgt a0 zero kill_env
	j skip_mis_hit
kill_env:
	sw zero 8(s0)
skip_mis_hit:
	addi s3 s3 -1
	addi s2 s2 16
	j mis_hit_loop
exit_mis_hit_loop:
	addi s1 s1 -1
	addi s0 s0 12
	j env_hit_loop
exit_env_hit_loop:
#check if player was hit
	jal Check_Joueur_Hit
	ble a0 zero end_game # If a0 <= 0, end of game

# spawn 1 missile from the envahisseurs
	lw t0 no_cur_mis
	li t1 2
	bge t0 t1 skip_launch_env
	li a1 1
	jal M_lancer
skip_launch_env:
#check if missile hit obstacle
#continue game
	j game_loop
end_game:
	li a7,10
	ecall	
