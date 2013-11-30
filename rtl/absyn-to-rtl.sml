(* rtl/absyn-to-rtl.sml *)

signature ABSYN_TO_RTL =
  sig
    structure Absyn : ABSYN
    structure RTL   : RTL
    val program     : Absyn.program -> RTL.program
  end (* signature ABSYN_TO_RTL *)

functor AbsynToRTLFn(structure Absyn : ABSYN structure RTL : RTL) : ABSYN_TO_RTL =
  struct

    structure Absyn = Absyn
    structure RTL = RTL

    structure Env = Absyn.IdentDict

    fun procLabel id = "P" ^ Absyn.identName id
    fun varLabel id = "V" ^ Absyn.identName id
    fun arrLabel id = "Arr" ^ Absyn.identName id


    exception AbsynToRTL
    fun bug msg =
      (TextIO.output(TextIO.stdErr, "Compiler error: "^msg^"\n");
       raise AbsynToRTL)

    (* REPLACE WITH YOUR CODE *)

    fun first (a,_) = a
    fun second (_,b) = b

    fun firstTrip (a,_,_) = a
    fun secondTrip (_,b,_) = b
    fun thirdTrip (_,_,c) = c
    
    val en = Env.empty

    val sav = []    


    val TRUE = RTL.newTemp()
    val FALSE = RTL.newTemp()

    (* global or local *)
    val loc = 0 
    val glob = 1
    val arg  = 2

     
    fun program(Absyn.PROGRAM{decs = xs,...}) = RTL.PROGRAM(declar xs en sav) 

    and declar [] _ sav = rev sav
      | declar (y::ys) env sav = 
          case y of  
            Absyn.GLOBAL(Absyn.VARDEC(t,d)) => 
              let val envDec = global(t,d,env)
              in 
                declar ys (second envDec) ((first envDec)::sav)
              end
          | Absyn.FUNC{name = id,formals = forms,retTy = ty,locals = locs, body =fBody} => 
              let 
                val endOfFunLabel = RTL.newLabel()
                val envDec = func(id,forms,ty,locs,fBody,env,endOfFunLabel)
              in 
                declar ys (second envDec) ((first envDec)::sav)
              end 
          | Absyn.EXTERN {name,formals,retTy} => 
              let val env' = insertFName (Absyn.identName(name),name) retTy env
              in  declar ys env' sav
              end
        
    (**************************************************************************************************)
    and global (t,d,en) =  
          case d of 
            Absyn.VARdecl(x) =>
               (if (t = Absyn.INTty) then 
                 let 
                   val ty = RTL.LONG
                   val nam = varLabel x
                 in 
                   (RTL.DATA{label = nam, size = RTL.sizeof(RTL.LONG)},Env.insert(en,x,(glob,ty,(0,nam))))
                 end
                else 
                 let 
                   val ty = RTL.BYTE               
                   val nam= varLabel x
                 in 
                   (RTL.DATA{label = nam,size = RTL.sizeof(RTL.BYTE)},Env.insert(en,x,(glob,ty,(0,nam))))
                 end)

          | Absyn.ARRdecl(x,SOME i) =>
               (if (t = Absyn.INTty) then  
                 let 
                   val ty = RTL.LONG
                   val nam = arrLabel x
                 in 
                   (RTL.DATA{label = nam,size = RTL.sizeof(RTL.LONG)*i},Env.insert(en,x,(glob,ty,(0,nam))))
                 end
                else
                 let 
                   val ty = RTL.BYTE               
                   val nam= arrLabel x
                 in 
                   (RTL.DATA{label = nam,size = RTL.sizeof(RTL.BYTE)*i},Env.insert(en,x,(glob,ty,(0,nam))))
                 end)

          | Absyn.ARRdecl(x,NONE) =>
               (if (t = Absyn.INTty) then
                 let 
                   val ty = RTL.LONG
                   val nam = arrLabel x
                 in 
                   (RTL.DATA{label = nam,size = 0},Env.insert(en,x,(glob,ty,(0,nam))))
                 end
                else
                 let 
                   val ty = RTL.BYTE               
                   val nam= arrLabel x
                 in 
                   (RTL.DATA{label = nam,size = 0},Env.insert(en,x,(glob,ty,(0,nam))))
                 end)

    (*************************************************************)
    and func (id,forms,ty,locs,fBody,en,eofLab) =
        let val nam = if (Absyn.identName(id)= "main") then Absyn.identName(id) else procLabel id 
            val formals= transFormals(forms,en,RTL.FP-1)
            val env' = secondTrip formals
            val locals = transLocals (locs,env',RTL.FP-1)
            val env'' = secondTrip locals
            val env  = insertFName (nam,id) ty env''    
            val instTempList = checkBody (fBody,env,ty,eofLab)
            val eofDef = RTL.LABDEF(eofLab)
            val inst = (first instTempList)@[eofDef]
        in
            (RTL.PROC{label= nam, formals = thirdTrip formals ,locals = (thirdTrip locals @ second instTempList) , 
                    frameSize = firstTrip locals , insns = inst},env)
        end

    and transLocals ([],en,fp) = (fp,en,[])
      | transLocals (x::xs,en,fp) = 
        case x of 
          Absyn.VARDEC(t,Absyn.VARdecl(x)) =>
          let 
            val nam = RTL.newTemp()
          in 
            if (t = Absyn.INTty) then 
             let val (fp',en',xs') = transLocals(xs,Env.insert(en,x,(loc,RTL.LONG,(nam,"0"))),fp) 
             in 
               (fp',en',nam::xs')
             end
            else let val (fp',en',xs') = transLocals(xs,Env.insert(en,x,(loc,RTL.BYTE,(nam,"0"))),fp)
                 in 
                   (fp',en',nam::xs')
                 end
          end
        | Absyn.VARDEC(t,Absyn.ARRdecl(x,SOME i)) =>
          if (t = Absyn.INTty) then 
           let 
             val fp' = fp + (RTL.sizeof(RTL.LONG) * i)
             val (fp'',en',xs') = transLocals(xs,Env.insert(en,x,(loc,RTL.LONG,(fp,"1"))),fp') 
           in (fp'',en',xs')
           end
          else 
           let 
             val fp' = fp + (RTL.sizeof(RTL.BYTE) * i)
             val (fp'',en',xs') = transLocals(xs,Env.insert(en,x,(loc,RTL.BYTE,(fp,"1"))),fp') 
           in (fp'',en',xs')
           end
        | Absyn.VARDEC(t,Absyn.ARRdecl(x,NONE)) =>
          if (t = Absyn.INTty) then 
           let 
             val fp' = fp 
             val (fp'',en',xs')=transLocals(xs,Env.insert(en,x,(loc,RTL.LONG,(fp,"1"))),fp')
           in (fp'',en',xs')
           end
          else 
           let 
             val fp' = fp 
             val (fp'',en',xs')=  transLocals(xs,Env.insert(en,x,(loc,RTL.BYTE,(fp,"1"))),fp')
           in (fp'',en',xs')
           end
(*
    and transFormals ([],en,fp) = (fp,en,[])
      | transFormals (x::xs,en,fp) = 
        case x of 
          Absyn.VARDEC(t,Absyn.VARdecl(x)) =>
          let val nam = RTL.newTemp()
          in 
            if (t = Absyn.INTty) then 
             let val (fp',en',xs') = transFormals(xs,Env.insert(en,x,(loc,RTL.LONG,(nam,"0"))),fp) 
             in 
               (fp',en',nam::xs')
             end
            else let val (fp',en',xs') = transFormals(xs,Env.insert(en,x,(loc,RTL.BYTE,(nam,"0"))),fp)
                 in 
                   (fp',en',nam::xs')
                 end
          end
        | Absyn.VARDEC(t,Absyn.ARRdecl(x,SOME i)) =>
          let val nam = RTL.newTemp() 
          in
            if (t = Absyn.INTty) then 
            let 
               val (fp',en',xs') = transFormals(xs,Env.insert(en,x,(arg,RTL.LONG,(nam,"1"))),fp) 
            in (fp',en',nam::xs')
            end
          else 
           let 
               val (fp',en',xs') = transFormals(xs,Env.insert(en,x,(arg,RTL.BYTE,(nam,"1"))),fp) 
           in (fp',en',nam::xs')
           end
          end
        | Absyn.VARDEC(t,Absyn.ARRdecl(x,NONE)) =>
          let val nam = RTL.newTemp() 
          in          
           if (t = Absyn.INTty) then 
           let  
               val (fp',en',xs')=  transFormals(xs,Env.insert(en,x,(arg,RTL.LONG,(nam,"1"))),fp)
           in (fp',en',nam::xs')
           end
          else 
           let  
               val (fp',en',xs')=  transFormals(xs,Env.insert(en,x,(arg,RTL.BYTE,(nam,"1"))),fp)
           in (fp',en',nam::xs')
           end
         end
*)


    and transFormals ([],en,fp) = (fp,en,[])
      | transFormals (x::xs,en,fp) = 
        case x of 
          Absyn.VARDEC(t,Absyn.VARdecl(x)) =>
          (let val nam = RTL.newTemp()
          in 
            if (t = Absyn.INTty) then 
             let val (fp',en',xs') = transFormals(xs,Env.insert(en,x,(loc,RTL.LONG,(nam,"0"))),fp) 
             in 
               (fp',en',nam::xs')
             end
            else let val (fp',en',xs') = transFormals(xs,Env.insert(en,x,(loc,RTL.BYTE,(nam,"0"))),fp)
                 in 
                   (fp',en',nam::xs')
                 end
          end)
         

        | Absyn.VARDEC(t,Absyn.ARRdecl(x,SOME i)) =>
          if checkFormal x t en then  
          (let val nam = RTL.newTemp() 
               val (fp',en',xs') = transFormals(xs,en,fp) 
           in (fp',en',nam::xs')
           end)
          else 
         (let val nam = RTL.newTemp() 
          in
            if (t = Absyn.INTty) then 
            let 
               val (fp',en',xs') = transFormals(xs,Env.insert(en,x,(arg,RTL.LONG,(nam,"1"))),fp) 
            in (fp',en',nam::xs')
            end
          else 
           let 
               val (fp',en',xs') = transFormals(xs,Env.insert(en,x,(arg,RTL.BYTE,(nam,"1"))),fp) 
           in (fp',en',nam::xs')
           end
          end)

        | Absyn.VARDEC(t,Absyn.ARRdecl(x,NONE)) =>
          if checkFormal x t en then   
          (let val nam = RTL.newTemp() 
               val (fp',en',xs')=  transFormals(xs,en,fp)
           in (fp',en',nam::xs')
           end)
        
         else 
          (let val nam = RTL.newTemp() 
           in          
            if (t = Absyn.INTty) then 
            let  
               val (fp',en',xs')=  transFormals(xs,Env.insert(en,x,(arg,RTL.LONG,(nam,"1"))),fp)
            in (fp',en',nam::xs')
            end
           else 
           let  
               val (fp',en',xs')=  transFormals(xs,Env.insert(en,x,(arg,RTL.BYTE,(nam,"1"))),fp)
           in (fp',en',nam::xs')
           end
         end )



   and checkBody (stmt,en,ty,eofLab) = 
        case stmt of 
          Absyn.STMT(Absyn.SEQ(st1,st2),_,_) =>  
            let val t1 = checkBody (st1,en,ty,eofLab)
                val t2 = checkBody (st2,en,ty,eofLab)
            in 
              (first t1 @ first t2,second t1 @ second t2)
            end
        | Absyn.STMT(Absyn.EFFECT(exp),_,_) => 
            let val expResult = checkExpr(exp,en)
                val instList = firstTrip(expResult)
                val tmpList  = thirdTrip(expResult)
            in (instList,tmpList)
            end
        | Absyn.STMT(Absyn.EMPTY,_,_) => ([],[])
        | Absyn.STMT(Absyn.IF(exp,stm1,SOME stm2),_,_) =>
            let val ex = checkExpr(exp,en)
                val se = firstTrip ex                   
                val te = secondTrip ex                     
                val l1 = RTL.newLabel()
                val fals = RTL.newTemp()
                val loadF = RTL.EVAL(fals,RTL.ICON(0))
                val cJump = RTL.CJUMP(RTL.EQ,te,fals,l1)
                val tmpStm1 = checkBody (stm1,en,ty,eofLab)
                val s1 = first tmpStm1
                val l2 = RTL.newLabel()
                val jump = RTL.JUMP(l2)
                val labDefL1 = RTL.LABDEF(l1)
                val tmpStm2 = checkBody (stm2,en,ty,eofLab)
                val s2 = first tmpStm2
                val labDefL2 = RTL.LABDEF(l2)
                val insList = se@loadF::cJump::s1@jump::labDefL1::s2@labDefL2::[]
            in 
              (insList,fals::thirdTrip ex@second tmpStm1@second tmpStm2)
            end
        | Absyn.STMT(Absyn.IF(exp,stm1,NONE),_,_) =>
            let val ex = checkExpr(exp,en)
                val se = firstTrip ex                   
                val te = secondTrip ex                     
                val l1 = RTL.newLabel()
                val tru = RTL.newTemp()
                val loadTru = RTL.EVAL(tru,RTL.ICON(0))
                val cJump = RTL.CJUMP(RTL.EQ,te,tru,l1)
                val tmpStm1 = checkBody (stm1,en,ty,eofLab)
                val s1 = first tmpStm1
                val labDefL1 = RTL.LABDEF(l1)
                val insList = se@loadTru::cJump::s1@labDefL1::[]
            in 
              (insList,thirdTrip ex@ tru::second tmpStm1)
            end
        | Absyn.STMT(Absyn.WHILE(exp,stmt),_,_) =>
            let val ex = checkExpr(exp,en)
                val te = secondTrip ex
                val s  = checkBody (stmt,en,ty,eofLab)
                val loop = RTL.newLabel()
                val stop = RTL.newLabel()
                val loopDef = RTL.LABDEF(loop)
                val se = firstTrip ex
                val fals = RTL.newTemp()
                val loadF = RTL.EVAL(fals,RTL.ICON(0)) 
                val cJump = RTL.CJUMP(RTL.EQ,te,fals,stop)
                val sIns = first s
                val jump = RTL.JUMP(loop)
                val stopDef = RTL.LABDEF(stop)
                val insList = loopDef::se@loadF::cJump::sIns@jump::stopDef::[]
            in 
              (insList,thirdTrip ex @ fals::second s)
            end
        | Absyn.STMT(Absyn.RETURN(SOME exp),_,_) =>
            let val ex = checkExpr(exp,en)
                val res = secondTrip ex 
                val inst = firstTrip ex
                val lEnd = eofLab
                val jump = RTL.JUMP(lEnd)
                val lDef = RTL.LABDEF(lEnd)
                val ins = RTL.EVAL(RTL.RV,RTL.TEMP(res))
            in 
              (inst@ins::jump::[],thirdTrip ex) 
            end
        | Absyn.STMT(Absyn.RETURN(NONE),_,_) =>
            let val lEnd = eofLab
                val jump = RTL.JUMP(lEnd)
                val lDef = RTL.LABDEF(lEnd)
            in 
              (jump::lDef::[],[]) 
            end

    and checkExpr (ex,en) = 
       case ex of 
         Absyn.EXP(Absyn.ASSIGN(ex1,ex2),_,_) => 
           (case ex1 of 
              Absyn.EXP(Absyn.ARRAY(id,e),_,_) =>
              let 
                val befInst1 = checkExpr (ex2,en)
                val befInst2 = checkExpr (e,en)
                val instList1 = firstTrip befInst1
                val instList2 = firstTrip befInst2
                val tmpList1 = thirdTrip befInst1
                val tmpList2 = thirdTrip befInst2   
                val stat = firstTrip (valOf(Env.find(en,id)))
                val ty   = secondTrip(valOf(Env.find(en,id)))
                val offset = first(thirdTrip (valOf(Env.find(en,id))))
                val labRef = second(thirdTrip (valOf(Env.find(en,id))))
                val index  = secondTrip befInst2
                val tmp  = secondTrip befInst1
              in 
                if (stat = 0 ) then
                  let 
                    val t1 = RTL.newTemp()
                    val t2 = RTL.newTemp()
                    val t3 = RTL.newTemp()
                    val t4 = RTL.newTemp()
                    val t5 = RTL.newTemp()
                    val ins1 = RTL.EVAL(t1,RTL.ICON(RTL.sizeof(ty)))
                    val ins2 = RTL.EVAL(t2,RTL.BINARY(RTL.MUL,index,t1))
                    val ins3 = RTL.EVAL(t3,RTL.ICON(offset))
                    val ins4 = RTL.EVAL(t4,RTL.BINARY(RTL.ADD,t3,t2))
                    val ins5 = RTL.EVAL(t5,RTL.BINARY(RTL.ADD,t4,RTL.FP))
                    val ins6 = RTL.STORE(ty,t5,tmp)
                  in  
                    ((instList1@instList2)@(ins1::ins2::ins3::ins4::ins5::ins6::[]),
                    t5,(tmpList1@tmpList2)@(t1::t2::t3::t4::t5::[]))
                  end
                else if (stat = 2) then 
                  let 
                    val t1 = RTL.newTemp()
                    val t2 = RTL.newTemp()
                    val t3 = RTL.newTemp()
                    val ins1 = RTL.EVAL(t1,RTL.ICON(RTL.sizeof(ty)))
                    val ins2 = RTL.EVAL(t2,RTL.BINARY(RTL.MUL,index,t1))
                    val ins3 = RTL.EVAL(t3,RTL.BINARY(RTL.ADD,offset,t2))
                    val ins4 = RTL.STORE(ty,t3,tmp)
                  in 
                    ((instList1@instList2)@(ins1::ins2::ins3::ins4::[]),
                    t3,(tmpList1@tmpList2)@(t1::t2::t3::[]))
                  end

                else
                  let 
                    val t1 = RTL.newTemp()
                    val t2 = RTL.newTemp()
                    val t3 = RTL.newTemp()
                    val t4 = RTL.newTemp()
                    val ins1 = RTL.EVAL(t1,RTL.ICON(RTL.sizeof(ty)))
                    val ins2 = RTL.EVAL(t2,RTL.BINARY(RTL.MUL,index,t1))
                    val ins3 = RTL.EVAL(t3,RTL.LABREF(labRef))
                    val ins4 = RTL.EVAL(t4,RTL.BINARY(RTL.ADD,t3,t2))
                    val ins5 = RTL.STORE(ty,t4,tmp)
                  in 
                    ((instList1@instList2)@(ins1::ins2::ins3::ins4::ins5::[]),
                    t4,(tmpList1@tmpList2)@(t1::t2::t3::t4::[]))
                  end
              end
           | Absyn.EXP(Absyn.VAR(id),_,_) =>
             let 
               val midInst = checkExpr (ex2,en)
               val midInstList = firstTrip midInst
               val midTmpList = thirdTrip midInst
               val stat = firstTrip (valOf(Env.find(en,id)))
               val ty   = secondTrip(valOf(Env.find(en,id)))
               val alocDet  = first(thirdTrip (valOf(Env.find(en,id))))
               val labRef =  second(thirdTrip (valOf(Env.find(en,id))))
               val tmp  = secondTrip midInst
             in
               if (stat = 0) then
                 let 
                   val inst1 = RTL.EVAL(alocDet,RTL.TEMP(tmp))
                 in  (midInstList@(inst1::[]),tmp, midTmpList)
                 end
               else 
                 let 
                   val t0 = RTL.newTemp()
                   val inst1 = RTL.EVAL(t0, RTL.LABREF(labRef))
                   val inst2 = RTL.STORE(ty,t0,tmp)
                 in  (midInstList@(inst1::inst2::[]),t0,midTmpList@(t0::[]))
                 end 
             end
           | _ => ([],0,[]))


         | Absyn.EXP(Absyn.VAR(id),_,_) => 
           let   
             val stat = firstTrip (valOf(Env.find(en,id)))
             val ty   = secondTrip(valOf(Env.find(en,id)))
             val tmp = first(thirdTrip (valOf(Env.find(en,id))))
             val labRef =  second(thirdTrip (valOf(Env.find(en,id))))
           in 
             if (stat = 0) andalso (labRef = "0")  then ([],tmp,[])
    
             else if (stat = 2) andalso (labRef = "1") then 
               
                let   val t1   = RTL.newTemp()
             (*      val t2   = RTL.newTemp()
                   val t3   = RTL.newTemp() 
                   val ins1 = RTL.EVAL(t1,RTL.ICON(offset)) *)
             (*      val ins2 = RTL.EVAL(t2,RTL.BINARY(RTL.ADD,t1,RTL.FP))*)
                   val ins3 = RTL.EVAL(t1,RTL.UNARY(RTL.LOAD(RTL.LONG),tmp))
               in 
                 (ins3::[],t1,t1::[]) 
               end 

             else if (stat = 0) andalso (labRef = "1") then 
               let val offset = first(thirdTrip (valOf(Env.find(en,id))))
                   val t1   = RTL.newTemp()
                   val t2   = RTL.newTemp()
                   val t3   = RTL.newTemp() 
                   val ins1 = RTL.EVAL(t1,RTL.ICON(offset)) 
                   val ins2 = RTL.EVAL(t2,RTL.BINARY(RTL.ADD,t1,RTL.FP))
                   val ins3 = RTL.EVAL(t3,RTL.UNARY(RTL.LOAD(RTL.LONG),t2))
               in 
                 (ins1::ins2::ins3::[],t3,t1::t2::t3::[]) 
               end 
 
             else     let
                      val t0 = RTL.newTemp()
                      val tr = RTL.newTemp()
                      val inst1 = RTL.EVAL(t0,RTL.LABREF(labRef))
                      val inst2 = RTL.EVAL(tr,RTL.UNARY(RTL.LOAD(ty),t0))
                  in 
                    (inst1::inst2::[],tr,t0::tr::[]) 
                  end

            end
         | Absyn.EXP(Absyn.ARRAY(id,exp),_,_) => 
           let 
             val stat = firstTrip (valOf(Env.find(en,id)))
             val ty   = secondTrip(valOf(Env.find(en,id)))
             val offset = first(thirdTrip (valOf(Env.find(en,id))))
             val labRef = second(thirdTrip (valOf(Env.find(en,id))))
             val midInst = checkExpr (exp,en)
             val instListMid = firstTrip midInst
             val tmpListMid = thirdTrip midInst
             val index  = (secondTrip midInst)
           in 
             if (stat = 0) then 
               let 
                 val t1 = RTL.newTemp()
                 val t2 = RTL.newTemp()
                 val t3 = RTL.newTemp()
                 val t4 = RTL.newTemp()
                 val t5 = RTL.newTemp()
                 val t6 = RTL.newTemp()
                 val ins1 = RTL.EVAL(t1,RTL.ICON(RTL.sizeof(ty)))
                 val ins2 = RTL.EVAL(t2,RTL.BINARY(RTL.MUL,index,t1))
                 val ins3 = RTL.EVAL(t3,RTL.ICON(offset))
                 val ins4 = RTL.EVAL(t4,RTL.BINARY(RTL.ADD,t3,t2))
                 val ins5 = RTL.EVAL(t5,RTL.BINARY(RTL.ADD,t4,RTL.FP))
                 val ins6 = RTL.EVAL(t6,RTL.UNARY(RTL.LOAD(ty),t5))
               in 
                 (instListMid@(ins1::ins2::ins3::ins4::ins5::ins6::[]),
                  t6,tmpListMid@(t1::t2::t3::t4::t5::t6::[]))
               end
             else if stat = 2 then 
               let 
                 val t1 = RTL.newTemp()
                 val t2 = RTL.newTemp()
                 val t3 = RTL.newTemp()
                 val t4 = RTL.newTemp()
                 val t5 = RTL.newTemp()
                 val t6 = RTL.newTemp()
                 val ins1 = RTL.EVAL(t1,RTL.ICON(RTL.sizeof(ty)))
                 val ins2 = RTL.EVAL(t2,RTL.BINARY(RTL.MUL,index,t1))
                 val ins3 = RTL.EVAL(t3,RTL.ICON(0))
                 val ins4 = RTL.EVAL(t4,RTL.BINARY(RTL.ADD,t3,t2))
                 val ins5 = RTL.EVAL(t5,RTL.BINARY(RTL.ADD,t4,offset))
                 val ins6 = RTL.EVAL(t6,RTL.UNARY(RTL.LOAD(ty),t5))
               in 
                 (instListMid@(ins1::ins2::ins3::ins4::ins5::ins6::[]),
                  t6,tmpListMid@(t1::t2::t3::t4::t5::t6::[]))
               end
             else 
               let 
                 val t1 = RTL.newTemp()
                 val t2 = RTL.newTemp()
                 val t3 = RTL.newTemp()
                 val t4 = RTL.newTemp()
                 val t5 = RTL.newTemp()
                 val ins1 = RTL.EVAL(t1,RTL.ICON(RTL.sizeof(ty)))
                 val ins2 = RTL.EVAL(t2,RTL.BINARY(RTL.MUL,index,t1))
                 val ins3 = RTL.EVAL(t3,RTL.LABREF(labRef))
                 val ins4 = RTL.EVAL(t4,RTL.BINARY(RTL.ADD,t3,t2))
                 val ins5 = RTL.EVAL(t5,RTL.UNARY(RTL.LOAD(ty),t4))
               in 
                 (instListMid@(ins1::ins2::ins3::ins4::ins5::[]),
                  t5,tmpListMid@(t1::t2::t3::t4::t5::[]))
               end

             end


          | Absyn.EXP(Absyn.CONST(Absyn.INTcon(i)),_,_) => 
            let 
              val res = RTL.newTemp()
              val inst = RTL.EVAL(res,RTL.ICON(i))
            in 
              ([inst],res,[res]) 
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.ADD,ex1,ex2),_,_) => 
            let 
              val midInst1  = checkExpr (ex1,en)
              val midInst2  = checkExpr (ex2,en)
              val il1   = firstTrip midInst1
              val t1    =  (secondTrip midInst1)
              val il2   = firstTrip midInst2
              val t2    = (secondTrip midInst2)
              val tmp1List = thirdTrip midInst1
              val tmp2List = thirdTrip midInst2
              val t3 = RTL.newTemp()
              val inst  = RTL.EVAL(t3,RTL.BINARY(RTL.ADD,t1,t2))
            in
              ((il1@il2)@[inst],t3,(tmp1List@tmp2List)@[t3])
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.SUB,ex1,ex2),_,_) => 
            let 
              val midInst1  = checkExpr (ex1,en)
              val midInst2  = checkExpr (ex2,en)
              val il1   = firstTrip midInst1
              val t1    =  (secondTrip midInst1)
              val il2   = firstTrip midInst2
              val t2    = (secondTrip midInst2)
              val tmp1List = thirdTrip midInst1
              val tmp2List = thirdTrip midInst2
              val t3 = RTL.newTemp()
              val inst  = RTL.EVAL(t3,RTL.BINARY(RTL.SUB,t1,t2))
            in
              ((il1@il2)@[inst],t3,(tmp1List@tmp2List)@[t3])
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.MUL,ex1,ex2),_,_) => 
            let 
              val midInst1  = checkExpr (ex1,en)
              val midInst2  = checkExpr (ex2,en)
              val il1   = firstTrip midInst1
              val t1    =  (secondTrip midInst1)
              val il2   = firstTrip midInst2
              val t2    = (secondTrip midInst2)
              val tmp1List = thirdTrip midInst1
              val tmp2List = thirdTrip midInst2
              val t3 = RTL.newTemp()
              val inst  = RTL.EVAL(t3,RTL.BINARY(RTL.MUL,t1,t2))
            in
              ((il1@il2)@[inst],t3,(tmp1List@tmp2List)@[t3])
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.DIV,ex1,ex2),_,_) => 
            let 
              val midInst1  = checkExpr (ex1,en)
              val midInst2  = checkExpr (ex2,en)
              val il1   = firstTrip midInst1
              val t1    =  secondTrip midInst1
              val il2   = firstTrip midInst2
              val t2    = secondTrip midInst2
              val tmp1List = thirdTrip midInst1
              val tmp2List = thirdTrip midInst2
              val t3 = RTL.newTemp()
              val inst  = RTL.EVAL(t3,RTL.BINARY(RTL.DIV,t1,t2))
            in
              ((il1@il2)@[inst],t3,(tmp1List@tmp2List)@[t3])
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.LT,ex1,ex2),_,_) => 
            let 
              val exp1 = checkExpr(ex1,en)
              val exp2 = checkExpr(ex2,en)
              val se1 = firstTrip exp1
              val se2 = firstTrip exp2                      
              val te1 = secondTrip exp1                    
              val te2 = secondTrip exp2
              val tmp1 = thirdTrip exp1
              val tmp2 = thirdTrip exp2
              val res = RTL.newTemp()
              val tru = RTL.newLabel()
              val return = RTL.newLabel()
              val cJump = RTL.CJUMP(RTL.LT,te1,te2,tru)
              val setFal = RTL.EVAL(res,RTL.ICON(0))
              val jump1 = RTL.JUMP(return)
              val labDefTru = RTL.LABDEF(tru)
              val setTru = RTL.EVAL(res,RTL.ICON(1))
              val jump2 = RTL.JUMP(return)
              val labDefReturn = RTL.LABDEF(return)
            in 
              ((se1@se2)@cJump::setFal::jump1::labDefTru::setTru::jump2::labDefReturn::[],res,(tmp1@tmp2)@[res])
                                                
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.LE,ex1,ex2),_,_) => 
            let 
              val exp1 = checkExpr(ex1,en)
              val exp2 = checkExpr(ex2,en)
              val se1 = firstTrip exp1
              val se2 = firstTrip exp2                      
              val te1 = secondTrip exp1                    
              val te2 = secondTrip exp2
              val tmp1 = thirdTrip exp1
              val tmp2 = thirdTrip exp2
              val res = RTL.newTemp()
              val tru = RTL.newLabel()
              val return = RTL.newLabel()
              val cJump = RTL.CJUMP(RTL.LE,te1,te2,tru)
              val setFal = RTL.EVAL(res,RTL.ICON(0))
              val jump1 = RTL.JUMP(return)
              val labDefTru = RTL.LABDEF(tru)
              val setTru = RTL.EVAL(res,RTL.ICON(1))
              val jump2 = RTL.JUMP(return)
              val labDefReturn = RTL.LABDEF(return)
            in 
              ((se1@se2)@cJump::setFal::jump1::labDefTru::setTru::jump2::labDefReturn::[],
                res,(tmp1@tmp2)@[res])
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.EQ,ex1,ex2),_,_) => 
            let 
              val exp1 = checkExpr(ex1,en)
              val exp2 = checkExpr(ex2,en)
              val se1 = firstTrip exp1
              val se2 = firstTrip exp2                      
              val te1 = secondTrip exp1                    
              val te2 = secondTrip exp2
              val tmp1 = thirdTrip exp1
              val tmp2 = thirdTrip exp2
              val res = RTL.newTemp()
              val tru = RTL.newLabel()
              val return = RTL.newLabel()
              val cJump = RTL.CJUMP(RTL.EQ,te1,te2,tru)
              val setFal = RTL.EVAL(res,RTL.ICON(0))
              val jump1 = RTL.JUMP(return)
              val labDefTru = RTL.LABDEF(tru)
              val setTru = RTL.EVAL(res,RTL.ICON(1))
              val jump2 = RTL.JUMP(return)
              val labDefReturn = RTL.LABDEF(return)
            in 
              ((se1@se2)@cJump::setFal::jump1::labDefTru::setTru::jump2::labDefReturn::[],
                res,(tmp1@tmp2)@[res])
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.NE,ex1,ex2),_,_) => 
            let 
              val exp1 = checkExpr(ex1,en)
              val exp2 = checkExpr(ex2,en)
              val se1 = firstTrip exp1
              val se2 = firstTrip exp2                      
              val te1 = secondTrip exp1                    
              val te2 = secondTrip exp2
              val tmp1 = thirdTrip exp1
              val tmp2 = thirdTrip exp2
              val res = RTL.newTemp()
              val tru = RTL.newLabel()
              val return = RTL.newLabel()
              val cJump = RTL.CJUMP(RTL.NE,te1,te2,tru)
              val setFal = RTL.EVAL(res,RTL.ICON(0))
              val jump1 = RTL.JUMP(return)
              val labDefTru = RTL.LABDEF(tru)
              val setTru = RTL.EVAL(res,RTL.ICON(1))
              val jump2 = RTL.JUMP(return)
              val labDefReturn = RTL.LABDEF(return)
            in 
              ((se1@se2)@cJump::setFal::jump1::labDefTru::setTru::jump2::labDefReturn::[],
                res,(tmp1@tmp2)@[res])
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.GE,ex1,ex2),_,_) => 
            let 
              val exp1 = checkExpr(ex1,en)
              val exp2 = checkExpr(ex2,en)
              val se1 = firstTrip exp1
              val se2 = firstTrip exp2                      
              val te1 = secondTrip exp1                    
              val te2 = secondTrip exp2
              val tmp1 = thirdTrip exp1
              val tmp2 = thirdTrip exp2
              val res = RTL.newTemp()
              val tru = RTL.newLabel()
              val return = RTL.newLabel()
              val cJump = RTL.CJUMP(RTL.GE,te1,te2,tru)
              val setFal = RTL.EVAL(res,RTL.ICON(0))
              val jump1 = RTL.JUMP(return)
              val labDefTru = RTL.LABDEF(tru)
              val setTru = RTL.EVAL(res,RTL.ICON(1))
              val jump2 = RTL.JUMP(return)
              val labDefReturn = RTL.LABDEF(return)
            in 
              ((se1@se2)@cJump::setFal::jump1::labDefTru::setTru::jump2::labDefReturn::[],
                res,(tmp1@tmp2)@[res])
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.GT,ex1,ex2),_,_) => 
            let 
              val exp1 = checkExpr(ex1,en)
              val exp2 = checkExpr(ex2,en)
              val se1 = firstTrip exp1
              val se2 = firstTrip exp2                      
              val te1 = secondTrip exp1                    
              val te2 = secondTrip exp2
              val tmp1 = thirdTrip exp1
              val tmp2 = thirdTrip exp2
              val res = RTL.newTemp()
              val tru = RTL.newLabel()
              val return = RTL.newLabel()
              val cJump = RTL.CJUMP(RTL.GT,te1,te2,tru)
              val setFal = RTL.EVAL(res,RTL.ICON(0))
              val jump1 = RTL.JUMP(return)
              val labDefTru = RTL.LABDEF(tru)
              val setTru = RTL.EVAL(res,RTL.ICON(1))
              val jump2 = RTL.JUMP(return)
              val labDefReturn = RTL.LABDEF(return)
            in 
              ((se1@se2)@cJump::setFal::jump1::labDefTru::setTru::jump2::labDefReturn::[],
                res,(tmp1@tmp2)@[res])
            end

          | Absyn.EXP(Absyn.BINARY(Absyn.ANDALSO,ex1,ex2),_,_) => 
            let 
              val exInst1  = checkExpr (ex1,en)
              val ilist1   = firstTrip exInst1
              val restm1   = secondTrip exInst1
              val tmpList1 = thirdTrip exInst1
              
              val tmptrue  = RTL.newTemp()
              val l1       = RTL.newLabel()
              val loadt2   = RTL.EVAL(tmptrue,RTL.ICON(1))
              val cJump1   = RTL.CJUMP(RTL.EQ,restm1,tmptrue,l1)
              val labdef1  = RTL.LABDEF(l1)
              val exInst2  = checkExpr (ex2,en)
              val ilist2   = firstTrip exInst2
              val restm2   = secondTrip exInst2
              val tmpList2 = thirdTrip exInst2
              val l2       = RTL.newLabel()
              val loadt2   = RTL.EVAL(tmptrue,RTL.ICON(1)) 
              val cJump2   = RTL.CJUMP(RTL.EQ,restm2,tmptrue,l2)
              val labdef2  = RTL.LABDEF(l2)
              val res      = RTL.newTemp()
              val restrue  = RTL.EVAL(res,RTL.ICON(1))
              val resfalse = RTL.EVAL(res,RTL.ICON(0))
              val endLabel = RTL.newLabel() 
              val jumpEnd  = RTL.JUMP(endLabel) 
              val labdefEnd= RTL.LABDEF(endLabel)
            in
              (ilist1@loadt2::cJump1::resfalse::jumpEnd::labdef1::ilist2
                     @loadt2::cJump2::resfalse::jumpEnd::labdef2::restrue::jumpEnd::labdefEnd::[],
               res,(tmpList1@tmpList2)@res::tmptrue::[])
            end

          | Absyn.EXP(Absyn.UNARY(Absyn.NEG,exp),i,j) =>
            let 
              val newExp = Absyn.EXP(Absyn.BINARY(Absyn.SUB,Absyn.EXP(Absyn.CONST(Absyn.INTcon(0)),i,j),exp),i,j) 
            in checkExpr(newExp,en) 
            end

          | Absyn.EXP(Absyn.UNARY(Absyn.NOT,exp),i,j) =>
            let 
              val newExp = Absyn.EXP(Absyn.BINARY(Absyn.EQ,Absyn.EXP(Absyn.CONST(Absyn.INTcon(0)),i,j),exp),i,j) 
            in checkExpr(newExp,en) 
            end

          | Absyn.EXP(Absyn.FCALL(id,exList),_,_) =>
            let 
              val f = valOf(Env.find(en,id))
              val ty = secondTrip f 
              val label = second(thirdTrip(f))
              val (inslist,ftmlist,tmlist) = checkExList exList en
              val tm = RTL.newTemp()
            in 
              if ty = RTL.BYTE then  
                (inslist@[RTL.CALL(SOME tm,label,ftmlist)],tm,tmlist) 
              else if ty = RTL.LONG then 
                     (inslist@[RTL.CALL(SOME tm,label,ftmlist)],tm,tmlist) 
              else (inslist@[RTL.CALL(NONE,label,ftmlist)],tm,tmlist)
            end

    and checkExList [] _ = ([],[],[])
      | checkExList (x::xs) en = 
        let val (insns,tm,tmplist) = checkExpr (x,en)
            val (inss,restm,tms) = checkExList xs en 
        in              
          (insns@inss,tm::restm,tmplist@tms)
        end

    and insertFName (nam,id) ty en = 
          case ty of 
            Absyn.INTty => Env.insert(en,id,(0,RTL.LONG,(0,nam))) 
          | Absyn.CHARty => Env.insert(en,id,(0,RTL.BYTE,(0,nam)))
          | _ => Env.insert(en,id,(0,RTL.BYTE,(0,nam)))




    and checkFormal x typ en = 
             case Env.find(en,x) of 
               SOME (_,ty,_) => if typ = Absyn.INTty andalso ty = RTL.LONG then true 
                                else if typ = Absyn.INTty andalso ty = RTL.BYTE then false
                                else if typ = Absyn.CHARty andalso ty = RTL.BYTE then true
                                else false
             | NONE   => false


  end (* functor AbsynToRTLFn *)
