/**
 * ...
 * @author $(DefaultUser)
 */

package htemplate;

enum TBlock 
{ 
	literal(s : String); 
	openBlock(s : String); 
	closeBlock;
	codeBlock(s : String);
	printBlock(s : String);
	// TODO: Comment block {* *}
}

class HTemplateParser 
{
	static var blockTest = ~/{([$#])\s*([^}]*)\s*}/;
	
	public function new() 
	{
		
	}
	
	public function parse(template : String) : Array<TBlock> 
	{
		var output = new Array<TBlock>();
		
		while(blockTest.match(template))
		{
			var leftContent = blockTest.matchedLeft();			
			if(leftContent.length > 0)
				output.push(TBlock.literal(leftContent));
				
			template = blockTest.matchedRight();
			
			if(blockTest.matched(2).length == 0)
			{
				output.push(TBlock.closeBlock);
				continue;
			}
				
			switch(blockTest.matched(1))
			{
				case '$':
					output.push(TBlock.printBlock(blockTest.matched(2)));
				case '#':
					output.push(TBlock.openBlock(blockTest.matched(2)));
			}			
		}
		
		if(template.length > 0)
			output.push(TBlock.literal(template));
		
		return output;
	}
}