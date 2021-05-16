;
; BANK $06 - GFX / BG Data
;

; =============== LoadGFX_TreasureRoom ===============
LoadVRAM_TreasureRoom:
	call LoadGFX_TreasureRoom
	call HomeCall_LoadGFX_WarioPowerHat
	ld   hl, BGRLE_TreasureRoom
	ld   bc, BGMap_Begin
	call DecompressBG
	call TrRoom_PlInit
	ret
; =============== LoadVRAM_Treasure_TreasureRoom ===============
LoadVRAM_Treasure_TreasureRoom:
	call LoadGFX_TreasureRoom
	call HomeCall_LoadGFX_WarioPowerHat
	ld   hl, BGRLE_TreasureRoom
	ld   bc, BGMap_Begin
	call DecompressBG
	call Treasure_TrRoom_PlInit
	ret
	
; =============== LoadVRAM_Ending_TreasureRoom ===============
LoadVRAM_Ending_TreasureRoom:
	call LoadGFX_TreasureRoom
	call HomeCall_LoadGFX_WarioPowerHat
	ld   hl, BGRLE_TreasureRoom
	ld   bc, BGMap_Begin
	call DecompressBG
	call Ending_TrRoom_PlInit
	ret
	
; =============== LoadGFX_TreasureRoom ===============
LoadGFX_TreasureRoom:
	ld   hl, GFXRLE_TreasureRoom
	call DecompressGFX
	ret
	
; =============== TrRoom_PlInit ===============
; Stub to NonGame_PlInit specifically used when loading the treasure room.
TrRoom_PlInit:
	call NonGame_PlInit
	ret
	
; =============== Ending_TrRoom_PlInit ===============
; Stub to NonGame_PlInit specifically used when loading the treasure room in the ending.
Ending_TrRoom_PlInit:
	call NonGame_PlInit
	ret
	
; =============== NonGame_PlInit ===============
; Sets the player sprite for nonstatic screens that spawn the player from the left:
; This includes:
; - Course Clear screen
; - Treasure room (level clear & ending)
; NOTE: The default player position this subroutine sets is 8px above the
;       bottom border of the screen (right above the status bar).
;		This is valid for the Treasure Room, but other modes like the Course Clear
;       screen are expected to adjust this position.
NonGame_PlInit:
	ld   a, $98				; Right above status bar
	ld   [sPlYRel], a
	ld   a, -$10			; Off-screen left
	ld   [sPlXRel], a
	ld   a, OBJ_WARIO_WALK0
	ld   [sPlLstId], a
	ld   a, OBJLST_XFLIP	; Face right
	ld   [sPlFlags], a
	xor  a					; Reset timer
	ld   [sPlTimer], a
	ret
	
; =============== Treasure_TrRoom_PlInit ===============
; Prepares the player and the treasure he's holding.
Treasure_TrRoom_PlInit:
	call NonGame_PlInitHold
	call ExActS_SpawnTreasureGet
	ret
	
; =============== NonGame_PlInitHold ===============
; Variant of NonGame_PlInit where the player is holding something while walking.
NonGame_PlInitHold:
	ld   a, $98				; Right above status bar
	ld   [sPlYRel], a
	ld   a, -$10			; Off-screen left
	ld   [sPlXRel], a
	ld   a, OBJ_WARIO_HOLDWALK0
	ld   [sPlLstId], a
	ld   a, OBJLST_XFLIP	; Face right
	ld   [sPlFlags], a
	xor  a					; Reset timer
	ld   [sPlTimer], a
	ret
	
; =============== ExActS_SpawnTreasureGet ===============
; Spawns the treasure in the Treasure Room which is initially held by the player.
ExActS_SpawnTreasureGet:
	ld   hl, sExActSet
	ld   a, EXACT_TREASUREGET	; Actor ID
	ldi  [hl], a
	xor  a
	ldi  [hl], a
	ldi  [hl], a
	ldi  [hl], a
	ldi  [hl], a
	; Determine the initial animation frame for the treasure.
	; Frames for the treasures are ordered by ID, so sTreasureId can be used.
	; Each treasure has 2 frames of animation one after the other, so we multiply by 2.
	; FrameId = $8C + sTreasureId*2
	ld   a, [sTreasureId]
	add  a
	add  OBJ_TRROOM_TREASURE_C0 - $02
	ldi  [hl], a
	
	ld   a, $10			; Flags
	ldi  [hl], a
	xor  a
	ldi  [hl], a
	ldi  [hl], a
	ldi  [hl], a
	ldi  [hl], a
	; Position treasure so it looks like Wario is holding it
	ld   a, $78			; Y position
	ldi  [hl], a
	ld   a, $F8			; X position
	ldi  [hl], a
	xor  a
	ldi  [hl], a
	ldi  [hl], a
	ld   [hl], a
	call ExActS_Spawn
	ret
	
; =============== LoadVRAM_SaveSelect ===============
LoadVRAM_SaveSelect:
	call LoadGFX_SaveSelect
	ld   hl, BGRLE_SaveSelect
	ld   bc, BGMap_Begin
	call DecompressBG
	ret
LoadGFX_SaveSelect:
	ld   hl, GFXRLE_SaveSelect
	call DecompressGFX
	ret
	
; =============== SaveSel_InitOBJ ===============
; Initializes the OBJ and ExAct used in the save select screen.
;
; Because OAM is completely empty when this is called, the subroutines
; which set OBJ do so by directly writing data to OAM, instead of going through OBJLst.
; They use hardcoded slot numbers which other code depends on.
SaveSel_InitOBJ:
	call SaveSel_InitLevelTextOBJ
	call SaveSel_WriteBrickOBJ
	call ExActS_SpawnSaveSel_WarioHat
	call SaveSel_InitWarioOBJLst
	ret
	
; =============== mSetLevelText ===============
; This macro generates code to write the two digits of the completed levels text
; to WorkOAM.
; IN
; - HL: Ptr to WorkOAM
; -  1: Ptr to level cleared count (BCD)
; -  2: Y coord of text
; -  3: X coord of text
mSetLevelText: MACRO
	; Upper digit
	ld   a, \2		; Y Coord
	ldi  [hl], a
	ld   a, \3		; X Coord
	ldi  [hl], a	
	; Get the amount of levels cleared from the save file, which is in BCD format
	; The currently loaded tileset has the number tiles at A0-A9.
	ld   a, [\1]	; Tile ID
	ld   b, a		
	swap a			; Get high nybble
	and  a, $0F		; 
	add  $A0		; Add to it the base tile offset and we've got the tile ID
	ldi  [hl], a	
	ld   a, $00		; Flags (use normal pal)
	ldi  [hl], a
	
	; Do similar for the lower digit
	ld   a, \2		; Y coord
	ldi  [hl], a
	ld   a, \3+$08	; X coord
	ldi  [hl], a
	ld   a, b		; Tile ID
	and  a, $0F		; Use low nybble
	add  $A0
	ldi  [hl], a	
	ld   a, $00		; Flags (use normal pal)
	ldi  [hl], a
ENDM	

; =============== SaveSel_InitLevelTextOBJ ===============
; Writes to OAM the text for the amount of levels completed.
SaveSel_InitLevelTextOBJ:
	; Expected OAM size: $00
	ld   hl, sWorkOAM
	
	; For all files, write the level text
	
	;                             VAR    Y    X
	mSetLevelText sSave1LevelsCleared, $90, $1C
	mSetLevelText sSave2LevelsCleared, $90, $3C
	mSetLevelText sSave3LevelsCleared, $90, $5C
	
	; We wrote 6 digits ($18 bytes)
	ld   a, ($00+$06)*$04
	ld   [sWorkOAMPos], a
	ret
	
; =============== SaveSel_WriteBrickOBJ ===============
; Writes to OAM the breakable bricks at the left of the screen.
SaveSel_WriteBrickOBJ:
	; Expected OAM size: $18
	ld   hl, sWorkOAM + ($06*$04)
	
	; Write the 4 bricks in a column, one 8px below the other
I = 0
REPT 4
	ld   a, $58+I	; Y
	ldi  [hl], a
	ld   a, $08		; X
	ldi  [hl], a
	ld   a, $B0		; Tile ID
	ldi  [hl], a
	ld   a, $00		; Flags
	ldi  [hl], a
I = I + $08			
ENDR
	
	;----------
	; Two extra bricks are here, but they aren't seen since they
	; overlap existing bricks.
	; They are used for the break effect.
	
	; 4
	ld   a, $58
	ldi  [hl], a
	ld   a, $08
	ldi  [hl], a
	ld   a, $B0
	ldi  [hl], a
	ld   a, $00
	ldi  [hl], a
	
	; 5
	ld   a, $60
	ldi  [hl], a
	ld   a, $08
	ldi  [hl], a
	ld   a, $B0
	ldi  [hl], a
	ld   a, $10
	ldi  [hl], a
	
	; We wrote 6 bricks ($18 bytes)
	ld   a, ($06+$06)*$04
	ld   [sWorkOAMPos], a
	ret
	
; =============== ExActS_SpawnSaveSel_WarioHat ===============
; Sets up the ExOBJ for the Wario's (new) hat in the save select screen.
ExActS_SpawnSaveSel_WarioHat:
	ld   hl, sExActSet
	ld   a, $08
	ldi  [hl], a
	xor  a
	ldi  [hl], a
	ldi  [hl], a
	ldi  [hl], a
	ldi  [hl], a
	ld   a, $63
	ldi  [hl], a
	xor  a
	ldi  [hl], a
	ldi  [hl], a
	ldi  [hl], a
	ldi  [hl], a
	ldi  [hl], a
	ld   a, $40		; Y
	ldi  [hl], a
	ld   a, $18		; X
	ldi  [hl], a
	xor  a
	ldi  [hl], a
	ldi  [hl], a
	ld   [hl], a
	call ExActS_Spawn
	ret
	
; =============== SaveSel_InitWarioOBJLst ===============
; Sets Wario's starting position / OBJLst settings.
SaveSel_InitWarioOBJLst:
	ld   a, $78
	ld   [sPlYRel], a
	ld   a, $F0
	ld   [sPlXRel], a
	ld   a, $68
	ld   [sPlLstId], a
	ld   a, $20
	ld   [sPlFlags], a
	xor  a
	ld   [sPlTimer], a
	ret
; =============== LoadVRAM_CourseClr ===============
LoadVRAM_CourseClr:
	call LoadGFX_CourseClr
	call LoadBG_CourseClr
	call NonGame_PlInit
	ret
; =============== LoadGFX_CourseClr ===============
LoadGFX_CourseClr:
	ld   hl, GFXRLE_CourseClr
	call DecompressGFX
	ret
; =============== LoadBG_CourseClr ===============
LoadBG_CourseClr:
	ld   hl, BGRLE_CourseClr
	ld   bc, BGMap_Begin
	call DecompressBG
	ret
	
GFXRLE_TreasureRoom: INCBIN "data/gfx/trroom.rlc"
;--
L0655B9: db $00;X
L0655BA: db $00;X
L0655BB: db $00;X
;--
BGRLE_TreasureRoom: INCBIN "data/bg/trroom.rls"
GFXRLE_SaveSelect: INCBIN "data/gfx/saveselect.rlc"
BGRLE_SaveSelect: INCBIN "data/bg/saveselect.rls"
GFX_Level_Ice: INCBIN "data/gfx/level/level_ice.bin"
GFX_Level_StoneCave: INCBIN "data/gfx/level/level_stonecave.bin"
GFXRLE_CourseClr: INCBIN "data/gfx/courseclear.rlc"
BGRLE_CourseClr: INCBIN "data/bg/courseclear.rls"
; =============== END OF BANK ===============
L0679C6: db $AE;X
L0679C7: db $EF;X
L0679C8: db $FF;X
L0679C9: db $BA;X
L0679CA: db $BA;X
L0679CB: db $AA;X
L0679CC: db $AB;X
L0679CD: db $AB;X
L0679CE: db $FA;X
L0679CF: db $EF;X
L0679D0: db $BE;X
L0679D1: db $BE;X
L0679D2: db $EF;X
L0679D3: db $AB;X
L0679D4: db $FF;X
L0679D5: db $AB;X
L0679D6: db $AB;X
L0679D7: db $EB;X
L0679D8: db $BB;X
L0679D9: db $A2;X
L0679DA: db $AF;X
L0679DB: db $AE;X
L0679DC: db $BF;X
L0679DD: db $BB;X
L0679DE: db $BA;X
L0679DF: db $EB;X
L0679E0: db $EE;X
L0679E1: db $BB;X
L0679E2: db $EB;X
L0679E3: db $BE;X
L0679E4: db $AB;X
L0679E5: db $AA;X
L0679E6: db $AA;X
L0679E7: db $AB;X
L0679E8: db $EB;X
L0679E9: db $BE;X
L0679EA: db $AA;X
L0679EB: db $FF;X
L0679EC: db $AF;X
L0679ED: db $EF;X
L0679EE: db $BB;X
L0679EF: db $EA;X
L0679F0: db $EE;X
L0679F1: db $AF;X
L0679F2: db $BB;X
L0679F3: db $EF;X
L0679F4: db $EE;X
L0679F5: db $BA;X
L0679F6: db $BB;X
L0679F7: db $EA;X
L0679F8: db $BE;X
L0679F9: db $BB;X
L0679FA: db $AE;X
L0679FB: db $AF;X
L0679FC: db $BE;X
L0679FD: db $BA;X
L0679FE: db $EB;X
L0679FF: db $AE;X
L067A00: db $A8;X
L067A01: db $0A;X
L067A02: db $88;X
L067A03: db $28;X
L067A04: db $22;X
L067A05: db $A2;X
L067A06: db $2A;X
L067A07: db $AA;X
L067A08: db $A8;X
L067A09: db $22;X
L067A0A: db $08;X
L067A0B: db $00;X
L067A0C: db $A8;X
L067A0D: db $2A;X
L067A0E: db $22;X
L067A0F: db $AA;X
L067A10: db $22;X
L067A11: db $A2;X
L067A12: db $AA;X
L067A13: db $02;X
L067A14: db $20;X
L067A15: db $AA;X
L067A16: db $A0;X
L067A17: db $82;X
L067A18: db $A0;X
L067A19: db $8A;X
L067A1A: db $2A;X
L067A1B: db $20;X
L067A1C: db $82;X
L067A1D: db $08;X
L067A1E: db $88;X
L067A1F: db $08;X
L067A20: db $AA;X
L067A21: db $28;X
L067A22: db $AA;X
L067A23: db $AA;X
L067A24: db $8A;X
L067A25: db $00;X
L067A26: db $20;X
L067A27: db $88;X
L067A28: db $A2;X
L067A29: db $02;X
L067A2A: db $AA;X
L067A2B: db $00;X
L067A2C: db $0A;X
L067A2D: db $22;X
L067A2E: db $02;X
L067A2F: db $8A;X
L067A30: db $82;X
L067A31: db $22;X
L067A32: db $A8;X
L067A33: db $02;X
L067A34: db $08;X
L067A35: db $22;X
L067A36: db $2A;X
L067A37: db $2A;X
L067A38: db $82;X
L067A39: db $8A;X
L067A3A: db $0A;X
L067A3B: db $0A;X
L067A3C: db $A2;X
L067A3D: db $22;X
L067A3E: db $AA;X
L067A3F: db $AA;X
L067A40: db $8A;X
L067A41: db $28;X
L067A42: db $0A;X
L067A43: db $A8;X
L067A44: db $28;X
L067A45: db $AA;X
L067A46: db $8A;X
L067A47: db $A2;X
L067A48: db $0A;X
L067A49: db $08;X
L067A4A: db $00;X
L067A4B: db $80;X
L067A4C: db $20;X
L067A4D: db $88;X
L067A4E: db $82;X
L067A4F: db $2A;X
L067A50: db $88;X
L067A51: db $82;X
L067A52: db $2A;X
L067A53: db $08;X
L067A54: db $88;X
L067A55: db $A2;X
L067A56: db $AA;X
L067A57: db $8A;X
L067A58: db $20;X
L067A59: db $0A;X
L067A5A: db $AA;X
L067A5B: db $02;X
L067A5C: db $AA;X
L067A5D: db $02;X
L067A5E: db $A0;X
L067A5F: db $0A;X
L067A60: db $A8;X
L067A61: db $00;X
L067A62: db $8A;X
L067A63: db $A0;X
L067A64: db $22;X
L067A65: db $0A;X
L067A66: db $22;X
L067A67: db $AA;X
L067A68: db $22;X
L067A69: db $08;X
L067A6A: db $22;X
L067A6B: db $AA;X
L067A6C: db $28;X
L067A6D: db $AA;X
L067A6E: db $2A;X
L067A6F: db $A2;X
L067A70: db $88;X
L067A71: db $20;X
L067A72: db $00;X
L067A73: db $82;X
L067A74: db $28;X
L067A75: db $80;X
L067A76: db $8A;X
L067A77: db $8A;X
L067A78: db $A0;X
L067A79: db $82;X
L067A7A: db $A2;X
L067A7B: db $88;X
L067A7C: db $A3;X
L067A7D: db $02;X
L067A7E: db $2A;X
L067A7F: db $A2;X
L067A80: db $AB;X
L067A81: db $AF;X
L067A82: db $EE;X
L067A83: db $FF;X
L067A84: db $BE;X
L067A85: db $EB;X
L067A86: db $AE;X
L067A87: db $EA;X
L067A88: db $EB;X
L067A89: db $AA;X
L067A8A: db $AF;X
L067A8B: db $BF;X
L067A8C: db $FA;X
L067A8D: db $FA;X
L067A8E: db $BF;X
L067A8F: db $EE;X
L067A90: db $BE;X
L067A91: db $FA;X
L067A92: db $BE;X
L067A93: db $9E;X
L067A94: db $BE;X
L067A95: db $BB;X
L067A96: db $EE;X
L067A97: db $BA;X
L067A98: db $BB;X
L067A99: db $EE;X
L067A9A: db $BB;X
L067A9B: db $AE;X
L067A9C: db $BA;X
L067A9D: db $AE;X
L067A9E: db $AB;X
L067A9F: db $BE;X
L067AA0: db $EE;X
L067AA1: db $AB;X
L067AA2: db $BA;X
L067AA3: db $AF;X
L067AA4: db $BE;X
L067AA5: db $BB;X
L067AA6: db $FA;X
L067AA7: db $BF;X
L067AA8: db $AA;X
L067AA9: db $EA;X
L067AAA: db $BF;X
L067AAB: db $FA;X
L067AAC: db $FE;X
L067AAD: db $EB;X
L067AAE: db $BE;X
L067AAF: db $FF;X
L067AB0: db $EE;X
L067AB1: db $FE;X
L067AB2: db $AB;X
L067AB3: db $BB;X
L067AB4: db $BB;X
L067AB5: db $AA;X
L067AB6: db $EB;X
L067AB7: db $AE;X
L067AB8: db $AA;X
L067AB9: db $FF;X
L067ABA: db $EF;X
L067ABB: db $EF;X
L067ABC: db $EE;X
L067ABD: db $EB;X
L067ABE: db $BE;X
L067ABF: db $AA;X
L067AC0: db $BA;X
L067AC1: db $FF;X
L067AC2: db $AF;X
L067AC3: db $BB;X
L067AC4: db $FA;X
L067AC5: db $EB;X
L067AC6: db $FA;X
L067AC7: db $BA;X
L067AC8: db $AE;X
L067AC9: db $EE;X
L067ACA: db $AA;X
L067ACB: db $BB;X
L067ACC: db $AF;X
L067ACD: db $AF;X
L067ACE: db $EA;X
L067ACF: db $EF;X
L067AD0: db $BE;X
L067AD1: db $AA;X
L067AD2: db $BA;X
L067AD3: db $AE;X
L067AD4: db $BB;X
L067AD5: db $AB;X
L067AD6: db $EE;X
L067AD7: db $EA;X
L067AD8: db $FA;X
L067AD9: db $BA;X
L067ADA: db $EA;X
L067ADB: db $AE;X
L067adc: db $AE;X
L067add: db $FA;X
L067ADE: db $FB;X
L067ADF: db $BE;X
L067AE0: db $EA;X
L067AE1: db $AE;X
L067AE2: db $AE;X
L067AE3: db $AF;X
L067AE4: db $AB;X
L067AE5: db $BB;X
L067AE6: db $BA;X
L067AE7: db $AB;X
L067AE8: db $AE;X
L067AE9: db $AE;X
L067AEA: db $FF;X
L067AEB: db $BB;X
L067AEC: db $AA;X
L067AED: db $EB;X
L067AEE: db $AE;X
L067AEF: db $AA;X
L067AF0: db $EE;X
L067AF1: db $AE;X
L067AF2: db $EA;X
L067AF3: db $BB;X
L067AF4: db $BA;X
L067AF5: db $AB;X
L067AF6: db $EB;X
L067AF7: db $AE;X
L067AF8: db $AE;X
L067AF9: db $BB;X
L067AFA: db $EF;X
L067AFB: db $AA;X
L067AFC: db $E2;X
L067AFD: db $EE;X
L067AFE: db $FB;X
L067AFF: db $FB;X
L067B00: db $A8;X
L067B01: db $22;X
L067B02: db $A0;X
L067B03: db $00;X
L067B04: db $82;X
L067B05: db $02;X
L067B06: db $20;X
L067B07: db $00;X
L067B08: db $00;X
L067B09: db $A2;X
L067B0A: db $80;X
L067B0B: db $08;X
L067B0C: db $20;X
L067B0D: db $8A;X
L067B0E: db $0A;X
L067B0F: db $A2;X
L067B10: db $A8;X
L067B11: db $28;X
L067B12: db $88;X
L067B13: db $88;X
L067B14: db $2A;X
L067B15: db $22;X
L067B16: db $28;X
L067B17: db $8A;X
L067B18: db $AA;X
L067B19: db $8A;X
L067B1A: db $02;X
L067B1B: db $00;X
L067B1C: db $A2;X
L067B1D: db $20;X
L067B1E: db $02;X
L067B1F: db $AA;X
L067B20: db $8A;X
L067B21: db $08;X
L067B22: db $21;X
L067B23: db $02;X
L067B24: db $A8;X
L067B25: db $8A;X
L067B26: db $A8;X
L067B27: db $00;X
L067B28: db $A8;X
L067B29: db $02;X
L067B2A: db $AA;X
L067B2B: db $A8;X
L067B2C: db $A0;X
L067B2D: db $08;X
L067B2E: db $A8;X
L067B2F: db $82;X
L067B30: db $A0;X
L067B31: db $08;X
L067B32: db $A8;X
L067B33: db $AA;X
L067B34: db $80;X
L067B35: db $A0;X
L067B36: db $08;X
L067B37: db $A0;X
L067B38: db $88;X
L067B39: db $2A;X
L067B3A: db $82;X
L067B3B: db $AA;X
L067B3C: db $AA;X
L067B3D: db $28;X
L067B3E: db $20;X
L067B3F: db $AA;X
L067B40: db $0A;X
L067B41: db $88;X
L067B42: db $8A;X
L067B43: db $0A;X
L067B44: db $AA;X
L067B45: db $00;X
L067B46: db $A0;X
L067B47: db $22;X
L067B48: db $A0;X
L067B49: db $88;X
L067B4A: db $A8;X
L067B4B: db $A8;X
L067B4C: db $02;X
L067B4D: db $82;X
L067B4E: db $22;X
L067B4F: db $A0;X
L067B50: db $0A;X
L067B51: db $2A;X
L067B52: db $2A;X
L067B53: db $22;X
L067B54: db $82;X
L067B55: db $08;X
L067B56: db $82;X
L067B57: db $0A;X
L067B58: db $2A;X
L067B59: db $A0;X
L067B5A: db $80;X
L067B5B: db $82;X
L067B5C: db $02;X
L067B5D: db $00;X
L067B5E: db $2A;X
L067B5F: db $02;X
L067B60: db $8A;X
L067B61: db $A8;X
L067B62: db $82;X
L067B63: db $80;X
L067B64: db $0A;X
L067B65: db $22;X
L067B66: db $A0;X
L067B67: db $A9;X
L067B68: db $82;X
L067B69: db $2A;X
L067B6A: db $AA;X
L067B6B: db $82;X
L067B6C: db $8A;X
L067B6D: db $A8;X
L067B6E: db $AA;X
L067B6F: db $AA;X
L067B70: db $02;X
L067B71: db $8A;X
L067B72: db $AA;X
L067B73: db $AA;X
L067B74: db $2A;X
L067B75: db $8A;X
L067B76: db $22;X
L067B77: db $A0;X
L067B78: db $82;X
L067B79: db $22;X
L067B7A: db $A0;X
L067B7B: db $A2;X
L067B7C: db $80;X
L067B7D: db $A2;X
L067B7E: db $2A;X
L067B7F: db $A8;X
L067B80: db $AE;X
L067B81: db $AB;X
L067B82: db $FF;X
L067B83: db $EB;X
L067B84: db $AB;X
L067B85: db $AF;X
L067B86: db $FF;X
L067B87: db $EE;X
L067B88: db $BA;X
L067B89: db $AA;X
L067B8A: db $AA;X
L067B8B: db $AB;X
L067B8C: db $BB;X
L067B8D: db $BA;X
L067B8E: db $BA;X
L067B8F: db $EE;X
L067B90: db $AA;X
L067B91: db $BE;X
L067B92: db $AA;X
L067B93: db $BB;X
L067B94: db $FE;X
L067B95: db $AF;X
L067B96: db $AA;X
L067B97: db $AB;X
L067B98: db $FF;X
L067B99: db $AA;X
L067B9A: db $EA;X
L067B9B: db $AA;X
L067B9C: db $BE;X
L067B9D: db $EB;X
L067B9E: db $FA;X
L067B9F: db $FB;X
L067BA0: db $FB;X
L067BA1: db $EA;X
L067BA2: db $FF;X
L067BA3: db $BA;X
L067BA4: db $FE;X
L067BA5: db $FE;X
L067BA6: db $EA;X
L067BA7: db $EB;X
L067BA8: db $BB;X
L067BA9: db $EB;X
L067BAA: db $FB;X
L067BAB: db $FA;X
L067BAC: db $BA;X
L067BAD: db $AA;X
L067BAE: db $FA;X
L067BAF: db $AE;X
L067BB0: db $EB;X
L067BB1: db $EB;X
L067BB2: db $BF;X
L067BB3: db $BB;X
L067BB4: db $BE;X
L067BB5: db $AE;X
L067BB6: db $EA;X
L067BB7: db $EA;X
L067BB8: db $BE;X
L067BB9: db $BF;X
L067BBA: db $EE;X
L067BBB: db $A3;X
L067BBC: db $EA;X
L067BBD: db $EE;X
L067BBE: db $BA;X
L067BBF: db $FE;X
L067BC0: db $BB;X
L067BC1: db $AB;X
L067BC2: db $FF;X
L067BC3: db $AA;X
L067BC4: db $AB;X
L067BC5: db $EB;X
L067BC6: db $AE;X
L067BC7: db $AA;X
L067BC8: db $AB;X
L067BC9: db $FB;X
L067BCA: db $AB;X
L067BCB: db $EE;X
L067BCC: db $AE;X
L067BCD: db $AE;X
L067BCE: db $FF;X
L067BCF: db $BE;X
L067BD0: db $AB;X
L067BD1: db $FF;X
L067BD2: db $AB;X
L067BD3: db $EA;X
L067BD4: db $EF;X
L067BD5: db $AA;X
L067BD6: db $FA;X
L067BD7: db $AB;X
L067BD8: db $AE;X
L067BD9: db $FA;X
L067BDA: db $FF;X
L067BDB: db $EA;X
L067BDC: db $AA;X
L067BDD: db $EE;X
L067BDE: db $BA;X
L067BDF: db $AB;X
L067BE0: db $FE;X
L067BE1: db $FA;X
L067BE2: db $BE;X
L067BE3: db $BE;X
L067BE4: db $BA;X
L067BE5: db $BA;X
L067BE6: db $AB;X
L067BE7: db $BE;X
L067BE8: db $AF;X
L067BE9: db $BA;X
L067BEA: db $EE;X
L067BEB: db $AB;X
L067BEC: db $EB;X
L067BED: db $EB;X
L067BEE: db $BA;X
L067BEF: db $BA;X
L067BF0: db $BA;X
L067BF1: db $EE;X
L067BF2: db $FF;X
L067BF3: db $BA;X
L067BF4: db $AE;X
L067BF5: db $AF;X
L067BF6: db $AB;X
L067BF7: db $AE;X
L067BF8: db $FF;X
L067BF9: db $EA;X
L067BFA: db $AB;X
L067BFB: db $AB;X
L067BFC: db $AE;X
L067BFD: db $AB;X
L067BFE: db $AA;X
L067BFF: db $EA;X
L067C00: db $2A;X
L067C01: db $22;X
L067C02: db $A0;X
L067C03: db $AA;X
L067C04: db $AA;X
L067C05: db $A2;X
L067C06: db $80;X
L067C07: db $88;X
L067C08: db $80;X
L067C09: db $AA;X
L067C0A: db $20;X
L067C0B: db $08;X
L067C0C: db $08;X
L067C0D: db $88;X
L067C0E: db $A8;X
L067C0F: db $02;X
L067C10: db $8A;X
L067C11: db $AA;X
L067C12: db $88;X
L067C13: db $A8;X
L067C14: db $80;X
L067C15: db $2A;X
L067C16: db $2A;X
L067C17: db $A8;X
L067C18: db $A0;X
L067C19: db $08;X
L067C1A: db $82;X
L067C1B: db $06;X
L067C1C: db $8A;X
L067C1D: db $8A;X
L067C1E: db $AA;X
L067C1F: db $80;X
L067C20: db $0A;X
L067C21: db $08;X
L067C22: db $0A;X
L067C23: db $A8;X
L067C24: db $A8;X
L067C25: db $02;X
L067C26: db $A8;X
L067C27: db $A0;X
L067C28: db $A0;X
L067C29: db $22;X
L067C2A: db $88;X
L067C2B: db $A0;X
L067C2C: db $2A;X
L067C2D: db $28;X
L067C2E: db $A2;X
L067C2F: db $A0;X
L067C30: db $28;X
L067C31: db $88;X
L067C32: db $08;X
L067C33: db $A2;X
L067C34: db $02;X
L067C35: db $02;X
L067C36: db $20;X
L067C37: db $28;X
L067C38: db $20;X
L067C39: db $AA;X
L067C3A: db $AA;X
L067C3B: db $28;X
L067C3C: db $A8;X
L067C3D: db $08;X
L067C3E: db $88;X
L067C3F: db $2E;X
L067C40: db $A8;X
L067C41: db $22;X
L067C42: db $22;X
L067C43: db $80;X
L067C44: db $88;X
L067C45: db $02;X
L067C46: db $A2;X
L067C47: db $22;X
L067C48: db $A2;X
L067C49: db $AA;X
L067C4A: db $08;X
L067C4B: db $80;X
L067C4C: db $82;X
L067C4D: db $2A;X
L067C4E: db $28;X
L067C4F: db $88;X
L067C50: db $88;X
L067C51: db $AA;X
L067C52: db $0A;X
L067C53: db $00;X
L067C54: db $A2;X
L067C55: db $82;X
L067C56: db $08;X
L067C57: db $A0;X
L067C58: db $82;X
L067C59: db $AA;X
L067C5A: db $28;X
L067C5B: db $0A;X
L067C5C: db $A8;X
L067C5D: db $88;X
L067C5E: db $82;X
L067C5F: db $88;X
L067C60: db $80;X
L067C61: db $A2;X
L067C62: db $0A;X
L067C63: db $80;X
L067C64: db $A8;X
L067C65: db $AA;X
L067C66: db $A8;X
L067C67: db $A0;X
L067C68: db $2A;X
L067C69: db $22;X
L067C6A: db $80;X
L067C6B: db $A8;X
L067C6C: db $22;X
L067C6D: db $A2;X
L067C6E: db $2A;X
L067C6F: db $A2;X
L067C70: db $88;X
L067C71: db $A8;X
L067C72: db $2A;X
L067C73: db $2A;X
L067C74: db $2A;X
L067C75: db $A2;X
L067C76: db $AA;X
L067C77: db $88;X
L067C78: db $08;X
L067C79: db $2A;X
L067C7A: db $02;X
L067C7B: db $2A;X
L067C7C: db $A8;X
L067C7D: db $0A;X
L067C7E: db $2A;X
L067C7F: db $08;X
L067C80: db $AA;X
L067C81: db $AA;X
L067C82: db $BA;X
L067C83: db $AA;X
L067C84: db $AE;X
L067C85: db $BA;X
L067C86: db $AE;X
L067C87: db $EE;X
L067C88: db $AE;X
L067C89: db $BE;X
L067C8A: db $AA;X
L067C8B: db $EE;X
L067C8C: db $EE;X
L067C8D: db $BA;X
L067C8E: db $AE;X
L067C8F: db $BA;X
L067C90: db $AE;X
L067C91: db $AB;X
L067C92: db $AA;X
L067C93: db $AA;X
L067C94: db $AA;X
L067C95: db $AA;X
L067C96: db $BE;X
L067C97: db $EA;X
L067C98: db $AA;X
L067C99: db $AA;X
L067C9A: db $EA;X
L067C9B: db $AE;X
L067C9C: db $EE;X
L067C9D: db $EA;X
L067C9E: db $AA;X
L067C9F: db $AA;X
L067CA0: db $EE;X
L067CA1: db $EA;X
L067CA2: db $AA;X
L067CA3: db $AB;X
L067CA4: db $AE;X
L067CA5: db $BA;X
L067CA6: db $AE;X
L067CA7: db $EA;X
L067CA8: db $BA;X
L067CA9: db $EE;X
L067CAA: db $AA;X
L067CAB: db $AA;X
L067CAC: db $AE;X
L067CAD: db $AA;X
L067CAE: db $EE;X
L067CAF: db $AE;X
L067CB0: db $AA;X
L067CB1: db $AE;X
L067CB2: db $BE;X
L067CB3: db $AA;X
L067CB4: db $EA;X
L067CB5: db $FA;X
L067CB6: db $EE;X
L067CB7: db $AA;X
L067CB8: db $EB;X
L067CB9: db $AE;X
L067CBA: db $AA;X
L067CBB: db $AA;X
L067CBC: db $EB;X
L067CBD: db $EA;X
L067CBE: db $AA;X
L067CBF: db $EA;X
L067CC0: db $EE;X
L067CC1: db $FE;X
L067CC2: db $AA;X
L067CC3: db $AE;X
L067CC4: db $AA;X
L067CC5: db $EE;X
L067CC6: db $EE;X
L067CC7: db $EE;X
L067CC8: db $AA;X
L067CC9: db $EA;X
L067CCA: db $AA;X
L067CCB: db $EA;X
L067CCC: db $AA;X
L067CCD: db $EA;X
L067CCE: db $EE;X
L067CCF: db $EA;X
L067CD0: db $BA;X
L067CD1: db $EE;X
L067CD2: db $AA;X
L067CD3: db $FE;X
L067CD4: db $EE;X
L067CD5: db $AA;X
L067CD6: db $AF;X
L067CD7: db $FA;X
L067CD8: db $EE;X
L067CD9: db $EE;X
L067CDA: db $AA;X
L067CDB: db $AA;X
L067CDC: db $EE;X
L067CDD: db $AA;X
L067CDE: db $EA;X
L067CDF: db $AA;X
L067CE0: db $AA;X
L067CE1: db $AE;X
L067CE2: db $EA;X
L067CE3: db $FF;X
L067CE4: db $BA;X
L067CE5: db $AA;X
L067CE6: db $AE;X
L067CE7: db $AA;X
L067CE8: db $AE;X
L067CE9: db $EE;X
L067CEA: db $AA;X
L067CEB: db $AA;X
L067CEC: db $EA;X
L067CED: db $EA;X
L067CEE: db $EA;X
L067CEF: db $EE;X
L067CF0: db $AA;X
L067CF1: db $AF;X
L067CF2: db $AA;X
L067CF3: db $EA;X
L067CF4: db $EE;X
L067CF5: db $EA;X
L067CF6: db $BA;X
L067CF7: db $AE;X
L067CF8: db $EE;X
L067CF9: db $EA;X
L067CFA: db $FE;X
L067CFB: db $AA;X
L067CFC: db $EA;X
L067CFD: db $EA;X
L067CFE: db $EE;X
L067CFF: db $AE;X
L067D00: db $A8;X
L067D01: db $A2;X
L067D02: db $2A;X
L067D03: db $8A;X
L067D04: db $00;X
L067D05: db $AA;X
L067D06: db $22;X
L067D07: db $8A;X
L067D08: db $80;X
L067D09: db $A8;X
L067D0A: db $02;X
L067D0B: db $20;X
L067D0C: db $80;X
L067D0D: db $A2;X
L067D0E: db $28;X
L067D0F: db $02;X
L067D10: db $00;X
L067D11: db $2A;X
L067D12: db $8A;X
L067D13: db $2A;X
L067D14: db $AA;X
L067D15: db $8A;X
L067D16: db $A2;X
L067D17: db $00;X
L067D18: db $A0;X
L067D19: db $2A;X
L067D1A: db $A8;X
L067D1B: db $22;X
L067D1C: db $AA;X
L067D1D: db $A2;X
L067D1E: db $22;X
L067D1F: db $0A;X
L067D20: db $A8;X
L067D21: db $A2;X
L067D22: db $22;X
L067D23: db $82;X
L067D24: db $82;X
L067D25: db $08;X
L067D26: db $08;X
L067D27: db $00;X
L067D28: db $82;X
L067D29: db $A2;X
L067D2A: db $2A;X
L067D2B: db $0A;X
L067D2C: db $82;X
L067D2D: db $80;X
L067D2E: db $02;X
L067D2F: db $82;X
L067D30: db $08;X
L067D31: db $28;X
L067D32: db $A0;X
L067D33: db $AA;X
L067D34: db $A8;X
L067D35: db $8A;X
L067D36: db $8A;X
L067D37: db $8A;X
L067D38: db $0A;X
L067D39: db $8A;X
L067D3A: db $8A;X
L067D3B: db $A2;X
L067D3C: db $AA;X
L067D3D: db $00;X
L067D3E: db $A8;X
L067D3F: db $AA;X
L067D40: db $A0;X
L067D41: db $AA;X
L067D42: db $8A;X
L067D43: db $A0;X
L067D44: db $8A;X
L067D45: db $A0;X
L067D46: db $08;X
L067D47: db $A0;X
L067D48: db $2A;X
L067D49: db $02;X
L067D4A: db $AA;X
L067D4B: db $88;X
L067D4C: db $22;X
L067D4D: db $A0;X
L067D4E: db $A8;X
L067D4F: db $A0;X
L067D50: db $0A;X
L067D51: db $80;X
L067D52: db $8A;X
L067D53: db $22;X
L067D54: db $AA;X
L067D55: db $A2;X
L067D56: db $A8;X
L067D57: db $8A;X
L067D58: db $A8;X
L067D59: db $2A;X
L067D5A: db $AA;X
L067D5B: db $A8;X
L067D5C: db $02;X
L067D5D: db $A2;X
L067D5E: db $02;X
L067D5F: db $02;X
L067D60: db $AA;X
L067D61: db $8A;X
L067D62: db $8A;X
L067D63: db $82;X
L067D64: db $20;X
L067D65: db $2A;X
L067D66: db $AA;X
L067D67: db $82;X
L067D68: db $88;X
L067D69: db $AA;X
L067D6A: db $2A;X
L067D6B: db $8A;X
L067D6C: db $82;X
L067D6D: db $8A;X
L067D6E: db $28;X
L067D6F: db $2A;X
L067D70: db $A8;X
L067D71: db $00;X
L067D72: db $A2;X
L067D73: db $88;X
L067D74: db $28;X
L067D75: db $2A;X
L067D76: db $8A;X
L067D77: db $A0;X
L067D78: db $88;X
L067D79: db $00;X
L067D7A: db $28;X
L067D7B: db $88;X
L067D7C: db $08;X
L067D7D: db $AA;X
L067D7E: db $AA;X
L067D7F: db $AA;X
L067D80: db $EA;X
L067D81: db $EA;X
L067D82: db $AE;X
L067D83: db $EA;X
L067D84: db $BE;X
L067D85: db $AA;X
L067D86: db $E3;X
L067D87: db $AE;X
L067D88: db $EE;X
L067D89: db $AE;X
L067D8A: db $BF;X
L067D8B: db $AE;X
L067D8C: db $BB;X
L067D8D: db $BA;X
L067D8E: db $AA;X
L067D8F: db $EE;X
L067D90: db $AA;X
L067D91: db $EE;X
L067D92: db $FE;X
L067D93: db $AA;X
L067D94: db $EE;X
L067D95: db $EA;X
L067D96: db $EB;X
L067D97: db $BE;X
L067D98: db $AE;X
L067D99: db $BE;X
L067D9A: db $FF;X
L067D9B: db $EA;X
L067D9C: db $AE;X
L067D9D: db $BE;X
L067D9E: db $EE;X
L067D9F: db $EE;X
L067DA0: db $EA;X
L067DA1: db $EF;X
L067DA2: db $BF;X
L067DA3: db $AA;X
L067DA4: db $AF;X
L067DA5: db $EE;X
L067DA6: db $AA;X
L067DA7: db $AE;X
L067DA8: db $AF;X
L067DA9: db $EA;X
L067DAA: db $AB;X
L067DAB: db $EE;X
L067DAC: db $AA;X
L067DAD: db $EA;X
L067DAE: db $EA;X
L067DAF: db $EE;X
L067DB0: db $AA;X
L067DB1: db $EA;X
L067DB2: db $EE;X
L067DB3: db $AE;X
L067DB4: db $AE;X
L067DB5: db $AE;X
L067DB6: db $EE;X
L067DB7: db $AA;X
L067DB8: db $BA;X
L067DB9: db $AA;X
L067DBA: db $AA;X
L067DBB: db $EE;X
L067DBC: db $EE;X
L067DBD: db $EA;X
L067DBE: db $AA;X
L067DBF: db $AE;X
L067DC0: db $BE;X
L067DC1: db $EA;X
L067DC2: db $BE;X
L067DC3: db $EE;X
L067DC4: db $AA;X
L067DC5: db $EE;X
L067DC6: db $BE;X
L067DC7: db $EA;X
L067DC8: db $EA;X
L067DC9: db $AE;X
L067DCA: db $AA;X
L067DCB: db $EA;X
L067DCC: db $EA;X
L067DCD: db $EE;X
L067DCE: db $EE;X
L067DCF: db $AB;X
L067DD0: db $BE;X
L067DD1: db $EE;X
L067DD2: db $AA;X
L067DD3: db $EE;X
L067DD4: db $AE;X
L067DD5: db $EA;X
L067DD6: db $AE;X
L067DD7: db $AA;X
L067DD8: db $EF;X
L067DD9: db $EF;X
L067DDA: db $AE;X
L067DDB: db $AA;X
L067DDC: db $AE;X
L067DDD: db $EB;X
L067DDE: db $AE;X
L067DDF: db $AB;X
L067DE0: db $AE;X
L067DE1: db $AE;X
L067DE2: db $EB;X
L067DE3: db $BA;X
L067DE4: db $AA;X
L067DE5: db $AE;X
L067DE6: db $EA;X
L067DE7: db $FE;X
L067DE8: db $AA;X
L067DE9: db $AA;X
L067DEA: db $EA;X
L067DEB: db $AA;X
L067dec: db $AA;X
L067DED: db $EE;X
L067DEE: db $EE;X
L067DEF: db $BE;X
L067DF0: db $AE;X
L067DF1: db $AA;X
L067DF2: db $AE;X
L067DF3: db $EE;X
L067DF4: db $AA;X
L067DF5: db $AA;X
L067DF6: db $AF;X
L067DF7: db $EA;X
L067DF8: db $AF;X
L067DF9: db $EA;X
L067DFA: db $EE;X
L067DFB: db $EA;X
L067DFC: db $AE;X
L067DFD: db $AA;X
L067DFE: db $AA;X
L067DFF: db $AA;X
L067E00: db $8A;X
L067E01: db $2A;X
L067E02: db $28;X
L067E03: db $0A;X
L067E04: db $8A;X
L067E05: db $A8;X
L067E06: db $02;X
L067E07: db $82;X
L067E08: db $AA;X
L067E09: db $88;X
L067E0A: db $0A;X
L067E0B: db $08;X
L067E0C: db $8A;X
L067E0D: db $02;X
L067E0E: db $A2;X
L067E0F: db $AA;X
L067E10: db $AA;X
L067E11: db $22;X
L067E12: db $20;X
L067E13: db $A2;X
L067E14: db $20;X
L067E15: db $82;X
L067E16: db $8A;X
L067E17: db $8A;X
L067E18: db $AA;X
L067E19: db $A0;X
L067E1A: db $22;X
L067E1B: db $A2;X
L067E1C: db $A2;X
L067E1D: db $A2;X
L067E1E: db $A0;X
L067E1F: db $AA;X
L067E20: db $0A;X
L067E21: db $20;X
L067E22: db $0A;X
L067E23: db $80;X
L067E24: db $28;X
L067E25: db $82;X
L067E26: db $A2;X
L067E27: db $AA;X
L067E28: db $0A;X
L067E29: db $20;X
L067E2A: db $88;X
L067E2B: db $AA;X
L067E2C: db $A8;X
L067E2D: db $A8;X
L067E2E: db $A2;X
L067E2F: db $22;X
L067E30: db $80;X
L067E31: db $8A;X
L067E32: db $AA;X
L067E33: db $88;X
L067E34: db $28;X
L067E35: db $0A;X
L067E36: db $82;X
L067E37: db $A8;X
L067E38: db $8A;X
L067E39: db $2A;X
L067E3A: db $A8;X
L067E3B: db $A8;X
L067E3C: db $AA;X
L067E3D: db $AA;X
L067E3E: db $20;X
L067E3F: db $0A;X
L067E40: db $88;X
L067E41: db $80;X
L067E42: db $22;X
L067E43: db $2A;X
L067E44: db $88;X
L067E45: db $2A;X
L067E46: db $AA;X
L067E47: db $2A;X
L067E48: db $82;X
L067E49: db $20;X
L067E4A: db $AA;X
L067E4B: db $0A;X
L067E4C: db $28;X
L067E4D: db $0A;X
L067E4E: db $0A;X
L067E4F: db $AA;X
L067E50: db $A8;X
L067E51: db $0A;X
L067E52: db $22;X
L067E53: db $2A;X
L067E54: db $88;X
L067E55: db $88;X
L067E56: db $22;X
L067E57: db $02;X
L067E58: db $08;X
L067E59: db $8A;X
L067E5A: db $8A;X
L067E5B: db $0A;X
L067E5C: db $0A;X
L067E5D: db $0A;X
L067E5E: db $A2;X
L067E5F: db $8A;X
L067E60: db $2A;X
L067E61: db $22;X
L067E62: db $AC;X
L067E63: db $22;X
L067E64: db $88;X
L067E65: db $88;X
L067E66: db $02;X
L067E67: db $AA;X
L067E68: db $28;X
L067E69: db $AA;X
L067E6A: db $82;X
L067E6B: db $A2;X
L067E6C: db $A0;X
L067E6D: db $28;X
L067E6E: db $AA;X
L067E6F: db $28;X
L067E70: db $22;X
L067E71: db $88;X
L067E72: db $8A;X
L067E73: db $20;X
L067E74: db $A0;X
L067E75: db $28;X
L067E76: db $82;X
L067E77: db $0A;X
L067E78: db $02;X
L067E79: db $02;X
L067E7A: db $AA;X
L067E7B: db $22;X
L067E7C: db $A8;X
L067E7D: db $28;X
L067E7E: db $0A;X
L067E7F: db $20;X
L067E80: db $EA;X
L067E81: db $AA;X
L067E82: db $EA;X
L067E83: db $EE;X
L067E84: db $EE;X
L067E85: db $AA;X
L067E86: db $AA;X
L067E87: db $EA;X
L067E88: db $EE;X
L067E89: db $EA;X
L067E8A: db $EE;X
L067E8B: db $EE;X
L067E8C: db $FA;X
L067E8D: db $AB;X
L067E8E: db $AA;X
L067E8F: db $AB;X
L067E90: db $AA;X
L067E91: db $EA;X
L067E92: db $FB;X
L067E93: db $AA;X
L067E94: db $AA;X
L067E95: db $EA;X
L067E96: db $EA;X
L067E97: db $EA;X
L067E98: db $AA;X
L067E99: db $EB;X
L067E9A: db $AE;X
L067E9B: db $EA;X
L067E9C: db $AA;X
L067E9D: db $AE;X
L067E9E: db $EA;X
L067E9F: db $EA;X
L067EA0: db $EE;X
L067EA1: db $BA;X
L067EA2: db $EF;X
L067EA3: db $EF;X
L067EA4: db $AE;X
L067EA5: db $EA;X
L067EA6: db $EF;X
L067EA7: db $AA;X
L067EA8: db $EA;X
L067EA9: db $BE;X
L067EAA: db $EA;X
L067EAB: db $BE;X
L067EAC: db $EA;X
L067EAD: db $AA;X
L067EAE: db $EA;X
L067EAF: db $BA;X
L067EB0: db $FA;X
L067EB1: db $EA;X
L067EB2: db $AE;X
L067EB3: db $EE;X
L067EB4: db $EA;X
L067EB5: db $AF;X
L067EB6: db $AF;X
L067EB7: db $AA;X
L067EB8: db $AE;X
L067EB9: db $BA;X
L067EBA: db $AA;X
L067EBB: db $AB;X
L067EBC: db $BA;X
L067EBD: db $AE;X
L067EBE: db $EA;X
L067EBF: db $EA;X
L067EC0: db $EA;X
L067EC1: db $AA;X
L067EC2: db $AB;X
L067EC3: db $BA;X
L067EC4: db $EA;X
L067EC5: db $EA;X
L067EC6: db $AA;X
L067EC7: db $AA;X
L067EC8: db $AA;X
L067EC9: db $EA;X
L067ECA: db $BA;X
L067ECB: db $AA;X
L067ECC: db $AA;X
L067ECD: db $FA;X
L067ECE: db $AA;X
L067ECF: db $AA;X
L067ED0: db $EE;X
L067ED1: db $EB;X
L067ED2: db $AF;X
L067ED3: db $BA;X
L067ED4: db $EE;X
L067ED5: db $EE;X
L067ED6: db $AE;X
L067ED7: db $AA;X
L067ED8: db $AA;X
L067ED9: db $EA;X
L067EDA: db $EE;X
L067EDB: db $AB;X
L067EDC: db $EB;X
L067EDD: db $2A;X
L067EDE: db $EA;X
L067EDF: db $EA;X
L067EE0: db $AA;X
L067EE1: db $AE;X
L067EE2: db $AE;X
L067EE3: db $EE;X
L067EE4: db $AE;X
L067EE5: db $EA;X
L067EE6: db $EF;X
L067EE7: db $AA;X
L067EE8: db $EA;X
L067EE9: db $AA;X
L067EEA: db $AA;X
L067EEB: db $BA;X
L067EEC: db $BB;X
L067EED: db $EE;X
L067EEE: db $AA;X
L067EEF: db $AB;X
L067EF0: db $EA;X
L067EF1: db $FE;X
L067EF2: db $AA;X
L067EF3: db $EA;X
L067EF4: db $EA;X
L067EF5: db $EE;X
L067EF6: db $EA;X
L067EF7: db $AE;X
L067EF8: db $AE;X
L067EF9: db $EA;X
L067EFA: db $FF;X
L067EFB: db $EE;X
L067EFC: db $AB;X
L067EFD: db $EF;X
L067EFE: db $FF;X
L067EFF: db $AE;X
L067F00: db $02;X
L067F01: db $80;X
L067F02: db $0A;X
L067F03: db $A2;X
L067F04: db $0A;X
L067F05: db $80;X
L067F06: db $2A;X
L067F07: db $02;X
L067F08: db $2A;X
L067F09: db $2A;X
L067F0A: db $8A;X
L067F0B: db $8A;X
L067F0C: db $8A;X
L067F0D: db $22;X
L067F0E: db $02;X
L067F0F: db $C8;X
L067F10: db $A0;X
L067F11: db $22;X
L067F12: db $A8;X
L067F13: db $00;X
L067F14: db $8A;X
L067F15: db $22;X
L067F16: db $80;X
L067F17: db $28;X
L067F18: db $82;X
L067F19: db $A8;X
L067F1A: db $A2;X
L067F1B: db $8A;X
L067F1C: db $80;X
L067F1D: db $22;X
L067F1E: db $A0;X
L067F1F: db $A2;X
L067F20: db $AA;X
L067F21: db $A2;X
L067F22: db $AA;X
L067F23: db $00;X
L067F24: db $82;X
L067F25: db $2A;X
L067F26: db $0A;X
L067F27: db $80;X
L067F28: db $A8;X
L067F29: db $02;X
L067F2A: db $8A;X
L067F2B: db $28;X
L067F2C: db $28;X
L067F2D: db $28;X
L067F2E: db $A2;X
L067F2F: db $2A;X
L067F30: db $2A;X
L067F31: db $02;X
L067F32: db $AA;X
L067F33: db $02;X
L067F34: db $AA;X
L067F35: db $A8;X
L067F36: db $AA;X
L067F37: db $A2;X
L067F38: db $AA;X
L067F39: db $82;X
L067F3A: db $28;X
L067F3B: db $0A;X
L067F3C: db $88;X
L067F3D: db $AA;X
L067F3E: db $A0;X
L067F3F: db $20;X
L067F40: db $88;X
L067F41: db $8A;X
L067F42: db $08;X
L067F43: db $08;X
L067F44: db $88;X
L067F45: db $08;X
L067F46: db $20;X
L067F47: db $88;X
L067F48: db $2A;X
L067F49: db $AA;X
L067F4A: db $8A;X
L067F4B: db $2A;X
L067F4C: db $8A;X
L067F4D: db $A0;X
L067F4E: db $88;X
L067F4F: db $20;X
L067F50: db $A0;X
L067F51: db $80;X
L067F52: db $22;X
L067F53: db $A8;X
L067F54: db $0A;X
L067F55: db $AA;X
L067F56: db $AA;X
L067F57: db $A8;X
L067F58: db $AA;X
L067F59: db $82;X
L067F5A: db $2A;X
L067F5B: db $22;X
L067F5C: db $AA;X
L067F5D: db $A2;X
L067F5E: db $A8;X
L067F5F: db $8A;X
L067F60: db $88;X
L067F61: db $20;X
L067F62: db $28;X
L067F63: db $20;X
L067F64: db $2A;X
L067F65: db $2A;X
L067F66: db $A2;X
L067F67: db $08;X
L067F68: db $00;X
L067F69: db $A8;X
L067F6A: db $08;X
L067F6B: db $20;X
L067F6C: db $A2;X
L067F6D: db $A2;X
L067F6E: db $A8;X
L067F6F: db $28;X
L067F70: db $28;X
L067F71: db $2A;X
L067F72: db $20;X
L067F73: db $22;X
L067F74: db $08;X
L067F75: db $A0;X
L067F76: db $28;X
L067F77: db $A8;X
L067F78: db $AA;X
L067F79: db $8A;X
L067F7A: db $28;X
L067F7B: db $A8;X
L067F7C: db $A8;X
L067F7D: db $00;X
L067F7E: db $08;X
L067F7F: db $20;X
L067F80: db $AB;X
L067F81: db $EA;X
L067F82: db $EA;X
L067F83: db $AA;X
L067F84: db $BB;X
L067F85: db $BE;X
L067F86: db $FA;X
L067F87: db $EF;X
L067F88: db $AA;X
L067F89: db $FE;X
L067F8A: db $EB;X
L067F8B: db $EA;X
L067F8C: db $AE;X
L067F8D: db $AE;X
L067F8E: db $EF;X
L067F8F: db $AE;X
L067F90: db $AA;X
L067F91: db $EF;X
L067F92: db $EA;X
L067F93: db $AE;X
L067F94: db $AF;X
L067F95: db $AE;X
L067F96: db $EE;X
L067F97: db $EA;X
L067F98: db $AB;X
L067F99: db $AA;X
L067F9A: db $EE;X
L067F9B: db $AA;X
L067F9C: db $BE;X
L067F9D: db $AE;X
L067F9E: db $AE;X
L067F9F: db $EB;X
L067FA0: db $AE;X
L067FA1: db $EE;X
L067FA2: db $EE;X
L067FA3: db $AE;X
L067FA4: db $AB;X
L067FA5: db $AA;X
L067FA6: db $EA;X
L067FA7: db $BF;X
L067FA8: db $EE;X
L067FA9: db $AF;X
L067FAA: db $BE;X
L067FAB: db $AB;X
L067FAC: db $EF;X
L067FAD: db $AA;X
L067FAE: db $EA;X
L067FAF: db $AA;X
L067FB0: db $EE;X
L067FB1: db $AE;X
L067FB2: db $AA;X
L067FB3: db $BA;X
L067FB4: db $AA;X
L067FB5: db $AA;X
L067FB6: db $EA;X
L067FB7: db $AA;X
L067FB8: db $AA;X
L067FB9: db $AE;X
L067FBA: db $AF;X
L067FBB: db $EB;X
L067FBC: db $FA;X
L067FBD: db $EB;X
L067FBE: db $AB;X
L067FBF: db $EA;X
L067FC0: db $AA;X
L067FC1: db $AB;X
L067FC2: db $AE;X
L067FC3: db $AE;X
L067FC4: db $AE;X
L067FC5: db $AE;X
L067FC6: db $EA;X
L067FC7: db $EE;X
L067FC8: db $EB;X
L067FC9: db $AA;X
L067FCA: db $AA;X
L067FCB: db $EE;X
L067FCC: db $EB;X
L067FCD: db $FA;X
L067FCE: db $BA;X
L067FCF: db $FE;X
L067FD0: db $AA;X
L067FD1: db $EA;X
L067FD2: db $AB;X
L067FD3: db $AE;X
L067FD4: db $AB;X
L067FD5: db $EF;X
L067FD6: db $EE;X
L067FD7: db $EF;X
L067FD8: db $AE;X
L067FD9: db $AA;X
L067FDA: db $EB;X
L067FDB: db $EA;X
L067FDC: db $AB;X
L067FDD: db $AA;X
L067FDE: db $EA;X
L067FDF: db $AE;X
L067FE0: db $EE;X
L067FE1: db $AA;X
L067FE2: db $AE;X
L067FE3: db $AE;X
L067FE4: db $EE;X
L067FE5: db $EA;X
L067FE6: db $EE;X
L067FE7: db $AB;X
L067FE8: db $AE;X
L067FE9: db $AA;X
L067FEA: db $BA;X
L067FEB: db $AA;X
L067FEC: db $AE;X
L067FED: db $EB;X
L067FEE: db $EE;X
L067FEF: db $FA;X
L067FF0: db $EE;X
L067FF1: db $EA;X
L067FF2: db $AF;X
L067FF3: db $EA;X
L067FF4: db $AA;X
L067FF5: db $AA;X
L067FF6: db $AE;X
L067FF7: db $AA;X
L067FF8: db $EF;X
L067FF9: db $BB;X
L067FFA: db $FA;X
L067FFB: db $EE;X
L067FFC: db $AB;X
L067FFD: db $AE;X
L067FFE: db $EA;X
L067FFF: db $AE;X
