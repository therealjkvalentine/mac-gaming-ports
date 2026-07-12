#!/usr/bin/env python3
# Build Interstate '76 "Option 1 (Sim-Combat, analog)" Steam Deck controller config
# from the neptune WASD template. Uses a real VDF text parser -> tree -> serialize so
# structure stays valid. Left stick -> analog gamepad; right stick -> glance arrows;
# triggers/bumpers/faces/dpad/trackpad rebound; trackpad-click + A -> mouse-left.
import re, sys

SRC="/private/tmp/claude-501/-Users-jamesvalentine-Documents-Repositories-mac-gaming-ports/b50977da-e002-449c-b723-ede354c6d910/scratchpad/ref_neptune_wasd.vdf"
OUT="/private/tmp/claude-501/-Users-jamesvalentine-Documents-Repositories-mac-gaming-ports/b50977da-e002-449c-b723-ede354c6d910/scratchpad/i76-deck-bundle/config/controller_neptune_i76_analog.vdf"

# ---- tiny VDF (text KeyValues) parser -> nested list-of-[k,v] (v is str or list) ----
tok=re.compile(r'"((?:[^"\\]|\\.)*)"|(\{)|(\})')
def parse(s):
    pos=0;
    def rd(i):
        out=[]
        while i<len(s):
            m=tok.search(s,i)
            if not m: break
            i=m.end()
            if m.group(2)=='{':  # shouldn't hit here
                pass
            elif m.group(3)=='}':
                return out,i
            else:
                key=m.group(1)
                m2=tok.search(s,i); i=m2.end()
                if m2.group(2)=='{':
                    val,i=rd(i); out.append([key,val])
                else:
                    out.append([key,m2.group(1)])
        return out,i
    root,_=rd(0); return root

def ser(node,d=0):
    t="\t"*d; out=[]
    for k,v in node:
        if isinstance(v,list):
            out.append(f'{t}"{k}"\n{t}{{\n{ser(v,d+1)}{t}}}\n')
        else:
            out.append(f'{t}"{k}"\t\t"{v}"\n')
    return "".join(out)

def find(node,key):
    for kv in node:
        if kv[0]==key: return kv[1]
    return None
def findall(node,key):
    return [kv[1] for kv in node if kv[0]==key]

txt=open(SRC,encoding="utf-8-sig").read()
root=parse(txt)
cm=find(root,"controller_mappings")

# helper: a simple key_press binding block
def kb(binding):
    return [["activators",[["Full_Press",[["bindings",[["binding",binding]]]]]]]]

# groups by id
groups={find(g,"id"):g for g in findall(cm,"group")}

def set_input(gid,inp,binding):
    g=groups[gid]; inputs=find(g,"inputs")
    for kv in inputs:
        if kv[0]==inp:
            kv[1]=kb(binding); return
    inputs.append([inp,kb(binding)])

def set_mode(gid,mode):
    for kv in groups[gid]:
        if kv[0]=="mode": kv[1]=mode; return

def replace_inputs(gid,pairs):
    g=groups[gid]
    for kv in g:
        if kv[0]=="inputs":
            kv[1]=[[inp,kb(b)] for inp,b in pairs]; return

# ---- Group 3 = LEFT STICK -> analog gamepad (joystick_move). Movement auto-outputs the
#      XInput left stick (analog). Click -> handbrake (C). ----
set_mode("3","joystick_move")
replace_inputs("3",[("click","key_press C, Handbrake")])
# ensure a sane deadzone setting exists
if not find(groups["3"],"settings"):
    groups["3"].append(["settings",[["deadzone_inner_radius","7199"]]])

# ---- Group 9 = RIGHT STICK -> glance arrows (dpad mode) ----
set_mode("9","dpad")
replace_inputs("9",[("dpad_north","key_press UP_ARROW, Glance up"),
                    ("dpad_south","key_press DOWN_ARROW, Glance down"),
                    ("dpad_east","key_press RIGHT_ARROW, Glance right"),
                    ("dpad_west","key_press LEFT_ARROW, Glance left"),
                    ("click","key_press U, Untarget")])

# ---- Group 0 = ABXY ----
set_input("0","button_a","mouse_button LEFT, Select / skip cutscene")
set_input("0","button_b","key_press ESCAPE, Back / pause")
set_input("0","button_x","key_press X, Reverse")
set_input("0","button_y","key_press V, Change view")

# ---- Group 4 = LEFT TRIGGER (L2) -> fire-all/linked ; Group 5 = RIGHT TRIGGER (R2) -> fire ----
replace_inputs("4",[("edge","key_press F, Fire-all / link")])
replace_inputs("5",[("edge","key_press SPACE, Fire weapon")])

# ---- Group 7 = D-PAD -> engine/lights/horn/binoculars ----
replace_inputs("7",[("dpad_north","key_press I, Start engine"),
                    ("dpad_south","key_press H, Headlights"),
                    ("dpad_west","key_press G, Horn"),
                    ("dpad_east","key_press B, Binoculars")])

# ---- Group 1 = LEFT TRACKPAD -> systems radial (map/notepad/radar) ----
replace_inputs("1",[("dpad_north","key_press M, Map"),
                    ("dpad_south","key_press N, Notepad"),
                    ("dpad_west","key_press R, Radar range"),
                    ("dpad_east","key_press K, Radar camera"),
                    ("click","key_press Y, Next target")])

# ---- Group 2 = RIGHT TRACKPAD -> mouse; make its click a real left-click ----
for kv in find(groups["2"],"inputs"):
    if kv[0]=="click": kv[1]=kb("mouse_button LEFT, Click")

# ---- Group 6 = SWITCHES: bumpers, menu/select, rear buttons ----
set_input("6","left_bumper","key_press T, Target nearest")
set_input("6","right_bumper","key_press TAB, Change weapon")
set_input("6","button_menu","key_press ESCAPE, Pause")
set_input("6","button_escape","key_press M, Map")
set_input("6","button_back_left","key_press Q, Front target")     # L4
set_input("6","button_back_right","key_press Y, Next target")     # R4
set_input("6","button_back_left_upper","key_press PAGE_UP, Zoom out")   # L5
set_input("6","button_back_right_upper","key_press PAGE_DOWN, Zoom in") # R5

# ---- titles ----
for kv in cm:
    if kv[0]=="title": kv[1]="Interstate 76 - Option 1 (Sim-Combat, analog)"
    if kv[0]=="game": kv[1]="Interstate 76"

open(OUT,"w",encoding="utf-8").write('"controller_mappings"\n{\n'+ser(cm,1)+'}\n')
# validate braces + report bindings
o=open(OUT).read()
print("braces:",o.count("{"),o.count("}"),"OK" if o.count("{")==o.count("}") else "MISMATCH")
print("left stick mode:", find(groups["3"],"mode"))
print("right stick mode:", find(groups["9"],"mode"))
import collections
b=re.findall(r'"binding"\s+"([^"]+)"',o)
print(f"{len(b)} bindings:")
for x in b: print("   ",x)
