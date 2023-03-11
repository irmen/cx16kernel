
; the Shell that is running for the user.

	.section UserShell
	
shell_entrypoint:
	jsr  print_newline
	jsr  print_newline
	lda  #<_message1
	ldy  #>_message1
	jsr  printz
	jsr  print_newline
	lda  #<_message2
	ldy  #>_message2
	jsr  printz
_done	wai
	bra  _done
	
_message1:
	.text "this line is from the shell routine",0
_message2
	.text "this too",0
	.endsection
	
