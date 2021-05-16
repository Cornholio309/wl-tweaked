	dp GFX_Level_Forest	; Main GFX
	dw GFX_LevelShared_00	; Block GFX
	dw GFX_StatusBar_01	; Status Bar GFX
	dw GFX_LevelAnim_0C	; Animated tiles GFX
	db $0A,$00	; Level Layout ID	
	dw LevelBlock_Forest	; 16x16 Blocks 
	db $01,$E0	; Player X
	db $00,$28	; Player Y
	db OBJ_WARIO_STAND ; OBJLst Frame
	db $20		; OBJLst Flags
	db $01,$60	; Scroll Y
	db $00,$00	; Scroll X
	db $02		; Screen Lock Flags
	db $00		; Screen Scroll Mode
	db $00		; Spawn in swim action
	db $0F		; Tile animation speed
	db $E1		; BG Palette
	dw ActGroup_C26_Room10	; Actor Setup code