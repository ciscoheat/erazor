package htemplate;

private typedef Block = {
	var block : TBlock;
	var length : Int;
}

private enum ParseContext {
	literal;
	code;
}

private enum ParseResult {
	keepGoing;
	doneIncludeCurrent;
	doneSkipCurrent;
}

class Parser
{
	private static var at = '@';
	
	private var condMatch : EReg;
	private var inConditionalMatch : EReg;
	private var variableMatch : EReg;
	private var variableChar : EReg;

	// State variables for the parser
	private var context : ParseContext;
	private var conditionalStack : Int;

	function parseScriptPart(template : String, startBrace = '{', endBrace = ')') : String
	{
		var insideSingleQuote = false;
		var insideDoubleQuote = false;
		
		// If startbrace is empty, assume we are in the script already.
		var stack = (startBrace == '') ? 1 : 0;
		var i = -1;
		
		while(++i < template.length)
		{
			var char = template.charAt(i);
			
			if(!insideDoubleQuote && !insideSingleQuote)
			{
				switch(char)
				{
					case startBrace:
						++stack;

					case endBrace:
						--stack;
						
						if(stack == 0)
							return template.substr(0, i+1);
						if (stack < 0)
							throw 'Unbalanced braces for block: ' + template.substr(0, 100) + " ...";						
					
					case '"':
						insideDoubleQuote = true;
						
					case "'":
						insideSingleQuote = true;
				}
			}
			else if(insideDoubleQuote && char == '"' && template.charAt(i-1) != '\\')
			{
				insideDoubleQuote = false;
			}
			else if(insideSingleQuote && char == "'" && template.charAt(i-1) != '\\')
			{
				insideSingleQuote = false;
			}
		}
		
		//trace(startBrace); trace(endBrace);
		throw 'Failed to find a closing delimiter for the script block: ' + template.substr(0, 100);
	}
	
	function parseContext(template : String) : ParseContext
	{
		// If a single @ is found, go into code context.
		if (template.charAt(0) == Parser.at && template.length > 1 && template.charAt(1) != Parser.at) 
			return ParseContext.code;
		
		// Same if we're inside a conditional and a } is found.
		if (this.conditionalStack > 0 && template.charAt(0) == '}')
			return ParseContext.code;
		
		// Otherwise parse pure text.
		return ParseContext.literal;
	}
	
	/**
	 * Main block parse method, called from parse().
	 */
	function parseBlock(template : String) : Block
	{
		//trace(">>> " + (template.length > 30 ? template.substr(0, 30) + '...' : template));
		return (context == ParseContext.code) ? parseCodeBlock(template) : parseLiteral(template);
	}

	function parseConditional(template : String) : Block
	{
		var str = parseScriptPart(template, '', '{');
		return { block: TBlock.codeBlock(str.substr(1)), length: str.length };
	}
	
	function parseVariable(template : String) : Block
	{
		var str = parseString(template.substr(1), parseVariableChar, false);
		return { block: TBlock.printBlock(str), length: str.length + 1 };
	}

	function parseVariableChar(char : String) : ParseResult
	{
		return variableChar.match(char) ? ParseResult.keepGoing : ParseResult.doneSkipCurrent;
	}

	function parseCodeBlock(template : String) : Block
	{
		// Test if at end of a conditional
		if (conditionalStack > 0 && template.charAt(0) == '}')
		{
			// It may not be an end, just a continuation
			if (inConditionalMatch.match(template))
			{
				var str = parseScriptPart(template, '', '{');
				return { block: TBlock.codeBlock(str), length: str.length };
			}
			
			//trace("--conditionalStack");
			--conditionalStack;
			
			return { block: TBlock.codeBlock('}'), length: 1 };
		}
		
		// Test for conditional code block
		if (condMatch.match(template))
		{
			//trace("++conditionalStack");
			++conditionalStack;
			
			return parseConditional(template);
		}
		
		// Test for variable like @name
		if (variableMatch.match(template))
			return parseVariable(template);
			
		// Test for code or print block @{ or @(
		var startBrace = template.charAt(1);		
		var endBrace = (startBrace == '{') ? '}' : ')';
		
		var str = parseScriptPart(template.substr(1), startBrace, endBrace);
		var noBraces = StringTools.trim(str.substr(1, str.length - 2));
		
		if(startBrace == '{')
			return { block: TBlock.codeBlock(noBraces), length: str.length + 1 };
		else // (
			return { block: TBlock.printBlock(noBraces), length: str.length + 1 };
	}
	
	private function parseString(str : String, modifier : String -> ParseResult, throwAtEnd : Bool) : String
	{
		var insideSingleQuote = false;
		var insideDoubleQuote = false;
		
		var i = -1;		
		while(++i < str.length)
		{
			var char = str.charAt(i);
			
			if(!insideDoubleQuote && !insideSingleQuote)
			{
				switch(modifier(char))
				{
					case ParseResult.doneIncludeCurrent:
						return str.substr(0, i + 1);
						
					case ParseResult.doneSkipCurrent:
						return str.substr(0, i);
						
					case ParseResult.keepGoing:
						// Just do as he says!
				}
				
				if (char == '"')
					insideDoubleQuote = true;
				else if (char == "'")
					insideSingleQuote = true;
			}
			else if(insideDoubleQuote && char == '"' && str.charAt(i-1) != '\\')
			{
				insideDoubleQuote = false;
			}
			else if(insideSingleQuote && char == "'" && str.charAt(i-1) != '\\')
			{
				insideSingleQuote = false;
			}
		}
		
		if(throwAtEnd)
			throw 'Failed to find a closing delimiter: ' + str.substr(0, 100);
	
		return str;
	}

	function parseLiteral(template : String) : Block
	{
		var nextAt = template.indexOf(Parser.at);
		var nextBracket = this.conditionalStack > 0 ? template.indexOf('}') : -1;
		
		//trace("nextAt: " + nextAt + ", nextBracket: " + nextBracket);

		while (nextAt >= 0 || nextBracket >= 0)
		{
			// If we hit a bracket before the @, return the block from there.
			if (nextBracket >= 0 && (nextAt == -1 || nextBracket < nextAt))
			{
				return { 
					block: TBlock.literal(escapeLiteral(template.substr(0, nextBracket))),
					length: nextBracket 
				};
			}

			var len = template.length;

			// Test for escaped @
			if (len > nextAt + 1 && template.charAt(nextAt + 1) != Parser.at)
			{
				return { 
					block: TBlock.literal(escapeLiteral(template.substr(0, nextAt))), 
					length: nextAt 
				};
			}
			
			nextAt = template.indexOf(Parser.at, nextAt + 2);
		}
		
		return { 
			block: TBlock.literal(escapeLiteral(template)), 
			length: template.length 
		};
	}
	
	function escapeLiteral(input : String) : String
	{
		return StringTools.replace(input, Parser.at + Parser.at, Parser.at);
	}
	
	/**
	 * Takes a template string as input and returns an AST made of TBlock instances.
	 * @param	template
	 * @return
	 */
	public function parse(template : String) : Array<TBlock>
	{
		var output = new Array<TBlock>();		
		conditionalStack = 0;
		
		while (template != '')
		{
			context = parseContext(template);
			var block = parseBlock(template);
			
			if(block.block != null)
				output.push(block.block);
				
			template = template.substr(block.length);
		}
		
		return output;
	}
	
	// Constructor must be put at end of class to prevent intellisense problems with regexps
	public function new()
	{
		// Some are quite simple, could be made with string functions instead for speed
		condMatch = ~/^@(?:if|for|while)\b/;
		inConditionalMatch = ~/^(?:\}[\s\r\n]*else if\b|\}[\s\r\n]*else[\s\r\n]*{)/;
		variableMatch = ~/^@[A-Za-z]/;
		variableChar = ~/^[\w\[\]"'\.]$/;
	}
}