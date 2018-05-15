versions = {"POKEMON RUBY",
            "POKEMON SAPP",
            "POKEMON FIRE",
            "POKEMON LEAF",
            "POKEMON EMER"}

languages = {"Unknown",
			 "Deutsch",
             "French",
			 "Italian",
			 "Spanish",
			 "English",
			 "Japanese"}
			 
function checkversion(version)
	for i,v in pairs(versions) do
		if comparebytetostring(version,v) then
			return i
		end
	end
end

function comparebytetostring(b, s)
	local isequal = true
	local blen = table.getn(b)
	local slen = string.len(s)
	local x,y
	if blen ~= slen then
		isequal = false
    else
    	for i=1,blen do
    		x = b[i]
    		y = string.byte(s, i)
    		if(x~=y) then
    			isequal = false
    			break
    		end
    	end
    end
	return isequal
end
			 
local vbytes = memory.readbyterange(0x080000A0, 12)
local vindex = checkversion(vbytes)
if vindex==nil then
	print("Unknown version. Stopping script.")
	return
end

print(string.format("Version: %s", versions[vindex]))
local lan = memory.readbyte(0x080000AF)
local lindex = 1
local language

if lan==0x44 then
	lindex = 2
elseif lan==0x46 then
	lindex = 3
elseif lan==0x49 then
	lindex = 4
elseif lan==0x53 then
	lindex = 5
elseif lan==0x45 then
	lindex = 6
elseif lan==0x4A then
	lindex = 7
end

print(string.format("Language: %s", languages[lindex]))

if lindex == 1 then
	print("This language is not currently supported")
	print("You can help improving this script at: https://github.com/red-the-dev/gen3-pokemonstatsdisplay")
	print("Stopping scrpt")
	return
end

local game=1 --see below

-- Auto-setting game variable

if vindex == 1 or vindex == 2 then  -- R/S
	if lindex == 4 then
		game = 7
	elseif lindex == 6 then
		game = 1
	elseif lindex == 7 then
		game = 4
	end
end

if vindex == 3 or vindex == 4 then  -- FR/LG
	if lindex == 4 or lindex == 6 then
		game = 3
	elseif lindex == 7 then
		game = 6
	end
end

if vindex == 5 then  -- E
	if lindex == 4 or lindex == 6 then
		game = 2
	elseif lindex == 7 then
		game = 5
	end
end

local startvalue=0x83ED --insert the first value of RNG

-- These are all the possible key names: [keys]
-- backspace, tab, enter, shift, control, alt, pause, capslock, escape,
-- space, pageup, pagedown, end, home, left, up, right, down, insert, delete,
-- 0 .. 9, A .. Z, numpad0 .. numpad9, numpad*, numpad+, numpad-, numpad., numpad/,
-- F1 .. F24, numlock, scrolllock, semicolon, plus, comma, minus, period, slash, tilde,
-- leftbracket, backslash, rightbracket, quote.
-- [/keys]
-- Key names must be in quotes.
-- Key names are case sensitive.
local key={"9", "8", "7"}

-- It is not necessary to change anything beyond this point.

--for different display modes
local status=1
local substatus={1,1,1}

local tabl={}
local prev={}

local xfix=0 --x position of display handle
local yfix=65 --y position of display handle

local xfix2=105 --x position of 2nd handle
local yfix2=0 --y position of 2nd handle

local k 

--for different game versions
--1: Ruby/Sapphire U
--2: Emerald U
--3: FireRed/LeafGreen U
--4: Ruby/Sapphire J
--5: Emerald J (TODO)
--6: FireRed/LeafGreen J (1360)
--7: Ruby/Sapphire I

local gamename={"Ruby/Sapphire U", "Emerald U", "FireRed/LeafGreen U", "Ruby/Sapphire J", "Emerald J", "FireRed/LeafGreen J (1360)", "Ruby/Sapphire I"}

--game dependent

local pstats={0x3004360, 0x20244EC, 0x2024284, 0x3004290, 0x2024190, 0x20241E4, 0x3004370}
local estats={0x30045C0, 0x2024744, 0x202402C, 0x30044F0, 0x20243E8, 0x2023F8C, 0x30045D0}
local rng   ={0x3004818, 0x3005D80, 0x3005000, 0x3004748, 0x3005AE0, 0x3005040, 0} --0X3004FA0
local rng2  ={0x0000000, 0x0000000, 0x20386D0, 0x0000000, 0x0000000, 0x203861C, 0}


--HP, Atk, Def, Spd, SpAtk, SpDef
local statcolor = {"yellow", "red", "blue", "green", "magenta", "cyan"}


dofile "tables.lua"

local flag=0
local last=0
local counter=0

local bnd,br,bxr=bit.band,bit.bor,bit.bxor
local rshift, lshift=bit.rshift, bit.lshift
local mdword=memory.readdwordunsigned
local mword=memory.readwordunsigned
local mbyte=memory.readbyteunsigned

local natureorder={"Atk","Def","SpAtk","SpDef","Spd"}
local naturename={
 "Hardy","Lonely","Brave","Adamant","Naughty",
 "Bold","Docile","Relaxed","Impish","Lax",
 "Timid","Hasty","Serious","Jolly","Naive",
 "Modest","Mild","Quiet","Bashful","Rash",
 "Calm","Gentle","Sassy","Careful","Quirky"}
local typeorder={
 "Fighting","Flying","Poison","Ground",
 "Rock","Bug","Ghost","Steel",
 "Fire","Water","Grass","Electric",
 "Psychic","Ice","Dragon","Dark"}

nor={168, 168, 120}
fire={240, 128, 48}
wat={104, 144, 240}
gra={120, 200, 80}
ele={248, 208, 48}
ice={152, 216, 216}
fig={192, 48, 40}
poi={160, 64, 160}
gro={224, 192, 104}
fly={168, 144, 240}
psy={248, 88, 136}
bug={168, 184, 32}
roc={184, 160, 56}
gho={112, 88, 152}
dra={112, 56, 1248}
dar={112, 88, 72}
ste={184, 184, 208}

--a 32-bit, b bit position bottom, d size
function getbits(a,b,d)
 return rshift(a,b)%lshift(1,d)
end

--for RNG purposes
function gettop(a)
 return(rshift(a,16))
end

--does 32-bit multiplication
--necessary because Lua does not allow 32-bit integer definitions
--so one cannot do 32-bit arithmetic
--furthermore, precision loss occurs at around 10^10
--so numbers must be broken into parts
--may be improved using bitop library exclusively
function mult32(a,b)
 local c=rshift(a,16)
 local d=a%0x10000
 local e=rshift(b,16)
 local f=b%0x10000
 local g=(c*f+d*e)%0x10000
 local h=d*f
 local i=g*0x10000+h
 return i
end

--checksum stuff; add halves
function ah(a)
 b=getbits(a,0,16)
 c=getbits(a,16,16)
 return b+c
end

-- draws a 3x3 square with x position a, y position b, and color c
function drawsquare(a,b,c)
 gui.box(a,b,a+2,b+2,c)
end

-- draws a down arrow, x position a, y position b, and color c
-- this arrow marks the square for the current RNG value
function drawarrow(a,b,c)
 gui.line(a,b,a-2,b-2,c)
 gui.line(a,b,a+2,b-2,c)
 gui.line(a,b,a,b-6,c)
end

--a press is when input is registered on one frame but not on the previous
--that's why the previous input is used as well
prev=input.get()
function fn()
--*********
 tabl=input.get()

 if tabl[key[1]] and not prev[key[1]] then
  status=status+1
  if status==3 then
   status=1
  end
 end

 if tabl[key[2]] and not prev[key[2]] then
  substatus[status]=substatus[status]+1
  if substatus[status]==7 then
   substatus[status]=1
  end
 end

 if tabl[key[3]] and not prev[key[3]] then
  substatus[status]=substatus[status]-1
  if substatus[status]==0 then
   substatus[status]=6
  end
 end

 prev=tabl
 
-- gui.text(200,0,status)
-- gui.text(200,10,substatus[1])
-- gui.text(200,20,substatus[2])

-- now for display
 if status==1 or status==2 then --status 1 or 2

    if status==1 then
     start=pstats[game]+100*(substatus[1]-1)
    else
     start=estats[game]+100*(substatus[2]-1)
    end

    personality=mdword(start)
    trainerid=mdword(start+4)
    magicword=bxr(personality, trainerid)
	
    i=personality%24
	
	growthoffset=(growthtbl[i+1]-1)*12
	attackoffset=(attacktbl[i+1]-1)*12
	effortoffset=(efforttbl[i+1]-1)*12
	miscoffset=(misctbl[i+1]-1)*12
    
	
	growth1=bxr(mdword(start+32+growthoffset),magicword)
	growth2=bxr(mdword(start+32+growthoffset+4),magicword)
	growth3=bxr(mdword(start+32+growthoffset+8),magicword)
	
	attack1=bxr(mdword(start+32+attackoffset),magicword)
	attack2=bxr(mdword(start+32+attackoffset+4),magicword)
	attack3=bxr(mdword(start+32+attackoffset+8),magicword)
	
	effort1=bxr(mdword(start+32+effortoffset),magicword)
	effort2=bxr(mdword(start+32+effortoffset+4),magicword)
	effort3=bxr(mdword(start+32+effortoffset+8),magicword)
	
	misc1=bxr(mdword(start+32+miscoffset),magicword)
	misc2=bxr(mdword(start+32+miscoffset+4),magicword)
	misc3=bxr(mdword(start+32+miscoffset+8),magicword)
	
    cs=ah(growth1)+ah(growth2)+ah(growth3)+ah(attack1)+ah(attack2)+ah(attack3)
	  +ah(effort1)+ah(effort2)+ah(effort3)+ah(misc1)+ah(misc2)+ah(misc3)
	
	cs=cs%65536
	
	gui.text(0,10, mword(start+28))
	gui.text(0,20, cs)
	
    species=getbits(growth1,0,16)

    holditem=getbits(growth1,16,16)

    pokerus=getbits(misc1,0,8)

    ivs=misc2

    evs1=effort1
    evs2=effort2

    hpiv=getbits(ivs,0,5)
    atkiv=getbits(ivs,5,5)
    defiv=getbits(ivs,10,5)
    spdiv=getbits(ivs,15,5)
    spatkiv=getbits(ivs,20,5)
    spdefiv=getbits(ivs,25,5)

    nature=personality%25
    natinc=math.floor(nature/5)
    natdec=nature%5

    hidpowtype=math.floor(((hpiv%2 + 2*(atkiv%2) + 4*(defiv%2) + 8*(spdiv%2) + 16*(spatkiv%2) + 32*(spdefiv%2))*15)/63)
    hidpowbase=math.floor((( getbits(hpiv,1,1) + 2*getbits(atkiv,1,1) + 4*getbits(defiv,1,1) + 8*getbits(spdiv,1,1) + 16*getbits(spatkiv,1,1) + 32*getbits(spdefiv,1,1))*40)/63 + 30)

	move1=getbits(attack1,0,16)
	move2=getbits(attack1,16,16)
	move3=getbits(attack2,0,16)
	move4=getbits(attack2,16,16)
	pp1=getbits(attack3,0,8)
	pp2=getbits(attack3,8,8)
	pp3=getbits(attack3,16,8)
	pp4=getbits(attack3,24,8)
	
    gui.text(xfix+15,yfix-8, "Stat")
    gui.text(xfix+35,yfix-8, "IV")
    gui.text(xfix+50,yfix-8, "EV")
    gui.text(xfix+65,yfix-8, "Nat")
	
	speciesname=pokemontbl[species]
	if speciesname==nil then speciesname="none" end
	
    gui.text(xfix,yfix-16, "CurHP: "..mword(start+86).."/"..mword(start+88), "yellow")
    if status==2 then
     gui.text(xfix,yfix-24, "Enemy "..substatus[2].." ("..speciesname..")")
    elseif status==1 then
     gui.text(xfix,yfix-24, "Player "..substatus[1].." ("..speciesname..")")
    end

    gui.text(xfix,yfix+0,"HP", "yellow")
    gui.text(xfix,yfix+8,"Atk", "red")
    gui.text(xfix,yfix+16,"Def", "blue")
    gui.text(xfix,yfix+40,"Spe", "green")
    gui.text(xfix,yfix+24,"SpA", "magenta")
    gui.text(xfix,yfix+32,"SpD", "cyan")

    gui.text(xfix+20,yfix, mword(start+88), "yellow")
    gui.text(xfix+20,yfix+8, mword(start+90), "red")
    gui.text(xfix+20,yfix+16, mword(start+92), "blue")
    gui.text(xfix+20,yfix+40, mword(start+94), "green")
    gui.text(xfix+20,yfix+24, mword(start+96), "magenta")
    gui.text(xfix+20,yfix+32, mword(start+98), "cyan")

    gui.text(xfix+35,yfix, hpiv, "yellow")
    gui.text(xfix+35,yfix+8, atkiv, "red")
    gui.text(xfix+35,yfix+16, defiv, "blue")
    gui.text(xfix+35,yfix+40, spdiv, "green")
    gui.text(xfix+35,yfix+24, spatkiv, "magenta")
    gui.text(xfix+35,yfix+32, spdefiv, "cyan")

    gui.text(xfix+50,yfix, getbits(evs1, 0, 8), "yellow")
    gui.text(xfix+50,yfix+8, getbits(evs1, 8, 8), "red")
    gui.text(xfix+50,yfix+16, getbits(evs1, 16, 8), "blue")
    gui.text(xfix+50,yfix+40, getbits(evs1, 24, 8), "green")
    gui.text(xfix+50,yfix+24, getbits(evs2, 0, 8), "magenta")
    gui.text(xfix+50,yfix+32, getbits(evs2, 8, 8), "cyan")

     if natinc < 2 and natdec < 2 then
     gui.text(xfix+65,yfix+8*(natinc+1), "+ ", statcolor[natinc+2])
     gui.text(xfix+65,yfix+8*(natdec+1), " -", statcolor[natdec+2])
       	elseif natinc < 2 and natdec == 2 then
     gui.text(xfix+65,yfix+8*(natinc+1), "+ ", statcolor[natinc+2])
     gui.text(xfix+65,yfix+8*(natdec+3), " -", statcolor[natdec+2])
 	elseif natinc < 2 and natdec > 2 then
     gui.text(xfix+65,yfix+8*(natinc+1), "+ ", statcolor[natinc+2])
     gui.text(xfix+65,yfix+8*(natdec), " -", statcolor[natdec+2])
	elseif natinc == 2 and natdec < 2 then
     gui.text(xfix+65,yfix+8*(natinc+3), "+ ", statcolor[natinc+2])
     gui.text(xfix+65,yfix+8*(natdec+1), " -", statcolor[natdec+2])
 	elseif natinc == 2 and natdec == 2 then
     gui.text(xfix+65,yfix+8*(natinc+3), "+ ", statcolor[natinc+2])
     gui.text(xfix+65,yfix+8*(natdec+3), " -", statcolor[natdec+2])
 	elseif natinc == 2 and natdec > 2 then
     gui.text(xfix+65,yfix+8*(natinc+3), "+ ", statcolor[natinc+2])
     gui.text(xfix+65,yfix+8*(natdec), " -", statcolor[natdec+2])
	elseif natinc > 2 and natdec < 2 then
     gui.text(xfix+65,yfix+8*(natinc), "+", statcolor[natinc+2])
     gui.text(xfix+65,yfix+8*(natdec+1), " -", statcolor[natdec+2])
 	elseif natinc > 2 and natdec == 2 then
     gui.text(xfix+65,yfix+8*(natinc), "+ ", statcolor[natinc+2])
     gui.text(xfix+65,yfix+8*(natdec+3), " -", statcolor[natdec+2])
	elseif natinc > 2 and natdec > 2 then
     gui.text(xfix+65,yfix+8*(natinc), "+ ", statcolor[natinc+2])
     gui.text(xfix+65,yfix+8*(natdec), " -", statcolor[natdec+2])
    end
 end --status 1 or 2

-- gui.text(xfix2, yfix2,"Species "..species)
-- gui.text(xfix2, yfix2+10,"Nature: "..naturename[nature+1])
-- gui.text(xfix2, yfix2+20,natureorder[natinc+1].."+ "..natureorder[natdec+1].."-")

 movename1=movetbl[move1]
 if movename1==nil then movename1="none" end
 movename2=movetbl[move2]
 if movename2==nil then movename2="none" end
 movename3=movetbl[move3]
 if movename3==nil then movename3="none" end
 movename4=movetbl[move4]
 if movename4==nil then movename4="none" end
 
 holditemname=itemtbl[holditem]
 if holditemname==nil then holditemname="none" end

 movecolor1=colortbl[move1]
 if movecolor1=="nor" then movecolor1=nor end
 if movecolor1=="fire" then movecolor1=fire end
 if movecolor1=="wat" then movecolor1=wat end
 if movecolor1=="gra" then movecolor1=gra end
 if movecolor1=="ele" then movecolor1=ele end
 if movecolor1=="ice" then movecolor1=ice end
 if movecolor1=="fig" then movecolor1=fig end
 if movecolor1=="poi" then movecolor1=poi end
 if movecolor1=="gro" then movecolor1=gro end
 if movecolor1=="fly" then movecolor1=fly end
 if movecolor1=="psy" then movecolor1=psy end
 if movecolor1=="bug" then movecolor1=bug end
 if movecolor1=="roc" then movecolor1=roc end
 if movecolor1=="gho" then movecolor1=gho end
 if movecolor1=="dra" then movecolor1=dra end
 if movecolor1=="dar" then movecolor1=dar end
 if movecolor1=="ste" then movecolor1=ste end
 movecolor2=colortbl[move2]
 if movecolor2=="nor" then movecolor2=nor end
 if movecolor2=="fire" then movecolor2=fire end
 if movecolor2=="wat" then movecolor2=wat end
 if movecolor2=="gra" then movecolor2=gra end
 if movecolor2=="ele" then movecolor2=ele end
 if movecolor2=="ice" then movecolor2=ice end
 if movecolor2=="fig" then movecolor2=fig end
 if movecolor2=="poi" then movecolor2=poi end
 if movecolor2=="gro" then movecolor2=gro end
 if movecolor2=="fly" then movecolor2=fly end
 if movecolor2=="psy" then movecolor2=psy end
 if movecolor2=="bug" then movecolor2=bug end
 if movecolor2=="roc" then movecolor2=roc end
 if movecolor2=="gho" then movecolor2=gho end
 if movecolor2=="dra" then movecolor2=dra end
 if movecolor2=="dar" then movecolor2=dar end
 if movecolor2=="ste" then movecolor2=ste end
 movecolor3=colortbl[move3]
 if movecolor3=="nor" then movecolor3=nor end
 if movecolor3=="fire" then movecolor3=fire end
 if movecolor3=="wat" then movecolor3=wat end
 if movecolor3=="gra" then movecolor3=gra end
 if movecolor3=="ele" then movecolor3=ele end
 if movecolor3=="ice" then movecolor3=ice end
 if movecolor3=="fig" then movecolor3=fig end
 if movecolor3=="poi" then movecolor3=poi end
 if movecolor3=="gro" then movecolor3=gro end
 if movecolor3=="fly" then movecolor3=fly end
 if movecolor3=="psy" then movecolor3=psy end
 if movecolor3=="bug" then movecolor3=bug end
 if movecolor3=="roc" then movecolor3=roc end
 if movecolor3=="gho" then movecolor3=gho end
 if movecolor3=="dra" then movecolor3=dra end
 if movecolor3=="dar" then movecolor3=dar end
 if movecolor3=="ste" then movecolor3=ste end
 movecolor4=colortbl[move4]
 if movecolor4=="nor" then movecolor4=nor end
 if movecolor4=="fire" then movecolor4=fire end
 if movecolor4=="wat" then movecolor4=wat end
 if movecolor4=="gra" then movecolor4=gra end
 if movecolor4=="ele" then movecolor4=ele end
 if movecolor4=="ice" then movecolor4=ice end
 if movecolor4=="fig" then movecolor4=fig end
 if movecolor4=="poi" then movecolor4=poi end
 if movecolor4=="gro" then movecolor4=gro end
 if movecolor4=="fly" then movecolor4=fly end
 if movecolor4=="psy" then movecolor4=psy end
 if movecolor4=="bug" then movecolor4=bug end
 if movecolor4=="roc" then movecolor4=roc end
 if movecolor4=="gho" then movecolor4=gho end
 if movecolor4=="dra" then movecolor4=dra end
 if movecolor4=="dar" then movecolor4=dar end
 if movecolor4=="ste" then movecolor4=ste end	

 gui.text(xfix2-65, yfix2, "1: "..movename1, movecolor1)
 gui.text(xfix2+35, yfix2, "2: "..movename2, movecolor2)
 gui.text(xfix2-65, yfix2+10, "3: "..movename3, movecolor3)
 gui.text(xfix2+35, yfix2+10, "4: "..movename4, movecolor4)
 
 gui.text(xfix2+0, yfix2, "PP: "..pp1)
 gui.text(xfix2+100, yfix2, "PP: "..pp2)
 gui.text(xfix2+0, yfix2+10, "PP: "..pp3)
 gui.text(xfix2+100, yfix2+10, "PP: "..pp4)
 gui.text(xfix2+0, yfix2+20,"Power: "..typeorder[hidpowtype+1].." "..hidpowbase)

	if holditemname=="none" then
 gui.text(xfix2+0, yfix2+30,"Item : "..holditemname)
	else 
 gui.text(xfix2+0, yfix2+30,"Item : "..holditemname, "yellow")
	end
 
 gui.text(xfix2+85, yfix2+20,"Pokerus: "..pokerus)

--gui.text(xfix2, yfix2+70, "Pokerus remain "..mbyte(start+85))
 
 
 if status==3 then
    i=0
    cur=memory.readdword(rng[game])
    test=last
    while bit.tohex(cur)~=bit.tohex(test) and i<=100 do
     test=mult32(test,0x41C64E6D) + 0x6073
     i=i+1
    end
    gui.text(120,20,"Last RNG value: "..bit.tohex(last))
    last=cur
    gui.text(120,0,"Current RNG value: "..bit.tohex(cur))
    if i<=100 then
     gui.text(120,10,"RNG distance since last: "..i)
    else
     gui.text(120,10,"RNG distance since last: >100")
    end
    

    
    
    --math
    indexfind=startvalue
    index=0
    for j=0,31,1 do
     if getbits(cur,j,1)~=getbits(indexfind,j,1) then
      indexfind=mult32(indexfind,multspa[j+1])+multspb[j+1]
      index=index+bit.lshift(1,j)
      if j==31 then
       index=index+0x100000000
      end
     end
    end
    gui.text(120,30,index)
    
    
	if substatus[3]>=5 and substatus[3]<=8 then
	 modd=2
	else
	 modd=3
	end
	
    if i>modd and i<=100 then
	 gui.box(3,30,17,44, "red")
	 gui.box(5,32,15,42, "black")
    end
	
	if substatus[3]%4==1 then
	   gui.text(10,45, "Critical Hit/Max Damage")
	elseif substatus[3]%4==2 then
       gui.text(10,45, "Move Miss (95%)")
	elseif substatus[3]%4==3 then
       gui.text(10,45, "Move Miss (90%)")
	else
       gui.text(10,45, "Quick Claw")
	end
	   
	  
    drawarrow(3,52, "#FF0000FF")
    test=cur
    -- i row j column
    for i=0,13,1 do
     for j=0,17,1 do
      if j%modd==1 then
       clr="#C0C0C0FF"
      else
       clr="#808080FF"
      end
      randvalue=gettop(test)
      if substatus[3]%4==1 then
       if randvalue%16==0 then
        test2=test
        for k=1,7,1 do
         test2=mult32(test2,0x41C64E6D) + 0x6073
        end
		clr={r=255, g=0x10*(gettop(test2)%16), b=0, a=255}
       end
      end
	  
	  if substatus[3]%4==2 then
	   if randvalue%100>=95 then
	    clr="#0000FFFF"
	   end
	  end
	  
	  if substatus[3]%4==3 then
	   if randvalue%100>=90 then
	    clr="#000080FF"
	   end
	  end

	  if substatus[3]%4==0 then
	   --if randvalue<0x3333 then
           if randvalue%512==62 then
	    clr="#00FF00FF"
	   end
	  end	  
	  
      drawsquare(2+4*j,54+4*i, clr)
    

      test=mult32(test,0x41C64E6D) + 0x6073
     end
    end
    
    
    
 end

gui.text(0,0,emu.framecount())
    
--*********
end
gui.register(fn)
