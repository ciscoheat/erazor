/**
 * ...
 * @author $(DefaultUser)
 */

package htemplate;

enum TBlock 
{ 
	literal(s : String); 
	
	// Keyword blocks
	ifBlock(s : String);
	elseifBlock(s : String);
	elseBlock;
	forBlock(s : String);
	
	// And the closing block for the keywords
	closeBlock;
	
	codeBlock(s : String);
	printBlock(s : String);
	// TODO: Comment block {* *}
}

class HTemplateParser 
{
	static var openBlockKeywords = ['if', 'else', 'elseif', 'for'];
	
	public function new() 
	{
		
	}
	
	/**
	 * Returns the position of the next TBlock, or -1 if not found.
	 * A TBlock always starts with {# or {$
	 * @param	template
	 * @return
	 */
	private function nextBlockPos(template : String) : Int
	{
		var next = template.indexOf('{');

		while(next >= 0)
		{
			var peek = template.charAt(next + 1);
			
			if(peek == '#' || peek == '$')
			{
				return next;
			}
			else
			{
				next = template.indexOf('{', next + 1);
			}
		}
		
		return next;
	}

	/**
	 * Parse a script block (one starting with {# or {$, taking strings and other braces into account.
	 * @param	scriptPart
	 * @return
	 */
	private function parseScript(scriptPart : String) : String
	{
		var braceStack = 0;
		var insideSingleQuote = false;
		var insideDoubleQuote = false;
		
		var buffer = new StringBuf();
		var i = -1;
		
		while(++i < scriptPart.length)
		{
			var char = scriptPart.charAt(i);
			
			if(!insideDoubleQuote && !insideSingleQuote)
			{
				switch(char)
				{
					case '{':
						++braceStack;
					
					case '}':
						if(braceStack == 0)
						{
							return scriptPart.substr(0, i);
						}
						else
							--braceStack;
					
					case '"':
						insideDoubleQuote = true;
						
					case "'":
						insideSingleQuote = true;
				}
			}
			else if(insideDoubleQuote && char == '"' && scriptPart.charAt(i-1) != '\\')
			{
				insideDoubleQuote = false;
			}
			else if(insideSingleQuote && char == "'" && scriptPart.charAt(i-1) != '\\')
			{
				insideSingleQuote = false;
			}
		}
		
		throw 'Failed to find a closing delimiter for the script block.';
	}
	
	private function parseBlock(template : String) : { block : TBlock, length : Int }
	{
		// TODO: Alternate delimiter syntax
		
		var nextPos = nextBlockPos(template);
		
		// If no code block is at first position, return a literal block.
		if(nextPos > 0)
		{
			return { 
				block: TBlock.literal(template.substr(0, nextPos)), 
				length: nextPos
			};
		}

		// No code block found, this will be the last block in the parsing.
		if(nextPos == -1)
		{
			return { 
				block: TBlock.literal(template),
				length: template.length
			};
		}

		// A closeBlock is simple
		if(template.substr(0, 3) == '{#}')
		{
			return { block: TBlock.closeBlock, length: 3 };
		}
		
		// Printblock - quite simple
		if(template.charAt(1) == '$')
		{
			var script = parseScript(template.substr(2));			
			return { block: TBlock.printBlock(StringTools.trim(script)), length: 2 + script.length + 1 };
		}

		// openBlock or codeBlock
		if(template.charAt(1) == '#')
		{
			// Test whether the block is an open block {#if, {#for ... {#} or a codeblock.
			for(keyword in openBlockKeywords)
			{
				var test = new EReg('^{#\\s*' + keyword + '\\b', 'i');
				if(test.match(template))
				{
					var script = parseScript(template.substr(test.matched(0).length));
					var blockType = Type.resolveEnum('TBlock.' + keyword + 'Block');
					
					var block = Type.createEnum(TBlock, keyword + 'Block', keyword == 'else' ? [] : [StringTools.trim(script)]);
					
					return { block: block, length: test.matched(0).length + script.length + 1 };
				}
			}
			
			// No keyword, so it's a codeBlock.
			var script = parseScript(template.substr(2));
			return { block: TBlock.codeBlock(StringTools.trim(script)), length: 2 + script.length + 1 };
		}
		
		throw 'No valid block type found.';
	}
	
	public function parse(template : String) : Array<TBlock> 
	{
		var output = new Array<TBlock>();
		
		while(template.length > 0)
		{
			var blockInfo = parseBlock(template);
			
			// The blockinfo contains the next block and the length of it.
			// Push it to the output and shorten the template string.			
			output.push(blockInfo.block);
			template = template.substr(blockInfo.length);
		}
		
		return output;
	}
}