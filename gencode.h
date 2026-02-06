#ifndef _GENCODE_H_
#define _GENCODE_H_

#include <stdint.h>

extern void generateCode(Program *, const char *);

extern int writeNumExpression(NodeList *n, int i, int num, FILE *f);
extern int writeExpression(NodeList *n, int i, FILE *f);
extern int writeExpressionProc(NodeList *n, int i, FILE *f);
extern int writeNumExpressionProc(NodeList *n, int i, int num, FILE *f);
extern void writeOp(unsigned short op, FILE *f);
extern void writeInt(uint32_t a, FILE *f);
extern void writeFloat(float a, FILE *f);
extern void writeString(uint32_t a, FILE *f);
extern int writeBlock(NodeList *n, int i, FILE *f);

#endif
