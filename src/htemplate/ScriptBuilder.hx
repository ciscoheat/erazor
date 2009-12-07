/**
 * ...
 * @author $(DefaultUser)
 */

package htemplate;

import htemplate.HTemplateParser;

class ScriptBuilder 
{
	private var context : String;
	private var concatMethod : String;

	public function new(context : String, concatMethod : String)
	{
		this.context = context;
		this.concatMethod = concatMethod;
	}
	
	public function build(blocks : Array<TBlock>) : String
	{
		var buffer = new StringBuf();
		
		for(block in blocks)
		{
			buffer.add(blockToString(block));
		}
		
		return buffer.toString();
	}
	
	public function blockToString(block : TBlock) : String
	{
		var output = context + '.' + concatMethod + '(';
		
		switch(block)
		{
			case literal(s):
				output += "'" + StringTools.replace(s, "'", "\\'") + "'";
			
			case openBlock(s):
			case closeBlock:
			case codeBlock(s):
			case printBlock(s):
				output += s;
		}
		
		return output + ");\n";
	}
}