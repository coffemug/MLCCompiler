(* absyn/absyn-check.sml *)

signature ABSYN_CHECK =
  sig
    structure Absyn: ABSYN
    val program: Absyn.program -> unit
  end (* signature ABSYN_CHECK *)

functor AbsynCheckFn(Absyn : ABSYN) : ABSYN_CHECK =
struct

  structure Absyn = Absyn

  (*
   * Reporting errors.
   *
   * Source file context is not easily available everywhere, so
   * a detected error is instead thrown as an exception.
   * At the top level where we do have the source file context,
   * we catch this exception and generate appropriate messages
   * before re-throwing the exception.
   * Limitation: We can't continue after an error. Big deal.
   *)

  type msg = string * int * int (* same as what Absyn.Source.sayMsg wants *)
  exception AbsynCheckError of msg list

  fun withSource(source, f) =
    f()
    handle (exn as AbsynCheckError(msgs)) =>
      (List.app (Absyn.Source.sayMsg source) msgs;
        raise exn)

  fun error1 msg = raise AbsynCheckError[msg]
  fun error2(msg1, msg2) = raise AbsynCheckError[msg1, msg2]

  fun mkIdErrorMsg(msg, Absyn.IDENT(name, left, right)) =
    ("Error: "^msg^name, left, right)
  fun idError(msg, id) = error1(mkIdErrorMsg(msg, id))
  fun doError(msg, left, right) = error1("Error: "^msg, left, right)
  fun expError(msg, Absyn.EXP(_,left,right)) = doError(msg, left, right)
  fun stmtError(msg, Absyn.STMT(_,left,right)) = doError(msg, left, right)

  (*
   * YOUR CODE HERE
   *
   * Hints:
   * - You need to represent uC types.
   * - You need an environment/symbol-table for identifiers.
   * - You need recursive functions over expressions and statements.
   * - You need to check type constraints at various places.
   * - Abstract syntax 'declarators' aren't types. You'll need
   *   to translate them.
   * - You need to process top-level declarations.
   *)


   (* XXX: REPLACE WITH YOUR CODE *)
   (* environment *)
   structure Env = Absyn.IdentDict


   (* Representation of types for UC language *)
   datatype ty = Int
     | Char  
     | Void 
     | IntArr of int 
     | CharArr of int
     | IntFunc of ty list
     | CharFunc of ty list
     | VoidFunc of ty list 
     | Error 
     | Ok
        
   (* Checking the global variables *)

   fun checkGlobal t (Absyn.VARdecl(id)) env =
       (case Env.find(env, id) of 
           SOME Int => (idError("Identifier name is in use: ", id); env)
         | SOME Char => (idError("Identifier name is in use: ", id); env)
         | _   => case t of 
                     Absyn.INTty  => (Env.insert (env, id, Int))
                   | Absyn.CHARty => (Env.insert (env, id, Char))
                   | Absyn.VOIDty => (Env.insert (env, id, Void)))

     | checkGlobal t (Absyn.ARRdecl(id, SOME i)) env =
       (case Env.find(env, id) of 
           SOME _ => (idError("Identifier name is in use: ", id); env)
         | _      => case t of 
                      Absyn.INTty  => (Env.insert (env, id, IntArr(i)))
                    | Absyn.CHARty => (Env.insert (env, id, CharArr(i)))
                    | Absyn.VOIDty => (idError("Identifier name is in use: ", id); env))

     | checkGlobal t (Absyn.ARRdecl(id, NONE)) env =
           (case Env.find(env, id) of 
              SOME _ => (idError("Identifier name is in use: ",id); env)
            | _   => case t of 
                       Absyn.INTty  => (Env.insert (env, id, IntArr(0)))
                     | Absyn.CHARty => (Env.insert (env, id, CharArr(0)))
                     | Absyn.VOIDty => (print("Array type is incompatibel!\n"); env))

                                                   
   (*************************************) 
                                            
   (*fun checkExtern dec = let *)
   (* Checking functions *)
   fun checkFunction (name,forms,ret,env) = 
     (case Env.find(env,name) of 
        SOME (_) => (idError("Identifier name is in use: ",name);env) 
      | _   => case ret of 
                 Absyn.INTty  => (Env.insert (env,name,IntFunc(makeFormList(forms))))
               | Absyn.CHARty => (Env.insert (env,name,CharFunc(makeFormList(forms))))
               | Absyn.VOIDty => (Env.insert (env,name,VoidFunc(makeFormList(forms)))))

   and makeFormList [] = []
     | makeFormList (f::fs) = 
         case f of 
           Absyn.VARDEC(Absyn.INTty,v) => 
            (case v of 
               Absyn.VARdecl(_) => (Int::(makeFormList fs))
             | Absyn.ARRdecl(_,SOME i) => (IntArr(i)::(makeFormList fs))
             | Absyn.ARRdecl(_,NONE) => (IntArr(0)::(makeFormList fs)))
             | Absyn.VARDEC(Absyn.CHARty,v) => 
                (case v of 
                   Absyn.VARdecl(_) => (Char::(makeFormList fs))
                 | Absyn.ARRdecl(_,SOME i) => (CharArr(i)::(makeFormList fs))
                 | Absyn.ARRdecl(_,NONE) => (CharArr(0)::(makeFormList fs)))
                 | Absyn.VARDEC(Absyn.VOIDty,_) => makeFormList fs

   fun process_declarations ([],env) = env
     | process_declarations ((dec::decs),env) =
         case dec of 
           Absyn.VARDEC(Absyn.INTty,Absyn.VARdecl(id)) =>   
             (case Env.find(env,id) of 
                SOME _ => (idError("Identifier name is in use: ",id);
                           process_declarations(decs,env)) 
              | NONE   => (process_declarations(decs,Env.insert (env,id,Int))))
         | Absyn.VARDEC(Absyn.CHARty,Absyn.VARdecl(id)) =>   
            (case Env.find(env,id) of 
               SOME _ => (idError("Identifier name is in use: ",id);
                          process_declarations(decs,env)) 
             | NONE   => (process_declarations(decs,Env.insert (env,id,Char))))
         | Absyn.VARDEC(Absyn.VOIDty,Absyn.VARdecl(id)) =>   
            (case Env.find(env,id) of 
               SOME _ => (idError("Identifier name is in use: ",id);
                          process_declarations(decs,env)) 
             | NONE   => (process_declarations(decs,Env.insert (env,id,Void))))
         | Absyn.VARDEC(Absyn.INTty,Absyn.ARRdecl(id,SOME i)) =>
            (case Env.find(env,id) of 
               SOME _ => (idError("Identifier name is in use: ",id);
                          process_declarations(decs,env)) 
             | NONE   => (process_declarations(decs,Env.insert (env,id,IntArr(i)))))
         | Absyn.VARDEC(Absyn.CHARty,Absyn.ARRdecl(id,SOME i)) =>
            (case Env.find(env,id) of 
               SOME _ => (idError("Identifier name is in use: ",id);
                          process_declarations(decs,env)) 
             | NONE   => (process_declarations(decs,Env.insert (env,id,CharArr(i)))))
         | Absyn.VARDEC(Absyn.VOIDty,Absyn.ARRdecl(id,SOME i)) =>
            (case Env.find(env,id) of 
               _ => (print("Array must be of type int or char!\n");
                     process_declarations(decs,env))) 


         | Absyn.VARDEC(Absyn.INTty,Absyn.ARRdecl(id,NONE)) =>
            (case Env.find(env,id) of 
               SOME _ => (print("Array name is in use!\n");
                          process_declarations(decs,env)) 
             | NONE   => (process_declarations(decs,Env.insert (env,id,IntArr(0)))))
         | Absyn.VARDEC(Absyn.CHARty,Absyn.ARRdecl(id,NONE)) =>
            (case Env.find(env,id) of 
               SOME _ => (print("Array name is in use!\n");
                          process_declarations(decs,env)) 
             | NONE   => (process_declarations(decs,Env.insert (env,id,CharArr(0)))))
         | Absyn.VARDEC(Absyn.VOIDty,Absyn.ARRdecl(id,NONE)) =>
            (case Env.find(env,id) of 
               _ => (print("Array must be of type int or char!\n");
                     process_declarations(decs,env))) 
                                  
   (* type checker module *)

   fun checkExp (ex,env) = 
     case ex of 
       Absyn.EXP(Absyn.CONST(Absyn.INTcon (i)),_,_) => Int
     | Absyn.EXP(Absyn.VAR(id),left,right) => 
         (case Env.find'(env,id) of 
            SOME (_,t) => t 
          | NONE => (expError("Identifier not defined",
                     Absyn.EXP(Absyn.VAR(id),left,right));Error))

     | Absyn.EXP(Absyn.ARRAY(id,exp),left,right) => 
         (case Env.find'(env,id) of 
            SOME (_,t) => (case t of 
                             IntArr(_) => checkExp(exp,env)
                           | CharArr(_) => checkExp(exp,env)
                           | Int => (expError("Indexing integer: ",
                                     Absyn.EXP(Absyn.ARRAY(id,exp),left,right));Error)
                           | Char => (expError("Indexing character: ",
                                      Absyn.EXP(Absyn.ARRAY(id,exp),left,right));Error)
                           | _    => (expError("Undefined Array: ",
                                      Absyn.EXP(Absyn.ARRAY(id,exp),left,right));Error))
                                                                                                                                                      | NONE => (expError("Undefined Array: ",
                     Absyn.EXP(Absyn.ARRAY(id,exp),left,right));Error))
     | Absyn.EXP(Absyn.ASSIGN(exp1,exp2),left,right) => 
         let 
           val lht = checkExp(exp1,env)
           val rht = checkExp(exp2,env)
         in 
           if (isLvalue lht exp1) then    
           (if isCompatible(lht,rht) then rht else 
           (expError("right hand side and left hand side of assign are not convertibel",
            Absyn.EXP(Absyn.ASSIGN(exp1,exp2),left,right));Error))  
            else (expError("Left hand side of assignment is not a l-value",
            Absyn.EXP(Absyn.ASSIGN(exp1,exp2),left,right));Error)
         end
    | Absyn.EXP(Absyn.UNARY(uo,exp),left,right) => 
        (case checkExp(exp,env) of 
           Int => Int
         | Char => Char
         | _    => (expError("unary operator is not applicable",
                    Absyn.EXP(Absyn.UNARY(uo,exp),left,right));Error))
    | Absyn.EXP(Absyn.BINARY(bo,ex1,ex2),left,right) => 
        (case checkExp(ex1,env) of 
           Int => (case checkExp(ex2,env) of 
                     Int => Int
                   | Char => Char
                   | _   => (expError("RHS of binary operator is not applicable",
                             Absyn.EXP(Absyn.BINARY(bo,ex1,ex2),left,right));Error))
         | Char => (case checkExp(ex2,env) of 
                      Int => Int
                    | Char => Char
                    | _   => (expError("RHS of binary operator is not applicable",
                              Absyn.EXP(Absyn.BINARY(bo,ex1,ex2),left,right));Error))
         | _ => (expError("LHS of binary operator is not applicable",
                 Absyn.EXP(Absyn.BINARY(bo,ex1,ex2),left,right));Error))
    | Absyn.EXP(Absyn.FCALL(id,exlist),left,right) => 
        (case Env.find'(env,id) of 
           SOME (_,IntFunc(t)) => 
             if List.length(t) > (List.length(exlist)) then 
             (expError("Too few arguments to function",
              Absyn.EXP(Absyn.FCALL(id,exlist),left,right));Error) 
             else (if List.length(t) < (List.length(exlist)) then 
                   (expError("Too many arguments to function",
                    Absyn.EXP(Absyn.FCALL(id,exlist),left,right));Error) 
                   else (if matchArgs ((exlist,t),env) then Int 
                         else (expError("Unexpected argument type to the function",
                               Absyn.EXP(Absyn.FCALL(id,exlist),left,right));Error)))
         | SOME (_,CharFunc(t)) => 
             if List.length(t) > (List.length(exlist)) then 
             (expError("Too few arguments to function",
              Absyn.EXP(Absyn.FCALL(id,exlist),left,right));Error) 
             else (if List.length(t) < (List.length(exlist)) then 
                   (expError("Too many arguments to function: ",
                    Absyn.EXP(Absyn.FCALL(id,exlist),left,right));Error) 
                   else (if matchArgs ((exlist,t),env) then Char 
                         else (expError("Unexpected argument type to the function",
                               Absyn.EXP(Absyn.FCALL(id,exlist),left,right));Error)))
         (* fix this *)
         | SOME (_,VoidFunc(t)) => 
             if List.length(t) > (List.length(exlist)) then 
             (expError("Too few arguments to function",
              Absyn.EXP(Absyn.FCALL(id,exlist),left,right));Error) 
             else (if List.length(t) < (List.length(exlist)) then 
                  (expError("Too many arguments to function",
                   Absyn.EXP(Absyn.FCALL(id,exlist),left,right));Error) 
                  else (if matchArgs ((exlist,t),env) then Void 
                        else (expError("Unexpected argument type to the function",
                              Absyn.EXP(Absyn.FCALL(id,exlist),left,right));Error))) 
         | _ => (expError("is not a function",
                 Absyn.EXP(Absyn.FCALL(id,exlist),left,right));Error))
        
   and isLvalue lht exp = 
     case lht of  
       Int => if (checkVar exp) 
              then true else false  
     | Char  => if (checkVar exp) then true else false  
     | IntArr(_) => if (checkArr exp) then true else false
     | CharArr(_) => if (checkArr exp) then true else false
     | _ => false
   and checkArr exp = 
     case exp of 
       Absyn.EXP(Absyn.VAR(_),_,_) => false
     | Absyn.EXP(Absyn.ARRAY(_,_),_,_) => true
     | Absyn.EXP(Absyn.CONST(Absyn.INTcon (_)),_,_) => false
     | _ => false
   and checkVar exp = 
     case exp of 
       Absyn.EXP(Absyn.VAR(_),_,_) => true
     | Absyn.EXP(Absyn.ARRAY(_,_),_,_) => true
     | Absyn.EXP(Absyn.CONST(Absyn.INTcon (_)),_,_) => false
     | _ => false
   and isCompatible (lhTy,rhTy) = 
     case lhTy of Int => 
       (case rhTy of 
          Char => true 
        | Int => true
        | IntFunc(_)   => true
        | CharFunc(_)  => true
        | _            => false)
        | Char => (case rhTy of 
                     Char => true 
                   | Int => true
                   | IntFunc(_)   => true
                   | CharFunc(_)  => true
                   | _            => false)
        | IntArr(_) => (case rhTy of 
                          CharArr(_) => true 
                        | IntArr(_) => true
                        | _  => false)
        | CharArr(_) => (case rhTy of 
                           CharArr(_) => true 
                         | IntArr(_) => false
                         | _   => false)
        | _ => false
   and matchArgs (([],_),env) = true 
     | matchArgs((_,[]),env) = true
     | matchArgs (((r::rs),(f::fs)),env) = 
         let 
           val rt =  checkExp(r,env)
         in 
           if isCompatible(rt,f) then matchArgs ((rs,fs),env) else false
         end
   fun analyzeBody (name,ret,body,env) =
     case body of 
       Absyn.STMT(Absyn.EMPTY,_,_) => env
     | Absyn.STMT(Absyn.EFFECT(exp),_,_) => (checkExp (exp,env);env)
     | Absyn.STMT(Absyn.IF(exp,stmt,SOME st),_,_) => (checkExp(exp,env);analyzeBody(name,ret,stmt,env);
                                                      analyzeBody(name,ret,st,env);env)
     | Absyn.STMT(Absyn.IF(exp,stmt,NONE),_,_) => (checkExp(exp,env);analyzeBody(name,ret,stmt,env);env)
     | Absyn.STMT(Absyn.WHILE(exp,stmt),_,_) => (checkExp(exp,env);analyzeBody(name,ret,stmt,env);env)
     | Absyn.STMT(Absyn.SEQ(st1,st2),_,_) => (analyzeBody(name,ret,st1,env);analyzeBody(name,ret,st2,env);env)
     | Absyn.STMT(Absyn.RETURN(SOME exp),left,right) => 
         let val retTy = checkExp(exp,env) 
         in
           (case ret of 
              Absyn.VOIDty => (stmtError("function cannot return a value",
                               Absyn.STMT(Absyn.RETURN(SOME exp),left,right));env)
            | _            => env)
         end             
     | Absyn.STMT(Absyn.RETURN(NONE),left,right) => 
         (case ret of 
            Absyn.VOIDty => env 
          | Absyn.INTty  => (stmtError("function must return integer",
                             Absyn.STMT(Absyn.RETURN(NONE),left,right));env)
          | Absyn.CHARty   => (stmtError("function must return character",
                             Absyn.STMT(Absyn.RETURN(NONE),left,right));env))
   fun analyzeFunc (name,form,ret,loc,body,env) =
     let 
       val locForm = (form@loc)
       val envGlob = checkFunction (name,form,ret,env)
       val envFunc = Env.empty
       val envLoc = process_declarations (locForm,envFunc)
       val env2 = Env.plus (envGlob,envLoc)
     in 
       (analyzeBody(name,ret,body,env2);envGlob)
     end
   fun checkExtern (name,formals,retTy,env) = checkFunction (name,formals,retTy,env)
   (***********************************************************************)
   fun checkDeck (env,dec) =
     case dec of 
       Absyn.GLOBAL(Absyn.VARDEC(t,d))  => checkGlobal t d env
     | Absyn.FUNC{name,formals,retTy,locals,body} => analyzeFunc (name,formals,retTy,locals,body,env)
     | Absyn.EXTERN{name,formals,retTy} => checkExtern (name,formals,retTy,env)

   (* Auxiliary function to traverse the list of declarations *)
   fun checkDeclarations' [] _ = ()
     | checkDeclarations' (dec::decs) env = 
         let val env' = checkDeck (env,dec)
         in 
           checkDeclarations' decs env'
         end

   (* initial empty environment *)
   val en = Env.empty 

   fun checkDeclarations decs  = checkDeclarations' decs en

   (* Programs *)

   fun program(Absyn.PROGRAM{decs,source}) =
     let fun check() = checkDeclarations decs 
     in
       withSource(source, check)
     end

end (* functor AbsynCheckFn *)
