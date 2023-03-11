
; the Shell that is running for the user.

	.section UserShell
	
shell_entrypoint:
	jsr  print_newline
	jsr  print_newline
	lda  #<_message1
	ldy  #>_message1
	jsr  printz
	ldx  #5
	ldy  #6
	jsr  plot
	lda  #<_message2
	ldy  #>_message2
	jsr  printz
	jsr  print_newline
	lda  #<_message3
	ldy  #>_message3
	jsr  printz
	jsr  print_newline
	jsr  print_newline
	lda  #'$'
	jsr  print_char
	lda  #'>'
	jsr  print_char
	lda  #' '
	jsr  print_char
	
_done	wai
	bra  _done
	
_message1:
	.text "This was printed from the Shell routine.",0
_message2
	.text "This one Too 12345 !@#$%",0
_message3
	.text "You can't type because no I/O has been implemented yet :-(",0

	.endsection
	
