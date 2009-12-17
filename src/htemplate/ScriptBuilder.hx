package htemplate;

class ScriptBuilder
{
	private var context : String;

	public function new(context : String)
	{
		this.context = context;
	}
	
	public function build(blocks : Array<TBlock>) : String
	{
		var buffer = new StringBuf();
		
		for(block in blocks)
		{
			buffer.add(blockToString(block));
		}
//trace(buffer.toString());
		return buffer.toString();
	}
	
	public function blockToString(block : TBlock) : String
	{
		var output = context + '.add(';
		
		switch(block)
		{
			case literal(s):
				return context + ".add('" + StringTools.replace(s, "'", "\\'") + "');\n";
			
			case ifBlock(s):
				return "if(" + s + ") {\n";

			case elseifBlock(s):
				return "} else if(" + s + ") {\n";

			case elseBlock:
				return "} else {\n";

			case closeBlock:
				return "}\n";
				
			case forBlock(s):
				return "for(" + s + ") {\n";

			case whileBlock(s):
				return "while(" + s + ") {\n";

			case codeBlock(s):
				return s + "\n";
			
			case printBlock(s):
				return context + ".add(" + s + ");\n";
				
			// Capture blocks
			case captureBlock(_):
				return context + " = __string_buf__(" + context + ");\n";
				
			case captureCloseBlock(v):
				return v + " = " + context + ".toString();\n" + context + " = __restore_buf__();\n";
		}
	}
}