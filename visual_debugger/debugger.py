from ast import Return
from distutils.cygwinccompiler import CygwinCCompiler
from itertools import cycle
from sre_parse import FLAGS
import tkinter as tk
from tkinter.ttk import Treeview
from unicodedata import numeric

cycle = 0
Last_cycle = 0
cycle_Text='Cycle is 0'
Maptable_Text=''

def ThousandCycle():
    global cycle
    global Last_cycle
    Last_cycle = cycle
    cycle= cycle+1000;
    global cycle_Label
    cycle_Text = "Cycle is " + str(cycle)
    cycle_Label.config(text=cycle_Text)

def HundredCycle():
    global cycle
    global Last_cycle
    Last_cycle = cycle
    cycle= cycle+100;
    global cycle_Label
    cycle_Text = "Cycle is " + str(cycle)
    cycle_Label.config(text=cycle_Text)

def lessHunCycle():
    global cycle
    global Last_cycle
    Last_cycle = cycle
    cycle= cycle-100;
    global cycle_Label
    cycle_Text = "Cycle is " + str(cycle)
    cycle_Label.config(text=cycle_Text)

def addCycle():
    global cycle
    global cycle_Label
    global Last_cycle
    Last_cycle = cycle
    cycle = cycle +1
    cycle_Text = "Cycle is " + str(cycle)
    cycle_Label.config(text=cycle_Text)
    
def decreaseCycle():
    global cycle
    global cycle_Label
    global Last_cycle
    Last_cycle = cycle
    if(cycle>0):
        cycle = cycle - 1
    cycle_Text = "Cycle is " + str(cycle)
    cycle_Label.config(text=cycle_Text)

def backCycle():
    global cycle
    global Last_cycle
    cycle = Last_cycle
    cycle_Text = "Cycle is " + str(cycle)
    cycle_Label.config(text=cycle_Text)

def DecadeCycle():
    global cycle
    global cycle_Label
    global Last_cycle
    Last_cycle = cycle
    if(cycle>0):
        cycle = cycle + 10
    cycle_Text = "Cycle is " + str(cycle)
    cycle_Label.config(text=cycle_Text)

def onKeyPress(event):
    if(event.char=='q'):
        exit()
    if(event.char=='n'):
        addCycle()
    if(event.char=='l'):
        decreaseCycle()
    if(event.char=="t"):
        ThousandCycle()
    if(event.char=="h"):
        HundredCycle()
    if(event.char=="g"):
        lessHunCycle()
    if(event.char=='b'):
        backCycle()
    if(event.char=='d'):
        DecadeCycle()

    readmaptable()
    readRob()
    readCDB()
    readRS()
    readAT()
    readFetch()
    readFu()
    readFL()
    readPP()
    #readRT()
    readPR()
    #readLSQ()
    
def readmaptable():
    global Maptable_Label
    global cycle
    Maptable_Text='Map table is NULL signal!!!'
    f=open("visual_debugger/maptable.out","r")
    f_out=open("visual_debugger/debugger.log","w")
    flag = 0;
    for entry in f:
        line = entry.split(' ')
        if(line[0]=='cycles'):
          #  print("we are cycle check"+line[1])
            
            if(int(line[1])==cycle):
                flag = 1
               # print(line[1])
                Maptable_Text="Map Table\n"
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag):
            Maptable_Text=Maptable_Text+" f"+str(line[1])+" PR#"+str(line[2])
            if(int(line[3])==1):
                Maptable_Text=Maptable_Text+"+\n"
            else:
                Maptable_Text=Maptable_Text+"\n"
    Maptable_Label.config(text=Maptable_Text)
    f.close()

def readRob():
    global Rob
    global cycle
    Rob_Text='Rob is NULL signal!!!'
    robfile=open("visual_debugger/rob.out","r")
    #print("we are going to load rob\n")
    flag = 0;
    for i,entry in enumerate(robfile):
        line = entry.split(' ')
        if(line[0]=='cycles'):
            #print("we are in ROB check"+line[1])
            if(int(line[1])==cycle):
                flag = 1
                #print(line[1])
                Rob_Text="Rob\n"
                Rob_Text= Rob_Text + "h  t  valid  T  Told Rold  C\n"
                head = int(line[2])
                tail = int(line[3])
                base_line = i
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag):
           # print(i,head,tail,base_line)
            if(int(line[0])==1 or int(line[3])==1):
                if(i-base_line-1==head):
                    Rob_Text=Rob_Text+"h "
                else:
                    Rob_Text=Rob_Text+"  "
            
                if(i-base_line-1==tail):
                    Rob_Text=Rob_Text+" t "
                else:
                    Rob_Text=Rob_Text+"   "

                Rob_Text=Rob_Text+str(line[0])+"  PR#"+str(line[1])+"  PR#"+str(line[2])+ " f"+str(line[4][0])
                if(int(line[3])==1):
                    Rob_Text=Rob_Text+"  +\n"
                else:
                    Rob_Text=Rob_Text+"   \n"
    Rob.config(text=Rob_Text)
    robfile.close()

def readCDB():
    global CDB
    global cycle
    CDB_Text = 'CDB is NULL signal'
    CDB_file = open("visual_debugger/cdb.out","r")
    for entry in CDB_file:
        line = entry.split(' ')
        if(int(line[1])==cycle):
            #print("we are going to rewrite CDB")
            CDB_Text="CDB\n"
            if(int(line[2])):
                CDB_Text=CDB_Text+"PR#"+line[3]
            if(int(line[4])):
                CDB_Text=CDB_Text+"PR#"+line[5]
    CDB.config(text=CDB_Text)
    CDB_file.close()

def readRS():
    global RS
    global cycle
    RS_Text = 'RS is empty'
    RS_file = open("visual_debugger/rs.out","r")
    for entry in RS_file:
        line = entry.split(' ')
        if(line[0]=='cycles'):
            #print("we are in ROB check"+line[1])
            if(int(line[1])==cycle):
                flag = 1
                #print(line[1])
                RS_Text="RS\n"
                RS_Text= RS_Text + "opcode TagR  Tag1  Tag2\n"
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag):
            opcode = line[0]
            valid = line[1]
            if(int(valid)==0):
                continue;
            destR = line[2]
            tag1 = line[3]
            tag1_valid = line[4]
            tag2 = line[5]
            tag2_valid = line[6]

            RS_Text = RS_Text +opcode + " PR#"+destR+" PR#"+tag1
            if(int(tag1_valid)==1):
               RS_Text = RS_Text + "+"
            else:
                RS_Text = RS_Text + " "
            RS_Text = RS_Text + " PR#"+tag2
            if(int(tag2_valid[0])==1):
                RS_Text = RS_Text  + "+"
            else:
                RS_Text = RS_Text + " "
            RS_Text = RS_Text + "\n"

    RS.config(text=RS_Text)
    RS_file.close()
        
def readAT():
    global AT
    global cycle
    AT_Text='Map table is NULL signal!!!'
    f=open("visual_debugger/at.out","r")
    f_out=open("visual_debugger/debugger.log","w")
    flag = 0;
    for entry in f:
        line = entry.split(' ')
        if(line[0]=='cycles'):
          #  print("we are cycle check"+line[1])
            
            if(int(line[1])==cycle):
                flag = 1
               # print(line[1])
                AT_Text="Architure Table\n"
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag):
            AT_Text = AT_Text + " f"+str(line[1])+" PR#"+str(line[2])
    AT.config(text=AT_Text)
    f.close()

def readFetch():
    global Fetch
    global cycle
    Fetch_Text = "Fetch now is empty!!!"
    f=open("visual_debugger/fetch.out","r")
    flag = 0;
    for entry in f:
        line = entry.split(' ')
        if(line[0]=='cycles'):
          #  print("we are cycle check"+line[1])
            
            if(int(line[1])==cycle):
                flag = 1
               # print(line[1])
                Fetch_Text="Fetch content:\n"
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag):
            #then we start to read the content
            Fetch_Text = Fetch_Text + "PC "+line[4]+": "
            if(line[0]=='nop'):
                Fetch_Text = Fetch_Text + "nop\n"
                continue
            if(line[0][-1]=='i'):
                Fetch_Text = Fetch_Text+line[0]+" "+"f"+line[1]+' f'+line[2]+" "
                if(line[5][0]=="-"):
                    Fetch_Text=Fetch_Text+line[5][0]+line[5][1]+'\n';
                else:
                    Fetch_Text=Fetch_Text+line[5][0]+' \n'
            else:
                if(line[0]=='sw'):
                    Fetch_Text = Fetch_Text+ line[0] + " f" + line[2]+ " [f"+line[3]+"+"+line[5][0]+']\n'
                    continue
                if(line[0]=='lw'):
                    Fetch_Text = Fetch_Text+ line[0] + " f" + line[1]+ " [f"+line[3]+"+"+line[5][0]+']\n'
                    continue
                Fetch_Text = Fetch_Text+line[0]+" f"+line[1]+' f'+line[2]+' f'+line[3]+' \n'         
    Fetch.config(text=Fetch_Text)
    f.close()


def readFu():
    global Fu
    global cycle
    Fu_Text = "Fetch now is empty!!!"
    f=open("visual_debugger/fu.out","r")
    flag = 0;
    for entry in f:
        line = entry.split(' ')
        if(line[0]=='cycles'):
          #  print("we are cycle check"+line[1])
            
            if(int(line[1])==cycle):
                flag = 1
               # print(line[1])
                Fu_Text="FU content:\n"
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag):
            Fu_Text = Fu_Text +"input:\n destR: "
            Fu_Text = Fu_Text +" PR#"+line[1]+" opa:"+line[2]+" opb:"+line[3]+"\n"
            Fu_Text = Fu_Text +"output:\n destR: PR#"+line[4]+" result:"+line[5]+"\n"
    Fu.config(text=Fu_Text)
    f.close()

def readFL():
    global Fl
    global cycle
    Fl_Text = "Fetch now is empty!!!"
    f=open("visual_debugger/fl.out","r")
    flag = 0;
    for entry in f:
        line = entry.split(' ')
        if(line[0]=='cycles'):
          #  print("we are cycle check"+line[1])
            
            if(int(line[1])==cycle):
                flag = 1
               # print(line[1])
                Fl_Text="Freelist:\n"
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag&int(line[1][0])):
            Fl_Text = Fl_Text +" PR#"+line[0]+"\n"
    Fl.config(text=Fl_Text)
    f.close()

def readPP():
    global PP
    global cycle
    PP_Text = "no data for pipeline status"
    f=open("visual_debugger/pipeline.out","r")
    flag = 0;
    for entry in f:
        line = entry.split(' ')
        if(line[0]=='cycles'):
          #  print("we are cycle check"+line[1])
            
            if(int(line[1])==cycle):
                flag = 1
               # print(line[1])
                PP_Text="Pipeline Status:\n"
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag):
            PP_Text = PP_Text +"D:"+line[0]+ " EX:"+line[1]+" C:"+line[2]+" R:"+line[3][0]+"\n"
    PP.config(text=PP_Text)
    f.close()

def readRT():
    global RT
    global cycle
    RT_Text = "no data for retire status"
    f=open("visual_debugger/retire.out","r")
    flag = 0;
    for entry in f:
        line = entry.split(' ')
        if(line[0]=='cycles'):
          #  print("we are cycle check"+line[1])
            
            if(int(line[1])==cycle):
                flag = 1
               # print(line[1])
                RT_Text="Retire Status:\n"
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag):
            RT_Text = RT_Text +"wr_mem:"+line[0]+ " rd_mem:"+line[1]+" branch:"+line[2]+" jump:"+line[3]+" halt:"+line[4]+"\n";
    RT.config(text=RT_Text)
    f.close()

def readPR():
    global PR1
    global PR2
    global cycle
    PR_Text1 = "no data for physical register"
    f=open("visual_debugger/fr.out","r")
    PR_Text2=" "
    flag = 0;
    for entry in f:
        line = entry.split(' ')
        if(line[0]=='cycles'):
          #  print("we are cycle check"+line[1])
            
            if(int(line[1])==cycle):
                flag = 1
               # print(line[1])
                PR_Text1="Physcial register:\n"             
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag):
            if(int(line[0])<=31):
                PR_Text1 = PR_Text1 +"PR#"+line[0]+ " "+line[1];
            else:
                PR_Text2 = PR_Text2 +"PR#"+line[0]+ " "+line[1];
    PR1.config(text=PR_Text1)
    PR2.config(text=PR_Text2)
    f.close()

def readLSQ():
    global LSQ
    global cycle
    LSQ_TEXT = "no data for retire status"
    f=open("visual_debugger/lsq.out","r")
    flag = 0;
    for entry in f:
        line = entry.split(' ')
        if(line[0]=='cycles'):
          #  print("we are cycle check"+line[1])
            
            if(int(line[1])==cycle):
                flag = 1
               # print(line[1])
                LSQ_TEXT="LSQ: " + line[2]+'\n';
                continue
            else:
                flag = 0
            
            if(int(line[1])>cycle):
                Return
        if(flag):
            if(int(line[0])):
                if(int(line[1])):
                    LSQ_TEXT = LSQ_TEXT + "SW "
                else:
                    LSQ_TEXT = LSQ_TEXT + "LW "
                if(int(line[3])):
                    LSQ_TEXT = LSQ_TEXT + " Adr:" + line[3];
                else:
                    LSQ_TEXT = LSQ_TEXT + " Adr: UN";
                if(int(line[5])):
                    LSQ_TEXT = LSQ_TEXT + " DATA:" + line[5];
                else:
                    LSQ_TEXT = LSQ_TEXT + " DATA: UN";
                LSQ_TEXT = LSQ_TEXT + " DestR" + line[6]+"\n";
            else:
                LSQ_TEXT = LSQ_TEXT + "NONE"+"\n";
    LSQ.config(text=LSQ_TEXT)
    f.close()

root = tk.Tk()
root.geometry('2048x1080')
root.title('Debugger')
cycle_Label = tk.Label(root, background='black', foreground='white', font=('Comic Sans MS', 40),text=cycle_Text)
cycle_Label.pack(side='top')

Maptable_Label = tk.Label(root, background='black',foreground='white', font=(25),text='')
readmaptable()

Rob = tk.Label(root,background='black',foreground='white',font=(25),text='Rob is empty',justify='left')
readRob()

CDB = tk.Label(root,background='black',foreground='white',font=(25),text='',justify='left')
readCDB()

RS = tk.Label(root,background='black',foreground='white',font=(25),text='',justify='left')
readRS()

AT = tk.Label(root,background='black',foreground='white',font=(25),text='',justify='left')
readAT()

Fetch = tk.Label(root,background='black',foreground='white',font=(25),text='Fetch content',justify='left')
readFetch()

Fu = tk.Label(root,background='black',foreground='white',font=(25),text='Fetch content',justify='left')
readFu()

Fl = tk.Label(root,background='black',foreground='white',font=(25),text='Fetch content',justify='left')
readFL()

PP = tk.Label(root,background='black',foreground='white',font=('', 30),text='Fetch content',justify='left')
readPP()

#RT = tk.Label(root,background='black',foreground='white',font=(25),text='Fetch content',justify='left')
#readRT()

PR1 = tk.Label(root,background='black',foreground='white',font=(25),text='PR_register',justify='left')
PR2 = tk.Label(root,background='black',foreground='white',font=(25),text='PR_register',justify='left')
readPR()

LSQ = tk.Label(root,background='black',foreground='white',font=(25),text='PR_register',justify='left')
#readLSQ()


PP.pack(side='top')
Fetch.pack(side='left')
Rob.pack(side="left")
RS.pack(side='left')
#Fu.pack(side='left')
CDB.pack(side='left')
#RT.pack(side='left')
Maptable_Label.pack(side='left')
AT.pack(side='left')
Fl.pack(side='left')
PR1.pack(side='left')
PR2.pack(side='left')
LSQ.pack(side='top')
root.bind('<KeyPress>', onKeyPress)
root.mainloop()