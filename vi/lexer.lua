local v1,v2,v3,v4,v5,v6,v7,v8,v9,va,vb,vc,vd,ve;
v1={};
v2={};
v2[("let")]=("let");
v2[("fn")]=("fn");
v2[("true")]=("true");
v2[("false")]=("false");
v2[("nil")]=("nil");
v2[("for")]=("for");
v2[("while")]=("while");
v2[("if")]=("if");
v2[("elseif")]=("elseif");
v2[("else")]=("else");
v2[("return")]=("return");
v2[("break")]=("break");
v2[("continue")]=("continue");
v2[("pub")]=("pub");
v2[("mod")]=("mod");
v2[("const")]=("const");
v2[("struct")]=("struct");
v2[("enum")]=("enum");
v2[("run")]=("run");
v3={};
v3[(97)]=(7);
v3[(98)]=(8);
v3[(102)]=(12);
v3[(110)]=(10);
v3[(114)]=(13);
v3[(116)]=(9);
v3[(118)]=(11);
v3[(92)]=(92);
v3[(34)]=(34);
v3[(39)]=(39);
v4=function(vf)
  return vf>=(48) and vf<=(57);
end;
v5=function(v10)
  return v10>=(97) and v10<=(122) or v10>=(65) and v10<=(90);
end;
v6=function(v11)
  return v5(v11) or v4(v11);
end;
v7=function(v12)
  return v12[("cur")]>#v12[("src")];
end;
v8=function(v13)
  return string[("byte")](v13[("src")],v13[("cur")]);
end;
v9=function(v14,v15)
  local v16;
  v16=v8(v14);
  if not v16 or v15 and type(v15)==("function") and not v15(v16) or type(v15)==("number") and v16~=v15 then
    return;
  end;
  v14[("cur")]=v14[("cur")]+(1);
  if v16==(10) then
    v14[("line")]=v14[("line")]+(1);
    v14[("col")]=(1);
  else 
    v14[("col")]=v14[("col")]+(1);
  end;
  return v16;
end;
va=function(v17,v18)
  local v19,v1a;
  v19={};
  v1a=v9(v17,v18);
  while v1a do
    v19[#v19+(1)]=v1a;
    v1a=v9(v17,v18);
  end;
  return v19;
end;
vb=function(v1b,v1c)
  table[("insert")](v1b[("errors")],{["msg"]=v1c,["token"]={["line"]=v1b[("startLine")],["col"]=v1b[("startCol")],["text"]=string[("sub")](v1b[("src")],v1b[("start")],v1b[("cur")]-(1))}});
end;
vc=function(v1d)
  return string[("sub")](v1d[("src")],v1d[("start")],v1d[("cur")]-(1));
end;
vd=function(v1e,v1f,v20)
  return {["ty"]=v1f,["line"]=v1e[("startLine")],["col"]=v1e[("startCol")],["text"]=vc(v1e),["value"]=v20};
end;
ve=function(v21)
  local v22;
  v22=v9(v21);
  if v22==(32) then
    return;
  end;
  if v22==(10) then
    return;
  end;
  if v22==(13) then
    return;
  end;
  if v22==(9) then
    return;
  end;
  if v22==(59) then
    va(v21,function(v23)
      return v23~=(10);
    end);
    return;
  end;
  if v22==(40) then
    return vd(v21,("("));
  end;
  if v22==(41) then
    return vd(v21,(")"));
  end;
  if v22==(123) then
    return vd(v21,("{"));
  end;
  if v22==(125) then
    return vd(v21,("}"));
  end;
  if v22==(91) then
    return vd(v21,("["));
  end;
  if v22==(93) then
    return vd(v21,("]"));
  end;
  if v22==(44) then
    return vd(v21,(","));
  end;
  if v22==(58) then
    return vd(v21,(":"));
  end;
  if v22==(43) then
    return vd(v21,("+"));
  end;
  if v22==(45) then
    return vd(v21,("-"));
  end;
  if v22==(42) then
    return vd(v21,("*"));
  end;
  if v22==(47) then
    return vd(v21,("/"));
  end;
  if v22==(37) then
    return vd(v21,("%"));
  end;
  if v22==(35) then
    return vd(v21,("#"));
  end;
  if v22==(46) then
    if v9(v21,(46)) then
      if v9(v21,(46)) then
        return vd(v21,("..."));
      else 
        return vd(v21,(".."));
      end;
    else 
      return vd(v21,("."));
    end;
  end;
  if v22==(33) then
    if v9(v21,(61)) then
      return vd(v21,("!="));
    else 
      return vd(v21,("!"));
    end;
  end;
  if v22==(61) then
    if v9(v21,(61)) then
      return vd(v21,("=="));
    else 
      return vd(v21,("="));
    end;
  end;
  if v22==(60) then
    if v9(v21,(61)) then
      return vd(v21,("<="));
    else 
      return vd(v21,("<"));
    end;
  end;
  if v22==(62) then
    if v9(v21,(61)) then
      return vd(v21,(">="));
    else 
      return vd(v21,(">"));
    end;
  end;
  if v22==(38) then
    if v9(v21,(38)) then
      return vd(v21,("&&"));
    else 
      return vd(v21,("&"));
    end;
  end;
  if v22==(124) then
    if v9(v21,(124)) then
      return vd(v21,("||"));
    else 
      return vd(v21,("|"));
    end;
  end;
  if v22==(39) then
    v22=v9(v21);
    if v22==(39) then
      vb(v21,("empty char literal"));
      return;
    elseif v22==(7) or v22==(8) or v22==(12) or v22==(10) or v22==(13) or v22==(9) or v22==(11) then
      vb(v21,("invalid char literal"));
      return;
    elseif v22==(92) then
      local v24;
      v24=v9(v21);
      v22=v3[v24];
      if not v22 then
        vb(v21,("unknown escape sequence: \\")..v24);
        return;
      end;
    end;
    if not v9(v21,(39)) then
      vb(v21,("expected \"'\" to end char literal"));
      return;
    end;
    return vd(v21,("char"),v22);
  end;
  if v22==(34) then
    local v25;
    v25={};
    v22=v9(v21);
    while not v7(v21) and v22~=(34) do
      if v22==(7) or v22==(8) or v22==(12) or v22==(10) or v22==(13) or v22==(9) or v22==(11) then
        vb(v21,("invalid string literal"));
        return;
      elseif v22==(92) then
        local v26;
        v26=v9(v21);
        v22=v3[v26];
        if not v22 then
          vb(v21,("unknown escape sequence: \\")..v26);
          return;
        end;
      end;
      table[("insert")](v25,string[("char")](v22));
      v22=v9(v21);
    end;
    if v22~=(34) then
      vb(v21,("unterminated string"));
      return;
    end;
    return vd(v21,("string"),table[("concat")](v25));
  end;
  if v4(v22) then
    local v27,v28;
    v27=(false);
    v28=function(v29)
      if v4(v29) then
        return (true);
      end;
      if not v27 and v29==(46) then
        v27=(true);
        return (true);
      end;
      return (false);
    end;
    va(v21,v28);
    return vd(v21,("number"),tonumber(vc(v21)));
  end;
  if v5(v22) or v22==(95) then
    local v2a,v2b;
    va(v21,function(v2c)
      return v6(v2c) or v2c==(95);
    end);
    v2a=vd(v21,("identifier"));
    v2b=v2[v2a[("text")]];
    if v2b then
      v2a[("ty")]=v2b;
    end;
    return v2a;
  end;
  vb(v21,("unexpected character"));
end;
v1[("scan")]=function(v2d)
  local v2e,v2f;
  v2e={};
  v2f={["src"]=v2d,["cur"]=(1),["start"]=(1),["startLine"]=(1),["startCol"]=(1),["col"]=(1),["line"]=(1),["errors"]={}};
  while not v7(v2f) do
    local v30;
    v2f[("start")]=v2f[("cur")];
    v2f[("startLine")]=v2f[("line")];
    v2f[("startCol")]=v2f[("col")];
    v30=ve(v2f);
    if v30 then
      table[("insert")](v2e,v30);
    end;
  end;
  return v2e,v2f[("errors")];
end;
return v1;
