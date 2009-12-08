package htemplate;

class Parser
{
	static var openBlocks = [
		{ keyword : 'ifBlock', pattern : ~/^{#\s*if\b/},
		{ keyword : 'elseifBlock', pattern : ~/^{#\s*else\s+if\b/},
		{ keyword : 'elseBlock', pattern : ~/^{#\s*else\b/},
		{ keyword : 'forBlock', pattern : ~/^{#\s*for\b/},
		{ keyword : 'whileBlock', pattern : ~/^{#\s*while\b/},
	];

	private var captureStack : Array<String>;
	
	public function new()
	{
		captureStack = [];
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
			
			if(peek == '#' || peek == '$' || peek == '?' || peek == '!')
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
		
		throw 'Failed to find a closing delimiter for the script block: ' + scriptPart.substr(0, 100) + " ...";
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

		// So is restoreCapture
		if(template.substr(0, 3) == '{!}')
		{
			return { block: TBlock.restoreCapture(captureStack.pop()), length: 3 };
		}
		
		// Printblock - quite simple
		if(template.charAt(1) == '$')
		{
			var script = parseScript(template.substr(2));
			return { block: TBlock.printBlock(StringTools.trim(script)), length: 2 + script.length + 1 };
		}

		// openBlock
		if(template.charAt(1) == '#')
		{
			// Test whether the block is an open block {#if, {#for ... {#} or a codeblock.
			for(item in openBlocks)
			{
				if(item.pattern.match(template))
				{
					var script = parseScript(template.substr(item.pattern.matched(0).length));
					var block = Type.createEnum(TBlock, item.keyword, item.keyword == 'elseBlock' ? [] : [StringTools.trim(script)]);
					
					return { block: block, length: item.pattern.matched(0).length + script.length + 1 };
				}
			}
		}
		
		// codeBlock
		if(template.charAt(1) == '?')
		{
			var script = parseScript(template.substr(2));
			return { block: TBlock.codeBlock(StringTools.trim(script)), length: 2 + script.length + 1 };
		}
		
		// captureBlock
		if(template.charAt(1) == '!')
		{
			var variable = parseScript(template.substr(2));
			captureStack.push(StringTools.trim(variable));
			return { block: TBlock.captureBlock, length: 2 + variable.length + 1 };
		}

		
		// nextBlockPos() prevents from coming here, but just in case.
		throw 'No valid block type found: ' + template.substr(0, 100) + " ...";
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
		
		// Test if capture blocks matches up correctly.
		var captureCount = 0;
		for(block in output)
		{
			switch(block)
			{
				case captureBlock:
					captureCount++;
				case restoreCapture(_):
					captureCount--;
				default:
			}
		}
		
		if(captureCount != 0)
			throw 'Unmatched capture blocks:' + template.substr(0, 100) + " ...";
		
		return output;
	}
}