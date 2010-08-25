#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <string.h>


#define MAX_DATA_BIT 100
#define YES 1
#define NO 0
#define POINT_UNEXIST -15
#define MAXSIZE 100

#ifdef __VERSION_ID__
        static const char version_id[] = __VERSION_ID__;
#else
	        static const char version_id[] = "1.0.0";
#endif

#if defined (__DATE__) && defined (__TIME__)
        static const char server_built[] = __DATE__ " " __TIME__;
#else
                static const char server_built[] = "unknown";
#endif

int EXP_INIT=YES;
int BRACKET_COUNT=0;
char liyx[1024] = {0};
int _index = 0;

int iscalchar(char c);
int is_space(char c);
int isFIRSTallow(char c);
int isallow(char c);
double char_to_double(char DigitString[],int markpot,int markend);
int getexp(double *data,char *oprt);

typedef struct
{
	char oprt_stack[MAXSIZE];
	double data_stack[MAXSIZE];
	char oprt_in,oprt_out,*oprt_curp;
	double data_in,data_out,*data_curp;
}stack;

int PopData(stack *p);
int PushData(stack *p);
int PopOprt(stack *p);
int PushOprt(stack *p);
void clear(stack *p);

int checkgram(int fsitua,int lsitua);
int priority(char cal1,char cal2);
void error(int state);
int calculat(double data1,char oprt,double data2,double *result);
stack STK;

int isoprt( char c)
{
	if (c=='+'||c=='-'||c=='*'||c=='/'||c=='^')
		return 1;
	else
		return 0;
}

int is_space(char c)
{
	if (c==' '||c=='\t'||c=='\v')
		return 1;
	else
		return 0;
}

int isFIRSTallow(char c)
{
	if (c=='.'||c=='-'||c=='('||isdigit(c))
		return 1;
	else
		return 0;
}

int isallowed(char c)
{
	if (c=='.'||isoprt(c)||c=='('||isdigit(c)||c==')')
		return 1;
	else
		return 0;
}

double char_to_double(char data[],int markpot,int markend)
{
	int i;
	double sumz=0,sumf=0;
	if (data[0]!='-'){
		for (i=0;i<markpot;++i)
			sumz=sumz*10+(data[i]-'0');
		for (i=markend-1;i>markpot;--i)
			sumf=sumf*0.1+(data[i]-'0');
		return sumz+sumf*0.1;
	}
	else
	{
		for (i=1;i<markpot;++i)
			sumz=sumz*10+(data[i]-'0');
		for (i=markend-1;i>markpot;--i)
			sumf=sumf*0.1+(data[i]-'0');
		return -(sumz+sumf*0.1);
	}
}

int getexp (double *data,char *oprt)
{ 
	int c,i=0,mrkpot=POINT_UNEXIST;
	char temp[MAX_DATA_BIT];

	while (is_space(c = liyx[_index++]));
	
	if (c=='\n') {*oprt=c;return 8;}
	if (!isallowed(c)) return -1;
	if (EXP_INIT==YES) {
		if(!isFIRSTallow(c)) return -4;
		if(c=='('){++BRACKET_COUNT;*oprt=c;return 6;}
		else{
			temp[i]=c;
			if (c=='.') mrkpot=i;
			++i;
		}
	}
	else {
		if (!isallowed(c)) return -1;
		if (c=='(') {
			++BRACKET_COUNT;
			*oprt=c;
			EXP_INIT=YES;
			return 6;
		}
		if (c==')') {
			--BRACKET_COUNT;
			*oprt=c;
			return 7;
		}
		if (isoprt(c)) {
			*oprt=c;
			return 5;
		}
		else {
			temp[i]=c;
			if (c=='.') mrkpot=i;
			++i;
		}
	}
	while ((isdigit(c=liyx[_index++])||c=='.') && i<MAX_DATA_BIT){
		if (c=='.'&&mrkpot!=POINT_UNEXIST) return -2;
		else{
			temp[i]=c;
			if (c=='.') mrkpot=i;
			++i;
		}
	}

	if (i==1&&!isdigit(temp[0])||i==2&&!isdigit(temp[0])&&!isdigit(temp[1])) {*oprt=c;return -2;}
	if(i==MAX_DATA_BIT&&(isdigit(c)||c=='.')) {*oprt=c;return -3;}
	if (mrkpot==POINT_UNEXIST) mrkpot=i;
	*data=char_to_double (temp,mrkpot,i);
	EXP_INIT=NO;
	if (is_space(c)) while (is_space(c=liyx[_index++]));
	if (c=='\n') {*oprt=c;return 4;}
	if (!isoprt(c)&&c!='('&&c!=')') {*oprt=c;return -1;}
	*oprt=c;
	if (isoprt(c)) return 1;
	
	if (c=='(') {
		++BRACKET_COUNT;
        	EXP_INIT=YES;
        	return 2;
	}
	else
	{
		--BRACKET_COUNT;
		return 3;
	}
}

int priority (char cal1,char cal2)
{
	if (cal1=='\0'||cal1=='('||cal2=='('||cal2=='^'||((cal2=='*'||cal2=='/')&&(cal1=='+'||cal1=='-')))
		return -1;
	else
		return 1;
}

void error (int state)
{
	if (state==-1)
		printf("表达式出现不合法字符!\n");
	else if(state==-2)
	        printf("表达式有不合法数据项!\n");
	else if(state==-3)
		printf("表达式中数据太大了!\n");
	else if(state==-4) 
		printf("表达式有语法错误!\n");  
	else if(state==-5)
		printf("表达式逻辑错误\n除数不能为0!\n");
	else if(state==-6) 
		printf("表达式逻辑错误\n幂运算错误!\n");
	else if(state==-7) 
		printf("栈操作失败,表达式可能太长!\n");
	else if(state==-8)
		printf("表达式的括号不匹配!");
}

int calculat (double data1,char calchar,double data2,double *result)
{
	switch(calchar){
		case '+':*result=data1+data2;return 1;
		case '-':*result=data1-data2;return 1;
		case '*':*result=data1*data2;return 1;
		case '/':if (data2!=0.0) {*result=data1/data2;return 1;}
			else return -5;
		case '^':if (data2>0.0||data1!=0) {*result=pow(data1,data2);return 1;}
			else return -6; /*没有零的零次方*/
	}
}

int checkgram (int fsitua,int lsitua) //返回-20表示表达式结束
{        
	switch (fsitua)
	{
		case 1:case 5:if (lsitua==1||lsitua==2||lsitua==3||lsitua==4||lsitua==6) return 1;
			else return -4;
		case 2: case 6:if (lsitua==1||lsitua==2||lsitua==3||lsitua==6) return 1;
			else return -4;
		case 3: case 7:if (lsitua==5||lsitua==6||lsitua==7||lsitua==8) return 1;
			else return -4;
		default:return 1;
	}
}

int PopData(stack *p)
{
	if (p->data_curp == p->data_stack) return -1;
	else {
		p->data_out = *p->data_curp;
		*p->data_curp=0;
		p->data_curp--;
		return 1;
	}
}

int PushData(stack *p)
{
	if (p->data_curp==p->data_stack+MAXSIZE-1) return -1;
	else {
		p->data_curp++;
		*p->data_curp=p->data_in;
		return 1;
	}
}

int PopOprt(stack *p)
{
	if (p->oprt_curp == p->oprt_stack) return -1;
	else {
		p->oprt_out = *p->oprt_curp;
		*p->oprt_curp = '\0';
		p->oprt_curp --;
		return 1;
	}
}

int PushOprt(stack *p)
{
	if (p->oprt_curp == p->oprt_stack + MAXSIZE-1) return -1; 
	else {
		p->oprt_curp ++;
		*p->oprt_curp = p->oprt_in;
		return 1;
	}
}

void clear(stack *p)
{
	while(p->data_curp != p->data_stack)
		*(p->data_curp--) = 0;
	while(p->oprt_curp != p->oprt_stack)
		*(p->oprt_curp--) = '\0';
}

void Usage(const char *prog)
{
	printf("	Version: %s\n", version_id);
	printf("	Built date: %s\n", server_built);
	printf("	Usage: %s ARG1 [operator(+|-|*|/)] (-ARG2) <... ARGn>\n", prog);
}

int main(int argc, char **argv)
{
	int FState,LState,GramState,CalcuState;
	double result,TempData;
	char TempOprt;
	STK.data_curp=STK.data_stack;
	STK.oprt_curp=STK.oprt_stack;
	
	if (argc < 2)
	{
		Usage(argv[0]);
		return 1;
	}
	
	for (int i = 1; i < argc; i++)
	{
		strncat (liyx, argv[i], strlen(argv[i]));
	}
	
	strncat(liyx, "\n", strlen("\n"));
	
		
		clear(&STK);
		EXP_INIT=YES;
		BRACKET_COUNT=0;
		LState=100;
		GramState=1;
		CalcuState=1;
		
		do{
			FState=LState;
			if((LState=getexp(&STK.data_in,&STK.oprt_in))<0){
				error(LState);
				break;
			}
			if((GramState=checkgram(FState,LState))<0){
				error(GramState);
				break;
			}
			if(LState==1||LState==2||LState==3||LState==4)
				PushData(&STK);
			if(LState==2||(LState==6&&(FState==3||FState==7))){
				TempOprt=STK.oprt_in;
				STK.oprt_in='*';
			}
			while(priority(*(STK.oprt_curp),STK.oprt_in)>0&& *STK.oprt_curp!='(' && STK.oprt_curp!=STK.oprt_stack)
			{
				PopData(&STK);
				TempData=STK.data_out;
				PopData(&STK);
				PopOprt(&STK);
				CalcuState=calculat(STK.data_out,STK.oprt_out,TempData,&result);
				if(CalcuState<0) break;
				STK.data_in=result;
				PushData(&STK);
			}
			if(*STK.oprt_curp=='(' && (LState==3||LState==7)) PopOprt(&STK);
			if(!(LState==3||LState==4||LState==7||LState==8)) PushOprt(&STK);
			if(LState==2||(LState==6&&(FState==3||FState==7))){
				STK.oprt_in=TempOprt;
				PushOprt(&STK);
			}
			if(CalcuState<0){
				error(CalcuState);
				break;
			}

		}while (LState!=4&&LState!=8);

		if((LState==4||LState==8)&&BRACKET_COUNT!=0) error(-8);


		if((LState==4||LState==8) && BRACKET_COUNT==0 && GramState>0 && CalcuState>0 && FState+LState!=108)
			printf("%f\n",STK.data_in);

	return 0;
}
