package htemplate;

enum TBlock
{
	literal(s : String);
	
	// Keyword blocks
	ifBlock(s : String);
	elseifBlock(s : String);
	elseBlock;
	forBlock(s : String);
	whileBlock(s : String);
	
	// Capture blocks
	captureBlock(v : String);
	captureCloseBlock(v : String);
	
	// And the closing block for the keywords
	closeBlock;

	codeBlock(s : String);
	printBlock(s : String);
	
	// TODO: Comment block {* *}
}