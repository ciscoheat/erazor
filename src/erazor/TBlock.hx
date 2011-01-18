package erazor;

enum TBlock
{
	// Pure text
	literal(s : String);
	
	// Code
	codeBlock(s : String);
	
	// Code that should be printed immediately
	printBlock(s : String);
}