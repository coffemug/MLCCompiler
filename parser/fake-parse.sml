(* parser/fake-parse.sml *)
(* This is only to be used for Assignment 1. *)

signature UC_TOKENS =
  sig
    type svalue (*= unit*)
    datatype ('a,'b) token
      =   EOF    of 'b * 'b		(* <end-of-file> *)
      	| NOTEQ  of 'b * 'b		(* != *)
		| ANDAND of 'b * 'b		(* && *)
		| CHAR   of 'b * 'b		(* char *)
		| COMMA  of 'b * 'b		(* , *)
		| DIV    of 'b * 'b		(* / *)
		| ELSE   of 'b * 'b		(* else *)
		| EQ     of 'b * 'b		(* = *)
		| EQEQ   of 'b * 'b		(* == *)
		| GTEQ   of 'b * 'b		(* >= *)
		| GT     of 'b * 'b		(* > *)
		| IDENT  of  string * 'b * 'b		(* foo *)
		| IF     of 'b * 'b		(* if *)
		| INT    of 'b * 'b		(* int *)
		| LBRACE of 'b * 'b		(* { *)
		| LPAREN of 'b * 'b		(* ( *)
		| LBRACK of 'b * 'b		(* [ *)
		| LT     of 'b * 'b		(* < *)
		| RETURN of 'b * 'b 	(* return *)
		| RPAREN of 'b * 'b		(* ) *)
		| RBRACE of 'b * 'b		(* } *)
		| RBRACK of 'b * 'b		(* ] *)
		| SEMI   of 'b * 'b		(* ; *)
		| VOID   of 'b * 'b		(* void *)
		| WHILE  of 'b * 'b		(* while *)
		| LTEQ   of 'b * 'b		(* <= *)
		| MINUS  of 'b * 'b		(* - *)
		| MUL    of 'b * 'b		(* * *)
		| NOT    of 'b * 'b		(* ! *)
		| PLUS   of 'b * 'b		(* + *)
		| INTEGER_CONSTANT of (int option * string) * 'b * 'b 	(* 27, '\n' *)

    val printToken: (svalue,int) token -> unit

  end (* signature UC_TOKENS *)

structure FakeTokens : UC_TOKENS =
  struct
    type svalue = unit

    datatype ('a,'b) token
      =   EOF    of 'b * 'b		(* <end-of-file> *)
      	| NOTEQ  of 'b * 'b		(* != *)
		| ANDAND of 'b * 'b		(* && *)
		| CHAR   of 'b * 'b		(* char *)
		| COMMA  of 'b * 'b		(* , *)
		| DIV    of 'b * 'b		(* / *)
		| ELSE   of 'b * 'b		(* else *)
		| EQ     of 'b * 'b		(* = *)
		| EQEQ   of 'b * 'b		(* == *)
		| GTEQ   of 'b * 'b		(* >= *)
		| GT     of 'b * 'b		(* > *)
		| IDENT  of  string * 'b * 'b	(* foo *)
		| IF     of 'b * 'b		(* if *)
		| INT    of 'b * 'b		(* int *)
		| LBRACE of 'b * 'b		(* { *)
		| LPAREN of 'b * 'b		(* ( *)
		| LBRACK of 'b * 'b		(* [ *)
		| LT     of 'b * 'b		(* < *)
		| RETURN of 'b * 'b 	(* return *)
		| RPAREN of 'b * 'b		(* ) *)
		| RBRACE of 'b * 'b		(* } *)
		| RBRACK of 'b * 'b		(* ] *)
		| SEMI   of 'b * 'b		(* ; *)
		| VOID   of 'b * 'b		(* void *)
		| WHILE  of 'b * 'b		(* while *)
		| LTEQ   of 'b * 'b		(* <= *)
		| MINUS  of 'b * 'b		(* - *)
		| MUL    of 'b * 'b		(* * *)
		| NOT    of 'b * 'b		(* ! *)
		| PLUS   of 'b * 'b		(* + *)
		| INTEGER_CONSTANT of (int option * string) * 'b * 'b	(* 27, '\n' *)
 
    fun printToken (t) = 
		case t of 
			  EOF (_,_)   => (print("eof");())
			| NOTEQ (_,_)  => (print("not equal");())	
			| ANDAND (_,_) =>  (print("and and");())
			| COMMA  (_,_) =>  (print("comma");())
			| DIV (_,_)	 =>  (print("div");())
			| ELSE (_,_)  =>  (print("else");())
			| EQ	(_,_) =>  (print("equal");())
			| EQEQ  (_,_) =>  (print("equalequal");())
			| GTEQ  (_,_) =>  (print("greater than or equal");())
			| GT   (_,_)  =>  (print("greater than");())
			| IDENT(s,_,_) =>  (print(s);())
			| IF  (_,_)	 =>  (print("if");())
			| INT  (_,_)  =>  (print("int");())
			| CHAR  (_,_)  =>  (print("char");())
			| LBRACE (_,_) =>  (print("lbrace");())
			| LPAREN (_,_) =>  (print("lparen");())
			| LBRACK (_,_) =>  (print("lbrack");())
			| LT (_,_)	=>  (print("less than");())
			| RETURN (_,_) =>  (print("return");())
			| SEMI (_,_)  =>  (print("semi");())
			| VOID (_,_)  =>  (print("void");())
			| WHILE (_,_)  =>  (print("while");())
			| LTEQ (_,_)  =>  (print("less than or equal");())
			| MINUS (_,_) =>  (print("minus");())
			| MUL  (_,_)  =>  (print("multiply");())
			| NOT  (_,_)  =>  (print("not");())
			| PLUS (_,_)  =>  (print("plus");())
			| RBRACE (_,_) =>  (print("rbrace");())
			| RBRACK (_,_) =>  (print("rbrack");()) 
			| RPAREN (_,_) =>  (print("rparen");())
			| INTEGER_CONSTANT((i,c),_,_) =>  case i of 
												  SOME x => (print(Int.toString(x));())
												| NONE  => (print(c);())
										 


  end (* structure Tokens *)

functor FakeParseFn(structure Absyn : ABSYN
		    structure Lex : ARG_LEXER
		      where type UserDeclarations.pos = int
		    structure LexArg : LEXARG
		    structure FakeTokens : UC_TOKENS
		    sharing type Lex.UserDeclarations.token = FakeTokens.token
		    sharing type Lex.UserDeclarations.svalue = FakeTokens.svalue
		    sharing type LexArg.lexarg = Lex.UserDeclarations.arg
		    sharing Absyn.Source = LexArg.Source
		      ) : PARSE =
  struct

    structure Absyn = Absyn

    exception ParseError

    fun processTokens(lexer,lexarg) = 
		if LexArg.seenErr lexarg then raise ParseError else
		let val nexttok = (lexer())
		in 
			case nexttok of FakeTokens.EOF(_,_) => ()
			| _ =>
				(FakeTokens.printToken nexttok;
				 print "\n";
				 processTokens (lexer,lexarg))

		end

    fun program file =
      let val is = TextIO.openIn file
      in
	(let val (lexarg,inputf) = LexArg.new(file, is)
	     val lexer = Lex.makeLexer inputf lexarg
	     val _ = processTokens(lexer,lexarg)
	 in
	   if LexArg.seenErr lexarg then raise ParseError
	   else
	     let val _ = TextIO.closeIn is
	     in
	       Absyn.PROGRAM{decs=[], source=LexArg.Source.dummy}
	     end
	 end) 
		handle e => (TextIO.closeIn is; raise e)
      end

  end (* functor FakeParseFn *)
