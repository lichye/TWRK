

#include <stdio.h>

#define NOOP_INST 0x00000013

static int cycle_count = 0;
static FILE* ppfile_MT = NULL;
static FILE* ppfile_ROB = NULL;
static FILE* ppfile_CDB = NULL;
static FILE* ppfile_RS = NULL;
static FILE* ppfile_AT = NULL;
static FILE* ppfile_FE = NULL;
static FILE* ppfile_FU = NULL;
static FILE* ppfile_FL = NULL;
static FILE* ppfile_PP = NULL;
static FILE* ppfile_RT = NULL;
static FILE* ppfile_PR = NULL;
static FILE* ppfile_MEM = NULL;
static FILE* ppfile_LSQ = NULL;
static FILE* ppfile_CM = NULL;
void next_cycle()
{
  cycle_count++;
}

void print_ROB_NC()
{
  if (ppfile_ROB == NULL)
    ppfile_ROB = fopen("visual_debugger/rob.out", "w");
  
  fprintf(ppfile_ROB,"cycles %d",cycle_count);
}

void print_ROB_ENTRY(int valid,int T,int T_old,int complete,int R_old)
{
  // how to print out inst is the  most diffcult thin
 // char* str;
  // switch (opcode) {
  // case 0x37: str = "lui"; break;
  // case 0x17: str = "auipc"; break;
  // case 0x6f: str = "jal"; break;
  // case 0x67: str = "jalr"; break;
  // case 0x63: str = "branch";break;
  // case 0x03: str = "load"; break;
  // case 0x23: str = "store"; break;
  // case 0x13: str = "imm_alu"; break;
  // case 0b101: str = "srli/srai"; break;
  // case 0x33: str = "Alu"; break;
  // case 0x0f: str = "fence"; break; // unimplemented, imprecise 
  // case 0x73: str = "wif"; break;
  // default: str = "unknown"; break;
  // }
  fprintf(ppfile_ROB,"%d %d %d %d %d\n",valid,T,T_old,complete,R_old);
}

void print_ROB_HEAD_TAIL(int head,int tail)
{
  fprintf(ppfile_ROB," %d %d\n",head,tail);
}

void print_MT_NC()
{
   if (ppfile_MT == NULL)
    ppfile_MT = fopen("visual_debugger/maptable.out", "w");
  fprintf(ppfile_MT,"cycles %d\n",cycle_count);
}

void print_MT_ENTRY(int num,int entry,int ready)
{
  fprintf(ppfile_MT,"level %d %d %d\n",num,entry,ready);
}

void print_CDB(int cd0_control,int cd0,int cd1_control,int cd1)
{
  if (ppfile_CDB == NULL)
    ppfile_CDB = fopen("visual_debugger/cdb.out", "w");
  fprintf(ppfile_CDB,"cycles %d %d %d %d %d\n",cycle_count,cd0_control,cd0,cd1_control,cd1);
}

void print_RS_NC()
{
  if  (ppfile_RS == NULL)
    ppfile_RS = fopen("visual_debugger/rs.out","w");
  fprintf(ppfile_RS,"cycles %d\n",cycle_count);
}


void print_RS_ENTRY(int valid,int destR,int tag1,int tag1_valid, int tag2, int tag2_valid,int alu_opcode,int rd_mem,int wr_mem,int cond_branch,int uncond_branch,int halt)
{
  //how to print out inst is the  most diffcult thin
  char* str;
  if(rd_mem){
    str = "LW";
    goto out;
  }
  if(wr_mem){
    str = "SW";
    goto out;
  }
  if(cond_branch){
    str = "bnq";
    goto out;
  }
  if(uncond_branch){
    str = "jump";
    goto out;
  }
  if(halt){
    str = "halt";
    goto out;
  }
  switch (alu_opcode)
  {
    case 0: str = "ADD";
          break;
    case 1: str = "SUB";
          break;
    case 2: str = "SLT";
          break;
    case 3: str = "SLTU";
          break;
    case 4: str = "AND";
          break;
    case 5: str = "OR";
          break;
    case 6: str = "XOR";
          break;
    case 7: str = "SLL";
          break;
    case 8: str = "SRL";
          break;
    case 9: str = "SRA";
          break;
    case 10: str = "MUL";
          break;
    case 11: str = "MULH";
          break;
    case 12: str = "MULHSU";
          break;
    case 13: str = "MULHU";
          break;
    case 14: str = "DIV";
          break;
    case 15: str = "DIVU";
          break;
    case 16: str = "REM";
          break;
    case 17: str = "REMU";
          break;
    default: str = "UNKNOW";
      break;
  }
  out:fprintf(ppfile_RS,"%s %d %d %d %d %d %d \n",str,valid,destR,tag1,tag1_valid,tag2,tag2_valid);
}


void print_AT_NC()
{
  if ( ppfile_AT == NULL)
    ppfile_AT  = fopen("visual_debugger/at.out","w");
  fprintf(ppfile_AT,"cycles %d\n",cycle_count);
}

void print_AT_ENTRY(int num,int entry)
{
  fprintf(ppfile_AT,"level %d %d\n",num,entry);
}

void print_Fetch_NC()
{
  if ( ppfile_FE == NULL )
    ppfile_FE = fopen("visual_debugger/fetch.out","w");
  fprintf(ppfile_FE,"cycles %d\n",cycle_count);
}

void print_Fecth_ENTRY(int inst,int destR,int tag1,int tag2,int pc)
{
  int opcode, funct3, funct7, funct12;
  int I_IMM = inst >>20;
  char *str;
  
  if(inst==NOOP_INST)
    str = "nop";
  else {
    opcode = inst & 0x7f;
    funct3 = (inst>>12) & 0x7;
    funct7 = inst>>25;
    funct12 = inst>>20; // for system instructions
    // See the RV32I base instruction set table
    switch (opcode) {
    case 0x37: str = "lui"; break;
    case 0x17: str = "auipc"; break;
    case 0x6f: str = "jal"; break;
    case 0x67: str = "jalr"; break;
    case 0x63: // branch
      switch (funct3) {
      case 0b000: str = "beq"; break;
      case 0b001: str = "bne"; break;
      case 0b100: str = "blt"; break;
      case 0b101: str = "bge"; break;
      case 0b110: str = "bltu"; break;
      case 0b111: str = "bgeu"; break;
      default: str = "invalid"; break;
      }
      break;
    case 0x03: // load
      switch (funct3) {
      case 0b000: str = "lb"; break;
      case 0b001: str = "lh"; break;
      case 0b010: str = "lw"; break;
      case 0b100: str = "lbu"; break;
      case 0b101: str = "lhu"; break;
      default: str = "invalid"; break;
      }
      break;
    case 0x23: // store
      switch (funct3) {
      case 0b000: str = "sb"; break;
      case 0b001: str = "sh"; break;
      case 0b010: str = "sw"; break;
      default: str = "invalid"; break;
      }
      break;
    case 0x13: // immediate
      switch (funct3) {
      case 0b000: str = "addi"; break;
      case 0b010: str = "slti"; break;
      case 0b011: str = "sltiu"; break;
      case 0b100: str = "xori"; break;
      case 0b110: str = "ori"; break;
      case 0b111: str = "andi"; break;
      case 0b001:
        if (funct7 == 0x00) str = "slli";
        else str = "invalid";
        break;
      case 0b101:
        if (funct7 == 0x00) str = "srli";
        else if (funct7 == 0x20) str = "srai";
        else str = "invalid";
        break;
      }
      break;
    case 0x33: // arithmetic
      switch (funct7 << 4 | funct3) {
      case 0x000: str = "add"; break;
      case 0x200: str = "sub"; break;
      case 0x001: str = "sll"; break;
      case 0x002: str = "slt"; break;
      case 0x003: str = "sltu"; break;
      case 0x004: str = "xor"; break;
      case 0x005: str = "srl"; break;
      case 0x205: str = "sra"; break;
      case 0x006: str = "or"; break;
      case 0x007: str = "and"; break;
      // M extension
      case 0x010: str = "mul"; break;
      case 0x011: str = "mulh"; break;
      case 0x012: str = "mulhsu"; break;
      case 0x013: str = "mulhu"; break;
      case 0x014: str = "div"; break;  // unimplemented
      case 0x015: str = "divu"; break; // unimplemented
      case 0x016: str = "rem"; break;  // unimplemented
      case 0x017: str = "remu"; break; // unimplemented
      default: str = "invalid"; break;
      }
      break;
    case 0x0f: str = "fence"; break; // unimplemented, imprecise 
    case 0x73:
      switch (funct3) {
      case 0b000:
        // unimplemented, somewhat inaccurate :(
        switch (funct12) {
        case 0x000: str = "ecall"; break;
        case 0x001: str = "ebreak"; break;
        case 0x105: str = "wfi"; break; // we just mostly care about this
        default: str = "system"; break;
        }
        break;
      case 0b001: str = "csrrw"; break;
      case 0b010: str = "csrrs"; break;
      case 0b011: str = "csrrc"; break;
      case 0b101: str = "csrrwi"; break;
      case 0b110: str = "csrrsi"; break;
      case 0b111: str = "csrrci"; break;
      default: str = "invalid"; break;
      }
      break;
    default: str = "invalid"; break;
    }
  }


  if (ppfile_FE != NULL)
    fprintf(ppfile_FE, "%s %d %d %d %x %d %x \n", str,destR,tag1,tag2,pc,I_IMM,pc);
}

void print_FU_NC()
{
  if ( ppfile_FU == NULL)
    ppfile_FU = fopen("visual_debugger/fu.out","w");
  fprintf(ppfile_FU,"cycles %d\n",cycle_count);
}

void print_FU_ENTRY(int func,int destR,int opa,int opb,int destRout,int result,int done)
{
  char * str;
  switch (func)
  {
  case 0: str = "ADD";
          break;
  case 1: str = "SUB";
          break;
  case 2: str = "SLT";
          break;
  case 3: str = "SLTU";
          break;
  case 4: str = "AND";
          break;
  case 5: str = "OR";
          break;
  case 6: str = "XOR";
          break;
  case 7: str = "SLL";
          break;
  case 8: str = "SRL";
          break;
  case 9: str = "SRA";
          break;
  case 10: str = "MUL";
          break;
  case 11: str = "MULH";
          break;
  case 12: str = "MULHSU";
          break;
  case 13: str = "MULHU";
          break;
  case 14: str = "DIV";
          break;
  case 15: str = "DIVU";
          break;
  case 16: str = "REM";
          break;
  case 17: str = "REMU";
          break;
  default: str = "UNKNOW";
    break;
  }

  fprintf(ppfile_FU,"%s %d %d %d %d %d %d\n",str,destR,opa,opb,destRout,result,done);
}

void print_FL_NC()
{
  if ( ppfile_FL == NULL)
    ppfile_FL = fopen("visual_debugger/fl.out","w");
  fprintf(ppfile_FL,"cycles %d\n",cycle_count);
}

void print_FL_ENTRY(int phy,int valid)
{
  fprintf(ppfile_FL,"%d %d\n",phy,valid);
}

void print_PP_NC()
{
  if ( ppfile_PP == NULL)
    ppfile_PP = fopen("visual_debugger/pipeline.out","w");
  fprintf(ppfile_PP,"cycles %d\n",cycle_count);
}

void print_PP_ENTRY(int dispatch_en,int ex_en, int complete_debug,int retire_debug)
{
  fprintf(ppfile_PP,"%d %d %d %d\n",dispatch_en,ex_en,complete_debug,retire_debug);
}

void print_RETIRE_NC()
{
  if ( ppfile_RT == NULL)
    ppfile_RT = fopen("visual_debugger/retire.out","w");
  fprintf(ppfile_RT,"cycles %d\n",cycle_count);
}

void print_RETIRE_ENTRY(int wr_mem,int rd_mem,int conb,int unconb,int halt)
{
  fprintf(ppfile_RT,"%d %d %d %d %d\n",wr_mem,rd_mem,conb,unconb,halt);
}

void print_PR_NC()
{
  if  (ppfile_PR == NULL)
    ppfile_PR = fopen("visual_debugger/fr.out","w");
  fprintf(ppfile_PR,"cycles %d\n",cycle_count);
}

void print_PR_ENTRY(int index,int value)
{
  fprintf(ppfile_PR,"%d %d\n",index,value);
}

void print_MEM_NC()
{
  if(ppfile_MEM == NULL)
    ppfile_MEM = fopen("visual_debugger/mem.out","w");
  fprintf(ppfile_MEM,"cycles %d\n",cycle_count);
}

void print_MEM_REQUEST(int cmd,int addr,int data_out,int size,int res,int data_in, int tag)
{
  char* str="NONE";
  if(cmd==1)
    str = "LW";
  if(cmd==2)
    str = "SW";
  
  fprintf(ppfile_MEM,"%s %d %d %d %d\n",str,addr,data_out,data_in,tag);
}

void print_LSQ_NC(int head)
{
  if(ppfile_LSQ == NULL)
    ppfile_LSQ = fopen("visual_debugger/lsq.out","w");
  fprintf(ppfile_LSQ,"cycles %d %d\n",cycle_count,head); 
}

void print_LSQ_ENTRY(int opcode_valid,int opcode,int address_valid,int address,int content_valid, int content, int dest_tag)
{
  fprintf(ppfile_LSQ,"%d %d %d %d %d %d %d \n",opcode_valid,opcode,address_valid,address,content_valid,content,dest_tag);
}

void print_CM_NC()
{
  if(ppfile_CM = NULL)
      ppfile_CM = fopen("visual_debugger/cmt.out","w");
  fprintf(ppfile_CM,"cycles\n");
}

void print_CM_ENTRY(int valid,int reg,int data,int pc)
{
  fprintf(ppfile_CM,"%d %d %h %h \n",valid,reg,data,pc);
}