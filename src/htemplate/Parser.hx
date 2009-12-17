package htemplate;

class Parser
{
	private var blocksStack : Array<TBlock>;
	private var codeBuf : StringBuf;
	public function new()
	{
		blocksStack = [];
	}
	
	/**
	 * Parse a script block taking strings and other braces into account.
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
	
	private function cleanCondition(s : String)
	{
		s = StringTools.trim(s);
		if (s.substr(0, 1) == '(')
		{
			s = s.substr(1, s.length - 2);
			s = StringTools.trim(s);
		}
		return s;
	}
	
	private function parseBlock(blockType : String, template : String) : { block : TBlock, length : Int }
	{
		switch(blockType)
		{
			case ':':
				var script = parseScript(template);
				return { block: TBlock.printBlock(StringTools.trim(script)), length: script.length + 1 };
			case '?':
				var script = parseScript(template);
				return { block: TBlock.codeBlock(StringTools.trim(script)), length: script.length + 1 };
			case 'if', 'for', 'while':
				var script = parseScript(template);
				var block = Type.createEnum(TBlock, blockType + "Block", blockType == 'else' ? [] : [cleanCondition(script)]);
				blocksStack.push(block);
				return { block: block, length: script.length + 1 };
			case 'else if':
				var script = parseScript(template);
				var block = TBlock.elseifBlock(cleanCondition(script));
				return { block: block, length: script.length + 1 };
			case 'else':
				var script = parseScript(template);
				var block = TBlock.elseBlock;
				return { block: block, length: script.length + 1 };
			case 'set':
				var variable = parseScript(template);
				var block = TBlock.captureBlock(StringTools.trim(variable));
				blocksStack.push(block);
				return { block: block, length: variable.length + 1 };
			case 'eval':
				var variable = parseScript(template);
				var block = TBlock.codeBlock(null);
				blocksStack.push(block);
				codeBuf = new StringBuf();
				return { block: null, length: variable.length + 1 };
			case 'end':
				var block = blocksStack.pop();
				if (null == block) throw "unbalanced block ends";
				switch(block)
				{
					case ifBlock(_), forBlock(_), whileBlock(_):
						return { block: TBlock.closeBlock, length: 1 };
					case captureBlock(n):
						return { block: TBlock.captureCloseBlock(n), length: 1 };
						case codeBlock(_):
						var block = TBlock.codeBlock(StringTools.trim(codeBuf.toString()));
						codeBuf = null;
						return { block: block, length: 1 };
					default:
					throw "invalid block type in stack: " + block;
				}
			default:
				throw "invalid blockType: " + blockType; // should never happen
		}
	}
	
	static var validBlock = ~/\{([:?]|if|else if|else|for|while|set|eval|end)/;
	
	/**
	 * Takes a template string as input and returns an AST made of TBlock instances.
	 * @param	template
	 * @return
	 */
	public function parse(template : String) : Array<TBlock>
	{
		var output = new Array<TBlock>();
		
		while (validBlock.match(template))
		{
			var left = validBlock.matchedLeft(); // not sure if it returns null consistently
			if (null != left && '' != left)
			{
				if (null != codeBuf)
					codeBuf.add(left);
				else
					output.push(TBlock.literal(left));
			}
			var block = parseBlock(validBlock.matched(1), validBlock.matchedRight());
			if(null != block.block)
				output.push(block.block);
			template = validBlock.matchedRight().substr(block.length);
		}
		if (blocksStack.length > 0)
			throw "some blocks have not been correctly closed";
		if ("" != template)
		{
			output.push(TBlock.literal(template));
		}
		return output;
	}
}